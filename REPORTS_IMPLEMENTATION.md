# Reports Feature Implementation Guide

## Overview
The Reports feature enables service providers to submit detailed progress reports on in-progress tasks with checklists, evidence uploads, and issue tracking. Managers can review reports in real-time and approve task completion.

## What Was Implemented

### 1. Database Schema (`supabase/migrations/reports_feature_schema.sql`)
- **7 new tables** with proper constraints and indexes:
  - `task_checklists` - Checklist templates for tasks
  - `task_checklist_items` - Individual checklist items
  - `task_evidence_requirements` - Evidence types required by manager
  - `task_reports` - Service provider's progress reports
  - `task_report_checklist_items` - Completed checklist items in reports
  - `task_evidence_submissions` - Uploaded evidence with approval workflow
  - `task_issues` - Issues/blockers raised by provider
- **Row Level Security (RLS)** policies for data access control
- **Helper views** for real-time reporting queries

### 2. TypeScript Types (`client/lib/supabase.ts`)
Added complete interfaces for all Reports feature entities:
- `TaskChecklist`
- `TaskChecklistItem`
- `TaskEvidenceRequirement`
- `TaskReport`
- `TaskReportChecklistItem`
- `TaskEvidenceSubmission`
- `TaskIssue`

### 3. React Components
#### Reports Tab (`client/pages/tasks/components/ReportsTab/`)
- **ReportsTab.tsx** - Main orchestrator component
- **ProviderReportForm.tsx** - Service provider interface
- **ManagerReportView.tsx** - Manager review interface

#### Features Implemented:
**For Service Providers:**
- Update progress reports with descriptions
- Track percentage completion with slider
- Check off completed checklist items
- Upload evidence (photos, videos, documents)
- Raise issues/blockers with severity levels
- View approval status of submitted evidence

**For Managers:**
- View all in-progress task reports
- See real-time progress percentages
- Monitor checklist completion
- Review and approve evidence submissions
- Acknowledge and resolve issues
- Auto-complete tasks upon approval

### 4. Integration with Existing System
- Added "Reports" tab to TasksPage navigation
- Integrated with existing Supabase client and auth
- Uses existing file upload infrastructure
- Maintains design consistency with Sheraton theme

## How to Use

### Setup: Run Migrations

1. **Open Supabase SQL Editor** in your Supabase dashboard
2. **Copy & paste** `supabase/migrations/reports_feature_schema.sql`
3. **Execute** to create tables and RLS policies
4. **Copy & paste** `supabase/migrations/reports_feature_sample_data.sql`
5. **Execute** to create sample test data (uses your actual user IDs)

### For Service Providers

1. Navigate to **Tasks > Reports** tab
2. Select an in-progress task from dropdown
3. **Update Progress:**
   - Add description of completed work
   - Adjust completion percentage
   - Save progress report
4. **Complete Checklist:**
   - Check off items as you complete them
   - Progress bar shows overall completion
5. **Submit Evidence:**
   - Click "Upload Evidence"
   - Select evidence type (photo/video/document)
   - Add optional description
   - Upload files
   - Manager will review and approve
6. **Raise Issues:**
   - Click "Raise Issue" if blocked or delayed
   - Select severity (low/medium/high/critical)
   - Describe the issue
   - Task is automatically flagged for manager attention

### For Managers

1. Navigate to **Tasks > Reports** tab
2. Select task to review
3. **Monitor Progress:**
   - View real-time progress percentage
   - Read provider's detailed report
   - Track checklist completion
4. **Review Evidence:**
   - See submitted evidence (pending/approved)
   - Approve each evidence item
   - Critical for task completion
5. **Handle Issues:**
   - See all flagged issues
   - Review severity levels
   - Mark resolved when fixed
6. **Complete Task:**
   - Once all evidence is approved
   - Click "Approve & Complete Task"
   - Task status auto-updates
   - Provider receives notification

## File Locations

```
supabase/migrations/
├── reports_feature_schema.sql          # Database tables & RLS
└── reports_feature_sample_data.sql     # Sample test data

client/lib/
└── supabase.ts                         # TypeScript types (updated)

client/pages/tasks/components/
├── ReportsTab/
│   ├── ReportsTab.tsx                  # Main component
│   ├── ProviderReportForm.tsx          # Provider interface
│   └── ManagerReportView.tsx           # Manager interface
└── TabsNavigation.tsx                  # Updated with Reports tab

client/pages/
└── TasksPage.tsx                       # Updated to include ReportsTab
```

