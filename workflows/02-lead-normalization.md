# Workflow 2: Lead Normalization + Deduplication

## Workflow Settings
- **Name**: `02_lead_normalization`
- **Trigger**: Execute Workflow Trigger
- **Timeout**: 60 seconds
- **Error Workflow**: `07_error_handler`

---

## Node 1: Execute Workflow Trigger
**Type**: Execute Workflow Trigger
**Name**: `trigger_normalization_start`

**Expected Input**:
```javascript
{
  client_id: UUID,
  client_config: Object,
  source_type: String,
  raw_data: Object,
  metadata: Object
}
```

---

## Node 2: Detect Source Format
**Type**: Switch
**Name**: `detect_source_format`

**Routing Property**: `{{ $json.source_type }}`

**Cases**:
- `website_form` → Node 3a
- `google_ads` → Node 3b
- `facebook_ads` → Node 3c
- `csv_upload` → Node 3d
- `api_ingestion` → Node 3e
- `phone_sms` → Node 3f
- Default → Node 3a

---

## Node 3a: Normalize Website Form
**Type**: Code
**Name**: `normalize_website_form`

**JavaScript**:
```javascript
const raw = $json.raw_data;

return {
  email: raw.email || raw.Email || raw.EMAIL || null,
  phone: raw.phone || raw.Phone || raw.telephone || raw.mobile || null,
  first_name: raw.first_name || raw.firstName || raw.fname || null,
  last_name: raw.last_name || raw.lastName || raw.lname || null,
  full_name: raw.name || raw.full_name || raw.fullName ||
             `${raw.first_name || ''} ${raw.last_name || ''}`.trim() || null,
  company: raw.company || raw.business || raw.organization || null,
  address_line1: raw.address || raw.street || raw.address_line1 || null,
  city: raw.city || null,
  state: raw.state || raw.province || null,
  postal_code: raw.zip || raw.postal_code || raw.zipcode || null,
  country: raw.country || 'US',
  service_requested: raw.service || raw.service_type || raw.interest || null,
  message: raw.message || raw.comments || raw.notes || null,
  budget_range: raw.budget || raw.budget_range || null,
  urgency: raw.urgency || raw.timeline || raw.timeframe || null,
  preferred_contact_method: raw.preferred_contact || raw.contact_preference || null,
  preferred_contact_time: raw.best_time || raw.contact_time || null,
  utm_source: raw.utm_source || null,
  utm_medium: raw.utm_medium || null,
  utm_campaign: raw.utm_campaign || null,
  utm_term: raw.utm_term || null,
  utm_content: raw.utm_content || null,
  page_url: raw.page_url || raw.landing_page || null,
  referrer_url: raw.referrer || raw.referrer_url || null
};
```

---

## Node 3b: Normalize Google Ads
**Type**: Code
**Name**: `normalize_google_ads`

**JavaScript**:
```javascript
const raw = $json.raw_data;

// Google Ads lead form extension format
return {
  email: raw.user_column_data?.find(c => c.column_id === 'EMAIL')?.string_value ||
         raw.email || null,
  phone: raw.user_column_data?.find(c => c.column_id === 'PHONE_NUMBER')?.string_value ||
         raw.phone || null,
  first_name: raw.user_column_data?.find(c => c.column_id === 'FIRST_NAME')?.string_value ||
              raw.first_name || null,
  last_name: raw.user_column_data?.find(c => c.column_id === 'LAST_NAME')?.string_value ||
             raw.last_name || null,
  full_name: raw.user_column_data?.find(c => c.column_id === 'FULL_NAME')?.string_value ||
             null,
  company: raw.user_column_data?.find(c => c.column_id === 'COMPANY_NAME')?.string_value ||
           null,
  city: raw.user_column_data?.find(c => c.column_id === 'CITY')?.string_value || null,
  state: raw.user_column_data?.find(c => c.column_id === 'STATE')?.string_value || null,
  postal_code: raw.user_column_data?.find(c => c.column_id === 'POSTAL_CODE')?.string_value ||
               null,
  country: raw.user_column_data?.find(c => c.column_id === 'COUNTRY')?.string_value || 'US',
  service_requested: raw.campaign_name || null,
  source_campaign: raw.campaign_id || null,
  source_id: raw.lead_id || raw.google_lead_id || null,
  utm_source: 'google',
  utm_medium: 'cpc',
  utm_campaign: raw.campaign_name || null
};
```

