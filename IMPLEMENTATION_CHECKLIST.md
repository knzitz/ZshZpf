# Reports Feature Implementation Checklist

Use this checklist to track your progress through the implementation.

## Phase 1: Database Setup ⚙️

### SQL Execution
- [ ] Read REPORTS_FEATURE_PLAN.md (overview)
- [ ] Open Supabase SQL Editor
- [ ] Copy entire REPORTS_FEATURE_SQL_MIGRATION.sql into editor
- [ ] Execute the migration script
- [ ] Verify all 7 tables created:
  ```sql
  SELECT tablename FROM pg_tables 
  WHERE schemaname = 'public' 
  AND tablename LIKE 'task_%'
  ```

### Verify RLS
- [ ] Check RLS is enabled on all tables:
  ```sql
  SELECT schemaname, tablename, rowsecurity 
  FROM pg_tables 
  WHERE tablename LIKE 'task_%';
  ```
- [ ] All should show `rowsecurity = t` (true)

### Load Sample Data
- [ ] Get real manager user_profiles.id and user_id:
  ```sql
  SELECT id, user_id, email, first_name FROM user_profiles WHERE role = 'manager' LIMIT 1;
  ```
- [ ] Get real service_provider user_profiles.id and user_id:
  ```sql
  SELECT id, user_id, email, first_name FROM user_profiles WHERE role = 'service_provider' LIMIT 1;
  ```
- [ ] Get real task ID to attach to:
  ```sql
  SELECT id, title FROM tasks LIMIT 1;
  ```
- [ ] Update placeholder IDs in REPORTS_FEATURE_SAMPLE_DATA.sql
- [ ] Execute the sample data script
- [ ] Verify data loaded with queries provided in the script

### Database Validation Complete ✅
- [ ] All 7 tables exist
- [ ] RLS is enabled
- [ ] Sample data loaded
- [ ] Queries return expected results

---

## Phase 2: TypeScript Integration 📝

### Add Interfaces to Client
- [ ] Open `client/lib/supabase.ts`
- [ ] Copy all interfaces from `REPORTS_FEATURE_TYPESCRIPT_INTERFACES.ts`
- [ ] Paste after existing interfaces (after TaskMessageAttachment)
- [ ] Verify no syntax errors
- [ ] Run `npm run typecheck` to verify TypeScript compiles

### Interfaces Added
- [ ] TaskChecklist
- [ ] TaskChecklistItem
- [ ] TaskEvidenceRequirement
- [ ] TaskReport
- [ ] TaskReportChecklistItem
- [ ] TaskEvidenceSubmission
- [ ] TaskIssue
- [ ] TaskReportSummary
- [ ] FlaggedTask
- [ ] ProviderReportDraft
- [ ] EvidenceSubmissionWithAttachment
- [ ] TaskReportsQueryResult
- [ ] TaskWithReportData
- [ ] NewTaskWithChecklistForm
- [ ] EvidenceApprovalAction
- [ ] IssueReportSubmission
- [ ] ReportNotificationPayload
- [ ] ReportFilters
- [ ] All type aliases (EvidenceType, IssueSeverity, etc.)

### Type Checking Complete ✅
- [ ] No TypeScript errors
- [ ] All interfaces compile
- [ ] `npm run typecheck` passes

---

## Phase 3: Create Custom Hook 🎣

### Create useReports.ts
- [ ] Create file: `client/hooks/useReports.ts`
- [ ] Implement fetchProviderReports method
- [ ] Implement fetchTaskChecklist method
- [ ] Implement submitProgressReport method
- [ ] Implement submitEvidence method
- [ ] Implement raiseIssue method
- [ ] Implement approveEvidence method
- [ ] Add error handling to all methods
- [ ] Add loading state management
- [ ] Export all methods

### Hook Complete ✅
- [ ] Hook file created
- [ ] All methods implemented
- [ ] No TypeScript errors in hook

---

## Phase 4: Create Components 🧩

### Create Reports Tab Directory
- [ ] Create: `client/pages/tasks/components/ReportsTab/`

### ReportsTab.tsx (Router Component)
- [ ] Create file: `ReportsTab.tsx`
- [ ] Define ReportsTabProps interface
- [ ] Check activeTab === 'reports'
- [ ] Route based on userRole (manager vs service_provider)
- [ ] Pass necessary props to child components
- [ ] Handle loading/error states

### ManagerReportsView.tsx
- [ ] Create file: `ManagerReportsView.tsx`
- [ ] Fetch all task reports for manager's tasks
- [ ] Display reports in a list/dashboard format
- [ ] Show task title, provider name, progress %
- [ ] Filter section (status, priority, issues)
- [ ] Flagged tasks section at top
- [ ] Click to view detail
- [ ] Subscribe to real-time updates
- [ ] Show counts: pending evidence, open issues, etc.

