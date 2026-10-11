# Looker Studio Dashboard Specification

## Dashboard Overview

**Name**: `[Client Name] - Lead Qualification Dashboard`
**Data Source**: Google Sheets (Client Spreadsheet)
**Refresh**: Every 15 minutes (Looker Studio default for Sheets)

---

## Data Sources Configuration

### Source 1: Leads Data
- **Connector**: Google Sheets
- **Spreadsheet**: `[Client Name] - Lead Qualification Dashboard`
- **Range**: `leads_data` (named range)
- **Field Configuration**:

| Field | Type | Aggregation |
|-------|------|-------------|
| Lead ID | Text | None |
| Timestamp | Date Hour | None |
| Source | Text | None |
| Campaign | Text | None |
| Name | Text | None |
| Status | Text | None |
| Score | Number | Avg, Sum, Count |
| Location | Text (Geo) | None |

### Source 2: Daily Summary
- **Connector**: Google Sheets
- **Range**: `daily_summary`

### Source 3: Source Summary
- **Connector**: Google Sheets
- **Range**: `source_summary`

---

## Page 1: Executive Overview

### Layout: 3-column grid

---

### Row 1: KPI Scorecards (4 cards)

#### Card 1: Total Leads (This Period)
- **Type**: Scorecard
- **Metric**: COUNT(Lead ID)
- **Comparison**: Previous period (%)
- **Style**: Large number, green/red delta arrow

#### Card 2: Qualification Rate
- **Type**: Scorecard
- **Metric**: COUNT(Status = "qualified") / COUNT(Lead ID) * 100
- **Format**: Percentage
- **Comparison**: Previous period

#### Card 3: Average Score
- **Type**: Scorecard
- **Metric**: AVG(Score)
- **Format**: Number (0 decimal)
- **Comparison**: Previous period

#### Card 4: Qualified Leads
- **Type**: Scorecard
- **Metric**: COUNT(Status = "qualified")
- **Comparison**: Previous period

---

### Row 2: Trend Charts

#### Chart 1: Leads Over Time (2/3 width)
- **Type**: Time Series
- **Dimension**: Timestamp (by Day)
- **Metrics**:
  - Total Leads (line, blue)
  - Qualified (line, green)
  - Needs Follow-Up (line, yellow)
- **Date Range**: Last 30 days
- **Interactions**: Drill-down to weekly/daily

#### Chart 2: Qualification Status Distribution (1/3 width)
- **Type**: Pie Chart
- **Dimension**: Status
- **Metric**: COUNT(Lead ID)
- **Colors**:
  - qualified: #34a853
  - needs_followup: #fbbc04
  - unqualified: #ea4335
- **Show**: Percentage labels

---

### Row 3: Source Performance

#### Chart 3: Leads by Source (1/2 width)
- **Type**: Bar Chart (Horizontal)
- **Dimension**: Source
- **Metric**: COUNT(Lead ID)
- **Sort**: Descending by count
- **Colors**: By source channel

#### Chart 4: Qualification Rate by Source (1/2 width)
- **Type**: Bar Chart (Horizontal)
- **Dimension**: Source
- **Metric**: Qualification Rate (calculated field)
- **Sort**: Descending by rate
- **Conditional Color**: Green >60%, Yellow 30-60%, Red <30%

---

### Row 4: Score Distribution

#### Chart 5: Score Distribution Histogram
- **Type**: Histogram / Bar Chart
- **Dimension**: Score (binned: 0-10, 11-20, ..., 91-100)
- **Metric**: COUNT(Lead ID)
- **Colors**: Gradient blue→green

#### Chart 6: Average Score by Source
- **Type**: Column Chart
- **Dimension**: Source
- **Metric**: AVG(Score)
- **Reference Line**: 60 (qualification threshold)

---

## Page 2: Lead Details

### Controls

#### Date Range Control
- **Type**: Date range picker
- **Default**: Last 30 days

#### Source Filter
- **Type**: Drop-down (multi-select)
- **Dimension**: Source

#### Status Filter
- **Type**: Drop-down (multi-select)
- **Dimension**: Status

#### Score Range Filter
- **Type**: Slider
- **Range**: 0-100

