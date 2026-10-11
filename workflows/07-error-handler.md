# Workflow 7: Error Handler (Global)

## Workflow Settings
- **Name**: `07_error_handler`
- **Trigger**: Error Trigger
- **Timeout**: 30 seconds
- **Error Workflow**: None (terminal)

---

## Node 1: Error Trigger
**Type**: Error Trigger
**Name**: `catch_workflow_error`

**Scope**: All workflows in instance

**Output Fields**:
```javascript
{
  execution: Object,
  workflow: Object,
  error: {
    message: String,
    stack: String,
    name: String
  }
}
```

---

## Node 2: Extract Error Context
**Type**: Code
**Name**: `extract_error_context`

**JavaScript**:
```javascript
const execution = $json.execution || {};
const workflow = $json.workflow || {};
const error = $json.error || {};

// Try to extract client_id and lead_id from execution data
let clientId = null;
let leadId = null;
let nodeData = {};

try {
  const executionData = execution.data || {};
  const resultData = executionData.resultData || {};
  const runData = resultData.runData || {};

  // Look through nodes for client/lead IDs
  Object.keys(runData).forEach(nodeName => {
    const nodeOutput = runData[nodeName]?.[0]?.data?.main?.[0]?.[0]?.json;
    if (nodeOutput) {
      if (nodeOutput.client_id) clientId = nodeOutput.client_id;
      if (nodeOutput.lead_id) leadId = nodeOutput.lead_id;
    }
  });

  // Get the last node's data
  const lastNode = resultData.lastNodeExecuted;
  if (lastNode && runData[lastNode]) {
    nodeData = runData[lastNode]?.[0]?.data?.main?.[0]?.[0]?.json || {};
  }
} catch (e) {
  // Extraction failed, continue with nulls
}

// Determine error severity
let level = 'error';
if (error.message?.includes('timeout')) level = 'warning';
if (error.message?.includes('rate limit')) level = 'warning';
if (error.message?.includes('unauthorized')) level = 'critical';
if (error.message?.includes('database')) level = 'critical';

return {
  workflow_id: workflow.id || 'unknown',
  workflow_name: workflow.name || 'unknown',
  workflow_execution_id: execution.id || 'unknown',
  node_name: execution.lastNodeExecuted || 'unknown',

  client_id: clientId,
  lead_id: leadId,

  error_code: error.name || 'UNKNOWN_ERROR',
  error_message: error.message || 'Unknown error occurred',
  error_stack: error.stack || '',

  level: level,
  node_data: nodeData,

  timestamp: new Date().toISOString()
};
```

---

## Node 3: Insert Error Log
**Type**: Supabase
**Name**: `insert_error_log`

**Operation**: Insert
**Table**: `error_logs`

**Data**:
```javascript
{
  client_id: {{ $json.client_id }},
  lead_id: {{ $json.lead_id }},
  level: {{ $json.level }},
  error_code: {{ $json.error_code }},
  error_message: {{ $json.error_message }},
  error_stack: {{ $json.error_stack }},
  workflow_id: {{ $json.workflow_id }},
  workflow_execution_id: {{ $json.workflow_execution_id }},
  node_name: {{ $json.node_name }},
  request_data: {{ $json.node_data }}
}
```

**Return Fields**: `id`

---

## Node 4: Insert Error Event
**Type**: Supabase
**Name**: `insert_error_event`

**Operation**: Insert
**Table**: `events`

**Data**:
```javascript
{
  client_id: {{ $node.extract_error_context.json.client_id }},
  lead_id: {{ $node.extract_error_context.json.lead_id }},
  event_type: 'error_occurred',
  event_data: {
    error_log_id: {{ $node.insert_error_log.json.id }},
    error_code: {{ $node.extract_error_context.json.error_code }},
    error_message: {{ $node.extract_error_context.json.error_message }},
    workflow_id: {{ $node.extract_error_context.json.workflow_id }},
    node_name: {{ $node.extract_error_context.json.node_name }},
    level: {{ $node.extract_error_context.json.level }}
  },
  workflow_id: '07_error_handler',
  workflow_execution_id: {{ $execution.id }}
}
```

---

## Node 5: Check If Critical
**Type**: IF
**Name**: `check_if_critical`

**Condition**:
```javascript
{{ $node.extract_error_context.json.level === 'critical' ||
   $node.extract_error_context.json.level === 'error' }}
```

**True**: Continue to Node 6
**False**: Return (warning, no alert needed)

---

## Node 6: Get System Slack Webhook
**Type**: Set
**Name**: `get_system_slack_webhook`

**Fields**:
```javascript
{
  webhook_url: {{ $env.SYSTEM_SLACK_WEBHOOK_URL }}
}
```

---

## Node 7: Check Slack Configured
**Type**: IF
**Name**: `check_system_slack_configured`

**Condition**:
```javascript
{{ $json.webhook_url !== undefined && $json.webhook_url !== '' }}
```

**True**: Continue to Node 8
**False**: Return

---

## Node 8: Build Error Alert
**Type**: Code
**Name**: `build_error_alert`

**JavaScript**:
```javascript
const ctx = $node.extract_error_context.json;

const emoji = ctx.level === 'critical' ? ':rotating_light:' : ':warning:';
const color = ctx.level === 'critical' ? '#dc3545' : '#f2c744';

return {
  webhook_url: $node.get_system_slack_webhook.json.webhook_url,
  message: {
    blocks: [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: `${emoji} Workflow Error: ${ctx.level.toUpperCase()}`,
          emoji: true
        }
      },
      {
        type: 'section',
        fields: [
          {
            type: 'mrkdwn',
            text: `*Workflow:*\n${ctx.workflow_name}`
          },
          {
            type: 'mrkdwn',
            text: `*Node:*\n${ctx.node_name}`
          },
          {
            type: 'mrkdwn',
            text: `*Execution ID:*\n${ctx.workflow_execution_id}`
          },
          {
            type: 'mrkdwn',
            text: `*Time:*\n${ctx.timestamp}`
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
              text: `*Error:* \`${ctx.error_code}\`\n${ctx.error_message}`
            }
          }
        ]
      }
    ]
  }
};
```

---

## Node 9: Send Error Alert
**Type**: HTTP Request
**Name**: `send_error_alert`

**Method**: POST
**URL**: `{{ $json.webhook_url }}`

**Headers**:
```
content-type: application/json
```

**Body**: `{{ JSON.stringify($json.message) }}`

**Options**:
- Continue on fail: true (don't cause recursive error)

---

## Node 10: Return
**Type**: NoOp
**Name**: `error_handler_complete`

---

## Error Handling

This workflow must never fail. All nodes have:
- `continueOnFail: true`
- Fallback values for null data
