import json
import os
import sys
import urllib.error
import urllib.request

from dotenv import load_dotenv

load_dotenv()

gateway_url = os.environ.get(
    "APIM_URL",
    "https://zava-apim-mh2609.azure-api.net/agents/zava-returns-langgraph/invoke",
)
subscription_key = os.environ["APIM_SUBSCRIPTION_KEY"]
message = (
    sys.argv[1]
    if len(sys.argv) > 1
    else "Hi, I need to return a dress that does not fit. What is the next safe step?"
)

payload = json.dumps({"message": message}).encode("utf-8")
request = urllib.request.Request(
    gateway_url,
    data=payload,
    method="POST",
    headers={
        "Content-Type": "application/json",
        "Ocp-Apim-Subscription-Key": subscription_key,
    },
)

try:
    with urllib.request.urlopen(request, timeout=180) as response:
        result = json.load(response)
except urllib.error.HTTPError as exc:
    error_body = exc.read().decode("utf-8", errors="replace")
    raise RuntimeError(f"Gateway returned HTTP {exc.code}: {error_body}") from exc

print(f"Agent: {result['agent_id']} version {result['agent_version']}")
print(f"Trace ID: {result['trace_id']}")
print(result["response"])
