# Reports Feature - Quick Start Guide

## What Was Implemented

This implementation provides a complete Reports workflow enabling service providers to report on task progress and managers to review and approve work in real-time.

---

## For Managers: Creating Tasks with Checklists and Evidence Requirements

### Step 1: Go to Tasks Page → "New Task" Tab

### Step 2: Fill in Basic Task Information
- Task Title *
- Description
- Priority *
- Category *
- Assignment Type (Internal/External) *
- Assign To *
- Due Date *
- Estimated Time
- Payment Terms
- Budget

### Step 3: (NEW) Add Checklist Items (Optional)

**Section:** "Task Checklist (Optional)" - Light blue section

- Click **"+ Add Item"** button
- Enter checklist item (e.g., "Inspect faucet")
- Add another item (e.g., "Replace seals")
- Remove items with **"Remove"** button
- Items appear in service provider's Reports tab

**Example checklist:**
```
□ Inspect faucet and identify issue
□ Replace washers/seals as needed
□ Test water flow and check for leaks
□ Clean up work area
```

### Step 4: (NEW) Select Evidence Requirements (Optional)

**Section:** "Evidence/Proof Requirements (Optional)" - Light green section

Select what types of proof you need:
- ☑ Photo (images/screenshots)
- ☑ Video (video recordings)
- ☑ Document (documents/files/signatures)

Selected evidence types appear in a summary box below.

### Step 5: Add Attachments (Optional)

**Section:** "Attachments & Media"

Drag-and-drop or click to upload files related to the task.

### Step 6: Click "Create & Send Task"

- Task is created
- Checklist items are saved to `task_checklists` table
- Evidence requirements are saved to `task_evidence_requirements` table
- Service provider receives notification

---

## For Service Providers: Accepting and Reporting on Tasks

### Step 1: Accept Task

**Location:** Tasks → "To Do List" tab → "Awaiting Your Response" section

- See task details: title, description, budget, due date, priority
- Click **"Accept"** button
- Task moves to "Your Accepted Tasks" section

### Step 2: Change Task Status to "In Progress"

**Location:** Tasks → "To Do List" tab → "Your Accepted Tasks" section

- Find the task card
- Locate "Task Status" dropdown
- Select **"In Progress"** (Pending, In Progress, ~~Completed~~)
- Task now appears in **Reports** tab

**Note:** You cannot select "Completed" - only managers can approve and complete tasks.

### Step 3: Go to Reports Tab

**Location:** Tasks → **"Reports"** tab

- Select your task from "Select Task" dropdown
- See report form

### Step 4: Update Progress Report

**Section:** "Progress Report & Progress"

- **Work Description & Progress:** Write what you've completed, what you're working on, any notes
- **Completion Percentage:** Drag slider to show how complete the task is (0-100%)
- Click **"Save Progress Report"** button

**Example progress update:**
```
Day 1: Completed wall preparation (patching, sanding). Walls smooth and ready for paint.
Day 2: Applied base coat to all walls. Color looks excellent.
Day 3: Finishing second coat now.
```

### Step 5: Check Off Checklist Items (if checklist exists)

**Section:** "Task Checklist (X/Y items complete)"

Only visible if manager created a checklist for this task.

- ☑ Check box for each completed item
- Add notes per item (e.g., "Installed new rubber washers")
- Completion count updates automatically

### Step 6: Upload Evidence (if required)

**Section:** "Evidence Required"

Only visible if manager specified evidence requirements.

**To upload evidence:**
1. Click **"+ Upload Evidence"** button
2. Select evidence type:
   - Photo
   - Video
   - Document
3. Add optional description (e.g., "Photos showing completion")
4. Upload files via drag-and-drop or file picker
5. Manager will see evidence and approve/reject

**Evidence statuses:**
- ⏳ **Pending Approval** - Awaiting manager review
- ✓ **Approved** - Manager approved this evidence

### Step 7: Raise Issues (if blocked)

**Section:** "Issues & Blockers"

If you encounter problems:

1. Click **"+ Raise Issue"** button
2. Enter:
   - **Issue Title** (e.g., "Marble tile delivery delayed")
   - **Description** (detailed explanation)
   - **Severity:** Low, Medium, High, Critical
3. Click **"Raise Issue"** button
4. Manager is notified and task is flagged for attention

