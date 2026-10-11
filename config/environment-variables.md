# Environment Variables

## Required Variables

All variables must be configured in n8n.cloud under Settings → Variables.

---

### Database (Supabase)

| Variable | Description | Example |
|----------|-------------|---------|
| `SUPABASE_URL` | Supabase project URL | `https://xxxxx.supabase.co` |
| `SUPABASE_SERVICE_KEY` | Service role key (full access) | `eyJhbGciOiJIUzI1NiIsInR5cCI6...` |

**How to obtain**:
1. Go to Supabase Dashboard → Settings → API
2. Copy Project URL
3. Copy `service_role` key (NOT anon key)

---

### AI (Claude API)

| Variable | Description | Example |
|----------|-------------|---------|
| `CLAUDE_API_KEY` | Anthropic API key | `sk-ant-api03-...` |

**How to obtain**:
1. Go to console.anthropic.com
2. Settings → API Keys
3. Create new key or copy existing

**Model**: `claude-sonnet-5-5` (hardcoded in workflows)

---

### Notifications (Slack)

| Variable | Description | Example |
|----------|-------------|---------|
| `SYSTEM_SLACK_WEBHOOK_URL` | Webhook for system error alerts | `https://hooks.slack.com/services/...` |

**How to obtain**:
1. Go to api.slack.com/apps
2. Create new app or select existing
3. Incoming Webhooks → Add New Webhook
4. Select channel for system alerts

**Note**: Client-specific Slack webhooks are stored in the `clients` table.

---

### Google Integration

| Variable | Description | Example |
|----------|-------------|---------|
| `GOOGLE_SERVICE_ACCOUNT_EMAIL` | Service account email | `n8n-sheets@project.iam.gserviceaccount.com` |
| `GOOGLE_PRIVATE_KEY` | Service account private key | `-----BEGIN PRIVATE KEY-----\n...` |

**How to obtain**:
1. Go to Google Cloud Console
2. IAM & Admin → Service Accounts
3. Create service account
4. Create key (JSON format)
5. Extract `client_email` and `private_key`

**Required API scopes**:
- `https://www.googleapis.com/auth/spreadsheets`
- `https://www.googleapis.com/auth/drive.file`

---

## Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `LOG_LEVEL` | Logging verbosity | `info` |
| `WEBHOOK_BASE_URL` | Base URL for webhooks (if custom domain) | n8n.cloud default |
| `RATE_LIMIT_WINDOW_MS` | Rate limit window | `60000` |
| `RATE_LIMIT_MAX_REQUESTS` | Max requests per window | `100` |

---

## Security Notes

1. **Never commit keys to version control**
2. **Rotate keys quarterly**
3. **Use separate keys per environment** (dev/staging/prod)
4. **Restrict Supabase service key** to specific IPs if possible
5. **Monitor API usage** for anomalies

---

## n8n.cloud Variable Configuration

### Steps to Configure

1. Login to n8n.cloud
2. Go to Settings → Variables
3. Click "Add Variable" for each required variable
4. Enter Name and Value
5. Click Save

### Variable Reference in Workflows

Access variables using:
```javascript
{{ $env.VARIABLE_NAME }}
```

Example:
```javascript
{{ $env.CLAUDE_API_KEY }}
{{ $env.SUPABASE_URL }}
```

---

## Validation Checklist

Before going live, verify:

- [ ] `SUPABASE_URL` connects successfully
- [ ] `SUPABASE_SERVICE_KEY` has correct permissions
- [ ] `CLAUDE_API_KEY` is active and has credits
- [ ] `SYSTEM_SLACK_WEBHOOK_URL` sends test message
- [ ] `GOOGLE_SERVICE_ACCOUNT_EMAIL` has sheet access
- [ ] `GOOGLE_PRIVATE_KEY` is properly formatted (with `\n` for newlines)

---

## Troubleshooting

### "Invalid API Key" errors

1. Check key is copied correctly (no trailing spaces)
2. Verify key is active in provider dashboard
3. Check key has required scopes/permissions

### "Connection refused" errors

1. Verify URL is correct
2. Check if service is region-restricted
3. Verify n8n.cloud IP is not blocked

### Google Sheets "Permission denied"

1. Share spreadsheet with service account email
2. Verify service account has Editor access
3. Check API is enabled in Google Cloud project
