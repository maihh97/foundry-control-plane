<!--
Foundry Control Plane demo kit — 06 token limits -> 429 / 403 (Preview)
Derived from (verbatim):
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-enforce-limits-models
  https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/control-plane/how-to-enforce-limits-models.md (ms.date 07/15/2026)
  https://learn.microsoft.com/en-us/azure/api-management/llm-token-limit-policy   (mechanism: 429 on TPM, 403 on quota)
  https://learn.microsoft.com/en-us/azure/foundry/configuration/enable-ai-api-management-gateway-portal
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/overview   (Manage > Quota > Show all)
-->
# 06 · Cost control — token limits through the AI Gateway (Preview)

> **Automation status (verified 24 Sep 2026 — see `AUTOMATION.md`).** The Foundry **Token management** pane is documented only in the portal. The *enforcement* is not portal-bound: the same article says the gateway "makes all requests flow through the API Management instance" and links to the APIM `llm-token-limit` policy, whose reference states the identical semantics — "When a specified token rate limit is exceeded, the caller receives a 429 Too Many Requests… When a specified quota is exceeded, the caller receives a 403 Forbidden." So a coding agent can deploy `apim-policies/llm-token-limit.xml` to the gateway APIM as code. **Not documented:** whether a policy set directly in APIM is shown back in the Foundry pane — configure the limit in one place only.

**Setup dependency:** the project must be enabled on the AI Gateway (`01-infra/ai-gateway.md`); "All requests flow through the APIM instance once associated." Role: "API Management Service Contributor role (or Owner) on the Azure API Management resource."

## Portal path (verbatim steps)

1. "Select **Manage > AI Gateway**."
2. "In the AI Gateway list, select the gateway… select **Token management**."
3. "Select **+ Set limit**… Select the project and deployment that you want to restrict, and enter a value for Limit (Token-per-minute). Select **Create**."

Key sentences to say out loud:

- "**Limits apply at the project level.** That is, each project can have its own TPM and quota settings."
- "**New limits apply immediately to subsequent requests.**"
- Two kinds of limit (verbatim): "TPM rate limit: … When requests exceed the TPM limit, the caller receives a **429 Too Many Requests**… Total token quota: Limits token consumption to a configured maximum per quota period (for example, hourly, daily, weekly, monthly, or yearly). When requests exceed the quota, the caller receives a **403 Forbidden**…"
- Caveat (verbatim): "If you send many requests concurrently, token consumption can temporarily exceed the configured limits until responses are processed."

## Live sequence (≈4 min)

1. Show the Returns Assistant working: `python 04-traffic/send_traffic.py --count 3`.
2. **+ Set limit** → project = demo project, deployment = `<FOUNDRY_MODEL_NAME>`, a deliberately low TPM.
3. `python 06-cost/burst_test.py --count 15` → expect a run of successes then **429**s. Print shows status codes per request.
4. Lower the **quota** (per period) → run the burst again → **403** once the period budget is exhausted.
5. Remove/raise the limits so modules 07–09 keep working.

Under the hood (APIM policy reference, verbatim): "When a specified token rate limit is exceeded, the caller receives a 429 Too Many Requests response status code. When a specified quota is exceeded, the caller receives a 403 Forbidden response status code." · "The v2 tiers use a token bucket algorithm for rate limiting" · "Streaming: … prompt tokens are always estimated regardless of the estimate-prompt-tokens setting."

## Policy-as-code (for the platform-team conversation)

`apim-policies/llm-token-limit.xml` and `apim-policies/llm-emit-token-metric.xml` are verbatim from **Azure-Samples/AI-Gateway** labs `token-rate-limiting` / `token-metrics-emitting`: an inbound `llm-token-limit` (rate and/or quota) and token-metric emission to Application Insights ("You can configure a maximum of 5 custom dimensions per policy."). They are the official, code-level equivalent of the **+ Set limit** wizard (same APIM policy family, same 429/403). Apply them through APIM — Azure portal policy editor, Bicep/ARM, or the lab notebooks, which "deploy `main.bicep` and apply the policy". Foundry's own guidance for gateway policies is that they are applied "only in the Azure portal, not the Foundry portal" (MCP tools governance article). Choose **either** the Foundry pane **or** the APIM policy for a given deployment; the docs do not state that one reflects the other.

## Other cost surfaces to show

- **Operate > Assets > Agents**: **Estimated cost** ("based on the number of tokens consumed") and **Token usage** columns — need **Cost Management Reader** ("Cost data doesn't appear: Verify that you have the Cost Management Reader role on the subscription.").
- **Manage > Quota**: "By default, the quota view displays only models with active deployments. Turn on the **Show all** toggle to see the full list of available models and regions, including models you haven't deployed yet."
- Optional: model router in **Cost** mode (routing modes Balanced (default), Quality and Cost; UK South supports Global Standard only).

## Troubleshoot (verbatim table)

| Problem | Possible cause | Action |
|---|---|---|
| API Management instance doesn't appear | Provisioning delay | Refresh after a few minutes. |
| Limits aren't enforced | Misconfiguration or project not linked | Reopen settings and confirm that the enforcement toggle is on. Confirm that AI Gateway is enabled for the project and that correct limits are configured. |
| Latency is high after enablement | API Management cold start or region mismatch | Check API Management region versus resource region. Call the model directly and compare the result with the call proxied through AI Gateway to identify if performance problems are related to the gateway. |
