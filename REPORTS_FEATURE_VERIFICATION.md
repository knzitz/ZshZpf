# Reports Feature - Complete Verification Checklist

## Pre-Deployment Checklist

### Database Migration
- [ ] Run SQL migration: `supabase/migrations/fix_reports_workflows.sql`
  - [ ] Verify: RLS policies created for task_reports
  - [ ] Verify: Trigger created for auto-report creation on task in_progress
  - [ ] Verify: Trigger created for syncing todo_list status to tasks status
  - [ ] Verify: flagged_tasks view created
  - [ ] Verify: task_progress_summary view created

### Frontend Code Changes
- [ ] ProviderReportForm.tsx improved error handling
- [ ] ManagerReportView.tsx has evidence approval UI
- [ ] TodoItem.tsx restricts "Completed" status (only Pending, In Progress)
- [ ] ReportsTab.tsx uses useMemo for relevantTasks

---

## Workflow Testing

### Test Case 1: Manager Creates Task with Checklist & Evidence Requirements

**Setup:**
- Login as Manager
- Navigate to Tasks > New Task tab

**Steps:**
1. Fill in task title: "Paint Conference Room"
2. Fill in description: "Paint all walls in conference room A"
3. Set priority: "High"
4. Set budget: "$1500"
5. **Checklist Section:**
   - [ ] Add item: "Prepare surfaces"
   - [ ] Add item: "Prime walls"
   - [ ] Add item: "Apply first coat"
   - [ ] Add item: "Apply second coat"
   - [ ] Add item: "Clean up and inspect"
6. **Evidence Requirements:**
   - [x] Photo (checkbox)
   - [x] Video (checkbox)
   - [ ] Document (leave unchecked)
7. Select Service Provider
8. Click "Create Task"

**Expected Results:**
- [ ] Task created successfully
- [ ] Checklist items saved to `task_checklists` and `task_checklist_items` tables
- [ ] Evidence requirements saved to `task_evidence_requirements` table
- [ ] Toast shows "Task created successfully"

---

### Test Case 2: Service Provider Accepts Task

**Setup:**
- Login as Service Provider
- Task from Test Case 1 is available for response

**Steps:**
1. Navigate to Tasks > To Do List tab
2. Find the task "Paint Conference Room" under "Assigned to You"
3. Click task card to see details
4. Click "Accept Task" button

**Expected Results:**
- [ ] Task response recorded in `task_responses` table
- [ ] Task appears in "Your Accepted Tasks" section
- [ ] Status shows: "Pending"
- [ ] Task is now in their TodoList as a TodoItem

---

### Test Case 3: Service Provider Marks Task as In Progress

**Setup:**
- Service Provider has accepted task from Test Case 2

**Steps:**
1. In "Your Accepted Tasks" section, find the task
2. Click on the Task card
3. In the Status dropdown, select "In Progress"

**Expected Results:**
- [ ] TodoItem status changes to "In Progress"
- [ ] `todo_list.status` updated to "in_progress"
- [ ] `tasks.status` synced to "in_progress" (via trigger)
- [ ] Task now appears in Reports tab (filtered by status = "in_progress")
- [ ] `task_reports` record created automatically (via trigger)
- [ ] Toast shows "Task moved to in progress"

---

### Test Case 4: Service Provider Submits Progress Report

**Setup:**
- Service Provider task status is "In Progress"
- Provider is viewing the task in "Your Accepted Tasks" or Reports tab

**Steps:**
1. Navigate to Reports tab
2. Task should appear in the list
3. Click on the task to open ProviderReportForm
4. Fill in "Work Description & Progress": "Prepared all surfaces, sanded and cleaned. Starting primer tomorrow."
5. Set Completion Percentage: 25%
6. Click "Save Progress Report"

**Expected Results:**
- [ ] `task_reports` record created/updated with description and percentage
- [ ] Toast shows "Progress report updated/created"
- [ ] Form persists the values

---

### Test Case 5: Service Provider Updates Checklist Items

**Setup:**
- Service Provider has submitted progress report
- Task has checklist items (from Test Case 1)

**Steps:**
1. In Reports tab, scroll to "Task Checklist" section
2. Check "Prepare surfaces"
3. Check "Prime walls"

**Expected Results:**
- [ ] Checkboxes toggle
- [ ] `task_report_checklist_items` records created for checked items
- [ ] Checklist progress shows "2/5" items completed
- [ ] Progress bar updates

---

### Test Case 6: Service Provider Submits Evidence

**Setup:**
- Service Provider has submitted progress report
- Task has evidence requirements (photo and video)

**Steps:**
1. In Reports tab, scroll to "Evidence Required" section
2. Click "+ Upload Evidence"
3. Set Evidence Type: "Photo"
4. Set Description: "Before and after photos of prepared surfaces"
5. Upload 2-3 image files (or use test images)
6. Click submit button in file upload
7. Repeat with Video type if possible

