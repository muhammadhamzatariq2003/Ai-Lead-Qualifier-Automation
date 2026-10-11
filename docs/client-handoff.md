# Client Handoff Document

## AI Lead Qualification System

**Client**: {{CLIENT_NAME}}
**Go-Live Date**: {{DATE}}
**Support Contact**: {{SUPPORT_EMAIL}}

---

## System Overview

Your AI Lead Qualification System automatically:

1. **Captures leads** from all your marketing channels
2. **Qualifies leads** using AI to score and categorize
3. **Generates follow-up messages** personalized to each lead
4. **Notifies your team** via Slack when new leads arrive
5. **Reports everything** to your dashboard

---

## What You'll Receive

### 1. Slack Notifications

When a new lead comes in, your team receives a Slack message with:

- Lead name and contact info
- Service requested
- AI qualification score (0-100)
- Status: Qualified, Needs Follow-Up, or Unqualified
- AI reasoning for the score
- Recommended next action

**Hot leads (score 80+)** get a fire emoji for immediate attention.

### 2. Google Sheets Dashboard

Your leads are automatically logged to:

**Spreadsheet**: `{{CLIENT_NAME}} - Lead Qualification Dashboard`

**Sheets included**:
- **Leads**: Every lead with full details
- **Daily Summary**: Daily totals and averages
- **Source Summary**: Performance by lead source

### 3. Looker Studio Dashboard

Visual analytics at: `{{LOOKER_STUDIO_URL}}`

**Key metrics**:
- Total leads and qualification rate
- Leads by source
- Score distribution
- Conversion funnel

---

## Lead Sources Connected

| Source | Status | Integration Type |
|--------|--------|------------------|
| Website Form | Active | Webhook |
| Google Ads | Active | Webhook |
| Facebook Ads | Active | Webhook |
| Manual Upload | Active | Google Sheets |

---

## How Leads Are Scored

The AI evaluates each lead on:

| Factor | Points | Description |
|--------|--------|-------------|
| Contact Info | 0-25 | Email, phone, completeness |
| Service Intent | 0-25 | Specific service mentioned |
| Urgency | 0-20 | Timeline indicators |
| Budget | 0-15 | Budget mentioned and fit |
| Message Quality | 0-15 | Detail and clarity |

**Score Meanings**:
- **80-100**: Hot lead, call immediately
- **60-79**: Qualified, follow up same day
- **30-59**: Needs more info, nurture
- **0-29**: Likely not a fit

---

## Follow-Up Messages

For qualified leads and those needing follow-up, the AI generates a personalized message that:

- References their specific inquiry
- Matches their urgency level
- Includes a clear call-to-action

**Important**: Messages are generated but NOT automatically sent. Your team reviews and sends them.

---

## Your API Credentials

**Webhook Endpoint**:
```
POST {{WEBHOOK_URL}}
```

**API Key**:
```
{{API_KEY}}
```

**Keep this key secure. Do not share publicly.**

---

## Webhook Integration

### For Your Web Developer

To send leads from your website form:

```javascript
fetch('{{WEBHOOK_URL}}', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': '{{API_KEY}}',
    'X-Source-Type': 'website_form'
  },
  body: JSON.stringify({
    email: formData.email,
    phone: formData.phone,
    name: formData.name,
    service_requested: formData.service,
    message: formData.message,
    urgency: formData.urgency
  })
})
```

### Accepted Fields

| Field | Required | Description |
|-------|----------|-------------|
| email | Yes* | Lead email |
| phone | Yes* | Lead phone |
| name | No | Full name |
| service_requested | No | Service type |
| message | No | Lead message |
| budget | No | Budget range |
| urgency | No | Timeline |

*At least one of email or phone required

---

## Manual Lead Upload

To upload leads manually:

1. Open your Google Sheet
2. Go to "Leads" tab
3. Add leads directly (they won't trigger AI processing)

OR

Use the CSV upload feature:
1. Prepare CSV with standard columns
2. Upload to designated folder
3. System processes automatically

---

## Notification Settings

### Current Configuration

| Setting | Value |
|---------|-------|
| Slack Channel | {{SLACK_CHANNEL}} |
| Notification Delay | 5 minutes |
| Quiet Hours | None |

### To Change Settings

Contact support to adjust:
- Slack channel destination
- Qualification thresholds
- Notification timing

---

## Dashboard Access

### Google Sheets
- **URL**: {{SHEETS_URL}}
- **Access**: Shared with your team emails

### Looker Studio
- **URL**: {{LOOKER_URL}}
- **Access**: Shared with your team emails

---

## Common Questions

### "Why was a lead marked unqualified?"

Check the "AI Reasoning" column in the Leads sheet. Common reasons:
- Missing contact information
- Service not in your area
- Detected as spam or test submission

### "Can I override a qualification?"

Currently, scores are read-only. Contact support if you need to dispute a score.

### "How fast are leads processed?"

Leads are typically qualified within 30 seconds of submission.

### "What happens if the system is down?"

Leads are queued and processed when service resumes. You'll receive all notifications.

---

## Support

### Standard Support
- **Email**: {{SUPPORT_EMAIL}}
- **Response Time**: Within 4 business hours

### Emergency Issues
- System completely down
- No leads receiving
- Critical errors

**Emergency Contact**: {{EMERGENCY_CONTACT}}

---

## Monthly Reporting

Each month you'll receive:

1. **Lead Volume Report**: Total leads, by source, by status
2. **Qualification Metrics**: Average scores, qualification rate
3. **System Health**: Uptime, errors, performance
4. **Recommendations**: Optimization suggestions

---

## Training Resources

### Video Tutorials
- Reading Slack notifications
- Using the Google Sheets dashboard
- Understanding Looker Studio reports

### Documentation
- This handoff document
- Webhook integration guide
- Troubleshooting guide

---

## Change Log

| Date | Change | By |
|------|--------|-----|
| {{GO_LIVE_DATE}} | Initial deployment | {{DEPLOYER}} |

---

## Acceptance

By signing below, you acknowledge:
- System has been demonstrated
- Access credentials received
- Dashboard access confirmed
- Support contact information provided

**Client Representative**:

Name: _______________________

Signature: _______________________

Date: _______________________

---

**Agency Representative**:

Name: _______________________

Signature: _______________________

Date: _______________________
