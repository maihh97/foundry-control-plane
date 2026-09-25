# Foundry Control Plane demo kit — 04 generate traffic against the PROMPT agent (fills Operate > Assets metrics, traces, continuous eval)
# Derived from (verbatim API usage):
#   https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/agents/sample_agent_basic.py
#     (project_client.get_openai_client(agent_name=...), conversations.create, responses.create(conversation=...))
#   https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/agents/telemetry/sample_agent_basic_with_azure_monitor_tracing.py
#     (responses.create(conversation=conversation.id, input="..."))
#   https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-agents
#     ("Metrics and traces are collected only for runs that occur after configuration… Wait up to 15 minutes for data to propagate")
# For the CUSTOM (LangGraph) agent, traffic must go to the APIM URL so the gateway sees it -> use 03-custom-agent/client_via_gateway.py.
# For the HOSTED agent, repeat `azd ai agent invoke "..."`.
# Note: Azure-Samples/foundry-hosted-agentframework-demos includes scripts/send_requests.py and locustfile.py, but they
# were "not visible in the live scripts/ tree" — this simple loop is the always-available alternative.
#
# USAGE:
#   python 04-traffic/send_traffic.py --count 20            # sequential, one conversation per request
#   python 04-traffic/send_traffic.py --count 30 --burst    # no pause between requests (use with 06-cost token limits)
# ENV: FOUNDRY_PROJECT_ENDPOINT, FOUNDRY_AGENT_NAME

import argparse
import os
import time
from dotenv import load_dotenv
from azure.identity import AzureCliCredential
from azure.ai.projects import AIProjectClient

load_dotenv()

PROMPTS = [
    "Hi, I want to return a pair of trainers I bought last week. What do I do?",
    "My order arrived with a missing item. Can I get a refund for just that item?",
    "How long does a refund usually take once you receive my return?",
    "Can I return something I bought in a sale?",
    "I lost my returns label. Can you send another one?",
    "I paid with a gift voucher. How will I be refunded?",
    "The jacket I received is damaged. Do I still have to pay for the return?",
    "Can I exchange for a different size instead of a refund?",
    "I returned my parcel 10 days ago and still have no refund. What now?",
    "Which return options are available in the UK?",
]


def main() -> None:
    parser = argparse.ArgumentParser(description="Send demo traffic to the Foundry prompt agent.")
    parser.add_argument("--count", type=int, default=10, help="number of requests to send")
    parser.add_argument("--burst", action="store_true", help="send requests back-to-back with no pause")
    parser.add_argument("--pause", type=float, default=2.0, help="seconds between requests when not --burst")
    args = parser.parse_args()

    endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
    agent_name = os.environ.get("FOUNDRY_AGENT_NAME") or "zava-returns-assistant"

    ok = 0
    failed = 0
    with (
        AzureCliCredential(process_timeout=60) as credential,
        AIProjectClient(endpoint=endpoint, credential=credential) as project_client,
        project_client.get_openai_client(agent_name=agent_name) as openai_client,
    ):
        for i in range(args.count):
            prompt = PROMPTS[i % len(PROMPTS)]
            started = time.time()
            try:
                conversation = openai_client.conversations.create()
                response = openai_client.responses.create(
                    conversation=conversation.id,
                    input=prompt,
                )
                elapsed = time.time() - started
                ok += 1
                print(f"[{i + 1}/{args.count}] OK {elapsed:.1f}s | {prompt[:48]}... -> {response.output_text[:80]!r}")
            except Exception as exc:  # print status where the SDK exposes it (e.g. 429/403 from the gateway)
                elapsed = time.time() - started
                failed += 1
                status = getattr(exc, "status_code", None)
                print(f"[{i + 1}/{args.count}] FAIL {elapsed:.1f}s status={status} {type(exc).__name__}: {exc}")
            if not args.burst:
                time.sleep(args.pause)

    print(f"\nDone: {ok} ok, {failed} failed. Portal: Operate > Assets > Agents > {agent_name} (allow up to 15 minutes for data).")


if __name__ == "__main__":
    main()
