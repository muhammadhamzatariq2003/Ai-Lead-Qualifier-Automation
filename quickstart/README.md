# Setup guide: run the AI Lead Qualifier

This is the technical setup guide. For the problem, the solution and how the AI works, see the [main README](../README.md). It is one importable n8n workflow: Webhook, Normalize, Claude scoring, Parse, optional Slack alert, JSON response.
The full multi-workflow design in `/workflows` is the production roadmap; this is the version you can run today.

## Setup
1. In n8n, go to **Workflows → Import from file** and pick `lead-qualifier-quickstart.json`.
2. Create a credential: **Header Auth**, name `Anthropic API Key`, header name `x-api-key`, value = your Anthropic API key. Select it on the **Claude Qualify** node.
3. (Optional) Paste your Slack Incoming Webhook URL into **Slack Alert (optional)** and enable the node. Never commit that URL.
4. Click **Execute workflow**, then send the sample lead to the **test** webhook URL:

```bash
curl -X POST "<your-n8n-test-webhook-url>" \
  -H "Content-Type: application/json" \
  -d @sample-lead.json
```

## Example response
```json
{
  "success": true,
  "lead": { "full_name": "Sarah Ahmed", "email": "sarah@brightdental.example", "...": "..." },
  "qualification": {
    "score": 82,
    "status": "qualified",
    "recommended_action": "immediate_call",
    "reasoning": "...",
    "key_signals": ["..."],
    "missing_info": []
  }
}
```

## Notes
- Score, status and action are recomputed in code, so they stay consistent even if the model's own labels disagree.
- If the model returns invalid JSON, the lead is marked `needs_followup` for manual review instead of crashing.
- The Claude call retries up to 3 times.
- Before going live, add **Header Auth** on the Webhook node so strangers can't spend your API credits.
- The model name is set in the **Claude Qualify** node body (`claude-sonnet-5-5`). Change it there if you want another model.