---

## Node 3c: Normalize Facebook Ads
**Type**: Code
**Name**: `normalize_facebook_ads`

**JavaScript**:
```javascript
const raw = $json.raw_data;

// Facebook/Meta lead form format
const fieldData = raw.field_data || [];
const getField = (name) => fieldData.find(f => f.name === name)?.values?.[0] || null;

return {
  email: getField('email') || raw.email || null,
  phone: getField('phone_number') || raw.phone || null,
  first_name: getField('first_name') || null,
  last_name: getField('last_name') || null,
  full_name: getField('full_name') || null,
  company: getField('company_name') || null,
  city: getField('city') || null,
  state: getField('state') || null,
  postal_code: getField('zip_code') || getField('post_code') || null,
  country: getField('country') || 'US',
  service_requested: raw.ad_name || raw.adset_name || null,
  source_campaign: raw.campaign_id || null,
  source_id: raw.leadgen_id || raw.id || null,
  utm_source: 'facebook',
  utm_medium: 'paid_social',
  utm_campaign: raw.campaign_name || null
};
```

---

## Node 3d: Normalize CSV Upload
**Type**: Code
**Name**: `normalize_csv_upload`

**JavaScript**:
```javascript
const raw = $json.raw_data;

// Flexible CSV column mapping
const normalizeKey = (key) => key.toLowerCase().replace(/[^a-z0-9]/g, '_');
const normalized = {};
Object.keys(raw).forEach(key => {
  normalized[normalizeKey(key)] = raw[key];
});

return {
  email: normalized.email || normalized.email_address || normalized.e_mail || null,
  phone: normalized.phone || normalized.phone_number || normalized.telephone ||
         normalized.mobile || null,
  first_name: normalized.first_name || normalized.firstname || normalized.first || null,
  last_name: normalized.last_name || normalized.lastname || normalized.last || null,
  full_name: normalized.full_name || normalized.name || normalized.fullname || null,
  company: normalized.company || normalized.company_name || normalized.business || null,
  address_line1: normalized.address || normalized.street_address || normalized.address_1 || null,
  city: normalized.city || null,
  state: normalized.state || normalized.province || normalized.region || null,
  postal_code: normalized.zip || normalized.postal_code || normalized.zip_code || null,
  country: normalized.country || 'US',
  service_requested: normalized.service || normalized.service_type || normalized.interest || null,
  message: normalized.notes || normalized.comments || normalized.message || null,
  budget_range: normalized.budget || null,
  urgency: normalized.urgency || normalized.timeline || null,
  source_id: normalized.row_id || normalized.id || null
};
```

---

## Node 3e: Normalize API Ingestion
**Type**: Code
**Name**: `normalize_api_ingestion`

**JavaScript**:
```javascript
const raw = $json.raw_data;

// Direct API format (expects structured data)
return {
  email: raw.email || null,
  phone: raw.phone || null,
  first_name: raw.first_name || null,
  last_name: raw.last_name || null,
  full_name: raw.full_name || raw.name || null,
  company: raw.company || null,
  address_line1: raw.address_line1 || raw.address || null,
  address_line2: raw.address_line2 || null,
  city: raw.city || null,
  state: raw.state || null,
  postal_code: raw.postal_code || raw.zip || null,
  country: raw.country || 'US',
  service_requested: raw.service_requested || raw.service || null,
  message: raw.message || null,
  budget_range: raw.budget_range || null,
  urgency: raw.urgency || null,
  preferred_contact_method: raw.preferred_contact_method || null,
  preferred_contact_time: raw.preferred_contact_time || null,
  utm_source: raw.utm_source || null,
  utm_medium: raw.utm_medium || null,
  utm_campaign: raw.utm_campaign || null,
  utm_term: raw.utm_term || null,
  utm_content: raw.utm_content || null,
  source_id: raw.external_id || raw.source_id || null,
  source_campaign: raw.campaign_id || null,
  custom_fields: raw.custom_fields || {}
};
```

