# Reports Feature - Complete Implementation Guide

## Overview

The Reports feature enables service providers to report on task progress and managers to review and approve work in real-time. This document explains the complete workflow, schema, and implementation.

---

## Feature Workflow

### 1. Manager Creates Task (New Task Tab)

**What changed:**
- New Task form now includes:
  - **Checklist section** (optional): Manager can add multiple checklist items that the service provider must complete
  - **Evidence Requirements section** (optional): Manager can specify what types of proof are needed (photos, videos, documents)

**How it works:**
```
Manager fills out task form:
├── Basic fields (title, description, priority, etc.)
├── Checklist Items (optional)
│   └── Each item: label + description
├── Evidence Types (optional)
│   └── Select: photo, video, document
└── Attachments
```

**Database tables involved:**
- `tasks` - Main task record
- `task_checklists` - One checklist per task
- `task_checklist_items` - Multiple items per checklist
- `task_evidence_requirements` - Evidence requirements for the task

---

### 2. Service Provider Accepts Task

**What happens:**
- Task appears in "Your Accepted Tasks" section in the Todo List tab
- Task shows status dropdown with options: "Pending", "In Progress" (NOT "Completed")
- Service provider cannot manually mark task as complete

**Database:**
- `tasks` status = "todo"
- `task_responses` with action = "accept"
- `todo_list` entry created with negotiated terms

---

### 3. Service Provider Marks Task as "In Progress"

**What happens:**
- Service provider changes task status to "In Progress"
- Task now appears in Reports tab
- A progress report is automatically created

**Database:**
- `tasks` status = "in_progress"
- `task_reports` created with status = "in_progress"

---

### 4. Service Provider Uses Reports Tab

**What the service provider can do:**

#### 4.1 Update Progress Report
- Write description of what's completed and what's currently being worked on
- Update completion percentage (0-100%)
- Save changes

```sql
UPDATE task_reports
SET description = '...', percentage_complete = 50, ...
WHERE id = report_id;
```

#### 4.2 Check Off Checklist Items (if checklist exists)
- View all checklist items from the task
- Check items off as they're completed
- Add notes per item

```sql
INSERT INTO task_report_checklist_items
  (report_id, checklist_item_id, is_completed, completed_at, notes)
VALUES (...);
```

#### 4.3 Upload Evidence (if required)
- Select evidence type: Photo, Video, Document
- Add optional description
- Upload files via drag-and-drop or file picker

```sql
INSERT INTO task_evidence_submissions
  (task_id, provider_id, evidence_type, attachment_id, description)
VALUES (...);
```

#### 4.4 Raise Issues (if blocked)
- Title and description of issue
- Severity: Low, Medium, High, Critical
- Automatically flags the task for manager attention

```sql
INSERT INTO task_issues
  (task_id, provider_id, title, description, severity, status)
VALUES (...);
```

---

### 5. Manager Views Real-Time Progress

**Manager sees in Reports tab:**

```
Task: Repair Bathroom Sink - Room 305
Provider: John Plumber

Progress Report:
├── Status: In Progress
├── Completion: 50%
├── Description: "Walls patched and sanded. Ready for paint."
├── Last Updated: 2 hours ago

Checklist Progress (if checklist exists):
├── ✓ Inspect faucet and identify issue
├── ✓ Replace washers/seals as needed
├── ○ Test water flow and check for leaks
└── ○ Clean up work area

Evidence Review (if required):
├── Pending Approval:
│   └── Photo: "Before and after sink" (1 file)
├── Approved:
│   └── (none yet)

Issues & Blockers:
├── 🔴 HIGH: Delayed marble tile delivery
│   └── "Custom marble tiles delayed 1-2 days"

Approval Button:
└── [Approve Task] (becomes enabled when satisfied)
```

**Database queries:**
```sql
SELECT * FROM task_reports WHERE task_id = ?;
SELECT * FROM task_checklist_items WHERE checklist_id = ?;
SELECT * FROM task_report_checklist_items WHERE report_id = ?;
SELECT * FROM task_evidence_submissions WHERE task_id = ?;
SELECT * FROM task_issues WHERE task_id = ?;
```

---

### 6. Manager Approves Report

**What happens:**
1. Manager reviews all sections (checklist, evidence, issues)
2. Manager clicks "Approve Task" button
3. Automatically:
   - `task_reports` status → "approved"
   - `tasks` status → "completed" (via trigger)
   - Service provider receives notification
   - Task disappears from "Your Accepted Tasks"

```sql
-- Manager action
UPDATE task_reports
SET status = 'approved', updated_at = now()
WHERE id = report_id;

-- Triggered automatically
UPDATE tasks
SET status = 'completed', updated_at = now()
WHERE id = task_id;
```

---

### 7. Service Provider Cannot Manually Complete

