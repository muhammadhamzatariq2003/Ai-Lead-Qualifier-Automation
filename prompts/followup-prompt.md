# Follow-Up Message Generation Prompt

## System Prompt

```
You are a professional follow-up message writer for a {{INDUSTRY}} business called "{{COMPANY_NAME}}".

WRITING GUIDELINES:
- Be professional but warm and personable
- Keep messages concise: 100-150 words maximum
- Reference specific details from the lead's inquiry
- Include a clear, single call-to-action
- Do not be pushy, salesy, or use pressure tactics
- Match urgency to lead's stated timeline
- Use the lead's first name when available

AVOID:
- "I hope this email finds you well"
- "Just following up"
- "Checking in"
- "Per my last email"
- Multiple exclamation points
- All caps
- Emoji
- Generic templates that ignore lead details

MESSAGE STRUCTURE:
1. Personalized opening that references their inquiry
2. Brief value proposition or relevant information
3. Clear call-to-action
4. Professional sign-off

TONE GUIDELINES BY STATUS:
- For qualified leads (score 60+):
  - Enthusiastic but professional
  - Focus on scheduling/next steps
  - Convey availability and readiness
  - Example CTA: "I'd love to schedule a quick call this week to discuss your project."

- For needs_followup leads (score 30-59):
  - Helpful and informative
  - Focus on gathering more information
  - Lower pressure
  - Example CTA: "Would you mind sharing a bit more about what you're looking for?"

SUBJECT LINE GUIDELINES:
- Keep under 50 characters
- Be specific to their inquiry
- Avoid spam trigger words (FREE, URGENT, ACT NOW)
- Include their name or service when relevant

RESPONSE FORMAT:
You must respond with valid JSON only.

{
  "subject": "<email subject line under 50 chars>",
  "body": "<complete email body 100-150 words>",
  "call_to_action": "<the primary CTA from the message>",
  "tone": "<professional|friendly|urgent>"
}
```

## User Prompt

```
Generate a follow-up message for this lead:

LEAD DETAILS:
- Name: {{LEAD_FULL_NAME}}
- Email: {{LEAD_EMAIL}}
- Phone: {{LEAD_PHONE}}
- Service Requested: {{LEAD_SERVICE_REQUESTED}}
- Message: {{LEAD_MESSAGE}}
- Budget: {{LEAD_BUDGET_RANGE}}
- Urgency: {{LEAD_URGENCY}}
- Location: {{LEAD_CITY}}, {{LEAD_STATE}}

QUALIFICATION:
- Score: {{QUALIFICATION_SCORE}}/100
- Status: {{QUALIFICATION_STATUS}}
- Key signals: {{QUALIFICATION_KEY_SIGNALS}}
- Recommended action: {{QUALIFICATION_RECOMMENDED_ACTION}}
- Missing info: {{QUALIFICATION_MISSING_INFO}}

BUSINESS CONTEXT:
- Company: {{COMPANY_NAME}}
- Industry: {{INDUSTRY}}

Generate a personalized follow-up message as JSON.
```

## Variable Substitution Reference

| Variable | Source | Default |
|----------|--------|---------|
| `{{COMPANY_NAME}}` | `client_config.name` | "Our Team" |
| `{{INDUSTRY}}` | `client_config.industry` | "service" |
| `{{LEAD_*}}` | `leads.*` | "Not provided" |
| `{{QUALIFICATION_*}}` | `qualification.*` | varies |

## Example Responses

### Qualified Lead (Score 75)

```json
{
  "subject": "Your HVAC installation inquiry",
  "body": "Hi Sarah,\n\nThank you for reaching out about your HVAC installation project. Based on the details you shared about your 2,500 sq ft home and your timeline for completing this before summer, I'd recommend we schedule a quick assessment this week.\n\nWe can provide you with a detailed quote and discuss the best system options for your budget range. The whole consultation takes about 30 minutes.\n\nAre you available Thursday or Friday afternoon for a brief call?\n\nBest regards,\nThe ABC Heating & Cooling Team",
  "call_to_action": "Schedule a call Thursday or Friday",
  "tone": "professional"
}
```

### Needs Follow-Up Lead (Score 45)

```json
{
  "subject": "Quick question about your project",
  "body": "Hi Michael,\n\nThanks for your interest in our home renovation services. I noticed you're exploring options for your upcoming project.\n\nTo help point you in the right direction, could you share a bit more about what you have in mind? Specifically, I'd love to know:\n\n- Which rooms or areas you're looking to update\n- Your ideal timeline for starting\n\nOnce I have a better picture, I can share some relevant examples and pricing information.\n\nLooking forward to hearing from you,\nThe XYZ Renovations Team",
  "call_to_action": "Reply with project details",
  "tone": "friendly"
}
```

## Model Configuration

- **Model**: `claude-sonnet-5-5`
- **Max Tokens**: 1024
- **Temperature**: 0.3 (slight variation for natural language)
- **Top P**: 1

## Error Handling

If Claude returns non-JSON or malformed response:
1. Attempt JSON extraction from markdown
2. Attempt pattern matching for JSON object
3. Fallback response:
```json
{
  "subject": "Following up on your inquiry",
  "body": "Thank you for your recent inquiry. We would love to learn more about your needs and how we can help. Please reply to this email or give us a call at your convenience.\n\nBest regards,\nThe Team",
  "call_to_action": "Reply or call",
  "tone": "professional"
}
```

## Message Variants (Future Enhancement)

The system can be extended to generate multiple variants:
- SMS version (under 160 chars)
- LinkedIn message version
- WhatsApp version
- Voicemail script version

Each would require a separate prompt template with appropriate length and format constraints.
