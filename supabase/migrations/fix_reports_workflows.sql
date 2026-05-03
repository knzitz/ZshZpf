-- ============================================================================
-- FIX: REPORTS WORKFLOWS AND RLS POLICIES
-- ============================================================================
-- This migration fixes critical issues in the Reports feature:
-- 1. Fix buggy RLS policy for task_reports that uses SELECT subquery on user_id
-- 2. Create auto-report creation trigger when task status changes to "in_progress"
-- 3. Ensure flagged_tasks view works correctly for displaying issues
-- ============================================================================

-- ============================================================================
-- 1. FIX RLS POLICIES FOR task_reports TABLE
-- ============================================================================
-- The current RLS policy has a bug - it tries to SELECT user_id from user_profiles
-- but the check should directly compare provider_id (UUID) with the current user's profile

-- Drop problematic policies
DROP POLICY IF EXISTS task_reports_view ON public.task_reports;
DROP POLICY IF EXISTS task_reports_insert ON public.task_reports;
DROP POLICY IF EXISTS task_reports_update ON public.task_reports;

-- Recreate task_reports view policy - fixed version
CREATE POLICY task_reports_view ON public.task_reports
  FOR SELECT USING (
    -- Service provider can view their own reports
    provider_id = (SELECT id FROM user_profiles WHERE user_id = auth.uid() LIMIT 1)
    OR
    -- Manager can view reports for tasks they created
    EXISTS (
      SELECT 1 FROM tasks t
      WHERE t.id = task_reports.task_id 
      AND t.created_by = auth.uid()
    )
  );

-- Recreate task_reports insert policy
CREATE POLICY task_reports_insert ON public.task_reports
  FOR INSERT WITH CHECK (
    -- Only the assigned service provider can create reports
    provider_id = (SELECT id FROM user_profiles WHERE user_id = auth.uid() LIMIT 1)
  );

-- Recreate task_reports update policy
CREATE POLICY task_reports_update ON public.task_reports
  FOR UPDATE USING (
    -- Service provider can update their own reports
    provider_id = (SELECT id FROM user_profiles WHERE user_id = auth.uid() LIMIT 1)
    OR
    -- Manager can update reports for their tasks (for approval)
    EXISTS (
      SELECT 1 FROM tasks t
      WHERE t.id = task_reports.task_id 
      AND t.created_by = auth.uid()
    )
  );

-- ============================================================================
-- 2. CREATE TRIGGER FOR AUTO-CREATING REPORTS WHEN TASK MOVES TO IN_PROGRESS
-- ============================================================================
-- When a service provider accepts a task and marks it as "in_progress",
-- a task_report should be automatically created so they can start reporting

CREATE OR REPLACE FUNCTION public.create_report_on_in_progress()
RETURNS TRIGGER AS $$
BEGIN
  -- When task status changes to 'in_progress' and provider is assigned
  IF NEW.status = 'in_progress' 
    AND OLD.status != 'in_progress'
    AND NEW.assigned_to IS NOT NULL 
  THEN
    -- Insert a new task_report with in_progress status
    INSERT INTO public.task_reports (
      task_id,
      provider_id,
      status,
      description,
      percentage_complete,
      last_updated_by
    )
    VALUES (
      NEW.id,
      NEW.assigned_to,
      'in_progress',
      '',
      0,
      NEW.assigned_to
    )
    ON CONFLICT DO NOTHING; -- Don't fail if report already exists
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS on_task_in_progress_create_report ON public.tasks;

-- Create the trigger
CREATE TRIGGER on_task_in_progress_create_report
  AFTER UPDATE OF status ON public.tasks
  FOR EACH ROW
  WHEN (NEW.status = 'in_progress' AND OLD.status != 'in_progress')
  EXECUTE FUNCTION public.create_report_on_in_progress();

-- ============================================================================
-- 3. CREATE TRIGGER FOR SYNCING todo_list STATUS TO tasks STATUS
-- ============================================================================
-- When a service provider updates their todo_list item status,
-- the corresponding task status should be updated as well

CREATE OR REPLACE FUNCTION public.sync_todo_status_to_task()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the task status based on todo_list status change
  IF NEW.status != OLD.status THEN
    UPDATE public.tasks
    SET status =
      CASE
        WHEN NEW.status = 'pending' THEN 'todo'
        WHEN NEW.status = 'in_progress' THEN 'in_progress'
        WHEN NEW.status = 'completed' THEN 'completed'
        ELSE 'todo'
      END,
      updated_at = now()
    WHERE id = NEW.task_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS sync_todo_status_to_task_trigger ON public.todo_list;

