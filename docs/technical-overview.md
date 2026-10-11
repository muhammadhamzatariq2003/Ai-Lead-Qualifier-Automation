# AI Lead Qualification + Follow-Up Automation System

Leads arrive from forms, ads or an API. The system cleans them, removes duplicates, scores them 0-100 with Claude, writes a follow-up message, alerts the sales team on Slack and logs everything to Supabase and Google Sheets.

> This is the full technical design. For a client-friendly summary, see the main [README](../README.md).

## Repository Structure

```
ai-lead-qualifier/
├── README.md
├── quickstart/
│   ├── lead-qualifier-quickstart.json   # importable n8n workflow
│   ├── sample-lead.json
│   └── README.md
├── database/
│   └── schema.sql
├── workflows/
│   ├── 01-lead-intake.md
│   ├── 02-lead-normalization.md
│   ├── 03-ai-qualification.md
│   ├── 04-followup-generation.md
│   ├── 05-slack-notification.md
│   ├── 06-sheets-export.md
│   └── 07-error-handler.md
├── prompts/
│   ├── qualification-prompt.md
│   └── followup-prompt.md
├── reporting/
│   ├── google-sheets-schema.md
│   └── looker-studio-spec.md
├── config/
│   ├── environment-variables.md
│   └── client-config-template.md
└── docs/
    ├── deployment-checklist.md
    └── client-handoff.md
```

## System Overview

Production-ready lead qualification automation for high-ticket service businesses.

### Stack
- **Orchestration**: n8n.cloud
- **Database**: Supabase (Postgres)
- **AI**: Claude API
- **Reporting**: Google Sheets + Looker Studio
- **Notifications**: Slack Webhooks

### Lead Sources Supported
- Website forms (Webhook)
- Google Ads lead forms (Webhook)
- Facebook/Meta lead forms (Webhook)
- Manual CSV upload (Google Sheets)
- API ingestion (Authenticated Webhook)
- Phone/SMS (Webhook-based)

### Core Capabilities
1. Multi-source lead ingestion
2. Data normalization and validation
3. Intelligent deduplication
4. AI-powered qualification (Claude)
5. Automated follow-up message generation
6. Real-time Slack notifications
7. Comprehensive audit logging
8. Automated reporting to Google Sheets
9. Looker Studio dashboard integration

## Quick Start

1. Run `database/schema.sql` in Supabase SQL Editor
2. Configure environment variables in n8n.cloud
3. Import workflows following specs in `workflows/`
4. Connect Google Sheets and Slack
5. Configure webhook endpoints
6. Test with sample lead data

## Client Configuration

See `config/client-config-template.md` for per-client customization options.

## Support

System designed for agency deployment. Each client instance requires:
- Dedicated Supabase project
- Dedicated n8n.cloud workspace
- Client-specific API credentials
- Custom qualification criteria (configurable)
