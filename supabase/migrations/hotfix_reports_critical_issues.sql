-- ============================================================================
-- HOTFIX: CRITICAL ISSUES IN REPORTS WORKFLOW
-- ============================================================================
-- This migration fixes:
-- 1. FK constraint violations when creating task_reports (last_updated_by issue)
-- 2. RLS policy null check issues
-- 3. Sync trigger properly using correct task assignment
-- ============================================================================

-- ============================================================================
-- 1. FIX: TASK REPORTS FK CONSTRAINT VIOLATION
-- ============================================================================
-- Problem: create_report_on_in_progress() sets last_updated_by = NEW.assigned_to
-- But NEW.assigned_to is user_profiles.id, and task_reports.last_updated_by 
-- has FK constraint to auth.users(id)
--
-- Solution: Get the actual auth.users.id from user_profiles

CREATE OR REPLACE FUNCTION public.create_report_on_in_progress()
RETURNS TRIGGER AS $$
DECLARE
  provider_user_id UUID;
BEGIN
  -- When task status changes to 'in_progress' and provider is assigned
  IF NEW.status = 'in_progress' 
    AND OLD.status != 'in_progress'
    AND NEW.assigned_to IS NOT NULL 
  THEN
    -- Get the auth.users.id for this provider
    SELECT user_id INTO provider_user_id
    FROM user_profiles
    WHERE id = NEW.assigned_to
    LIMIT 1;

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
      COALESCE(provider_user_id, NEW.created_by)  -- Use provider's user_id, fallback to task creator
    )
    ON CONFLICT DO NOTHING; -- Don't fail if report already exists
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_task_in_progress_create_report ON public.tasks;

CREATE TRIGGER on_task_in_progress_create_report
  AFTER UPDATE OF status ON public.tasks
  FOR EACH ROW
  WHEN (NEW.status = 'in_progress' AND OLD.status != 'in_progress')
  EXECUTE FUNCTION public.create_report_on_in_progress();

-- ============================================================================
-- 2. FIX: RLS POLICIES WITH NULL CHECKS
-- ============================================================================
-- Add COALESCE to prevent null comparison issues

DROP POLICY IF EXISTS task_reports_view ON public.task_reports;
DROP POLICY IF EXISTS task_reports_insert ON public.task_reports;
DROP POLICY IF EXISTS task_reports_update ON public.task_reports;

-- View policy with null safety
CREATE POLICY task_reports_view ON public.task_reports
  FOR SELECT USING (
    -- Service provider can view their own reports
    provider_id = COALESCE(
      (SELECT id FROM user_profiles WHERE user_id = auth.uid() LIMIT 1),
      '00000000-0000-0000-0000-000000000000'::uuid
    )
    OR
    -- Manager can view reports for tasks they created
    EXISTS (
      SELECT 1 FROM tasks t
      WHERE t.id = task_reports.task_id 
      AND t.created_by = auth.uid()
    )
  );

-- Insert policy with null safety
CREATE POLICY task_reports_insert ON public.task_reports
  FOR INSERT WITH CHECK (
    -- Only the assigned service provider can create reports
    provider_id = COALESCE(
      (SELECT id FROM user_profiles WHERE user_id = auth.uid() LIMIT 1),
      '00000000-0000-0000-0000-000000000000'::uuid
    )
  );

-- Update policy with null safety
CREATE POLICY task_reports_update ON public.task_reports
  FOR UPDATE USING (
    -- Service provider can update their own reports
    provider_id = COALESCE(
      (SELECT id FROM user_profiles WHERE user_id = auth.uid() LIMIT 1),
      '00000000-0000-0000-0000-000000000000'::uuid
    )
    OR
    -- Manager can update reports for their tasks (for approval)
    EXISTS (
      SELECT 1 FROM tasks t
      WHERE t.id = task_reports.task_id 
      AND t.created_by = auth.uid()
    )
  );

-- ============================================================================
-- 3. VERIFY sync_todo_status_to_task TRIGGER IS CORRECT
-- ============================================================================
-- This trigger syncs todo_list status changes back to tasks table
-- Should already be correct from previous migration

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

-- ============================================================================
-- 4. ENSURE task_reports TABLE HAS PROPER FK CONSTRAINTS
-- ============================================================================
-- Verify the FK constraint is defined correctly

-- Check if FK exists and has correct reference
-- task_reports.last_updated_by should reference auth.users(id)
-- task_reports.provider_id should reference user_profiles(id)

-- If task_reports.last_updated_by is missing FK, add it:
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'task_reports_last_updated_by_fkey'
    AND table_name = 'task_reports'
  ) THEN
    ALTER TABLE public.task_reports
    ADD CONSTRAINT task_reports_last_updated_by_fkey 
    FOREIGN KEY (last_updated_by) REFERENCES auth.users(id) ON DELETE SET NULL;
  END IF;
END $$;

-- ============================================================================
-- SUMMARY OF FIXES
-- ============================================================================
-- ✓ Fixed FK violation: create_report_on_in_progress now gets correct user_id
-- ✓ Added null checks to RLS policies to prevent silent failures
-- ✓ Ensured sync_todo_status_to_task uses correct field mappings
-- ✓ Verified FK constraints are in place
--
-- Result: Service providers can now change task status without FK errors
-- ============================================================================
