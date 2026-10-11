# Google Sheets Schema

## Spreadsheet Structure

**Spreadsheet Name**: `[Client Name] - Lead Qualification Dashboard`

---

## Sheet 1: Leads

**Purpose**: Raw lead data for reporting and manual review

| Column | Header | Data Type | Description |
|--------|--------|-----------|-------------|
| A | Lead ID | UUID | Unique identifier from database |
| B | Timestamp | DateTime | When lead was received |
| C | Source | Text | Lead source (website_form, google_ads, etc.) |
| D | Campaign | Text | UTM campaign or ad campaign name |
| E | Name | Text | Lead full name |
| F | Email | Text | Lead email address |
| G | Phone | Text | Lead phone number |
| H | Company | Text | Company name |
| I | Location | Text | City, State |
| J | Service | Text | Service requested |
| K | Message | Text | Lead message (truncated to 500 chars) |
| L | Budget | Text | Budget range |
| M | Urgency | Text | Urgency level |
| N | Status | Text | qualified / needs_followup / unqualified |
| O | Score | Number | Qualification score 0-100 |
| P | AI Reasoning | Text | AI qualification explanation |
| Q | Key Signals | Text | Key signals (semicolon-separated) |
| R | Recommended Action | Text | AI recommended next step |
| S | Follow-Up Generated | Text | Yes/No |
| T | Submitted At | DateTime | Original submission timestamp |
| U | Processed At | DateTime | When qualification completed |

**Formatting**:
- Row 1: Frozen header row, bold, background #4285f4
- Conditional formatting on Status column:
  - "qualified" → Green background (#34a853)
  - "needs_followup" → Yellow background (#fbbc04)
  - "unqualified" → Red background (#ea4335)
- Score column: Data bar visualization (0-100)
- Filter views enabled

---

## Sheet 2: Daily Summary

**Purpose**: Aggregated daily metrics for trend analysis

| Column | Header | Data Type | Description |
|--------|--------|-----------|-------------|
| A | Date | Date | YYYY-MM-DD |
| B | Total Leads | Number | Total leads received |
| C | Qualified | Number | Count of qualified status |
| D | Needs Follow-Up | Number | Count of needs_followup status |
| E | Unqualified | Number | Count of unqualified status |
| F | Avg Score | Number | Average qualification score |
| G | Avg Response Time (min) | Number | Avg minutes to process |
| H | Qualification Rate (%) | Formula | `=C2/B2*100` |

**Formulas** (Row 2 example):
- H2: `=IF(B2>0, C2/B2*100, 0)`

**Formatting**:
- Row 1: Frozen header, bold
- Date column: Sorted descending (newest first)
- Qualification Rate: Percentage format, conditional formatting (green >50%, yellow 30-50%, red <30%)

---

## Sheet 3: Source Log

**Purpose**: Raw event log for source attribution analysis

| Column | Header | Data Type | Description |
|--------|--------|-----------|-------------|
| A | Date | Date | YYYY-MM-DD |
| B | Source | Text | Lead source |
| C | Status | Text | Qualification status |
| D | Score | Number | Qualification score |

**Usage**: Pivot table source for Looker Studio

---

## Sheet 4: Source Summary

**Purpose**: Aggregated source performance metrics

| Column | Header | Data Type | Description |
|--------|--------|-----------|-------------|
| A | Source | Text | Lead source channel |
| B | Total Leads | Number | Total leads from source |
| C | Qualified | Number | Qualified leads from source |
| D | Qualification Rate | Percentage | `=C/B*100` |
| E | Avg Score | Number | Average qualification score |
| F | Last Lead | DateTime | Most recent lead from source |

**Formulas**: SUMIF/COUNTIF from Source Log sheet

---

## Sheet 5: Funnel Metrics

**Purpose**: Weekly funnel conversion data

| Column | Header | Data Type | Description |
|--------|--------|-----------|-------------|
| A | Week | Text | YYYY-Wnn format |
| B | Leads Received | Number | Total inbound leads |
| C | Unique Leads | Number | Deduplicated leads |
| D | Qualified | Number | Qualified leads |
| E | Contacted | Number | Leads marked contacted |
| F | Converted | Number | Leads marked converted |
| G | Receive→Qualified % | Percentage | Qualification rate |
| H | Qualified→Contacted % | Percentage | Contact rate |
| I | Contacted→Converted % | Percentage | Conversion rate |

---

## Sheet 6: Config (Hidden)

**Purpose**: Client configuration and reference data

| Column | Header | Value |
|--------|--------|-------|
| A | Client ID | `{{CLIENT_ID}}` |
| B | Client Name | `{{CLIENT_NAME}}` |
| C | Timezone | `{{TIMEZONE}}` |
| D | Min Qualified Score | `{{MIN_SCORE_QUALIFIED}}` |
| E | Last Updated | `{{TIMESTAMP}}` |

**Note**: Hide this sheet from end users

---

## Named Ranges

| Range Name | Sheet | Range | Purpose |
|------------|-------|-------|---------|
| `leads_data` | Leads | A:U | Source for Looker Studio |
| `daily_summary` | Daily Summary | A:H | Daily metrics source |
| `source_log` | Source Log | A:D | Source attribution data |
| `source_summary` | Source Summary | A:F | Source performance |
| `funnel_data` | Funnel Metrics | A:I | Funnel analysis |

---

## Permissions

- **Owner**: Agency Google account
- **Editor**: Client designated users
- **Viewer**: Looker Studio service account

---

## Data Retention

- Leads sheet: Keep all records
- Source Log: Keep all records (pivot source)
- Daily/Weekly summaries: Aggregated, can be rebuilt

---

## Setup Instructions

1. Create new Google Spreadsheet
2. Rename to `[Client Name] - Lead Qualification Dashboard`
3. Create sheets in order listed above
4. Add headers to each sheet
5. Apply formatting rules
6. Create named ranges
7. Share with n8n service account (Editor)
8. Copy Spreadsheet ID for n8n configuration
9. Hide Config sheet
10. Enable filter views on Leads sheet