**Open issues appear in red/orange** and alert the manager.

---

## For Managers: Reviewing and Approving Reports

### Step 1: Go to Reports Tab

**Location:** Tasks → **"Reports"** tab

### Step 2: Select a Task

**Section:** "Select Task"

- Dropdown shows all in-progress tasks
- Select a task to review its report

### Step 3: View Service Provider's Report

**Task Information:**
- Title, description, priority, budget

**Progress Report:**
- Status badge (In Progress)
- Completion percentage (visual progress bar)
- Provider's description of work

### Step 4: Check Checklist Progress (if applicable)

**Section:** "Checklist Progress (X/Y items complete)"

- Visual list of all checklist items
- Checkmarks show completed items
- Notes from service provider visible

Example:
```
✓ Inspect faucet and identify issue
  "Found worn rubber washer causing leak"
✓ Replace washers/seals as needed
  "Installed new rubber washers"
○ Test water flow and check for leaks
○ Clean up work area
```

### Step 5: Review Evidence (if required)

**Section:** "Evidence Review"

**Approved Evidence:**
- ✓ Green section showing approved submissions
- Type, description, status

**Pending Evidence:**
- ⏳ Yellow section showing pending submissions
- Click **"Approve"** button to approve
- Click **"Reject"** button to request resubmission

**Managing Evidence:**
- Click **"Approve"** to accept evidence
- Rejected evidence stays in pending until resubmitted

### Step 6: Address Open Issues (if any)

**Section:** "Issues & Blockers"

Color-coded by severity:
- 🔴 **CRITICAL** - Red
- 🟠 **HIGH** - Orange
- 🟡 **MEDIUM** - Yellow
- 🔵 **LOW** - Blue

**For each open issue:**
1. Review title and description
2. Determine if it blocks task completion
3. Click **"Resolve"** or **"Acknowledge"** as appropriate
4. Add notes if needed

### Step 7: Approve the Task (when satisfied)

**Section:** "Approval Actions"

When everything looks good:
1. Verify:
   - Checklist complete (or acceptable)
   - Evidence approved (or acceptable)
   - No blocking issues
2. Click **"Approve Task"** button

**What happens automatically:**
- Report status → "Approved"
- Task status → "Completed"
- Service provider is notified
- Task disappears from "Your Accepted Tasks"

---

## Status Workflow

### Task Status Journey

```
Manager creates task "todo"
         ↓
Service provider accepts
         ↓
Task shows in "Awaiting Response" → "Your Accepted Tasks"
         ↓
Service provider changes to "in_progress"
         ↓
Task appears in Reports tab
         ↓
Service provider updates progress, adds evidence, raises issues
         ↓
Manager reviews all sections in Reports tab
         ↓
Manager clicks "Approve Task"
         ↓
Task auto-completes (status = "completed")
         ↓
Task disappears from "Your Accepted Tasks"
Service provider sees notification: "Task Approved!"
```

### Status Dropdown for Service Providers

```
"Your Accepted Tasks" status dropdown shows:
├── Pending (waiting to start)
├── In Progress (currently working)
└── (Completed is NOT available - manager must approve)

Message displayed:
"Once you complete the work, use the Reports tab to 
submit evidence and request approval from the manager."
```

---

## Key Restrictions & Rules

### Service Providers CANNOT:
- ❌ Manually mark task as "Completed"
- ❌ Approve their own evidence
- ❌ Delete issues
- ❌ Update tasks after approved

### Service Providers CAN:
- ✓ Update progress description anytime
- ✓ Update completion percentage
- ✓ Check off checklist items
- ✓ Upload evidence
- ✓ Raise issues/blockers
- ✓ View manager's feedback

### Managers CAN:
- ✓ View all progress in real-time
- ✓ Approve/reject evidence
- ✓ Resolve issues
- ✓ Approve entire task (auto-completes)
- ✓ See all service provider updates immediately

### Managers CANNOT:
- ❌ Edit service provider's progress description
- ❌ Change completion percentage for provider
- ❌ Force complete task (must approve report)

---

## Real-Time Updates

The Reports tab updates in real-time as:
- Service provider updates progress percentage
- Service provider uploads evidence
- Service provider raises issues
- Manager approves evidence

