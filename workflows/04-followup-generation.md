# Workflow 4: Follow-Up Message Generation

## Workflow Settings
- **Name**: `04_followup_generation`
- **Trigger**: Execute Workflow Trigger
- **Timeout**: 90 seconds
- **Error Workflow**: `07_error_handler`

---

## Node 1: Execute Workflow Trigger
**Type**: Execute Workflow Trigger
**Name**: `trigger_followup_start`

**Expected Input**:
```javascript
{
  lead_id: UUID,
  client_id: UUID,
  client_config: Object,
  qualification: Object
}
```

---

## Node 2: Fetch Lead Data
**Type**: Supabase
**Name**: `fetch_lead_for_followup`

**Operation**: Select
**Table**: `leads`

**Filters**:
```sql
id = {{ $json.lead_id }}
```

**Return Fields**: `*`

---

## Node 3: Build Follow-Up Prompt
**Type**: Code
**Name**: `build_followup_prompt`

**JavaScript**:
```javascript
const lead = $node.fetch_lead_for_followup.json[0];
const config = $input.first().json.client_config;
const qualification = $input.first().json.qualification;
const settings = config.followup_settings || {};

const systemPrompt = `You are a professional follow-up message writer for a ${config.industry || 'service'} business called "${config.name}".

WRITING GUIDELINES:
- Be professional but warm
- Keep messages concise (under 150 words)
- Reference specific details from the lead's inquiry
- Include a clear call-to-action
- Do not be pushy or salesy
- Match urgency to lead's stated timeline
- Avoid generic phrases like "I hope this email finds you well"

MESSAGE TYPES:
- For qualified leads (score 60+): Enthusiastic, schedule-focused
- For needs_followup leads (score 30-59): Information-gathering, helpful

RESPONSE FORMAT (JSON only):
{
  "subject": "<email subject line>",
  "body": "<message body>",
  "call_to_action": "<primary CTA>",
  "tone": "<professional|friendly|urgent>"
}`;

const userPrompt = `Generate a follow-up message for this lead:

LEAD DETAILS:
- Name: ${lead.full_name || 'Valued Customer'}
- Email: ${lead.email}
- Phone: ${lead.phone || 'Not provided'}
- Service Requested: ${lead.service_requested || 'General inquiry'}
- Message: ${lead.message || 'No specific message'}
- Budget: ${lead.budget_range || 'Not specified'}
- Urgency: ${lead.urgency || 'Not specified'}
- Location: ${[lead.city, lead.state].filter(Boolean).join(', ') || 'Not specified'}

QUALIFICATION:
- Score: ${qualification.score}/100
- Status: ${qualification.status}
- Key signals: ${(qualification.key_signals || []).join(', ')}
- Recommended action: ${qualification.recommended_action}
- Missing info: ${(qualification.missing_info || []).join(', ')}

BUSINESS CONTEXT:
- Company: ${config.name}
- Industry: ${config.industry || 'Service'}

Generate a personalized follow-up message as JSON.`;

return {
  system_prompt: systemPrompt,
  user_prompt: userPrompt,
  lead: lead,
  qualification: qualification
};
```

---

## Node 4: Call Claude API
**Type**: HTTP Request
**Name**: `call_claude_followup`

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

## Node 5: Parse Follow-Up Response
**Type**: Code
**Name**: `parse_followup_response`

**JavaScript**:
```javascript
const response = $json;
const content = response.content?.[0]?.text || '';
const usage = response.usage || {};

let followup;
try {
  followup = JSON.parse(content);
} catch (e) {
  const jsonMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (jsonMatch) {
    followup = JSON.parse(jsonMatch[1].trim());
  } else {
    const objectMatch = content.match(/\{[\s\S]*\}/);
    if (objectMatch) {
      followup = JSON.parse(objectMatch[0]);
    } else {
      throw new Error('Could not parse follow-up response');
    }
  }
}

return {
  subject: followup.subject || 'Following up on your inquiry',
  body: followup.body || '',
  call_to_action: followup.call_to_action || '',
  tone: followup.tone || 'professional',
  model: 'claude-sonnet-5-5',
  tokens_used: (usage.input_tokens || 0) + (usage.output_tokens || 0)
};
```

---

## Node 6: Update Lead with Follow-Up
**Type**: Supabase
**Name**: `update_lead_followup`

**Operation**: Update
**Table**: `leads`

**Match**: `id = {{ $input.first().json.lead_id }}`

**Update Fields**:
```javascript
{
  followup_message: {{ $json.body }},
  followup_generated_at: {{ $now.toISO() }}
}
```

---

## Node 7: Insert Message Record
**Type**: Supabase
**Name**: `insert_message_record`

**Operation**: Insert
**Table**: `messages`

**Data**:
```javascript
{
  client_id: {{ $input.first().json.client_id }},
  lead_id: {{ $input.first().json.lead_id }},
  message_type: 'followup',
  channel: 'email',
  subject: {{ $node.parse_followup_response.json.subject }},
  body: {{ $node.parse_followup_response.json.body }},
  personalization_data: {
    lead_name: {{ $node.fetch_lead_for_followup.json[0].full_name }},
    service: {{ $node.fetch_lead_for_followup.json[0].service_requested }},
    qualification_score: {{ $input.first().json.qualification.score }}
  },
  ai_model: {{ $node.parse_followup_response.json.model }},
  ai_prompt_version: 'v1.0',
  generation_tokens: {{ $node.parse_followup_response.json.tokens_used }},
  status: 'generated'
}
```

**Return Fields**: `id`

---

## Node 8: Log Event
**Type**: Supabase
**Name**: `log_followup_generated`

**Operation**: Insert
**Table**: `events`

**Data**:
```javascript
{
  client_id: {{ $input.first().json.client_id }},
  lead_id: {{ $input.first().json.lead_id }},
  event_type: 'followup_generated',
  event_data: {
    message_id: {{ $node.insert_message_record.json.id }},
    subject: {{ $node.parse_followup_response.json.subject }},
    tone: {{ $node.parse_followup_response.json.tone }},
    tokens_used: {{ $node.parse_followup_response.json.tokens_used }}
  },
  workflow_id: '04_followup_generation',
  workflow_execution_id: {{ $execution.id }}
}
```

---

## Node 9: Return Result
**Type**: Set
**Name**: `return_followup_result`

**Fields**:
```javascript
{
  lead_id: {{ $input.first().json.lead_id }},
  message_id: {{ $node.insert_message_record.json.id }},
  subject: {{ $node.parse_followup_response.json.subject }},
  generated: true
}
```

---

## Error Handling

**On Error**: Execute `07_error_handler` workflow
