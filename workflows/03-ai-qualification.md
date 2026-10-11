# Workflow 3: AI Qualification (Claude)

## Workflow Settings
- **Name**: `03_ai_qualification`
- **Trigger**: Execute Workflow Trigger
- **Timeout**: 120 seconds
- **Error Workflow**: `07_error_handler`

---

## Node 1: Execute Workflow Trigger
**Type**: Execute Workflow Trigger
**Name**: `trigger_qualification_start`

**Expected Input**:
```javascript
{
  lead_id: UUID,
  client_id: UUID,
  client_config: Object
}
```

---

## Node 2: Fetch Lead Data
**Type**: Supabase
**Name**: `fetch_lead_data`

**Operation**: Select
**Table**: `leads`

**Filters**:
```sql
id = {{ $json.lead_id }}
```

**Return Fields**: `*`

---

## Node 3: Log Qualification Start
**Type**: Supabase
**Name**: `log_qualification_start`

**Operation**: Insert
**Table**: `events`

**Data**:
```javascript
{
  client_id: {{ $input.first().json.client_id }},
  lead_id: {{ $input.first().json.lead_id }},
  event_type: 'qualification_started',
  event_data: {},
  workflow_id: '03_ai_qualification',
  workflow_execution_id: {{ $execution.id }}
}
```

---

## Node 4: Build Qualification Prompt
**Type**: Code
**Name**: `build_qualification_prompt`

**JavaScript**:
```javascript
const lead = $node.fetch_lead_data.json[0];
const config = $input.first().json.client_config;
const criteria = config.qualification_criteria || {};

const systemPrompt = `You are a lead qualification AI for a ${config.industry || 'service'} business.

Your task is to analyze incoming leads and determine their quality and likelihood to convert.

QUALIFICATION CRITERIA:
- Required fields: ${(criteria.required_fields || ['email']).join(', ')}
- High-value services: ${(criteria.high_value_services || []).join(', ')}
- Urgency boost scoring: ${JSON.stringify(criteria.urgency_boost || {})}
- Minimum score for qualified: ${criteria.min_score_qualified || 60}
- Minimum score for follow-up: ${criteria.min_score_followup || 30}

SCORING GUIDELINES:
- Score from 0-100
- 80-100: Hot lead, high intent, immediate potential
- 60-79: Qualified lead, good fit, worth pursuing
- 30-59: Needs follow-up, unclear intent or missing info
- 0-29: Unqualified, poor fit or spam

RESPONSE FORMAT (JSON only):
{
  "score": <number 0-100>,
  "status": "<qualified|unqualified|needs_followup>",
  "reasoning": "<2-3 sentence explanation>",
  "key_signals": ["<signal1>", "<signal2>"],
  "recommended_action": "<immediate_call|email_followup|nurture_sequence|disqualify>",
  "missing_info": ["<field1>", "<field2>"]
}`;

const userPrompt = `Analyze this lead:

EMAIL: ${lead.email || 'Not provided'}
PHONE: ${lead.phone || 'Not provided'}
NAME: ${lead.full_name || 'Not provided'}
COMPANY: ${lead.company || 'Not provided'}
SERVICE REQUESTED: ${lead.service_requested || 'Not specified'}
MESSAGE: ${lead.message || 'No message'}
BUDGET: ${lead.budget_range || 'Not specified'}
URGENCY: ${lead.urgency || 'Not specified'}
LOCATION: ${[lead.city, lead.state].filter(Boolean).join(', ') || 'Not provided'}
SOURCE: ${lead.source}
UTM CAMPAIGN: ${lead.utm_campaign || 'Direct'}

Provide your qualification assessment as JSON.`;

return {
  system_prompt: systemPrompt,
  user_prompt: userPrompt,
  lead: lead
};
```

---

## Node 5: Call Claude API
**Type**: HTTP Request
**Name**: `call_claude_api`

**Method**: POST
**URL**: `https://api.anthropic.com/v1/messages`

**Headers**:
```
x-api-key: {{ $env.CLAUDE_API_KEY }}
anthropic-version: 2023-06-01
content-type: application/json
```

**Body**:
```json
{
  "model": "claude-sonnet-5-5",
  "max_tokens": 1024,
  "messages": [
    {
      "role": "user",
      "content": "{{ $json.user_prompt }}"
    }
  ],
  "system": "{{ $json.system_prompt }}"
}
```

**Timeout**: 60000

---

## Node 6: Parse Claude Response
**Type**: Code
**Name**: `parse_qualification_response`