### ManagerReportReview.tsx
- [ ] Create file: `ManagerReportReview.tsx`
- [ ] Display progress report details
- [ ] Show description text
- [ ] Show percentage complete with visual indicator
- [ ] Display checklist with completion status
- [ ] Show evidence submissions with thumbnails
- [ ] Approve/reject buttons for each evidence
- [ ] Issues summary section
- [ ] Acknowledge issue button
- [ ] Auto-complete task when all evidence approved
- [ ] Real-time subscription for provider updates

### ProviderReportsView.tsx
- [ ] Create file: `ProviderReportsView.tsx`
- [ ] Fetch tasks assigned to provider with status = 'in_progress'
- [ ] Display list of tasks needing reports
- [ ] Show if task has checklist requirement
- [ ] Show if task has evidence requirement
- [ ] Click to open report form
- [ ] Show notification of approvals/rejections

### ProviderReportForm.tsx
- [ ] Create file: `ProviderReportForm.tsx`
- [ ] Description text area with onChange handler
- [ ] Percentage complete slider (0-100)
- [ ] Checklist section (if task has checklist):
    - [ ] Fetch checklist items
    - [ ] Display as checkboxes
    - [ ] Handle toggle complete/incomplete
    - [ ] Show percentage of checklist complete
- [ ] Evidence upload section (if required):
    - [ ] Show required evidence types
    - [ ] Drag-drop upload zone
    - [ ] File type filter based on requirements
    - [ ] Camera capture for photo evidence
    - [ ] Progress indication during upload
- [ ] Issue reporting section:
    - [ ] Title input field
    - [ ] Description text area
    - [ ] Severity selector dropdown
    - [ ] Submit issue button
- [ ] Form validation before submit
- [ ] Submit report button
- [ ] Error/success messages
- [ ] Loading state during submission

### ReportStatusBadge.tsx
- [ ] Create file: `ReportStatusBadge.tsx`
- [ ] Display status badge with appropriate colors
- [ ] Status options: 'in_progress', 'completed_pending_approval', 'approved'
- [ ] Show severity badges for issues
- [ ] Show evidence approval status

### Additional Components

#### TaskChecklistBuilder.tsx (in client/components/)
- [ ] Create file: `TaskChecklistBuilder.tsx`
- [ ] Toggle to enable/disable checklist
- [ ] Add/remove checklist item inputs
- [ ] Reorder items (drag-drop or up/down buttons)
- [ ] Each item: label + optional description
- [ ] Mark as required checkbox
- [ ] Pass built checklist back to parent

#### EvidenceRequirementSelector.tsx (in client/components/)
- [ ] Create file: `EvidenceRequirementSelector.tsx`
- [ ] Checkboxes for: photo, video, document, signature
- [ ] Help text for each type
- [ ] Optional description field
- [ ] Show selected types
- [ ] Pass selections back to parent

#### TaskChecklistDisplay.tsx (in client/components/)
- [ ] Create file: `TaskChecklistDisplay.tsx`
- [ ] Display list of checklist items
- [ ] Show checkboxes for completion status
- [ ] Show visual progress bar
- [ ] Show percentage complete
- [ ] Handle item completion toggle

#### EvidenceUploadZone.tsx (in client/components/)
- [ ] Create file: `EvidenceUploadZone.tsx`
- [ ] Drag-drop zone for files
- [ ] File type filtering (based on requirements)
- [ ] Camera capture button for photos
- [ ] Show uploaded file previews
- [ ] Delete individual files
- [ ] Progress bar during upload
- [ ] File size validation
- [ ] Error messages for invalid files

#### TaskIssueReporter.tsx (in client/components/)
- [ ] Create file: `TaskIssueReporter.tsx`
- [ ] Title input field
- [ ] Description text area
- [ ] Severity dropdown selector
- [ ] Submit button
- [ ] Validation
- [ ] Success/error messages

### Components Complete ✅
- [ ] All 10 component files created
- [ ] All components have TypeScript types
- [ ] No compilation errors
- [ ] Basic structure in place (can add styling later)

---

## Phase 5: Integration with Existing Code 🔌

### Update Tab Navigation
**File**: `client/pages/tasks/components/TabsNavigation.tsx`
- [ ] Open file
- [ ] Locate tabs array
- [ ] Add new tab: `{ id: "reports", label: "Reports" }`
- [ ] Save file

### Update TasksPage.tsx
**File**: `client/pages/TasksPage.tsx`

