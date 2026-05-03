# Reports Feature Implementation Plan

## Overview
Implement a comprehensive Reports feature for task management that enables service providers to report progress on accepted tasks with evidence submission, and allows managers to view real-time progress, approve work, and flag issues.

---

## Phase 1: Database Schema (SQL)

### New Tables Required

#### 1. `task_checklists`
Store checklist items associated with tasks.

```sql
- id (UUID, PK)
- task_id (UUID, FK → tasks)
- title (TEXT)
- description (TEXT, nullable)
- is_required (BOOLEAN) - whether checklist is required for completion
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### 2. `task_checklist_items`
Individual items within a checklist.

```sql
- id (UUID, PK)
- checklist_id (UUID, FK → task_checklists)
- label (VARCHAR 255)
- order (INTEGER)
- created_at (TIMESTAMP)
```

#### 3. `task_evidence_requirements`
Manager specifies what proof/evidence is needed for task completion.

```sql
- id (UUID, PK)
- task_id (UUID, FK → tasks, UNIQUE)
- required_evidence_types (VARCHAR[] - enum: 'photo', 'video', 'document', 'signature')
- description (TEXT, nullable)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### 4. `task_reports`
Service provider's progress reports on in-progress tasks.

```sql
- id (UUID, PK)
- task_id (UUID, FK → tasks)
- provider_id (UUID, FK → user_profiles)
- status (VARCHAR - 'in_progress', 'completed_pending_approval', 'approved')
- description (TEXT)
- percentage_complete (INTEGER, 0-100)
- last_updated_by (UUID, FK → auth.users)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

#### 5. `task_report_checklist_items`
Tracks which checklist items have been completed in the report.

```sql
- id (UUID, PK)
- report_id (UUID, FK → task_reports)
- checklist_item_id (UUID, FK → task_checklist_items)
- is_completed (BOOLEAN)
- completed_at (TIMESTAMP, nullable)
- created_at (TIMESTAMP)
```

#### 6. `task_evidence_submissions`
Tracks evidence/proof submitted by service provider.

```sql
- id (UUID, PK)
- task_id (UUID, FK → tasks)
- provider_id (UUID, FK → user_profiles)
- evidence_type (VARCHAR - 'photo', 'video', 'document', 'signature')
- attachment_id (UUID, FK → attachments)
- description (TEXT, nullable)
- submitted_at (TIMESTAMP)
- approved_at (TIMESTAMP, nullable)
- approved_by (UUID, FK → auth.users, nullable)
```

#### 7. `task_issues`
Track issues/blockers raised by service provider.

```sql
- id (UUID, PK)
- task_id (UUID, FK → tasks)
- provider_id (UUID, FK → user_profiles)
- title (VARCHAR 255)
- description (TEXT)
- severity (VARCHAR - 'low', 'medium', 'high', 'critical')
- status (VARCHAR - 'open', 'acknowledged', 'resolved')
- resolved_at (TIMESTAMP, nullable)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

---

## Phase 2: TypeScript Interfaces

Add to `client/lib/supabase.ts`:

```typescript
export interface TaskChecklist {
  id: string
  task_id: string
  title: string
  description: string | null
  is_required: boolean
  created_at: string
  updated_at: string
}

export interface TaskChecklistItem {
  id: string
  checklist_id: string
  label: string
  order: number
  created_at: string
}

export interface TaskEvidenceRequirement {
  id: string
  task_id: string
  required_evidence_types: ('photo' | 'video' | 'document' | 'signature')[]
  description: string | null
  created_at: string
  updated_at: string
}

export interface TaskReport {
  id: string
  task_id: string
  provider_id: string
  status: 'in_progress' | 'completed_pending_approval' | 'approved'
  description: string
  percentage_complete: number
  last_updated_by: string
  created_at: string
  updated_at: string
}

export interface TaskReportChecklistItem {
  id: string
  report_id: string
  checklist_item_id: string
  is_completed: boolean
  completed_at: string | null
  created_at: string
}

export interface TaskEvidenceSubmission {
  id: string
  task_id: string
  provider_id: string
  evidence_type: 'photo' | 'video' | 'document' | 'signature'
  attachment_id: string
  description: string | null
  submitted_at: string
  approved_at: string | null
  approved_by: string | null
}

export interface TaskIssue {
  id: string
  task_id: string
  provider_id: string
  title: string
  description: string
  severity: 'low' | 'medium' | 'high' | 'critical'
  status: 'open' | 'acknowledged' | 'resolved'
  resolved_at: string | null
  created_at: string
  updated_at: string
}
```

---

## Phase 3: UI Components

### New Components to Create

#### 1. `ReportsTab.tsx`
Main reports tab container. Routes to either ManagerReportsView or ProviderReportsView based on user role.

#### 2. `ManagerReportsView.tsx`
Manager's view of all in-progress and completed reports.
- Display checklist progress
- Show evidence submissions with approval buttons
- Display issues/flags with acknowledgement
- Real-time updates via Supabase subscriptions