**JavaScript**:
```javascript
const response = $json;
const content = response.content?.[0]?.text || '';

// Extract JSON from response
let qualification;
try {
  // Try to parse the entire response as JSON
  qualification = JSON.parse(content);
} catch (e) {
  // Try to extract JSON from markdown code block
  const jsonMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonMatch) {
    qualification = JSON.parse(jsonMatch[1].trim());
  } else {
    // Try to find JSON object in text
    const objectMatch = content.match(/\{[\s\S]*\}/);
    if (objectMatch) {
      qualification = JSON.parse(objectMatch[0]);
    } else {
      throw new Error('Could not parse qualification response');
    }
  }
}

// Validate and normalize
const score = Math.min(100, Math.max(0, parseInt(qualification.score) || 0));
let status;

if (score >= 60) {
  status = 'qualified';
} else if (score >= 30) {
  status = 'needs_followup';
} else {
  status = 'unqualified';
}

return {
  score: score,
  status: status,
  reasoning: qualification.reasoning || '',
  key_signals: qualification.key_signals || [],
  recommended_action: qualification.recommended_action || 'email_followup',
  missing_info: qualification.missing_info || [],
  model: 'claude-sonnet-5-5',
  raw_response: content
};
```

---

## Node 7: Update Lead with Qualification
**Type**: Supabase
**Name**: `update_lead_qualification`

**Operation**: Update
**Table**: `leads`

**Match**: `id = {{ $input.first().json.lead_id }}`

**Update Fields**:
```javascript
{
  status: {{ $json.status }},
  qualification_score: {{ $json.score }},
  qualification_reasoning: {{ $json.reasoning }},
  qualification_model: {{ $json.model }},
  qualification_timestamp: {{ $now.toISO() }},
  processed_at: {{ $now.toISO() }}
}
```

---

## Node 8: Log Qualification Complete
**Type**: Supabase
**Name**: `log_qualification_complete`

**Operation**: Insert
**Table**: `events`

**Data**:
```javascript
{
  client_id: {{ $input.first().json.client_id }},
  lead_id: {{ $input.first().json.lead_id }},
  event_type: 'qualification_completed',
  event_data: {
    score: {{ $node.parse_qualification_response.json.score }},
    status: {{ $node.parse_qualification_response.json.status }},
    reasoning: {{ $node.parse_qualification_response.json.reasoning }},
    key_signals: {{ $node.parse_qualification_response.json.key_signals }},
    recommended_action: {{ $node.parse_qualification_response.json.recommended_action }}
  },
  workflow_id: '03_ai_qualification',
  workflow_execution_id: {{ $execution.id }}
}
```

---

## Node 9: Check If Needs Follow-Up Generation
**Type**: IF
**Name**: `check_needs_followup`

**Condition**:
```javascript
{{ $node.parse_qualification_response.json.status === 'qualified' ||
   $node.parse_qualification_response.json.status === 'needs_followup' }}
```

**True**: Continue to Node 10
**False**: Branch to Node 11 (Skip to notification)

---

## Node 10: Trigger Follow-Up Generation
**Type**: Execute Workflow
**Name**: `trigger_followup_generation`

**Workflow**: `04_followup_generation`
**Mode**: Wait for completion

**Input Data**:
```javascript
{
  lead_id: {{ $input.first().json.lead_id }},
  client_id: {{ $input.first().json.client_id }},
  client_config: {{ $input.first().json.client_config }},
  qualification: {{ $node.parse_qualification_response.json }}
}
```

---

## Node 11: Trigger Notification
**Type**: Execute Workflow
**Name**: `trigger_notification`

**Workflow**: `05_slack_notification`
**Mode**: Do not wait

**Input Data**:
```javascript
{
  lead_id: {{ $input.first().json.lead_id }},
  client_id: {{ $input.first().json.client_id }},
  client_config: {{ $input.first().json.client_config }},
  qualification: {{ $node.parse_qualification_response.json }},
  lead_data: {{ $node.fetch_lead_data.json[0] }}
}
```

---

## Node 12: Trigger Sheets Export
**Type**: Execute Workflow
**Name**: `trigger_sheets_export`

**Workflow**: `06_sheets_export`
**Mode**: Do not wait

**Input Data**:
```javascript
{
  lead_id: {{ $input.first().json.lead_id }},
  client_id: {{ $input.first().json.client_id }},
  client_config: {{ $input.first().json.client_config }},
  lead_data: {{ $node.fetch_lead_data.json[0] }},
  qualification: {{ $node.parse_qualification_response.json }}
}
```

---

## Node 13: Return Result
**Type**: Set
**Name**: `return_qualification_result`

**Fields**:
```javascript
{
  lead_id: {{ $input.first().json.lead_id }},
  status: {{ $node.parse_qualification_response.json.status }},
  score: {{ $node.parse_qualification_response.json.score }},
  followup_generated: {{ $node.check_needs_followup.json !== undefined }}
}
```

---

## Error Handling

**On Error**: Execute `07_error_handler` workflow with qualification-specific context
