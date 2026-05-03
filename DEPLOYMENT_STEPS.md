# Deployment Steps - Reports Feature Fixes

## STEP 1: Run SQL Migration
**Location:** Supabase SQL Editor

**File:** `supabase/migrations/hotfix_reports_critical_issues.sql`

**What it does:**
- ✅ Fixes FK constraint violation (last_updated_by issue)
- ✅ Improves RLS policies with null checks
- ✅ Ensures task_reports creation succeeds

**How to run:**
1. Go to Supabase dashboard
2. Open SQL Editor
3. Copy entire contents of `hotfix_reports_critical_issues.sql`
4. Paste and run
5. Verify no errors

---

## STEP 2: Deploy Code Changes
**Modified Files (4 total):**

### File 1: ManagerReportView.tsx
✅ Already updated - fixes notification user_id issue

### File 2: ProviderReportForm.tsx
✅ Already updated - adds fallback report creation

### File 3: TodoItem.tsx
✅ Already updated - improves error messages

### File 4: New migration file
✅ Already created - `hotfix_reports_critical_issues.sql`

**Push these changes to your repository**

---

## STEP 3: Test the Fix (End-to-End)

### Test Flow:
1. **Manager:** Create new task
   - Title: "Fix broken door lock"
   - Assign to: Any service provider
   - Optional: Add checklist items
   - Optional: Select evidence requirements
   - Click "Create & Send Task"

2. **Service Provider:** Accept task
   - Go to To Do List tab
   - Click "Accept" on the task
   - Task appears in "Your Accepted Tasks"

3. **Service Provider:** Change status to In Progress
   - Click status dropdown
   - Select "In Progress"
   - ⚠️ This was causing the error
   - ✅ Should now work without error

4. **Verify:** Reports tab appears
   - Click Reports tab
   - Should see "Provider Report Form" (not loading state)
   - Should see blank report ready for input

5. **Service Provider:** Submit progress
   - Enter work description (e.g., "Installed new deadbolt")
   - Set completion percentage (e.g., 100%)
   - If checklist exists: Check off items
   - Click "Save Progress Report"

6. **Manager:** View and approve
   - Go to Reports tab
   - Manager view should show provider's progress
   - Should see "Approve Task" button
   - Click to approve

7. **Verify:** Task completes
   - Task status changes to "completed"
   - Provider receives notification
   - Task disappears from "Your Accepted Tasks"
   - Appears in completed section

---

## STEP 4: Verify Each Issue is Fixed

### ✓ Issue #1: FK Constraint Fixed
- [ ] Provider can change status without error
- [ ] Task status changes successfully
- [ ] task_reports record created in database

### ✓ Issue #2: Notification user_id Fixed
- [ ] Manager approves task
- [ ] Provider receives notification (check Notifications menu)
- [ ] Notification has correct task title

### ✓ Issue #3: RLS Policies Strengthened
- [ ] Manager can view provider reports
- [ ] Provider can only view their own reports
- [ ] Manager can only view reports for their tasks

### ✓ Issue #4: Error Messages Improved
- [ ] If error occurs, shows helpful message (not "[Object Object]")
- [ ] Error suggests fix (e.g., "refresh the page")

---

## STEP 5: Rollback (if needed)

**Only if something breaks:**

1. Supabase SQL Editor - run DROP statements to revert:
```sql
-- Drop the fixed trigger
DROP TRIGGER IF EXISTS on_task_in_progress_create_report ON public.tasks;

-- Drop the fixed function
DROP FUNCTION IF EXISTS public.create_report_on_in_progress();

-- Restore original RLS policies (if you saved them)
-- Or revert code changes
```

2. Revert code changes in:
   - `client/pages/tasks/components/ReportsTab/ManagerReportView.tsx`
   - `client/pages/tasks/components/ReportsTab/ProviderReportForm.tsx`
   - `client/components/TodoItem.tsx`

---

## Expected Behavior After Fix

| Action | Before | After |
|--------|--------|-------|
| Change todo status → in_progress | ❌ Error | ✅ Works |
| task_reports auto-create | ❌ FK error | ✅ Success |
| Reports form appears | ❌ Missing | ✅ Shows |
| Manager sends notification | ❌ Wrong user_id | ✅ Correct |
| Error messages | ❌ Cryptic | ✅ Helpful |

---

## Questions?

Refer to: `CRITICAL_FIXES_APPLIED.md` for detailed explanation of each fix.
