# Workflow 1: Lead Intake + Authentication

## Workflow Settings
- **Name**: `01_lead_intake`
- **Trigger**: Webhook
- **Timeout**: 30 seconds
- **Error Workflow**: `07_error_handler`

---

## Node 1: Webhook Trigger
**Type**: Webhook
**Name**: `webhook_lead_intake`

**Configuration**:
- HTTP Method: POST
- Path: `lead-intake`
- Authentication: Header Auth
- Header Name: `X-API-Key`
- Response Mode: Last Node
- Response Code: 200

**Output Fields**:
```
headers.x-api-key
headers.x-source-type
body.*
query.client_slug
```

---

## Node 2: Set Metadata
**Type**: Set
**Name**: `set_intake_metadata`

**Fields**:
```javascript
{
  received_at: {{ $now.toISO() }},
  source_ip: {{ $json.headers['x-forwarded-for'] || $json.headers['x-real-ip'] || 'unknown' }},
  user_agent: {{ $json.headers['user-agent'] || '' }},
  raw_payload: {{ JSON.stringify($json.body) }},
  source_type: {{ $json.headers['x-source-type'] || 'website_form' }},
  client_slug: {{ $json.query.client_slug || $json.body.client_slug || 'demo' }}
}
```

---

## Node 3: Validate API Key
**Type**: Supabase
**Name**: `validate_api_key`

**Operation**: Select
**Table**: `api_keys`

**Filters**:
```sql
key_hash = sha256($json.headers['x-api-key'])
AND is_active = true
AND (expires_at IS NULL OR expires_at > NOW())
```

**Return Fields**: `id, client_id, scopes, rate_limit`

---

## Node 4: Check Auth Result
**Type**: IF
**Name**: `check_auth_valid`

**Condition**:
```javascript
{{ $json.length > 0 }}
```

**True**: Continue to Node 5
**False**: Branch to Node 4a (Reject)

---

## Node 4a: Reject Unauthorized
**Type**: Respond to Webhook
**Name**: `reject_unauthorized`

**Response Code**: 401
**Response Body**:
```json
{
  "success": false,
  "error": "unauthorized",
  "message": "Invalid or expired API key"
}
```

---

## Node 5: Get Client Config
**Type**: Supabase
**Name**: `get_client_config`

**Operation**: Select
**Table**: `clients`

**Filters**:
```sql
id = {{ $node.validate_api_key.json.client_id }}
AND is_active = true
```

**Return Fields**: `id, name, slug, industry, qualification_criteria, followup_settings, slack_webhook_url, google_sheet_id, timezone`

---

## Node 6: Check Client Active
**Type**: IF
**Name**: `check_client_active`

**Condition**:
```javascript
{{ $json.length > 0 }}
```

**True**: Continue to Node 7
**False**: Branch to Node 6a (Reject Inactive)

---

## Node 6a: Reject Inactive Client
**Type**: Respond to Webhook
**Name**: `reject_inactive_client`

**Response Code**: 403
**Response Body**:
```json
{
  "success": false,
  "error": "client_inactive",
  "message": "Client account is not active"
}
```

---

## Node 7: Validate Required Fields
**Type**: Code
**Name**: `validate_required_fields`

**JavaScript**:
```javascript
const body = $node.webhook_lead_intake.json.body;
const errors = [];

// Must have at least email or phone
if (!body.email && !body.phone) {
  errors.push('Either email or phone is required');
}

// Email format validation
if (body.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(body.email)) {
  errors.push('Invalid email format');
}

// Phone format validation (if provided)
if (body.phone) {
  const digits = body.phone.replace(/\D/g, '');
  if (digits.length < 10 || digits.length > 15) {
    errors.push('Invalid phone number');
  }
}

return {
  is_valid: errors.length === 0,
  errors: errors,
  validated_data: body
};
```

---

## Node 8: Check Validation Result
**Type**: IF
**Name**: `check_validation_passed`

**Condition**:
```javascript
{{ $json.is_valid === true }}
```

**True**: Continue to Node 9
**False**: Branch to Node 8a (Reject Invalid)

---

## Node 8a: Reject Invalid Data
**Type**: Respond to Webhook
**Name**: `reject_invalid_data`

**Response Code**: 400
**Response Body**:
```json
{
  "success": false,
  "error": "validation_failed",
  "message": "Lead data validation failed",
  "details": {{ $json.errors }}
}
```

---

## Node 9: Update API Key Usage
**Type**: Supabase
**Name**: `update_api_key_usage`

**Operation**: Update
**Table**: `api_keys`

**Match**: `id = {{ $node.validate_api_key.json[0].id }}`

**Update Fields**:
```json
{
  "last_used_at": "{{ $now.toISO() }}"
}
```

---

## Node 10: Prepare Lead Payload
**Type**: Set
**Name**: `prepare_lead_payload`

**Fields**:
```javascript
{
  client_id: {{ $node.get_client_config.json[0].id }},
  client_config: {{ $node.get_client_config.json[0] }},
  source_type: {{ $node.set_intake_metadata.json.source_type }},
  raw_data: {{ $node.webhook_lead_intake.json.body }},
  metadata: {
    received_at: {{ $node.set_intake_metadata.json.received_at }},
    source_ip: {{ $node.set_intake_metadata.json.source_ip }},
    user_agent: {{ $node.set_intake_metadata.json.user_agent }}
  }
}
```

---

## Node 11: Execute Normalization Workflow
**Type**: Execute Workflow
**Name**: `trigger_normalization`

**Workflow**: `02_lead_normalization`
**Mode**: Wait for completion

**Input Data**: Output from Node 10

---

## Node 12: Return Success Response
**Type**: Respond to Webhook
**Name**: `return_success`

**Response Code**: 202
**Response Body**:
```json
{
  "success": true,
  "message": "Lead received and queued for processing",
  "lead_id": {{ $json.lead_id }},
  "status": "processing"
}
```

---

## Error Handling

**On Error**: Execute `07_error_handler` workflow with:
```javascript
{
  workflow_id: "01_lead_intake",
  workflow_execution_id: {{ $execution.id }},
  node_name: {{ $node.name }},
  error_message: {{ $error.message }},
  error_stack: {{ $error.stack }},
  input_data: {{ $node.webhook_lead_intake.json }}
}
```