**Restriction implemented:**
- In "Your Accepted Tasks" section, the status dropdown shows only:
  - Pending
  - In Progress
- **NOT** "Completed"
- Message: "Once you complete the work, use the Reports tab to submit evidence and request approval from the manager."

---

## Database Schema

### Tables Involved

#### 1. `task_checklists`
```sql
- id: UUID
- task_id: UUID (FK → tasks.id)
- title: VARCHAR(255)
- description: TEXT
- is_required: BOOLEAN
- created_at, updated_at: TIMESTAMP
```

#### 2. `task_checklist_items`
```sql
- id: UUID
- checklist_id: UUID (FK → task_checklists.id)
- label: VARCHAR(255)
- description: TEXT
- display_order: INTEGER
- created_at: TIMESTAMP
```

#### 3. `task_evidence_requirements`
```sql
- id: UUID
- task_id: UUID (FK → tasks.id, UNIQUE)
- required_evidence_types: VARCHAR[] (ARRAY['photo', 'video', 'document'])
- description: TEXT
- created_at, updated_at: TIMESTAMP
```

#### 4. `task_reports`
```sql
- id: UUID
- task_id: UUID (FK → tasks.id, UNIQUE)
- provider_id: UUID (FK → user_profiles.id)
- status: VARCHAR (in_progress | completed_pending_approval | approved)
- description: TEXT
- percentage_complete: INTEGER (0-100)
- last_updated_by: UUID (FK → auth.users.id)
- created_at, updated_at: TIMESTAMP
```

#### 5. `task_report_checklist_items`
```sql
- id: UUID
- report_id: UUID (FK → task_reports.id)
- checklist_item_id: UUID (FK → task_checklist_items.id)
- is_completed: BOOLEAN
- completed_at: TIMESTAMP (nullable)
- created_at, updated_at: TIMESTAMP
- UNIQUE (report_id, checklist_item_id)
```

#### 6. `task_evidence_submissions`
```sql
- id: UUID
- task_id: UUID (FK → tasks.id)
- provider_id: UUID (FK → user_profiles.id)
- evidence_type: VARCHAR (photo | video | document | signature)
- attachment_id: UUID (FK → attachments.id)
- description: TEXT
- submitted_at: TIMESTAMP (default now())
- approved_at: TIMESTAMP (nullable)
- approved_by: UUID (FK → auth.users.id, nullable)
- created_at, updated_at: TIMESTAMP
- UNIQUE (report_id, attachment_id)
```

#### 7. `task_issues`
```sql
- id: UUID
- task_id: UUID (FK → tasks.id)
- provider_id: UUID (FK → user_profiles.id)
- title: VARCHAR(255)
- description: TEXT
- severity: VARCHAR (low | medium | high | critical)
- status: VARCHAR (open | acknowledged | resolved)
- resolved_at: TIMESTAMP (nullable)
- created_at, updated_at: TIMESTAMP
```

### RLS Policies

All tables have Row Level Security enabled with these policies:

**Service Providers can:**
- View their own reports and related data
- Create/update reports for tasks assigned to them
- Upload evidence for their tasks
- Raise issues on their tasks

**Managers can:**
- View all reports for tasks they created
- Approve/reject reports
- Approve evidence submissions
- Resolve issues

---

## Implementation in Code

### Frontend Components

#### 1. `TaskCreationForm.tsx`
**Added:**
- Checklist section with "Add Item" button
- Evidence Requirements section with checkboxes
- Form data includes `checklist: string[]` and `evidenceTypes: string[]`

#### 2. `ReportsTab.tsx`
**Features:**
- Task selector dropdown
- Loads all report data on task selection
- Shows appropriate view based on user role
- Handles loading states gracefully

#### 3. `ProviderReportForm.tsx`
**Features:**
- Progress report description textarea
- Completion percentage slider
- Checklist section (if checklist exists)
  - Checkboxes for each item
  - Notes field per item
- Evidence upload section (if required)
  - Evidence type selector
  - File upload zone
  - Status: Pending/Approved
- Issues section
  - Raise Issue button
  - Issue severity selector
  - List of open issues

#### 4. `ManagerReportView.tsx`
**Features:**
- Task information display
- Progress bar showing completion %
- Report status badge
- Checklist progress (if exists)
  - Count: "2/4 items complete"
  - Item names
- Evidence review (if required)
  - Pending evidence with Approve button
  - Approved evidence checkmark
- Issues display
  - Color-coded by severity
  - Resolve button for manager
- **Approve Task button**
  - Enabled when manager satisfied
  - Updates report status to "approved"
  - Trigger auto-completes task

#### 5. `TodoItem.tsx` (Restriction)
**Changes:**
- Status dropdown for service providers shows only:
  - Pending
  - In Progress
  - ~~Completed~~ (removed - cannot select)
- Message explains why: "Use Reports tab to submit evidence"

