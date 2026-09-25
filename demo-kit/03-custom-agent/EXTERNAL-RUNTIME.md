# Zava external LangGraph runtime

The external agent is deployed as a real HTTP service:

- **Runtime:** Azure Container Apps
- **Image:** private Azure Container Registry
- **Model authentication:** user-assigned managed identity with Cognitive Services User on the Foundry account
- **Caller gateway:** stable Azure API Management
- **Backend isolation:** Container Apps ingress allows only the stable APIM public IP
- **Caller authentication:** APIM subscription key
- **Rate limit:** 30 calls per minute per APIM subscription
- **Telemetry:** Microsoft OpenTelemetry to the same Application Insights resource as the Foundry project

## Public gateway contract

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/agents/zava-returns-langgraph/health` | Runtime health |
| `POST` | `/agents/zava-returns-langgraph/invoke` | Invoke with `{\"message\":\"...\"}` |

The direct Container App URL is intentionally not a client endpoint. Requests that do not originate from APIM return HTTP 403.

## Reproducible deployment

1. Deploy `01-infra/deploy_external_agent_platform.bicep`.
2. Build `03-custom-agent/runtime` with Azure Container Registry remote build.
3. Deploy `01-infra/deploy_external_agent_runtime.bicep`.
4. Set `APIM_SUBSCRIPTION_KEY` locally and run `03-custom-agent/client_via_gateway.py`.

Do not commit the APIM subscription key or Application Insights connection string.

## Verified behavior

- Direct backend health: HTTP 403
- APIM health without a subscription key: HTTP 401
- APIM health with a subscription key: HTTP 200
- APIM invoke with a subscription key: HTTP 200
- Rate-limit burst: 30 HTTP 200 responses followed by 5 HTTP 429 responses
- Response identifies `zava-returns-langgraph`, includes a trace ID, and emits post-deployment telemetry
- APIM GatewayLogs recorded two successful requests