## Key Features

### Progress Tracking
- Real-time percentage completion
- Detailed work descriptions
- Historical progress updates

### Checklist Management
- Manager-defined checklist items
- Provider checks off completed items
- Visual progress tracking

### Evidence Workflow
- Multiple evidence types supported (photo/video/document/signature)
- Upload and description fields
- Manager approval process
- Tracks approval status and dates

### Issue Management
- Severity levels (low/medium/high/critical)
- Open/acknowledged/resolved states
- Flags tasks for urgent attention
- Historical issue tracking

### Real-time Updates
- Supabase real-time subscriptions
- Instant data refreshes
- No manual page refresh needed

## Data Flow

### Creating a Report
1. Manager creates task with evidence requirements
2. Manager optionally creates checklist for task
3. Provider navigates to Reports tab
4. Provider creates progress report
5. Manager sees report in real-time

### Completing a Task
1. Provider marks checklist items complete
2. Provider uploads evidence
3. Provider updates percentage to 100%
4. Report status auto-updates to "completed_pending_approval"
5. Manager reviews and approves
6. Task status changes to "completed"
7. Provider notified of completion

### Handling Issues
1. Provider raises issue with description
2. Task is immediately flagged (open issue)
3. Manager sees flagged indicator
4. Manager acknowledges/resolves issue
5. Issue status updates
6. Task flag clears when all issues resolved

## Security

### Row Level Security (RLS)
- Service providers can only see their own reports
- Managers can see reports for their created tasks
- Evidence submissions tied to proper task ownership
- Issues accessible only to relevant parties

### Access Control
- Evidence approval restricted to task creators
- Report editing restricted to assigned provider or manager
- Task completion only by manager approval

## Sample Data

The sample data script creates:
- 1 task in progress
- 1 checklist with 8 items
- Evidence requirements (photo + video)
- Initial progress report (35% complete)
- 2 completed checklist items
- 1 flagged issue (HIGH severity)

Use this to test the complete workflow.

## Testing Checklist

- [ ] SQL migrations run successfully
- [ ] Sample data created without errors
- [ ] Reports tab visible in Tasks page
- [ ] Service provider can create progress report
- [ ] Service provider can check checklist items
- [ ] Service provider can upload evidence
- [ ] Service provider can raise issues
- [ ] Manager can see all reports
- [ ] Manager can approve evidence
- [ ] Manager can resolve issues
- [ ] Manager can approve task for completion
- [ ] Task status updates to completed
- [ ] Provider receives notification

## Troubleshooting

### "No in-progress tasks to report on"
- Service providers can only report on assigned in-progress tasks
- Ensure task status is "in_progress"
- Ensure task is assigned to the service provider

### Evidence upload fails
- Check file size limits
- Ensure file type is supported (image/video/file)
- Verify attachment table exists

### RLS policy errors
- Ensure user profile role is set correctly
- Verify user_id relationships are proper
- Check task assignment to user_profile.id

### Real-time updates not showing
- Verify Supabase real-time is enabled
- Check browser console for errors
- Try refreshing the page

## Next Steps

1. **Checklist Creation UI** - Add manager interface to create checklists when creating tasks
2. **Evidence Requirements UI** - Add manager interface to set evidence types when creating tasks
3. **Real-time Notifications** - Set up Supabase triggers for instant notifications
4. **Report History** - Create view showing all historical reports for a task
5. **Analytics Dashboard** - Show completion metrics and trend analysis
6. **Mobile Optimizations** - Optimize photo capture for mobile devices
7. **Bulk Actions** - Allow managers to approve multiple evidence items at once

## Support

For issues or questions:
1. Check the TypeScript interfaces in `client/lib/supabase.ts`
2. Review the component implementations in `client/pages/tasks/components/ReportsTab/`
3. Verify database schema in `supabase/migrations/reports_feature_schema.sql`
4. Check RLS policies for data access issues
5. Review the sample data to understand expected data structure