**Add Imports**:
- [ ] Import ReportsTab component
- [ ] Import useReports hook
- [ ] Import new types

**Add State**:
- [ ] Add state for taskReports
- [ ] Add state for taskChecklists
- [ ] Add state for taskEvidenceRequirements
- [ ] Add state for taskIssues
- [ ] Add state for taskEvidenceSubmissions

**Add Subscriptions**:
- [ ] Subscribe to task_reports changes
- [ ] Subscribe to task_issues changes
- [ ] Subscribe to task_evidence_submissions changes
- [ ] Add cleanup for subscriptions
- [ ] Handle real-time updates properly

**Add Tab Content**:
- [ ] Locate TabsContent sections
- [ ] Add new TabsContent for "reports"
- [ ] Pass all necessary props to ReportsTab
- [ ] Ensure data flows correctly

**Update getTabFromPath**:
- [ ] Add check for `/tasks/reports` path
- [ ] Return "reports" tab ID

### Update TaskCreationForm.tsx
**File**: `client/pages/tasks/components/NewTaskTab/TaskCreationForm.tsx`

**Add Imports**:
- [ ] Import TaskChecklistBuilder
- [ ] Import EvidenceRequirementSelector
- [ ] Import new types

**Add State**:
- [ ] Add state for checklist form data
- [ ] Add state for evidence requirements

**Add UI Sections**:
- [ ] Add TaskChecklistBuilder section
- [ ] Add EvidenceRequirementSelector section
- [ ] Position them logically in form

**Update Submit Handler**:
- [ ] After task is created, create checklist if provided
- [ ] Create checklist items if provided
- [ ] Create evidence requirements if provided
- [ ] Handle errors gracefully

### Update Notification Types
**File**: `client/lib/supabase.ts`

- [ ] Add new notification types to union:
  - [ ] 'report_submitted'
  - [ ] 'evidence_approved'
  - [ ] 'issue_raised'
  - [ ] 'issue_resolved'
  - [ ] 'task_flagged'

### Integration Complete ✅
- [ ] TabsNavigation updated
- [ ] TasksPage integrated with new state and subscriptions
- [ ] TaskCreationForm includes checklist/evidence builders
- [ ] Notification types extended
- [ ] No compilation errors
- [ ] All imports resolved

---

## Phase 6: Testing 🧪

### Setup Test Data
- [ ] Execute REPORTS_FEATURE_SAMPLE_DATA.sql (already done in Phase 1)
- [ ] Verify sample room renovation task exists
- [ ] Confirm checklist has 8 items
- [ ] Check evidence requirements set to [photo, video]
- [ ] Verify sample issues created

### Manager Tests
- [ ] Navigate to Reports tab
- [ ] See list of all in-progress tasks
- [ ] See real-time progress updates
- [ ] Click on task to view details
- [ ] See checklist with completion status
- [ ] See evidence submissions
- [ ] Can approve evidence submissions
- [ ] When all evidence approved, task auto-completes
- [ ] See flagged tasks section (critical/high issues)
- [ ] Can acknowledge issues
- [ ] Receive notifications on new reports

### Provider Tests
- [ ] Navigate to Reports tab
- [ ] See only their assigned in-progress tasks
- [ ] Open report form
- [ ] Update description and percentage
- [ ] Check off checklist items (persist on refresh)
- [ ] Upload photos/videos as evidence
- [ ] Raise issue with severity
- [ ] See approval status of evidence
- [ ] Get notified when evidence approved
- [ ] See task auto-complete in todo list

### Real-time Tests
- [ ] Provider updates progress → Manager sees it immediately
- [ ] Manager approves evidence → Provider notified immediately
- [ ] New issue raised → Manager sees flag immediately
- [ ] Issue resolved → Flag clears immediately

### Task Completion Tests
- [ ] Evidence approved → Task status changes to 'completed'
- [ ] Todo list item marked 'completed'
- [ ] Task appears completed in list
- [ ] Provider receives completion notification
- [ ] All dependent status updates work

### Edge Cases
- [ ] Task without checklist → works fine
- [ ] Task without evidence requirements → works fine
- [ ] Multiple evidence submissions on one task → all show
- [ ] Multiple issues on one task → all tracked
- [ ] Evidence rejection and resubmission → works

### RLS Security Tests
- [ ] Manager can't see other manager's tasks reports
- [ ] Provider can't see other provider's reports
- [ ] Provider can't approve evidence
- [ ] Manager can't submit reports
- [ ] Non-participants can't access reports

### Performance Tests
- [ ] Reports load in < 1 second
- [ ] Real-time updates don't lag
- [ ] Large file uploads work smoothly
- [ ] 20+ checklist items display correctly
- [ ] 100+ evidence submissions load quickly