**No page refresh needed** - changes appear immediately.

---

## Common Workflows

### Workflow 1: Simple Task with Checklist

```
Manager:
1. Create task with 4 checklist items
2. No evidence required
3. Send to service provider

Service Provider:
1. Accept task
2. Change to "In Progress"
3. Go to Reports tab
4. Check off each item as completed (or add notes)
5. Update progress %
6. When done, wait for manager approval

Manager:
1. See checklist progress in Reports
2. All items checked ✓
3. Click "Approve Task"
4. Task auto-completed
```

### Workflow 2: Task with Evidence Requirements

```
Manager:
1. Create task
2. Require: Photo + Video evidence
3. Create checklist (optional)
4. Send to service provider

Service Provider:
1. Accept and start task
2. Change to "In Progress"
3. Go to Reports tab
4. Complete work
5. Take photos/videos
6. Upload evidence with descriptions
7. Update progress to 100%

Manager:
1. See evidence pending approval
2. Review photos/videos
3. Click "Approve" on each evidence
4. Review checklist (if exists)
5. Click "Approve Task"
6. Task auto-completed
```

### Workflow 3: Task with Issues

```
During progress:
Service Provider:
1. Encounters blocker: "Marble tile supplier delayed"
2. Clicks "+ Raise Issue"
3. Title: "Marble tile delivery delayed"
4. Severity: HIGH
5. Issue is saved and flagged

Manager:
1. Sees HIGH severity issue in Reports
2. Reviews issue details
3. Resolves: "Approved budget +$100 for expedited delivery"
4. Clicks "Resolve Issue"
5. Service provider can continue work

Service Provider:
1. Sees issue resolved
2. Continues work with approval
3. Finishes task
4. Uploads evidence

Manager:
1. Approves evidence
2. Approves task
3. Task completes
```

---

## Troubleshooting

### Q: I can't see the Reports tab
**A:** 
- Make sure you're logged in as a service provider
- Make sure a task is assigned to you and in "in_progress" status

### Q: I selected "In Progress" but Reports tab is empty
**A:**
- The page may need a refresh
- Ensure the task was created with the "In Progress" status

### Q: I can't upload evidence
**A:**
- Make sure the manager selected evidence requirements when creating the task
- Check file size is not too large
- Try a different file format

### Q: Manager can't approve my report
**A:**
- Manager may be waiting for evidence approval
- Check if there are open high-severity issues that need resolution
- Manager needs all evidence in "Approved" status

### Q: Task shows "Completed" but I didn't approve it
**A:**
- Check the activity log - manager likely approved it
- This is expected behavior when manager clicks "Approve Task"

---

## Getting Help

For issues or questions:
1. Check the full documentation: `REPORTS_FEATURE_IMPLEMENTATION.md`
2. Review the workflow diagram above
3. Contact support with:
   - Task ID
   - Your role (manager/service provider)
   - What you were trying to do
   - Error message (if any)

---

## Key Files Modified/Created

**Code Changes:**
- `client/pages/tasks/components/NewTaskTab/TaskCreationForm.tsx` - Added checklist & evidence sections
- `client/pages/TasksPage.tsx` - Form data handling for checklist/evidence
- `client/components/TodoItem.tsx` - Restricted status to prevent manual completion
- `client/pages/tasks/components/ReportsTab/ReportsTab.tsx` - Fixed loading issues

**Database:**
- All schema already exists in `reports_feature_schema.sql`
- RLS policies configured in `reports_complete_implementation.sql`

**Documentation:**
- `REPORTS_FEATURE_IMPLEMENTATION.md` - Complete technical guide
- `REPORTS_FEATURE_QUICKSTART.md` - This file

---

## Next Steps

1. **Test the workflow:**
   - Manager: Create task with checklist + evidence
   - Provider: Accept, mark in progress, submit report
   - Manager: Review and approve

2. **Monitor real-time updates:**
   - Provider updates should appear immediately in Reports tab
   - No refresh needed

3. **Check database:**
   - Verify data in: `task_reports`, `task_checklist_items`, `task_evidence_submissions`
   - Check triggers are working (task auto-completes)

4. **Train users:**
   - Share this QuickStart guide with managers and service providers
   - Point them to specific sections based on their role

---

**Happy Reporting! 🎉**