### Backend Database Updates

#### `TasksPage.tsx` - `handleCreateTask()`
**When task is created:**
1. Insert task record
2. If checklist items provided:
   - Create `task_checklists` record
   - Create `task_checklist_items` for each item
3. If evidence types selected:
   - Create `task_evidence_requirements` record
4. Link attachments
5. Reset form (including `checklist: []`, `evidenceTypes: []`)

---

## Triggers and Automation

### Trigger: `on_report_approved_complete_task`
```sql
WHEN report status changes to 'approved'
THEN update task status to 'completed'
```

This ensures service providers cannot manually mark tasks as complete - only managers can approve reports, and completion follows automatically.

---

## RLS Policy Summary

| Table | Service Provider | Manager |
|-------|-----------------|---------|
| `task_checklists` | View/Select only | View/Create |
| `task_checklist_items` | View/Select only | View/Create |
| `task_evidence_requirements` | View/Select only | View/Create |
| `task_reports` | View/Create/Update own | View/Update for own tasks |
| `task_report_checklist_items` | Create/Update | View only |
| `task_evidence_submissions` | View/Create | View/Update (approve) |
| `task_issues` | Create | View/Update |

---

## Sample Data Setup

**To create sample data for testing:**

1. Manager creates task via "New Task" tab with:
   - Title: "Repair Bathroom Sink - Room 305"
   - Checklist: ["Inspect faucet", "Replace seals", "Test water flow", "Cleanup"]
   - Evidence: ["photo", "video"]

2. System creates:
   - `task_reports` record
   - `task_checklists` record
   - 4 `task_checklist_items` records
   - 1 `task_evidence_requirements` record

3. Service provider accepts → appears in "Your Accepted Tasks"

4. Service provider marks "In Progress" → appears in Reports tab

5. Service provider submits progress → manager sees in Reports tab

6. Manager approves → task auto-completed

---

## Security Considerations

1. **RLS Enforced:** All sensitive operations are protected by row-level security policies
2. **Role-Based Access:** Distinct policies for managers vs service providers
3. **No Manual Completion:** Service providers cannot bypass the approval workflow
4. **Audit Trail:** All approvals are timestamped with approver ID
5. **Data Isolation:** Providers see only their assigned tasks; managers see all tasks they created

---

## Testing Checklist

- [ ] Manager can create task with checklist
- [ ] Manager can create task with evidence requirements
- [ ] Service provider sees task in "Awaiting Response"
- [ ] Service provider accepts task
- [ ] Task appears in "Your Accepted Tasks" with status dropdown
- [ ] Service provider can change status to "In Progress"
- [ ] Task appears in Reports tab
- [ ] Service provider can update progress description
- [ ] Service provider can update completion %
- [ ] Service provider can check off checklist items
- [ ] Service provider can upload evidence
- [ ] Service provider can raise issues
- [ ] Manager sees all updates in real-time in Reports tab
- [ ] Manager cannot mark task complete without approving report
- [ ] Service provider cannot select "Completed" in status dropdown
- [ ] Manager clicks Approve → task auto-completes
- [ ] Task disappears from "Your Accepted Tasks"
- [ ] Completion is reflected in task list

---

## Deployment Steps

1. **Run migrations:**
   ```bash
   # Already run:
   - reports_feature_schema.sql
   - reports_feature_sample_data.sql
   
   # Run this:
   - reports_complete_implementation.sql
   ```

2. **Deploy code:**
   - Checklist/evidence sections in TaskCreationForm
   - ReportsTab with ProviderReportForm and ManagerReportView
   - TodoItem status restriction

3. **Test workflow end-to-end**

4. **Monitor:**
   - Check task status transitions
   - Verify RLS policies
   - Monitor report approvals

---

## Future Enhancements

- [ ] Email notifications on status changes
- [ ] Export reports as PDF
- [ ] Checklist item dependencies (finish A before B)
- [ ] Automatic photo geolocation for evidence
- [ ] Time tracking integration
- [ ] Multi-image comparison views
- [ ] Report templates by task category
- [ ] Performance analytics by service provider

---

## Support & Troubleshooting

**Issue: Reports tab showing "Loading..." indefinitely**
- Solution: Check that `task_reports` table exists and RLS policies are correct

**Issue: Service provider sees "Completed" option in status**
- Solution: Update TodoItem.tsx to remove completed status option

**Issue: Task not auto-completing on approval**
- Solution: Ensure trigger `on_report_approved_complete_task` exists

**Issue: RLS policy denying access**
- Solution: Verify user_profile.id is properly set and FK references are correct

---

## Additional Resources

- Supabase RLS documentation: https://supabase.com/docs/guides/auth/row-level-security
- React Hooks documentation: https://react.dev/reference/react
- Supabase JavaScript client: https://supabase.com/docs/reference/javascript/introduction
