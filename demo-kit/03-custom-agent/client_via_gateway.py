# Foundry Control Plane demo kit — 03 call the custom LangGraph agent THROUGH the AI Gateway (APIM) URL
# Derived from the published pattern, with whitespace normalized from GitHub rendering:
#   https://learn.microsoft.com/en-us/azure/foundry/control-plane/register-custom-agent
#   https://github.com/MicrosoftDocs/azure-ai-docs/blob/main/articles/foundry/control-plane/register-custom-agent.md
# Verify against source before running: https://learn.microsoft.com/en-us/azure/foundry/control-plane/register-custom-agent
# Changes vs the doc snippet: URL / assistant id / message read from env & argv instead of literals.
# Documented example URL form: https://apim-my-foundry-resource.azure-api.net/my-custom-agent/
# Copy the real value from Operate > Assets > [radio button next to the custom agent] > Agent URL > Copy.
# Note: "the original authorization and authentication schema in the original endpoint still applies."
# Kill-switch demo (module 09): after Operate > Assets > Update status > Block, this call fails; after Unblock it works again.
#
# USAGE: python 03-custom-agent/client_via_gateway.py ["your message"]

import asyncio
import os
import sys
from dotenv import load_dotenv
from langgraph_sdk import get_client

load_dotenv()

client = get_client(url=os.environ["APIM_URL"])
assistant_id = os.environ.get("LANGGRAPH_ASSISTANT_ID", "your_assistant_id")
message = sys.argv[1] if len(sys.argv) > 1 else "Hi, I need to return a dress that doesn't fit. What are my options?"


async def stream_run():
    thread = await client.threads.create()
    input_data = {"messages": [{"role": "human", "content": message}]}
    async for chunk in client.runs.stream(thread['thread_id'], assistant_id=assistant_id, input=input_data):
        print(chunk)


asyncio.run(stream_run())
