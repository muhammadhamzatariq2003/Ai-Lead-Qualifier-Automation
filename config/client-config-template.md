# Client Configuration Template

## Client Information

```sql
INSERT INTO clients (
    name,
    slug,
    industry,
    timezone,
    qualification_criteria,
    followup_settings,
    slack_webhook_url,
    google_sheet_id
) VALUES (
    '{{CLIENT_NAME}}',
    '{{CLIENT_SLUG}}',
    '{{INDUSTRY}}',
    '{{TIMEZONE}}',
    '{{QUALIFICATION_CRITERIA_JSON}}',
    '{{FOLLOWUP_SETTINGS_JSON}}',
    '{{SLACK_WEBHOOK_URL}}',
    '{{GOOGLE_SHEET_ID}}'
);
```

---

## Configuration Fields

### Basic Information

| Field | Description | Example |
|-------|-------------|---------|
| `name` | Client display name | "ABC Plumbing & Heating" |
| `slug` | URL-safe identifier (lowercase, no spaces) | "abc-plumbing" |
| `industry` | Business category | "Home Services" |
| `timezone` | IANA timezone | "America/New_York" |

---

### Qualification Criteria

```json
{
  "min_score_qualified": 60,
  "min_score_followup": 30,
  "required_fields": ["email", "service_requested"],
  "high_value_services": [
    "hvac_installation",
    "water_heater_replacement",
    "sewer_line_repair",
    "bathroom_remodel"
  ],
  "urgency_boost": {
    "emergency": 25,
    "today": 20,
    "this_week": 15,
    "this_month": 10,
    "just_looking": 0
  },
  "location_filter": {
    "enabled": false,
    "allowed_states": [],
    "allowed_zip_prefixes": []
  },
  "spam_keywords": [
    "test",
    "asdf",
    "sample"
  ]
}
```

#### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `min_score_qualified` | Integer | Minimum score for "qualified" status |
| `min_score_followup` | Integer | Minimum score for "needs_followup" status |
| `required_fields` | Array | Fields that must be present for qualification |
| `high_value_services` | Array | Service types that boost score |
| `urgency_boost` | Object | Score bonus for urgency levels |
| `location_filter` | Object | Geographic targeting rules |
| `spam_keywords` | Array | Keywords that auto-disqualify |

---

### Follow-Up Settings

```json
{
  "enabled": true,
  "channels": ["email"],
  "delay_minutes": 5,
  "max_followups": 3,
  "followup_intervals_hours": [24, 72, 168],
  "quiet_hours": {
    "enabled": true,
    "start": "21:00",
    "end": "08:00"
  },
  "templates": {
    "qualified": "enthusiastic",
    "needs_followup": "informative"
  }
}
```

#### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `enabled` | Boolean | Enable/disable auto follow-up |
| `channels` | Array | Follow-up channels (email, sms) |
| `delay_minutes` | Integer | Wait time before first follow-up |
| `max_followups` | Integer | Maximum follow-up attempts |
| `followup_intervals_hours` | Array | Hours between follow-ups |
| `quiet_hours` | Object | No messages during these hours |
| `templates` | Object | Template style per status |

---

## Industry Templates

### Home Services (HVAC, Plumbing, Electrical)

```json
{
  "qualification_criteria": {
    "min_score_qualified": 55,
    "min_score_followup": 25,
    "required_fields": ["email", "phone", "service_requested"],
    "high_value_services": [
      "hvac_installation",
      "hvac_replacement",
      "water_heater",
      "electrical_panel",
      "sewer_line",
      "remodel"
    ],
    "urgency_boost": {
      "emergency": 30,
      "today": 25,
      "this_week": 15,
      "this_month": 5
    }
  },
  "followup_settings": {
    "enabled": true,
    "channels": ["email", "sms"],
    "delay_minutes": 3,
    "max_followups": 4
  }
}
```

### Legal Services

```json
{
  "qualification_criteria": {
    "min_score_qualified": 65,
    "min_score_followup": 35,
    "required_fields": ["email", "phone"],
    "high_value_services": [
      "personal_injury",
      "medical_malpractice",
      "wrongful_death",
      "class_action",
      "business_litigation"
    ],
    "urgency_boost": {
      "immediate": 25,
      "this_week": 15,
      "this_month": 10
    }
  },
  "followup_settings": {
    "enabled": true,
    "channels": ["email"],
    "delay_minutes": 10,
    "max_followups": 3
  }
}
```

### Medical/Healthcare

```json
{
  "qualification_criteria": {
    "min_score_qualified": 60,
    "min_score_followup": 30,
    "required_fields": ["email", "phone", "service_requested"],
    "high_value_services": [
      "cosmetic_surgery",
      "dental_implants",
      "lasik",
      "fertility",
      "weight_loss"
    ],
    "urgency_boost": {
      "ready_to_schedule": 25,
      "researching": 10,
      "just_curious": 0
    }
  },
  "followup_settings": {
    "enabled": true,
    "channels": ["email"],
    "delay_minutes": 15,
    "max_followups": 2,
    "quiet_hours": {
      "enabled": true,
      "start": "20:00",
      "end": "09:00"
    }
  }
}
```

### Real Estate

```json
{
  "qualification_criteria": {
    "min_score_qualified": 50,
    "min_score_followup": 25,
    "required_fields": ["email", "phone"],
    "high_value_services": [
      "luxury_home",
      "investment_property",
      "commercial",
      "relocation"
    ],
    "urgency_boost": {
      "pre_approved": 30,
      "actively_looking": 20,
      "within_6_months": 10,
      "just_browsing": 0
    }
  },
  "followup_settings": {
    "enabled": true,
    "channels": ["email", "sms"],
    "delay_minutes": 5,
    "max_followups": 5
  }
}
```

---

## API Key Generation

### Generate API Key for Client

```sql
-- Generate a secure random key (do this in application code)
-- Example: 'lq_live_abc123xyz789...'

INSERT INTO api_keys (
    client_id,
    key_hash,
    key_prefix,
    name,
    scopes,
    rate_limit
) VALUES (
    '{{CLIENT_UUID}}',
    encode(sha256('{{GENERATED_API_KEY}}'::bytea), 'hex'),
    'lq_live_',
    'Production API Key',
    ARRAY['leads:write', 'leads:read'],
    100
);
```

### API Key Format

- Prefix: `lq_live_` (production) or `lq_test_` (testing)
- Length: 32 characters after prefix
- Characters: alphanumeric only

---

## Webhook Endpoints

After configuration, client receives these endpoints:

| Endpoint | Purpose | Auth |
|----------|---------|------|
| `POST /webhook/lead-intake?client_slug={{SLUG}}` | Submit leads | X-API-Key header |

### Example Request

```bash
curl -X POST "https://your-n8n.app.n8n.cloud/webhook/lead-intake?client_slug=abc-plumbing" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: lq_live_abc123..." \
  -H "X-Source-Type: website_form" \
  -d '{
    "email": "customer@example.com",
    "phone": "555-123-4567",
    "name": "John Smith",
    "service_requested": "HVAC Installation",
    "message": "Need new AC unit installed",
    "urgency": "this_week"
  }'
```

---

## Checklist

- [ ] Client information collected
- [ ] Industry template selected/customized
- [ ] Qualification criteria reviewed with client
- [ ] Follow-up settings approved
- [ ] Slack webhook created and tested
- [ ] Google Sheet created and shared
- [ ] API key generated and documented
- [ ] Webhook endpoints provided to client
- [ ] Test lead submitted and verified
