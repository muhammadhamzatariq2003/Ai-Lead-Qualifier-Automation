# Deployment Checklist

## Pre-Deployment

### 1. Supabase Setup

- [ ] Create new Supabase project
- [ ] Note Project URL: `_______________________`
- [ ] Note Service Role Key: `_______________________`
- [ ] Run `database/schema.sql` in SQL Editor
- [ ] Verify all tables created successfully
- [ ] Verify all indexes created
- [ ] Verify all functions created
- [ ] Verify triggers active
- [ ] Test RLS policies (service role bypass works)

### 2. n8n.cloud Setup

- [ ] Create new n8n.cloud workspace (or use existing)
- [ ] Note workspace URL: `_______________________`
- [ ] Configure environment variables:
  - [ ] `SUPABASE_URL`
  - [ ] `SUPABASE_SERVICE_KEY`
  - [ ] `CLAUDE_API_KEY`
  - [ ] `SYSTEM_SLACK_WEBHOOK_URL`
  - [ ] `GOOGLE_SERVICE_ACCOUNT_EMAIL`
  - [ ] `GOOGLE_PRIVATE_KEY`
- [ ] Verify all variables saved

### 3. Google Setup

- [ ] Create Google Cloud project (or use existing)
- [ ] Enable Google Sheets API
- [ ] Enable Google Drive API
- [ ] Create service account
- [ ] Download service account JSON
- [ ] Extract email and private key
- [ ] Note service account email: `_______________________`

### 4. Slack Setup

- [ ] Create Slack app (or use existing)
- [ ] Add Incoming Webhooks feature
- [ ] Create webhook for system alerts channel
- [ ] Note system webhook URL: `_______________________`
- [ ] Test webhook sends message

### 5. Claude API Setup

- [ ] Verify Anthropic account active
- [ ] Check API credits available
- [ ] Note API key: `_______________________`
- [ ] Test API key with curl request

---

## Workflow Deployment

### Build Workflows in n8n

For each workflow, create in n8n following specifications:

#### Workflow 01: Lead Intake
- [ ] Create workflow `01_lead_intake`
- [ ] Add Webhook trigger node
- [ ] Configure authentication
- [ ] Add all nodes per spec
- [ ] Set error workflow to `07_error_handler`
- [ ] Test with Postman/curl
- [ ] Activate workflow

#### Workflow 02: Lead Normalization
- [ ] Create workflow `02_lead_normalization`
- [ ] Add Execute Workflow Trigger
- [ ] Add source detection switch
- [ ] Add normalization code nodes
- [ ] Add Supabase insert
- [ ] Set error workflow
- [ ] Test with sample data
- [ ] Activate workflow

#### Workflow 03: AI Qualification
- [ ] Create workflow `03_ai_qualification`
- [ ] Add Execute Workflow Trigger
- [ ] Add Claude API HTTP node
- [ ] Configure prompts
- [ ] Add response parsing
- [ ] Add Supabase update
- [ ] Set error workflow
- [ ] Test with sample lead
- [ ] Verify qualification output
- [ ] Activate workflow

#### Workflow 04: Follow-Up Generation
- [ ] Create workflow `04_followup_generation`
- [ ] Add Execute Workflow Trigger
- [ ] Add Claude API HTTP node
- [ ] Configure prompts
- [ ] Add message insert
- [ ] Set error workflow
- [ ] Test message generation
- [ ] Activate workflow

#### Workflow 05: Slack Notification
- [ ] Create workflow `05_slack_notification`
- [ ] Add Execute Workflow Trigger
- [ ] Add Slack message builder
- [ ] Add HTTP webhook node
- [ ] Set error handling (continue on fail)
- [ ] Test notification
- [ ] Activate workflow

#### Workflow 06: Sheets Export
- [ ] Create workflow `06_sheets_export`
- [ ] Add Execute Workflow Trigger
- [ ] Add Google Sheets nodes
- [ ] Configure authentication
- [ ] Set error handling (continue on fail)
- [ ] Test export
- [ ] Activate workflow