---

## Node 3f: Normalize Phone/SMS
**Type**: Code
**Name**: `normalize_phone_sms`

**JavaScript**:
```javascript
const raw = $json.raw_data;

return {
  email: null,
  phone: raw.from_number || raw.phone || raw.caller_id || null,
  first_name: null,
  last_name: null,
  full_name: raw.caller_name || null,
  message: raw.message_body || raw.transcription || raw.sms_body || null,
  service_requested: raw.intent || raw.category || null,
  source_id: raw.call_sid || raw.message_sid || raw.conversation_id || null,
  custom_fields: {
    call_duration: raw.call_duration || null,
    call_status: raw.call_status || null,
    recording_url: raw.recording_url || null
  }
};
```

---

## Node 4: Merge Normalized Data
**Type**: Merge
**Name**: `merge_normalized_branches`

**Mode**: Merge by Position

---

## Node 5: Build Full Name
**Type**: Code
**Name**: `build_full_name`

**JavaScript**:
```javascript
let fullName = $json.full_name;

if (!fullName && ($json.first_name || $json.last_name)) {
  fullName = `${$json.first_name || ''} ${$json.last_name || ''}`.trim();
}

// Extract first/last from full name if not present
let firstName = $json.first_name;
let lastName = $json.last_name;

if (fullName && !firstName && !lastName) {
  const parts = fullName.split(' ');
  firstName = parts[0] || null;
  lastName = parts.slice(1).join(' ') || null;
}

return {
  ...$json,
  full_name: fullName,
  first_name: firstName,
  last_name: lastName
};
```

---

## Node 6: Normalize Email
**Type**: Code
**Name**: `normalize_email`

**JavaScript**:
```javascript
let email = $json.email;
let emailNormalized = null;

if (email) {
  email = email.trim();
  emailNormalized = email.toLowerCase();
}

return {
  ...$json,
  email: email,
  email_normalized: emailNormalized
};
```

---

## Node 7: Normalize Phone
**Type**: Code
**Name**: `normalize_phone`

**JavaScript**:
```javascript
let phone = $json.phone;
let phoneNormalized = null;

if (phone) {
  const digits = phone.replace(/\D/g, '');

  if (digits.length === 10) {
    phoneNormalized = '+1' + digits;
  } else if (digits.length === 11 && digits[0] === '1') {
    phoneNormalized = '+' + digits;
  } else if (digits.length > 10) {
    phoneNormalized = '+' + digits;
  } else {
    phoneNormalized = digits;
  }
}

return {
  ...$json,
  phone: phone,
  phone_normalized: phoneNormalized
};
```

---

## Node 8: Generate Fingerprint
**Type**: Code
**Name**: `generate_fingerprint`

**JavaScript**:
```javascript
const crypto = require('crypto');

const fingerprintInput = [
  $json.email_normalized || '',
  $json.phone_normalized || '',
  ($json.full_name || '').toLowerCase().trim()
].join('|');

const fingerprint = crypto.createHash('sha256')
  .update(fingerprintInput)
  .digest('hex');

return {
  ...$json,
  fingerprint: fingerprint
};
```

---

## Node 9: Check for Duplicates
**Type**: Supabase
**Name**: `check_duplicates`

**Operation**: Select
**Table**: `leads`

**Filters**:
```sql
client_id = {{ $input.first().json.client_id }}
AND fingerprint = {{ $json.fingerprint }}
AND is_duplicate = false
AND created_at > NOW() - INTERVAL '90 days'
```

**Order By**: `created_at DESC`
**Limit**: 1

**Return Fields**: `id, email, phone, status, created_at`

---

## Node 10: Evaluate Duplicate Status
**Type**: IF
**Name**: `is_duplicate`

**Condition**:
```javascript
{{ $json.length > 0 }}
```

**True**: Continue to Node 10a (Mark Duplicate)
**False**: Continue to Node 11 (Insert New)

---

## Node 10a: Mark as Duplicate
**Type**: Set
**Name**: `mark_duplicate`

**Fields**:
```javascript
{
  is_duplicate: true,
  duplicate_of_id: {{ $node.check_duplicates.json[0].id }},
  status: 'duplicate'
}
```

