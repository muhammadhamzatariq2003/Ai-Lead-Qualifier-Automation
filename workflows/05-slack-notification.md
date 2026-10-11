# Workflow 5: Slack Notification

## Workflow Settings
- **Name**: `05_slack_notification`
- **Trigger**: Execute Workflow Trigger
- **Timeout**: 30 seconds
- **Error Workflow**: `07_error_handler`

---

## Node 1: Execute Workflow Trigger
**Type**: Execute Workflow Trigger
**Name**: `trigger_notification_start`

**Expected Input**:
```javascript
{
  lead_id: UUID,
  client_id: UUID,
  client_config: Object,
  qualification: Object,
  lead_data: Object
}
```

---

## Node 2: Check Slack Configured
**Type**: IF
**Name**: `check_slack_configured`

**Condition**:
```javascript
{{ $json.client_config.slack_webhook_url !== null &&
   $json.client_config.slack_webhook_url !== '' }}
```

**True**: Continue to Node 3
**False**: Return (skip notification)

---

## Node 3: Build Slack Message
**Type**: Code
**Name**: `build_slack_message`

**JavaScript**:
```javascript
const lead = $json.lead_data;
const qual = $json.qualification;
const config = $json.client_config;

// Determine emoji and color based on status
let emoji, color;
switch (qual.status) {
  case 'qualified':
    emoji = ':fire:';
    color = '#36a64f'; // green
    break;
  case 'needs_followup':
    emoji = ':eyes:';
    color = '#f2c744'; // yellow
    break;
  case 'unqualified':
    emoji = ':x:';
    color = '#dc3545'; // red
    break;
  default:
    emoji = ':inbox_tray:';
    color = '#6c757d'; // gray
}

// Build score bar
const scoreBar = '█'.repeat(Math.floor(qual.score / 10)) +
                 '░'.repeat(10 - Math.floor(qual.score / 10));

const message = {
  blocks: [
    {
      type: 'header',
      text: {
        type: 'plain_text',
        text: `${emoji} New Lead: ${qual.status.toUpperCase()}`,
        emoji: true
      }
    },
    {
      type: 'section',
      fields: [
        {
          type: 'mrkdwn',
          text: `*Name:*\n${lead.full_name || 'Not provided'}`
        },
        {
          type: 'mrkdwn',
          text: `*Score:*\n${scoreBar} ${qual.score}/100`
        },
        {
          type: 'mrkdwn',
          text: `*Email:*\n${lead.email || 'Not provided'}`
        },
        {
          type: 'mrkdwn',
          text: `*Phone:*\n${lead.phone || 'Not provided'}`
        },
        {
          type: 'mrkdwn',
          text: `*Service:*\n${lead.service_requested || 'Not specified'}`
        },
        {
          type: 'mrkdwn',
          text: `*Source:*\n${lead.source}`
        }
      ]
    }
  ],
  attachments: [
    {
      color: color,
      blocks: [
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `*AI Assessment:*\n${qual.reasoning}`
          }
        },
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `*Key Signals:* ${(qual.key_signals || []).join(', ') || 'None identified'}`
          }
        },
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `*Recommended Action:* ${qual.recommended_action || 'Review manually'}`
          }
        }
      ]
    }
  ]
};

// Add message if present
if (lead.message) {
  message.attachments[0].blocks.push({
    type: 'section',
    text: {
      type: 'mrkdwn',
      text: `*Lead Message:*\n>${lead.message.substring(0, 500)}${lead.message.length > 500 ? '...' : ''}`
    }
  });
}

// Add urgency if present
if (lead.urgency) {
  message.blocks[1].fields.push({
    type: 'mrkdwn',
    text: `*Urgency:*\n${lead.urgency}`
  });
}

// Add location if present
const location = [lead.city, lead.state].filter(Boolean).join(', ');
if (location) {
  message.blocks[1].fields.push({
    type: 'mrkdwn',
    text: `*Location:*\n${location}`
  });
}

return {
  webhook_url: config.slack_webhook_url,
  message: message
};
```

---

## Node 4: Send Slack Webhook
**Type**: HTTP Request
**Name**: `send_slack_notification`

**Method**: POST
**URL**: `{{ $json.webhook_url }}`

**Headers**:
```
content-type: application/json
```

**Body**: `{{ JSON.stringify($json.message) }}`

**Timeout**: 10000

---

## Node 5: Log Notification Sent
**Type**: Supabase
**Name**: `log_notification_sent`

**Operation**: Insert
**Table**: `events`

**Data**:
```javascript
{
  client_id: {{ $input.first().json.client_id }},
  lead_id: {{ $input.first().json.lead_id }},
  event_type: 'notification_sent',
  event_data: {
    channel: 'slack',
    status: {{ $json.statusCode || 200 }}
  },
  workflow_id: '05_slack_notification',
  workflow_execution_id: {{ $execution.id }}
}
```

---

## Node 6: Return Result
**Type**: Set
**Name**: `return_notification_result`

**Fields**:
```javascript
{
  lead_id: {{ $input.first().json.lead_id }},
  notification_sent: true,
  channel: 'slack'
}
```

---

## Error Handling

**On Error**: Log error but do not fail entire workflow (non-critical)