---

### Lead Table

- **Type**: Table with heatmap
- **Columns**:

| Column | Width | Format |
|--------|-------|--------|
| Timestamp | 120px | MMM DD, YYYY HH:mm |
| Name | 150px | Text |
| Email | 200px | Text |
| Phone | 120px | Text |
| Source | 100px | Text |
| Service | 150px | Text |
| Score | 60px | Number + heatmap |
| Status | 100px | Text + color |
| Action | 100px | Text |

- **Pagination**: 25 rows per page
- **Sorting**: Default by Timestamp DESC
- **Row-level Interactions**: Click to show details

---

### Lead Details Panel (on row click)

- **Type**: Data panel / Custom report
- **Fields**:
  - Full lead information
  - AI Reasoning
  - Key Signals
  - Follow-up message (if generated)

---

## Page 3: Funnel Analysis

### Funnel Visualization

- **Type**: Funnel Chart
- **Stages**:
  1. Leads Received
  2. Unique Leads (deduplicated)
  3. Qualified
  4. Contacted
  5. Converted

- **Show**: Count and conversion rate between stages

---

### Conversion Metrics Table

| Stage | Count | % of Previous | % of Total |
|-------|-------|---------------|------------|
| Received | X | - | 100% |
| Unique | X | Y% | Z% |
| Qualified | X | Y% | Z% |
| Contacted | X | Y% | Z% |
| Converted | X | Y% | Z% |

---

### Response Time Analysis

#### Chart: Time to Qualification
- **Type**: Histogram
- **Dimension**: Processing Time (minutes, binned)
- **Metric**: COUNT
- **Insight**: Identify processing bottlenecks

---

## Page 4: Source Deep Dive

### Source Performance Matrix

- **Type**: Pivot Table / Heatmap
- **Rows**: Source
- **Columns**: Status
- **Values**: COUNT(Lead ID)
- **Color Scale**: By cell value

---

### Campaign Performance

- **Type**: Table
- **Columns**:
  - Campaign Name
  - Source
  - Leads
  - Qualified
  - Qualification Rate
  - Avg Score
- **Sort**: By Leads DESC

---

### Source Trend

- **Type**: Time Series
- **Dimension**: Timestamp (by Week)
- **Breakdown**: Source
- **Metric**: COUNT(Lead ID)
- **Style**: Stacked area chart

---

## Calculated Fields

### Qualification Rate
```
COUNT_DISTINCT(CASE WHEN Status = "qualified" THEN Lead ID END) /
COUNT_DISTINCT(Lead ID) * 100
```

### Processing Time (Minutes)
```
DATETIME_DIFF(Processed At, Submitted At, MINUTE)
```

### Score Tier
```
CASE
  WHEN Score >= 80 THEN "Hot (80-100)"
  WHEN Score >= 60 THEN "Qualified (60-79)"
  WHEN Score >= 30 THEN "Follow-Up (30-59)"
  ELSE "Unqualified (0-29)"
END
```

### Week Number
```
CONCAT(YEAR(Timestamp), "-W", LPAD(WEEK(Timestamp), 2, "0"))
```

---

## Filters Configuration

### Default Date Range
- Last 30 days

### Cross-Filtering
- Enable for all charts
- Clicking a source bar filters all charts

### Drill-Down
- Time series: Year → Month → Week → Day
- Source: Source → Campaign

---

## Sharing & Embedding

### Access Levels
- **Owner**: Agency account
- **Edit**: Internal team
- **View**: Client stakeholders

### Scheduled Emails
- Weekly summary: Monday 8am
- Recipients: Client contacts
- Format: PDF attachment

### Embed Options
- Generate embed code for client portal
- Restrict to allowed domains

---

## Style Guide

### Colors
- Primary: #4285f4
- Qualified: #34a853
- Needs Follow-Up: #fbbc04
- Unqualified: #ea4335
- Background: #ffffff
- Text: #202124

### Typography
- Headers: Google Sans, 24px
- Body: Roboto, 12px
- Numbers: Roboto Mono, 14px

### Logo
- Client logo top-left
- Agency logo footer (optional)