---

## Node 11: Insert Lead
**Type**: Supabase
**Name**: `insert_lead`

**Operation**: Insert
**Table**: `leads`

**Data**:
```javascript
{
  client_id: {{ $input.first().json.client_id }},
  source: {{ $input.first().json.source_type }},
  source_id: {{ $json.source_id || null }},
  source_campaign: {{ $json.source_campaign || null }},
  source_raw_data: {{ $input.first().json.raw_data }},

  email: {{ $json.email }},
  email_normalized: {{ $json.email_normalized }},
  phone: {{ $json.phone }},
  phone_normalized: {{ $json.phone_normalized }},
  first_name: {{ $json.first_name }},
  last_name: {{ $json.last_name }},
  full_name: {{ $json.full_name }},
  company: {{ $json.company }},

  address_line1: {{ $json.address_line1 }},
  address_line2: {{ $json.address_line2 }},
  city: {{ $json.city }},
  state: {{ $json.state }},
  postal_code: {{ $json.postal_code }},
  country: {{ $json.country }},

  service_requested: {{ $json.service_requested }},
  message: {{ $json.message }},
  budget_range: {{ $json.budget_range }},
  urgency: {{ $json.urgency }},
  preferred_contact_method: {{ $json.preferred_contact_method }},
  preferred_contact_time: {{ $json.preferred_contact_time }},

  status: {{ $json.is_duplicate ? 'duplicate' : 'new' }},
  is_duplicate: {{ $json.is_duplicate || false }},
  duplicate_of_id: {{ $json.duplicate_of_id || null }},
  fingerprint: {{ $json.fingerprint }},

  ip_address: {{ $input.first().json.metadata.source_ip }},
  user_agent: {{ $input.first().json.metadata.user_agent }},
  page_url: {{ $json.page_url }},
  referrer_url: {{ $json.referrer_url }},
  utm_source: {{ $json.utm_source }},
  utm_medium: {{ $json.utm_medium }},
  utm_campaign: {{ $json.utm_campaign }},
  utm_term: {{ $json.utm_term }},
  utm_content: {{ $json.utm_content }},

  custom_fields: {{ $json.custom_fields || {} }},
  submitted_at: {{ $input.first().json.metadata.received_at }}
}
```

**Return Fields**: `id, client_id, status, is_duplicate`

---

## Node 12: Log Event
**Type**: Supabase
**Name**: `log_lead_created_event`

**Operation**: Insert
**Table**: `events`

**Data**:
```javascript
{
  client_id: {{ $json.client_id }},
  lead_id: {{ $json.id }},
  event_type: {{ $json.is_duplicate ? 'lead_deduplicated' : 'lead_created' }},
  event_data: {
    source: {{ $input.first().json.source_type }},
    fingerprint: {{ $node.generate_fingerprint.json.fingerprint }},
    is_duplicate: {{ $json.is_duplicate }}
  },
  workflow_id: '02_lead_normalization',
  workflow_execution_id: {{ $execution.id }}
}
```

---

## Node 13: Check If Should Qualify
**Type**: IF
**Name**: `should_continue_to_qualification`

**Condition**:
```javascript
{{ $json.is_duplicate === false }}
```

**True**: Continue to Node 14
**False**: Return (duplicate, no further processing)

---

## Node 14: Trigger Qualification Workflow
**Type**: Execute Workflow
**Name**: `trigger_qualification`

**Workflow**: `03_ai_qualification`
**Mode**: Wait for completion

**Input Data**:
```javascript
{
  lead_id: {{ $node.insert_lead.json.id }},
  client_id: {{ $node.insert_lead.json.client_id }},
  client_config: {{ $input.first().json.client_config }}
}
```

---

## Node 15: Return Result
**Type**: Set
**Name**: `return_normalization_result`

**Fields**:
```javascript
{
  lead_id: {{ $node.insert_lead.json.id }},
  status: {{ $node.insert_lead.json.status }},
  is_duplicate: {{ $node.insert_lead.json.is_duplicate }},
  qualification_triggered: {{ $node.should_continue_to_qualification.json !== undefined }}
}
```

---

## Error Handling

**On Error**: Execute `07_error_handler` workflow
