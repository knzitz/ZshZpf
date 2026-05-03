# Reports Feature - Complete Implementation Guide

## Table of Contents
1. [Database Setup](#database-setup)
2. [TypeScript Integration](#typescript-integration)
3. [Component Architecture](#component-architecture)
4. [Integration Steps](#integration-steps)
5. [API/Supabase Operations](#apisupabase-operations)
6. [Testing Checklist](#testing-checklist)

---

## Database Setup

### Step 1: Run SQL Migrations

In your Supabase SQL Editor, execute these scripts **in order**:

1. **REPORTS_FEATURE_SQL_MIGRATION.sql** - Creates all tables and RLS policies
2. **REPORTS_FEATURE_SAMPLE_DATA.sql** - Populates sample data for testing

**Important**: Follow instructions in the sample data script to replace placeholder IDs with real user IDs from your database.

### Step 2: Verify Tables Created

Run these queries to confirm all tables exist:

```sql
-- Check all new tables
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename LIKE 'task_%'
ORDER BY tablename;

-- Should return:
-- task_checklists
-- task_checklist_items
-- task_evidence_requirements
-- task_evidence_submissions
-- task_issues
-- task_report_checklist_items
-- task_reports
```

### Step 3: Test RLS Policies

Verify RLS is enabled:

```sql
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN (
  'task_checklists', 'task_reports', 'task_evidence_submissions', 'task_issues'
);
-- All should show `rowsecurity = t` (true)
```

---

## TypeScript Integration

### Step 1: Add Interfaces to Supabase Types

1. Open `client/lib/supabase.ts`
2. Copy all interfaces from `REPORTS_FEATURE_TYPESCRIPT_INTERFACES.ts`
3. Add them to the file (after existing interfaces)

### Step 2: Create Query Helpers

Create `client/hooks/useReports.ts`:

```typescript
import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import type {
  TaskReport,
  TaskChecklist,
  TaskEvidenceSubmission,
  TaskIssue,
  TaskReportSummary,
} from '../lib/supabase';

export const useReports = () => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Fetch task reports for provider
  const fetchProviderReports = async (providerId: string) => {
    setIsLoading(true);
    try {
      const { data, error: err } = await supabase
        .from('task_reports')
        .select('*')
        .eq('provider_id', providerId)
        .order('updated_at', { ascending: false });

      if (err) throw err;
      return data as TaskReport[];
    } catch (err) {
      setError(String(err));
      return [];
    } finally {
      setIsLoading(false);
    }
  };

  // Fetch task checklist and items
  const fetchTaskChecklist = async (taskId: string) => {
    setIsLoading(true);
    try {
      const { data: checklist, error: err1 } = await supabase
        .from('task_checklists')
        .select('*')
        .eq('task_id', taskId)
        .single();

      if (err1) return null;

      const { data: items, error: err2 } = await supabase
        .from('task_checklist_items')
        .select('*')
        .eq('checklist_id', checklist.id)
        .order('display_order');

      if (err2) throw err2;

      return { checklist, items };
    } catch (err) {
      setError(String(err));
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  // Submit progress report
  const submitProgressReport = async (
    taskId: string,
    providerId: string,
    description: string,
    percentageComplete: number,
    userId: string
  ) => {
    setIsLoading(true);
    try {
      const { data, error: err } = await supabase
        .from('task_reports')
        .upsert(
          {
            task_id: taskId,
            provider_id: providerId,
            description,
            percentage_complete: percentageComplete,
            last_updated_by: userId,
            status: 'in_progress',
          },
          { onConflict: 'task_id' }
        )
        .select()
        .single();

      if (err) throw err;
      return data as TaskReport;
    } catch (err) {
      setError(String(err));
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  // Submit evidence
  const submitEvidence = async (
    taskId: string,
    providerId: string,
    evidenceType: string,
    attachmentId: string,
    description?: string
  ) => {
    setIsLoading(true);
    try {
      const { data, error: err } = await supabase
        .from('task_evidence_submissions')
        .insert({
          task_id: taskId,
          provider_id: providerId,
          evidence_type: evidenceType,
          attachment_id: attachmentId,
          description,
        })
        .select()
        .single();

      if (err) throw err;
      return data as TaskEvidenceSubmission;
    } catch (err) {
      setError(String(err));
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  // Raise issue
  const raiseIssue = async (
    taskId: string,
    providerId: string,
    title: string,
    description: string,
    severity: string
  ) => {
    setIsLoading(true);
    try {
      const { data, error: err } = await supabase
        .from('task_issues')
        .insert({
          task_id: taskId,
          provider_id: providerId,
          title,
          description,
          severity,
          status: 'open',
        })
        .select()
        .single();

      if (err) throw err;
      return data as TaskIssue;
    } catch (err) {
      setError(String(err));
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  // Approve evidence
  const approveEvidence = async (
    submissionId: string,
    managerId: string
  ) => {
    setIsLoading(true);
    try {
      const { data, error: err } = await supabase
        .from('task_evidence_submissions')
        .update({
          approved_at: new Date().toISOString(),
          approved_by: managerId,
        })
        .eq('id', submissionId)
        .select()
        .single();

      if (err) throw err;
      return data as TaskEvidenceSubmission;
    } catch (err) {
      setError(String(err));
      return null;
    } finally {
      setIsLoading(false);
    }
  };

  return {
    isLoading,
    error,
    fetchProviderReports,
    fetchTaskChecklist,
    submitProgressReport,
    submitEvidence,
    raiseIssue,
    approveEvidence,
  };
};
```

---

## Component Architecture

### File Structure

```
client/pages/tasks/components/
├── ReportsTab/
│   ├── ReportsTab.tsx                 # Main tab router
│   ├── ManagerReportsView.tsx          # Manager's view
│   ├── ManagerReportReview.tsx         # Review single report
│   ├── ProviderReportsView.tsx         # Provider's view
│   ├── ProviderReportForm.tsx          # Provider's report form
│   └── ReportStatusBadge.tsx           # Status indicator component
└── NewTaskTab/
    └── TaskCreationForm.tsx            # (Modify to add checklist/evidence)

client/components/
├── TaskChecklistBuilder.tsx            # Add checklist during task creation
├── EvidenceRequirementSelector.tsx     # Select evidence types
├── TaskChecklistDisplay.tsx            # Display checklist items
├── EvidenceUploadZone.tsx              # Upload evidence
└── TaskIssueReporter.tsx               # Report issues/blockers
```

### Component Descriptions

#### ReportsTab.tsx
**Purpose**: Main entry point for Reports tab. Routes to appropriate view based on user role.

```typescript
interface ReportsTabProps {
  activeTab: string;
  userRole: 'manager' | 'service_provider';
  currentUserId: string;
  currentUserProfileId: string;
}

const ReportsTab: React.FC<ReportsTabProps> = ({
  activeTab,
  userRole,
  currentUserId,
  currentUserProfileId,
}) => {
  if (activeTab !== 'reports') return null;

  if (userRole === 'manager') {
    return <ManagerReportsView managerId={currentUserId} />;
  } else {
    return <ProviderReportsView providerId={currentUserProfileId} />;
  }
};
```

#### ManagerReportsView.tsx
**Purpose**: Dashboard showing all in-progress and completed reports for tasks created by manager.

**Features**:
- List of reports with filters (status, priority, has issues)
- Real-time progress indicators
- Flagged tasks section (with open critical issues)
- Counts of pending evidence, open issues
- Click to view details

**Key Methods**:
```typescript
- fetchAllReports(managerId: string)
- subscribeToReports(managerId: string)
- filterReports(reports, filters)
- sortReports(reports, sortBy)
```

#### ManagerReportReview.tsx
**Purpose**: Detailed view of a single report. Manager reviews and approves work.

**Features**:
- Progress description and percentage
- Checklist completion display with visual indicators
- Evidence submissions with thumbnails/previews
- Approve/reject buttons for evidence
- Issues summary with severity badges
- Real-time updates on provider's changes

**Key Methods**:
```typescript
- approveEvidence(submissionId, managerId)
- requestChanges(submissionId, notes)
- acknowledgeIssue(issueId, managerId)
- auto-complete task when all evidence approved
```

#### ProviderReportsView.tsx
**Purpose**: Dashboard for service provider to see their accepted tasks in progress.

**Features**:
- List of tasks assigned to provider with "in_progress" status
- Click to open report form
- Shows if task has requirements (checklist, evidence)
- Notifications of manager approvals/rejections

**Key Methods**:
```typescript
- fetchProviderTasks(providerId: string)
- filterByStatus(tasks, status)
```

#### ProviderReportForm.tsx
**Purpose**: Form for provider to submit progress on task.

**Features**:
- Text area for description
- Percentage complete slider (0-100)
- Checklist section (if task has checklist):
  - Checkboxes for each item
  - Mark complete/incomplete
  - Optional descriptions
- Evidence upload section (if required):
  - Multiple file types (photo, video, document, signature)
  - Drag-drop upload zone
  - Camera capture for photos
  - File previews
- Issue reporting section:
  - Title and description
  - Severity selector
  - Submit button
- Progress indication and validation

**Key Methods**:
```typescript
- handleDescriptionChange(text)
- handlePercentageChange(percent)
- handleChecklistItemToggle(itemId, isCompleted)
- handleEvidenceUpload(files, evidenceType)
- handleIssueSubmit(title, description, severity)
- validateAndSubmit()
```

#### TaskChecklistBuilder.tsx
**Purpose**: UI component for manager to add checklist during task creation.

**Features**:
- Toggle to enable/disable checklist
- Add/remove checklist items
- Reorder items via drag-drop
- Item labels and optional descriptions
- Mark as required or optional

**Props**:
```typescript
interface TaskChecklistBuilderProps {
  onChecklistChange: (checklist: TaskChecklist) => void;
  initialChecklist?: TaskChecklist;
}
```

#### EvidenceRequirementSelector.tsx
**Purpose**: Manager selects what evidence types are needed for task.

**Features**:
- Checkboxes for: photo, video, document, signature
- Tooltip explanations for each type
- Optional description field
- Visual indication of selections

**Props**:
```typescript
interface EvidenceRequirementSelectorProps {
  onRequirementsChange: (requirements: EvidenceType[]) => void;
  initialRequirements?: EvidenceType[];
}
```

---

## Integration Steps

### Step 1: Update Tab Navigation

**File**: `client/pages/tasks/components/TabsNavigation.tsx`

```typescript
const tabs = [
  { id: "new-task", label: "New Task" },
  { id: "todo-list", label: "To Do List" },
  { id: "reports", label: "Reports" },      // ADD THIS
  { id: "live-chat", label: "Live Chat" },
];
```

### Step 2: Update TasksPage State

**File**: `client/pages/TasksPage.tsx`

Add state for reports data:

```typescript
// Add to state declarations
const [taskReports, setTaskReports] = useState<TaskReport[]>([]);
const [taskChecklists, setTaskChecklists] = useState<Map<string, TaskChecklist>>(new Map());
const [taskEvidenceRequirements, setTaskEvidenceRequirements] = 
  useState<Map<string, TaskEvidenceRequirement>>(new Map());
const [taskIssues, setTaskIssues] = useState<TaskIssue[]>([]);
const [taskEvidenceSubmissions, setTaskEvidenceSubmissions] = 
  useState<TaskEvidenceSubmission[]>([]);
```

Add subscriptions in useEffect:

```typescript
// Subscribe to reports for current provider
if (userRole === 'service_provider' && currentUserProfile?.id) {
  const reportsSub = supabase
    .from('task_reports')
    .on('*', payload => {
      setTaskReports(prev => {
        // Update or add new report
        const index = prev.findIndex(r => r.id === payload.new?.id);
        if (index >= 0) {
          const updated = [...prev];
          updated[index] = payload.new;
          return updated;
        }
        return [...prev, payload.new];
      });
    })
    .subscribe();

  return () => {
    reportsSub.unsubscribe();
  };
}

// Similar subscriptions for checklists, issues, evidence...
```

### Step 3: Add Reports Tab Content

**File**: `client/pages/TasksPage.tsx`

In the TabsContent section:

```typescript
<TabsContent value="reports">
  <ReportsTab
    activeTab={activeTab}
    userRole={userRole}
    currentUserId={currentUser?.id}
    currentUserProfileId={currentUserProfile?.id}
    tasks={tasks}
    reports={taskReports}
    checklists={taskChecklists}
    evidenceSubmissions={taskEvidenceSubmissions}
    issues={taskIssues}
  />
</TabsContent>
```

### Step 4: Modify Task Creation Form

**File**: `client/pages/tasks/components/NewTaskTab/TaskCreationForm.tsx`

Add checklist and evidence sections:

```typescript
const [checklist, setChecklist] = useState<TaskChecklist | null>(null);
const [evidenceRequirements, setEvidenceRequirements] = 
  useState<EvidenceType[] | null>(null);

// In form JSX:
<TaskChecklistBuilder 
  onChecklistChange={setChecklist}
/>

<EvidenceRequirementSelector
  onRequirementsChange={setEvidenceRequirements}
/>

// When submitting task:
// After task is created, create checklist if provided
if (checklist && newTask.id) {
  // Insert checklist
  // Insert checklist items
}

// Create evidence requirements if provided
if (evidenceRequirements && newTask.id) {
  // Insert evidence requirements
}
```

### Step 5: Update Notification Types

**File**: `client/lib/supabase.ts` (or wherever notifications are defined)

```typescript
export interface Notification {
  // ... existing fields ...
  type: 'complaint_filed' | 'task_created' | /* ... */ 
    | 'report_submitted' 
    | 'evidence_approved'
    | 'issue_raised'
    | 'issue_resolved'
    | 'task_flagged';
}
```

---

## API/Supabase Operations

### Key Operations Needed

#### 1. Create/Update Progress Report
```typescript
// When provider updates report
const { data, error } = await supabase
  .from('task_reports')
  .upsert({
    task_id: taskId,
    provider_id: providerId,
    status: 'in_progress' | 'completed_pending_approval',
    description: reportText,
    percentage_complete: percent,
    last_updated_by: userId,
  }, { onConflict: 'task_id' })
  .select()
  .single();
```

#### 2. Update Checklist Items
```typescript
// Mark checklist items complete
const { data, error } = await supabase
  .from('task_report_checklist_items')
  .upsert({
    report_id: reportId,
    checklist_item_id: itemId,
    is_completed: true,
    completed_at: new Date().toISOString(),
  }, { onConflict: 'report_id,checklist_item_id' });
```

#### 3. Submit Evidence
```typescript
// Provider uploads evidence
const { data, error } = await supabase
  .from('task_evidence_submissions')
  .insert({
    task_id: taskId,
    provider_id: providerId,
    evidence_type: 'photo' | 'video' | 'document' | 'signature',
    attachment_id: attachmentId,
    description: optionalNotes,
  });
```

#### 4. Approve Evidence
```typescript
// Manager approves evidence
const { data, error } = await supabase
  .from('task_evidence_submissions')
  .update({
    approved_at: new Date().toISOString(),
    approved_by: managerId,
  })
  .eq('id', submissionId);
```

#### 5. Auto-complete Task on Approval
```typescript
// Trigger when all evidence is approved
const { data, error } = await supabase
  .from('tasks')
  .update({
    status: 'completed',
    updated_at: new Date().toISOString(),
  })
  .eq('id', taskId);

// Update todo_list item
await supabase
  .from('todo_list')
  .update({
    status: 'completed',
    completed_at: new Date().toISOString(),
  })
  .eq('task_id', taskId);

// Notify provider
await supabase
  .from('notifications')
  .insert({
    user_id: providerUserId,
    task_id: taskId,
    type: 'task_completed',
    message: 'Your task has been approved and marked complete!',
  });
```

#### 6. Raise Issue
```typescript
// Provider reports issue
const { data, error } = await supabase
  .from('task_issues')
  .insert({
    task_id: taskId,
    provider_id: providerId,
    title: issueTitle,
    description: issueDescription,
    severity: 'low' | 'medium' | 'high' | 'critical',
    status: 'open',
  });

// If high or critical, flag the task
if (severity === 'critical' || severity === 'high') {
  // Create notification for manager
  await supabase
    .from('notifications')
    .insert({
      user_id: managerUserId,
      task_id: taskId,
      type: 'task_flagged',
      message: `Critical issue reported on task: ${issueTitle}`,
    });
}
```

---

## Testing Checklist

### Pre-Implementation
- [ ] Database migrations executed
- [ ] Sample data loaded
- [ ] All tables visible in Supabase
- [ ] RLS policies enabled
- [ ] TypeScript interfaces added to codebase

### Manager View
- [ ] Can navigate to Reports tab
- [ ] Sees all tasks with in_progress status
- [ ] See real-time progress updates
- [ ] Can see checklist completion percentage
- [ ] Can view evidence submissions
- [ ] Can approve/reject evidence
- [ ] Can acknowledge issues
- [ ] Sees flagged tasks prominently
- [ ] Receives notifications on report submissions

### Provider View
- [ ] Can navigate to Reports tab
- [ ] Sees only their assigned in_progress tasks
- [ ] Can open report form
- [ ] Can update percentage complete
- [ ] Can check off checklist items
- [ ] Can upload evidence (photos, videos, etc.)
- [ ] Can raise issues with severity selection
- [ ] See notifications of approvals/rejections
- [ ] Checklist items stay checked on refresh

### Real-time Updates
- [ ] Provider's progress updates in real-time on manager view
- [ ] Evidence approvals show immediately
- [ ] New issues appear immediately
- [ ] Checklist completion updates in real-time

### Task Completion
- [ ] Task auto-completes when all evidence approved
- [ ] Task status updates in "To Do List" tab
- [ ] Task appears as completed in task list
- [ ] Provider notified of completion
- [ ] Notifications reflect task completion

### Edge Cases
- [ ] Task without checklist still works
- [ ] Task without evidence requirements still works
- [ ] Multiple evidence submissions on same task
- [ ] Multiple issues on same task
- [ ] Reopened/unresolved issues
- [ ] Evidence rejection and resubmission

### Performance
- [ ] Reports load without delay (<1s)
- [ ] Real-time subscriptions don't cause lag
- [ ] Large evidence files upload smoothly
- [ ] Checklist with 20+ items displays properly

### Security (RLS)
- [ ] Manager can't see provider's reports for other managers' tasks
- [ ] Provider can't see other providers' reports
- [ ] Provider can't approve evidence
- [ ] Manager can't submit reports
- [ ] Non-assigned users can't access reports

---

## Troubleshooting

### Common Issues

**Issue**: "provider_id is not unique" error when creating report
- **Cause**: Trying to create two reports for same task
- **Solution**: Use `upsert` instead of `insert`

**Issue**: Checklist items not saving
- **Cause**: Missing FK relationship to task_checklists
- **Solution**: Ensure checklist is created first, then create items with correct checklist_id

**Issue**: Evidence uploads failing
- **Cause**: Attachment not created properly in attachments table
- **Solution**: Use existing `useFileUpload` hook to create attachment first

**Issue**: RLS blocking queries
- **Cause**: user_id or profile_id mismatch
- **Solution**: Verify correct IDs are being used (auth.users.id vs user_profiles.id)

**Issue**: Real-time subscriptions not updating
- **Cause**: Subscription not attached to correct table or filter
- **Solution**: Add console.logs to verify payload structure

---

## Next Steps

1. **Run the SQL migrations** (see Database Setup)
2. **Add TypeScript interfaces** to supabase.ts
3. **Create the hook** (useReports.ts)
4. **Create components** in the order listed
5. **Integrate into TasksPage** 
6. **Add to TabsNavigation**
7. **Test with sample data**
8. **Deploy and monitor**

---

## Files to Create/Modify

**New Files**:
- `client/pages/tasks/components/ReportsTab/ReportsTab.tsx`
- `client/pages/tasks/components/ReportsTab/ManagerReportsView.tsx`
- `client/pages/tasks/components/ReportsTab/ManagerReportReview.tsx`
- `client/pages/tasks/components/ReportsTab/ProviderReportsView.tsx`
- `client/pages/tasks/components/ReportsTab/ProviderReportForm.tsx`
- `client/pages/tasks/components/ReportsTab/ReportStatusBadge.tsx`
- `client/components/TaskChecklistBuilder.tsx`
- `client/components/EvidenceRequirementSelector.tsx`
- `client/components/TaskChecklistDisplay.tsx`
- `client/components/EvidenceUploadZone.tsx`
- `client/components/TaskIssueReporter.tsx`
- `client/hooks/useReports.ts`

**Modified Files**:
- `client/lib/supabase.ts` (add interfaces)
- `client/pages/TasksPage.tsx` (add state, subscriptions, tab content)
- `client/pages/tasks/components/TabsNavigation.tsx` (add Reports tab)
- `client/pages/tasks/components/NewTaskTab/TaskCreationForm.tsx` (add checklist/evidence UI)

---

## Success Metrics

After implementation, you should have:

✅ Service providers can submit detailed progress reports with descriptions and checklists
✅ Managers see real-time progress updates in dedicated Reports tab
✅ Evidence submission workflow with manager approval
✅ Issue/blocker tracking with task flagging
✅ Automatic task completion on evidence approval
✅ Full RLS security ensuring data privacy
✅ Real-time synchronization across users
✅ Backward compatibility with existing features

---

## Support & Documentation

For implementation questions, refer to:
- REPORTS_FEATURE_PLAN.md - Overview and design decisions
- REPORTS_FEATURE_SQL_MIGRATION.sql - Database structure
- REPORTS_FEATURE_TYPESCRIPT_INTERFACES.ts - Type definitions
- REPORTS_FEATURE_SAMPLE_DATA.sql - Example data