#### 3. `ProviderReportsView.tsx`
Service provider's view for reporting on their accepted tasks.
- Display accepted tasks in "in_progress" status
- Report form with:
  - Text description
  - Percentage complete slider
  - Checklist item completion (if applicable)
  - Evidence upload section (based on requirements)
  - Issue/blocker reporting option

#### 4. `ProviderReportForm.tsx`
Form for provider to submit progress report.
- Text editor for description
- Checklist UI with checkboxes
- File upload for evidence (with filters based on requirements)
- Issue reporting section

#### 5. `ManagerReportReview.tsx`
Manager's interface to review and approve reports.
- View provider's checklist completion
- View evidence submissions (images, videos, documents)
- Approve/request changes/reject button
- Issue acknowledgement and resolution tracking

#### 6. `TaskChecklistBuilder.tsx`
UI for manager to add checklist items when creating task (in NewTaskTab).

#### 7. `EvidenceRequirementSelector.tsx`
UI for manager to select what evidence types are needed (in NewTaskTab).

---

## Phase 4: Integration Points

### Modify Existing Files

#### `TasksPage.tsx`
- Add "reports" to tab management
- Add state for reports, checklists, evidence, issues
- Add Supabase subscriptions for real-time updates

#### `TabsNavigation.tsx`
- Add "Reports" tab after "To Do List"

#### `NewTaskTab.tsx` / `TaskCreationForm.tsx`
- Add checklist builder section
- Add evidence requirement selector

#### `TodoListTab.tsx`
- When service provider views their to-do and changes status to "in_progress"
- Show indicator that they need to submit reports

---

## Phase 5: Workflow Integration

### Service Provider Workflow
1. Provider accepts task (already exists)
2. Task appears in To Do List
3. Provider changes status to "in_progress"
4. Task now visible in Reports tab for provider
5. Provider submits report with:
   - Description of work done
   - Checklist items completion
   - Evidence uploads (photos/videos)
   - Can flag issues if blocked
6. Manager sees report in real-time in Reports tab
7. Manager approves evidence
8. Upon approval, task auto-completes
9. Provider sees task as completed in their to-do

### Manager Workflow
1. Manager creates task, specifies:
   - Checklist (optional)
   - Evidence requirements (optional)
2. Manager assigns to provider
3. When task goes "in_progress", manager sees it in Reports
4. Manager monitors real-time progress
5. When evidence submitted, manager reviews and approves
6. Task auto-completes upon approval
7. If issue raised, task is flagged and prioritized

---

## Phase 6: Implementation Order

1. **Create SQL migrations** for all 7 new tables with RLS policies
2. **Add TypeScript interfaces** to supabase.ts
3. **Create ReportsTab.tsx** and role-based view routing
4. **Create ProviderReportsView.tsx** and ProviderReportForm.tsx**
5. **Create ManagerReportsView.tsx** and ManagerReportReview.tsx**
6. **Modify TaskCreationForm.tsx** to add checklist and evidence builders
7. **Update TabsNavigation.tsx** to include Reports tab
8. **Integrate into TasksPage.tsx** with state and subscriptions
9. **Add notification types** for report submissions and approvals
10. **Test end-to-end workflows**

---

## Key Design Decisions

### 1. Separate Task Status vs Report Status
- Tasks keep their status in `tasks.status` (todo, in_progress, in_review, completed)
- Reports have their own `task_reports.status` (in_progress, completed_pending_approval, approved)
- Task transitions to "completed" only after manager approves report

### 2. Evidence Attachments
- Use existing `attachments` table with `task_evidence_submissions` junction
- Evidence submissions are separate from general task attachments
- Only specific evidence types are tracked in `task_evidence_submissions`

### 3. Real-time Updates
- Supabase subscriptions on `task_reports`, `task_evidence_submissions`, `task_issues`
- Manager sees updates in real-time without polling
- Provider sees approval status in real-time

### 4. Role-Based Access
- RLS policies ensure:
  - Providers can only see/modify their own reports and evidence
  - Managers can only see reports for tasks they created
  - Other users cannot access

### 5. Backward Compatibility
- Checklist and evidence are optional
- Existing tasks work without them
- No breaking changes to current schema

---

## Sample Data Requirements

For testing, we'll need:
- Sample tasks with/without checklists
- Sample tasks with/without evidence requirements
- Sample in-progress reports from providers
- Sample evidence submissions
- Sample issues with different severity levels

---

## Success Criteria

- [ ] Service provider can submit progress reports on in-progress tasks
- [ ] Checklist items can be tracked and checked off by provider
- [ ] Evidence requirements are enforced and tracked
- [ ] Manager sees real-time progress in Reports tab
- [ ] Manager can approve evidence and auto-complete tasks
- [ ] Provider can flag issues/blockers
- [ ] Issues flag tasks for priority
- [ ] All data is properly secured with RLS
- [ ] All changes are reflected in real-time
- [ ] Notification system notifies both parties of key events