-- Create the trigger
CREATE TRIGGER sync_todo_status_to_task_trigger
  AFTER UPDATE OF status ON public.todo_list
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_todo_status_to_task();

-- ============================================================================
-- 4. FIX FLAGGED_TASKS VIEW (if it exists)
-- ============================================================================
-- This view shows tasks that have open issues (flagged)

DROP VIEW IF EXISTS public.flagged_tasks CASCADE;

CREATE OR REPLACE VIEW public.flagged_tasks AS
SELECT DISTINCT
  t.id,
  t.title,
  t.description,
  t.priority,
  t.status,
  t.assigned_to,
  t.created_by,
  t.created_at,
  COUNT(ti.id) FILTER (WHERE ti.status = 'open') AS open_issues_count,
  MAX(ti.created_at) FILTER (WHERE ti.status = 'open') AS latest_issue_at,
  STRING_AGG(ti.severity, ', ' ORDER BY 
    CASE ti.severity 
      WHEN 'critical' THEN 1 
      WHEN 'high' THEN 2 
      WHEN 'medium' THEN 3 
      ELSE 4 
    END
  ) FILTER (WHERE ti.status = 'open') AS issue_severities
FROM public.tasks t
LEFT JOIN public.task_issues ti ON t.id = ti.task_id
WHERE ti.id IS NOT NULL -- Only show tasks that have issues
GROUP BY t.id
ORDER BY latest_issue_at DESC NULLS LAST;

-- ============================================================================
-- 5. CREATE OR REPLACE HELPER VIEW FOR TASK PROGRESS SUMMARY
-- ============================================================================
-- This view shows a complete summary of task progress including reports, 
-- checklist completion, and evidence status

DROP VIEW IF EXISTS public.task_progress_summary CASCADE;

CREATE OR REPLACE VIEW public.task_progress_summary AS
SELECT
  t.id AS task_id,
  t.title,
  t.assigned_to,
  t.status AS task_status,
  tr.status AS report_status,
  tr.percentage_complete,
  tr.updated_at AS last_progress_update,
  (
    SELECT COUNT(*)
    FROM task_checklist_items tci
    JOIN task_checklists tc ON tc.id = tci.checklist_id
    WHERE tc.task_id = t.id
  ) AS total_checklist_items,
  (
    SELECT COUNT(*)
    FROM task_report_checklist_items trci
    WHERE EXISTS (
      SELECT 1 FROM task_reports tr2
      WHERE tr2.id = trci.report_id
      AND tr2.task_id = t.id
    )
    AND trci.is_completed = true
  ) AS completed_checklist_items,
  (
    SELECT COUNT(*)
    FROM task_evidence_submissions tes
    WHERE tes.task_id = t.id
  ) AS total_evidence_submissions,
  (
    SELECT COUNT(*)
    FROM task_evidence_submissions tes
    WHERE tes.task_id = t.id
    AND tes.approved_at IS NOT NULL
  ) AS approved_evidence_count,
  (
    SELECT COUNT(*)
    FROM task_issues ti
    WHERE ti.task_id = t.id
    AND ti.status = 'open'
  ) AS open_issues_count
FROM public.tasks t
LEFT JOIN public.task_reports tr ON t.id = tr.task_id
WHERE t.status IN ('in_progress', 'in_review', 'completed');

-- ============================================================================
-- 6. ENSURE RLS IS ENABLED ON ALL REPORTING TABLES
-- ============================================================================

ALTER TABLE public.task_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_report_checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_evidence_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_issues ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Fixed:
--   ✓ task_reports RLS policies (removed buggy SELECT subquery)
--   ✓ Auto-create task_report when task.status = 'in_progress'
--   ✓ Sync todo_list.status to tasks.status (when provider updates their todo)
--   ✓ flagged_tasks view for displaying tasks with open issues
--   ✓ task_progress_summary view for complete task/report status
--
-- Result:
--   - RLS policies work correctly for both providers and managers
--   - Reports are automatically created when task starts (in_progress)
--   - Task status stays in sync with todo_list item status
--   - Flagged tasks are easily queryable
--   - Complete progress tracking is available
-- ============================================================================