### Testing Complete ✅
- [ ] All manager features working
- [ ] All provider features working
- [ ] Real-time sync verified
- [ ] Task completion flow works
- [ ] Security/RLS verified
- [ ] Performance acceptable
- [ ] No console errors
- [ ] No critical bugs

---

## Phase 7: Refinement & Polish 🎨

### Styling & UI
- [ ] Add TailwindCSS classes for consistent styling
- [ ] Color code status badges appropriately
- [ ] Style severity indicators (red for critical, etc)
- [ ] Make progress bars visually clear
- [ ] Responsive design on mobile
- [ ] Accessibility improvements (ARIA labels, etc)

### User Experience
- [ ] Add helpful tooltips and hints
- [ ] Confirm dialogs for destructive actions
- [ ] Smooth animations and transitions
- [ ] Clear error messages
- [ ] Success notifications
- [ ] Loading indicators

### Documentation
- [ ] Add JSDoc comments to components
- [ ] Document custom hooks
- [ ] Create user guide for managers
- [ ] Create user guide for providers
- [ ] Document troubleshooting steps

### Code Quality
- [ ] Run ESLint to check code style
- [ ] Run Prettier to format code
- [ ] Run `npm run typecheck` for type safety
- [ ] Remove any console.logs used for debugging
- [ ] No unused imports

### Refinement Complete ✅
- [ ] Polished UI/UX
- [ ] Full documentation
- [ ] Code quality improved
- [ ] Ready for production

---

## Phase 8: Deployment 🚀

### Pre-Deployment Checklist
- [ ] All features tested thoroughly
- [ ] No known bugs
- [ ] Performance acceptable
- [ ] Security reviewed (RLS policies)
- [ ] No console errors
- [ ] TypeScript compiles without warnings

### Build & Deploy
- [ ] Run `npm run build`
- [ ] Build completes successfully
- [ ] No warnings in build output
- [ ] Test production build locally if possible
- [ ] Deploy to staging environment
- [ ] Test on staging environment
- [ ] Deploy to production

### Post-Deployment
- [ ] Verify all features work in production
- [ ] Monitor for errors in error tracking
- [ ] Check database performance
- [ ] Verify real-time subscriptions work
- [ ] Get user feedback
- [ ] Document any deployment notes

### Deployment Complete ✅
- [ ] Successfully deployed to production
- [ ] All features working
- [ ] Users can access Reports tab
- [ ] No critical issues

---

## Summary

### Total Tasks: 80+
- Database Setup: 10 ✓
- TypeScript Integration: 20 ✓
- Create Components: 35 ✓
- Integration: 15 ✓

### Estimated Timeline
- Phase 1: 1 hour
- Phase 2: 30 minutes
- Phase 3: 30 minutes
- Phase 4: 4-6 hours
- Phase 5: 2-3 hours
- Phase 6: 1-2 hours
- Phase 7: 1-2 hours
- Phase 8: 1-2 hours

**Total: 11-17 hours**

### Success Criteria
- [ ] All 80+ checklist items completed
- [ ] No critical issues remaining
- [ ] All features tested and working
- [ ] Ready for production use

---

## Quick Reference

**Database Files to Run**:
1. `REPORTS_FEATURE_SQL_MIGRATION.sql` ← Run first
2. `REPORTS_FEATURE_SAMPLE_DATA.sql` ← Run second (with ID replacements)

**TypeScript File to Add**:
- `REPORTS_FEATURE_TYPESCRIPT_INTERFACES.ts` → Copy to `client/lib/supabase.ts`

**Documentation to Read**:
1. `REPORTS_FEATURE_PLAN.md` ← Design overview
2. `REPORTS_FEATURE_IMPLEMENTATION_GUIDE.md` ← Step-by-step guide
3. `REPORTS_FEATURE_README.md` ← Complete summary

**Progress Tracking**:
- Print this checklist or save as digital checklist
- Update daily as you complete tasks
- Cross off items as completed
- Use summary percentages to gauge progress

---

## Final Notes

This is a comprehensive feature implementation. Take your time and follow the checklist methodically. Each phase builds on the previous one, so don't skip steps.

If you get stuck:
1. Check the relevant section in `REPORTS_FEATURE_IMPLEMENTATION_GUIDE.md`
2. Review the SQL schema in `REPORTS_FEATURE_SQL_MIGRATION.sql`
3. Look at type definitions in `REPORTS_FEATURE_TYPESCRIPT_INTERFACES.ts`
4. Check troubleshooting section in the guide

**Happy implementing! 🎉**