**Expected Results:**
- [ ] Files uploaded successfully to B2 storage
- [ ] `attachments` records created
- [ ] `task_evidence_submissions` records created with:
  - [ ] evidence_type: "photo" or "video"
  - [ ] task_id: correct task ID
  - [ ] provider_id: correct provider ID
  - [ ] submitted_at: current timestamp
  - [ ] approved_at: NULL (not yet approved)
- [ ] "Pending Approval" section shows submitted evidence
- [ ] Toast shows "1 evidence file(s) uploaded"

---

### Test Case 7: Service Provider Raises an Issue

**Setup:**
- Service Provider is in Reports tab for their task

**Steps:**
1. Scroll to "Issues & Blockers" section
2. Click "+ Raise Issue" button
3. Fill in Issue Title: "Primer not available"
4. Fill in Description: "Ordered primer didn't arrive as scheduled. Delayed delivery expected tomorrow."
5. Set Severity: "High"
6. Click "Raise Issue" button

**Expected Results:**
- [ ] `task_issues` record created with:
  - [ ] task_id: correct task ID
  - [ ] provider_id: correct provider ID
  - [ ] title: "Primer not available"
  - [ ] status: "open"
  - [ ] severity: "high"
- [ ] "Open Issues" section shows the issue
- [ ] Toast shows "Issue raised and task flagged"
- [ ] Issue appears with red/orange background based on severity

---

### Test Case 8: Manager Views Real-Time Progress in Reports Tab

**Setup:**
- Manager is logged in
- Service Provider has submitted reports, evidence, and raised issues

**Steps:**
1. Navigate to Tasks > Reports tab
2. Manager should see a list of all in-progress tasks
3. Click on the task "Paint Conference Room"
4. Review ManagerReportView:

**Expected Results - Progress Report:**
- [ ] Task title and description visible
- [ ] Completion percentage shows: "25%"
- [ ] Progress bar shows 25% filled
- [ ] Report status shows: "in_progress"
- [ ] Last updated timestamp shown

**Expected Results - Checklist Progress:**
- [ ] Shows "2/5" items completed
- [ ] Progress bar shows 40% (2/5)
- [ ] Checked items show with green checkmark and strikethrough
- [ ] Unchecked items show empty checkbox

**Expected Results - Evidence Review:**
- [ ] "Pending Review" section shows submitted evidence
- [ ] Evidence cards show:
  - [ ] Type: "PHOTO" or "VIDEO"
  - [ ] Description: provided text
  - [ ] "Approve" button present
- [ ] No "Approved" section yet (nothing approved)

**Expected Results - Issues & Blockers:**
- [ ] "Open Issues" section shows the raised issue
- [ ] Issue card shows:
  - [ ] Title: "Primer not available"
  - [ ] Description: full description
  - [ ] Severity badge: "HIGH"
  - [ ] "Resolve" button present
- [ ] No "Resolved" section yet

---

### Test Case 9: Manager Approves Evidence

**Setup:**
- Manager is viewing task progress in Reports tab
- Evidence is pending approval

**Steps:**
1. In "Evidence Review" section, find "Pending Review" evidence
2. Click "Approve" button on the photo evidence

**Expected Results:**
- [ ] `task_evidence_submissions` record updated:
  - [ ] approved_at: set to current timestamp
  - [ ] approved_by: set to manager's user_id
- [ ] Evidence moves from "Pending Review" to "✓ Approved" section
- [ ] Toast shows "Evidence approved"
- [ ] Button disappears from approved evidence

---

### Test Case 10: Manager Resolves Issue

**Setup:**
- Manager is viewing task progress in Reports tab
- An open issue is displayed

**Steps:**
1. In "Issues & Blockers" section, find the open issue "Primer not available"
2. Click "Resolve" button

**Expected Results:**
- [ ] `task_issues` record updated:
  - [ ] status: changed to "resolved"
  - [ ] resolved_at: set to current timestamp
- [ ] Issue moves from "Open Issues" to "Resolved" section
- [ ] Issue no longer shows in red/orange background
- [ ] Toast shows "Issue marked as resolved"

---

### Test Case 11: Manager Approves Task (Auto-Completion)

**Setup:**
- Manager is viewing task progress
- All evidence approved
- Open issues resolved
- Task report shows good progress

**Steps:**
1. Review all evidence (checklist, photos, descriptions)
2. Scroll to bottom of ManagerReportView
3. If report status is "completed_pending_approval":
   - [ ] Button shown: "✓ Approve & Complete Task"
4. Click the approval button

**Expected Results:**
- [ ] `task_reports` status updated to "approved"
- [ ] `tasks` status updated to "completed" (via trigger `on_report_approved_complete_task`)
- [ ] Task no longer appears in Reports tab (filtered by in_progress status only)
- [ ] Manager sees "✓ Task Approved and Completed" message
- [ ] Service Provider's TodoItem status changed to "completed" 
- [ ] Service Provider receives notification: "Your task '...' has been approved and marked complete"