#### Workflow 07: Error Handler
- [ ] Create workflow `07_error_handler`
- [ ] Add Error Trigger
- [ ] Add error logging to Supabase
- [ ] Add Slack alert
- [ ] Set all nodes to continue on fail
- [ ] Test error capture
- [ ] Activate workflow

---

## Client Onboarding

### 6. Client Configuration

- [ ] Collect client information
- [ ] Determine industry template
- [ ] Customize qualification criteria
- [ ] Create client record in database
- [ ] Note client UUID: `_______________________`
- [ ] Note client slug: `_______________________`

### 7. Client Slack Setup

- [ ] Get client Slack workspace access
- [ ] Create incoming webhook for client channel
- [ ] Update client record with webhook URL
- [ ] Test client notification

### 8. Client Google Sheets Setup

- [ ] Create Google Sheet from template
- [ ] Apply formatting and headers
- [ ] Share with service account (Editor)
- [ ] Note Sheet ID: `_______________________`
- [ ] Update client record with Sheet ID
- [ ] Test export to sheet

### 9. API Key Generation

- [ ] Generate secure API key
- [ ] Hash and store in database
- [ ] Document key for client: `_______________________`
- [ ] Set appropriate rate limits

### 10. Webhook Configuration

- [ ] Document webhook URL for client
- [ ] Provide integration instructions
- [ ] Set up any required source integrations:
  - [ ] Website form
  - [ ] Google Ads
  - [ ] Facebook Ads
  - [ ] Other sources

---

## Testing

### 11. End-to-End Testing

- [ ] Submit test lead via webhook
- [ ] Verify lead appears in database
- [ ] Verify normalization correct
- [ ] Verify qualification runs
- [ ] Verify score calculated
- [ ] Verify follow-up generated
- [ ] Verify Slack notification sent
- [ ] Verify Google Sheet updated
- [ ] Verify no errors in error_logs

### 12. Edge Case Testing

- [ ] Test duplicate lead detection
- [ ] Test invalid email handling
- [ ] Test missing required fields
- [ ] Test invalid API key rejection
- [ ] Test rate limiting (if enabled)
- [ ] Test each lead source format

### 13. Error Handling Testing

- [ ] Simulate Claude API failure
- [ ] Simulate Supabase failure
- [ ] Simulate Slack webhook failure
- [ ] Simulate Sheets API failure
- [ ] Verify errors logged correctly
- [ ] Verify error alerts sent

---

## Go-Live

### 14. Final Verification

- [ ] All workflows active
- [ ] All environment variables set
- [ ] Client record complete
- [ ] API key documented
- [ ] Webhook URL documented
- [ ] Slack notifications working
- [ ] Sheets export working
- [ ] Error handling working

### 15. Client Handoff

- [ ] Provide client handoff document
- [ ] Provide API key securely
- [ ] Provide webhook endpoints
- [ ] Walk through Looker Studio dashboard
- [ ] Train on Slack notifications
- [ ] Establish support channel

### 16. Monitoring Setup

- [ ] Set up daily error log review
- [ ] Configure weekly summary report
- [ ] Document escalation procedures
- [ ] Set up uptime monitoring (optional)

---

## Post-Launch

### Week 1 Review

- [ ] Check error logs daily
- [ ] Verify lead volume expected
- [ ] Verify qualification accuracy
- [ ] Review follow-up messages
- [ ] Address any issues

### Month 1 Review

- [ ] Analyze qualification metrics
- [ ] Review conversion data
- [ ] Adjust scoring if needed
- [ ] Optimize prompts if needed
- [ ] Client feedback session

---

## Rollback Procedure

If critical issues occur:

1. [ ] Deactivate intake workflow immediately
2. [ ] Notify client of pause
3. [ ] Review error logs
4. [ ] Identify root cause
5. [ ] Fix and test in isolation
6. [ ] Reactivate with monitoring

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Technical Lead | | | |
| QA | | | |
| Client Contact | | | |
