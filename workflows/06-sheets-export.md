# Workflow 6: Google Sheets Export

## Workflow Settings
- **Name**: `06_sheets_export`
- **Trigger**: Execute Workflow Trigger
- **Timeout**: 60 seconds
- **Error Workflow**: `07_error_handler`

---

## Node 1: Execute Workflow Trigger
**Type**: Execute Workflow Trigger
**Name**: `trigger_export_start`

**Expected Input**:
```javascript
{
  lead_id: UUID,
  client_id: UUID,
  client_config: Object,
  lead_data: Object,
  qualification: Object
}
```

---

## Node 2: Check Sheets Configured
**Type**: IF
**Name**: `check_sheets_configured`

**Condition**:
```javascript
{{ $json.client_config.google_sheet_id !== null &&
   $json.client_config.google_sheet_id !== '' }}
```

**True**: Continue to Node 3
**False**: Return (skip export)

---

## Node 3: Format Lead for Sheets
**Type**: Code
**Name**: `format_lead_for_sheets`

**JavaScript**:
```javascript
const lead = $json.lead_data;
const qual = $json.qualification;
const config = $json.client_config;

// Format timestamp to client timezone
const formatDate = (isoString) => {
  if (!isoString) return '';
  const date = new Date(isoString);
  return date.toLocaleString('en-US', {
    timeZone: config.timezone || 'America/New_York',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  });
};

return {
  sheet_id: config.google_sheet_id,
  row_data: [
    lead.id,
    formatDate(lead.created_at),
    lead.source,
    lead.utm_campaign || '',
    lead.full_name || '',
    lead.email || '',
    lead.phone || '',
    lead.company || '',
    [lead.city, lead.state].filter(Boolean).join(', '),
    lead.service_requested || '',
    lead.message ? lead.message.substring(0, 500) : '',
    lead.budget_range || '',
    lead.urgency || '',
    qual.status,
    qual.score,
    qual.reasoning || '',
    (qual.key_signals || []).join('; '),
    qual.recommended_action || '',
    lead.followup_message ? 'Yes' : 'No',
    formatDate(lead.submitted_at),
    formatDate(lead.processed_at)
  ]
};
```

---

## Node 4: Append to Leads Sheet
**Type**: Google Sheets
**Name**: `append_to_leads_sheet`

**Authentication**: Google OAuth2 (Service Account)
**Operation**: Append Row
**Spreadsheet ID**: `{{ $json.sheet_id }}`
**Sheet Name**: `Leads`

**Data Mode**: Define Below
**Values**: `{{ $json.row_data }}`

**Options**:
- Value Input Option: USER_ENTERED
- Insert Data Option: INSERT_ROWS

---

## Node 5: Update Daily Summary Sheet
**Type**: Code
**Name**: `prepare_daily_summary_update`

**JavaScript**:
```javascript
const lead = $input.first().json.lead_data;
const qual = $input.first().json.qualification;

const today = new Date().toISOString().split('T')[0];

return {
  sheet_id: $input.first().json.client_config.google_sheet_id,
  date: today,
  source: lead.source,
  status: qual.status,
  score: qual.score
};
```

---

## Node 6: Get Daily Summary Row
**Type**: Google Sheets
**Name**: `get_daily_summary`

**Authentication**: Google OAuth2 (Service Account)
**Operation**: Read Rows
**Spreadsheet ID**: `{{ $json.sheet_id }}`
**Sheet Name**: `Daily Summary`

**Filters**:
- Date equals `{{ $json.date }}`

---

## Node 7: Check If Summary Exists
**Type**: IF
**Name**: `check_summary_exists`

**Condition**:
```javascript
{{ $json.length > 0 }}
```

**True**: Continue to Node 7a (Update existing)
**False**: Continue to Node 7b (Insert new)

---

## Node 7a: Update Daily Summary Row
**Type**: Google Sheets
**Name**: `update_daily_summary`

**Authentication**: Google OAuth2 (Service Account)
**Operation**: Update Row
**Spreadsheet ID**: `{{ $node.prepare_daily_summary_update.json.sheet_id }}`
**Sheet Name**: `Daily Summary`

**Row Number**: `{{ $json[0].row_number }}`

**Update Logic**:
```javascript
// Increment appropriate counters
const current = $json[0];
return {
  total_leads: (parseInt(current.total_leads) || 0) + 1,
  qualified: current.qualified + ($node.prepare_daily_summary_update.json.status === 'qualified' ? 1 : 0),
  needs_followup: current.needs_followup + ($node.prepare_daily_summary_update.json.status === 'needs_followup' ? 1 : 0),
  unqualified: current.unqualified + ($node.prepare_daily_summary_update.json.status === 'unqualified' ? 1 : 0)
};
```

---

## Node 7b: Insert Daily Summary Row
**Type**: Google Sheets
**Name**: `insert_daily_summary`

**Authentication**: Google OAuth2 (Service Account)
**Operation**: Append Row
**Spreadsheet ID**: `{{ $node.prepare_daily_summary_update.json.sheet_id }}`
**Sheet Name**: `Daily Summary`

**Values**:
```javascript
[
  $node.prepare_daily_summary_update.json.date,
  1, // total_leads
  $node.prepare_daily_summary_update.json.status === 'qualified' ? 1 : 0,
  $node.prepare_daily_summary_update.json.status === 'needs_followup' ? 1 : 0,
  $node.prepare_daily_summary_update.json.status === 'unqualified' ? 1 : 0,
  $node.prepare_daily_summary_update.json.score, // first score (will be averaged)
  '', // avg_response_time (calculated later)
  '' // conversion_rate (calculated later)
]
```

---

## Node 8: Update Source Summary
**Type**: Code
**Name**: `prepare_source_summary`

**JavaScript**:
```javascript
const lead = $input.first().json.lead_data;
const qual = $input.first().json.qualification;

const today = new Date().toISOString().split('T')[0];

return {
  sheet_id: $input.first().json.client_config.google_sheet_id,
  date: today,
  source: lead.source,
  status: qual.status,
  score: qual.score
};
```

---

## Node 9: Append to Source Log
**Type**: Google Sheets
**Name**: `append_source_log`

**Authentication**: Google OAuth2 (Service Account)
**Operation**: Append Row
**Spreadsheet ID**: `{{ $json.sheet_id }}`
**Sheet Name**: `Source Log`

**Values**:
```javascript
[
  $json.date,
  $json.source,
  $json.status,
  $json.score
]
```

---

## Node 10: Log Export Event
**Type**: Supabase
**Name**: `log_export_event`

**Operation**: Insert
**Table**: `events`

**Data**:
```javascript
{
  client_id: {{ $input.first().json.client_id }},
  lead_id: {{ $input.first().json.lead_id }},
  event_type: 'export_completed',
  event_data: {
    destination: 'google_sheets',
    sheet_id: {{ $input.first().json.client_config.google_sheet_id }}
  },
  workflow_id: '06_sheets_export',
  workflow_execution_id: {{ $execution.id }}
}
```

---

## Node 11: Return Result
**Type**: Set
**Name**: `return_export_result`

**Fields**:
```javascript
{
  lead_id: {{ $input.first().json.lead_id }},
  exported: true,
  destination: 'google_sheets'
}
```

---

## Error Handling

**On Error**: Log error but do not fail (non-critical path)