---

### Test Case 12: Service Provider Cannot Manually Mark Task as Completed

**Setup:**
- Service Provider is in their accepted tasks
- Task is in "In Progress" status

**Steps:**
1. Navigate to "Your Accepted Tasks" section
2. Find the task
3. Click on status dropdown in TodoItem

**Expected Results:**
- [ ] Dropdown shows only options:
  - [ ] "Pending"
  - [ ] "In Progress"
- [ ] NO "Completed" option visible
- [ ] Dropdown disabled when status is already "completed"
- [ ] Message shown: "Once you complete the work, use the Reports tab to submit evidence and request approval from the manager."

---

### Test Case 13: Flagged Tasks View (Issues Dashboard)

**Setup:**
- Multiple tasks exist with open issues

**Steps:**
1. If Reports feature has a Flagged Tasks view/dashboard:
2. Check that `flagged_tasks` view returns all tasks with open issues

**Expected Results:**
- [ ] `flagged_tasks` view returns correct tasks
- [ ] Each row shows:
  - [ ] task id
  - [ ] title
  - [ ] number of open_issues_count
  - [ ] latest_issue_at timestamp
  - [ ] issue_severities (comma-separated)
- [ ] Tasks ordered by latest_issue_at DESC

---

### Test Case 14: Task Progress Summary View

**Setup:**
- Multiple tasks in various stages of completion

**Steps:**
1. Query `task_progress_summary` view for in-progress tasks

**Expected Results:**
- [ ] View returns complete summary for each task:
  - [ ] task_id
  - [ ] title
  - [ ] assigned_to
  - [ ] task_status (in_progress, in_review, completed)
  - [ ] report_status (pending, in_progress, completed_pending_approval, approved)
  - [ ] percentage_complete (0-100)
  - [ ] last_progress_update timestamp
  - [ ] total_checklist_items
  - [ ] completed_checklist_items
  - [ ] total_evidence_submissions
  - [ ] approved_evidence_count
  - [ ] open_issues_count

---

## Security Testing

### RLS Policy Tests

**Test Case A: Service Provider RLS**
- [ ] Provider can view only their own task_reports
- [ ] Provider can create reports only for their assigned tasks
- [ ] Provider can update only their own reports
- [ ] Provider cannot view/edit other providers' reports
- [ ] Provider cannot view manager-only fields

**Test Case B: Manager RLS**
- [ ] Manager can view all task_reports for tasks they created
- [ ] Manager cannot view reports for tasks created by others
- [ ] Manager can update reports for approval
- [ ] Manager cannot approve their own reports (depends on business logic)

---

## Performance Testing

### Large Dataset
- [ ] Load test with 100+ tasks in progress
- [ ] Reports tab loads in < 2 seconds
- [ ] Checklist with 50+ items loads smoothly
- [ ] Evidence submissions with 10+ items loads smoothly
- [ ] No N+1 query problems

---

## Edge Cases

### Test Case E1: No Report Exists Yet
- [ ] Provider marks task as in_progress
- [ ] Report is auto-created (via trigger)
- [ ] Provider can immediately start submitting progress
- [ ] No "No report submitted yet" error

### Test Case E2: Multiple Evidence Types
- [ ] Provider uploads photo
- [ ] Provider uploads video
- [ ] Provider uploads document
- [ ] All appear in pending review
- [ ] Manager can approve each individually

### Test Case E3: Checklist with No Items
- [ ] Task created without checklist items
- [ ] Checklist section not shown in Reports tab
- [ ] No error thrown

### Test Case E4: No Evidence Requirements
- [ ] Task created without evidence requirements
- [ ] Evidence section not shown in Reports tab
- [ ] Provider can still submit progress and mark complete

### Test Case E5: Task Status Sync
- [ ] Provider changes todo status to in_progress
- [ ] `tasks.status` automatically synced to "in_progress" (via trigger)
- [ ] No manual update needed

---

## Regression Testing

- [ ] Task creation still works for tasks without checklists
- [ ] Task acceptance workflow unchanged
- [ ] Proposal workflow unchanged
- [ ] Existing completed tasks still show as completed
- [ ] Todo items show negotiated prices correctly
- [ ] Notifications still sent on task completion

---

## Final Validation

- [ ] All migrations run without errors
- [ ] No SQL syntax errors
- [ ] RLS policies don't block legitimate access
- [ ] Triggers fire correctly
- [ ] Views return expected data
- [ ] Frontend handles all error cases gracefully
- [ ] Toast notifications appear correctly
- [ ] No console errors in browser
- [ ] Performance is acceptable

---

## Sign-Off

- [ ] Feature implementation complete
- [ ] All tests passed
- [ ] Security verified
- [ ] Ready for production deployment

**Tester:** ________________  
**Date:** ________________  
**Notes:** ________________________________________________
