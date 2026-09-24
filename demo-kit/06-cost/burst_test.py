# Foundry Control Plane demo kit — 06 burst N rapid requests through the gateway-enabled project and print status codes (expect 429, then 403)
# Derived from (verbatim API usage):
#   https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/agents/telemetry/sample_agent_basic_with_azure_monitor_tracing.py
#     (get_openai_client(agent_name=...), conversations.create(), responses.create(conversation=..., input=...))
#   https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-enforce-limits-models
#     ("429 Too Many Requests" on TPM; "403 Forbidden" on quota; "New limits apply immediately to subsequent requests.")
#   https://learn.microsoft.com/en-us/azure/foundry/configuration/enable-ai-api-management-gateway-portal ("All requests flow through the APIM instance once associated.")
# The prompt agent's model calls are proxied by the AI Gateway once the project is enabled on it, so the token limit set in
# Manage > AI Gateway > Token management applies here. The status code is read from the SDK exception when present.
# Alternative raw check (from add-hosted-agent-guardrails): POST "$BASE_URL/agents/<agent>/endpoint/protocols/openai/responses?api-version=v1"
#   with a bearer token from `az account get-access-token --resource https://ai.azure.com` and inspect the HTTP status.
#
# USAGE: python 06-cost/burst_test.py --count 15
# ENV: FOUNDRY_PROJECT_ENDPOINT, FOUNDRY_AGENT_NAME

import argparse
import os
import time
from collections import Counter
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient

load_dotenv()

# Longer prompt = more tokens per request, so a low TPM trips sooner.
PROMPT = (
    "A customer writes: 'I ordered three items last month - a coat, a pair of boots and a scarf. The coat is the wrong size, "
    "the boots have a scuff on the left toe and the scarf is fine. I want to return the coat and the boots but keep the scarf. "
    "I paid partly with a gift voucher and partly by card. Please explain, step by step, how I return the two items, what I need "
    "to include in the parcel, how I get a label, and how the refund is split between the voucher and the card.' "
    "Reply as the Zava Returns & Refunds Assistant. Ask for the order number first and do not state policy details you cannot confirm."
)


def main() -> None:
    parser = argparse.ArgumentParser(description="Burst requests to trigger AI Gateway token limits.")
    parser.add_argument("--count", type=int, default=15)
    args = parser.parse_args()

    endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
    agent_name = os.environ.get("FOUNDRY_AGENT_NAME") or "zava-returns-assistant"
    statuses: Counter = Counter()

    with (
        DefaultAzureCredential() as credential,
        AIProjectClient(endpoint=endpoint, credential=credential) as project_client,
        project_client.get_openai_client(agent_name=agent_name) as openai_client,
    ):
        for i in range(args.count):
            started = time.time()
            try:
                conversation = openai_client.conversations.create()
                response = openai_client.responses.create(
                    conversation=conversation.id,
                    input=PROMPT,
                )
                statuses["200"] += 1
                print(f"[{i + 1:02d}] 200  {time.time() - started:.1f}s  {len(response.output_text)} chars")
            except Exception as exc:
                status = getattr(exc, "status_code", None)
                key = str(status) if status is not None else type(exc).__name__
                statuses[key] += 1
                hint = ""
                if status == 429:
                    hint = "  <- TPM rate limit (429 Too Many Requests)"
                elif status == 403:
                    hint = "  <- token quota for the period exhausted (403 Forbidden)"
                print(f"[{i + 1:02d}] {key}  {time.time() - started:.1f}s  {str(exc)[:100]}{hint}")

    print("\nStatus summary:", dict(statuses))
    print("Verify in Azure portal > APIM instance > Monitoring > Metrics (Requests) or Logs: ApiManagementGatewayLogs | where TimeGenerated > ago(1h)")


if __name__ == "__main__":
    main()
