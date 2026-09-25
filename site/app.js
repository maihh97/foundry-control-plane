const repositoryBase = "https://github.com/maihh97/foundry-control-plane/blob/main/";

const agents = {
  prompt: {
    kind: "Foundry prompt agent",
    name: "zava-returns-assistant",
    status: "Enabled · version 2",
    summary:
      "Foundry owns the versioned definition. The deployed object is primarily a model reference, instructions, endpoint protocol, version selector, and unique Entra agent identity.",
    sourceTitle: "Source of truth: prompt creation code",
    sourceCopy:
      "The portal can show and edit the prompt definition. The repository makes version 1 versus version 2, behavior changes, and rollback intent reviewable.",
    sourceLink: `${repositoryBase}demo-kit/02-agents/prompt_agent_versions.py`,
    items: [
      ["Definition", "PromptAgentDefinition", "Model gpt-4.1 plus instructions; no custom container."],
      ["Versioning", "Immutable versions 1 and 2", "A FixedRatio selector sends 100 percent of endpoint traffic to version 2."],
      ["Protocol", "OpenAI Responses", "Conversation history is managed through the project endpoint."],
      ["Identity", "Unique agent identity", "The inventory exposes an Entra blueprint and instance identity."],
      ["Operations", "Disable and enable", "The endpoint can be stopped without deleting configuration or versions."],
      ["Quality", "Continuous evaluation", "Response-completed events trigger safety and task-adherence evaluation."]
    ]
  },
  hosted: {
    kind: "Foundry hosted agent",
    name: "zava-hosted-returns",
    status: "Active · version 2",
    summary:
      "Foundry hosts a remotely built Python package. The UI shows runtime metadata and immutable versions, but the complete instructions and implementation remain in source control.",
    sourceTitle: "Source of truth: azure.yaml and main.py",
    sourceCopy:
      "azure.yaml defines runtime, CPU, memory, protocol, environment, and RAI policy. main.py defines the Agent Framework client, instructions, and Responses host server.",
    sourceLink: `${repositoryBase}demo-kit/02-agents/zava-hosted-returns/zava-hosted-returns/azure.yaml`,
    items: [
      ["Manifest", "azure.yaml", "Python 3.13 direct-code deployment using remote dependency resolution."],
      ["Runtime", "ResponsesHostServer", "Custom Python runs behind a Responses-protocol endpoint."],
      ["Resources", "0.5 CPU and 1 GiB", "The hosted version records the requested runtime resources."],
      ["Identity", "Managed agent identity", "The runtime authenticates to Foundry and the model with DefaultAzureCredential."],
      ["Guardrail", "zava-returns-guardrail", "Version 2 references the full RAI policy resource."],
      ["Evaluation", "Generated smoke suite", "Fifteen generated cases run against the deployed target; continuous evaluation rules are not supported for hosted agents."]
    ]
  },
  external: {
    kind: "Foundry external agent",
    name: "zava-returns-langgraph",
    status: "Enabled · version 1",
    summary:
      "Foundry stores inventory metadata and an OpenTelemetry correlation ID. The actual LangGraph server remains outside Foundry and must emit matching telemetry.",
    sourceTitle: "Source of truth: external registration code",
    sourceCopy:
      "The registration is metadata-only. It creates no compute, endpoint, gateway route, or application lifecycle inside Foundry.",
    sourceLink: `${repositoryBase}demo-kit/03-custom-agent/external_agent_register.py`,
    items: [
      ["Definition", "ExternalAgentDefinition", "The only runtime binding is the OpenTelemetry agent ID."],
      ["Runtime", "Outside Foundry", "A real endpoint must be hosted independently before users can invoke it."],
      ["Telemetry", "OpenTelemetry spans", "Five verified spans with the matching gen AI agent ID now light up the trace experience."],
      ["Identity", "No hosted runtime identity", "Registration itself is metadata; identity belongs to the external host."],
      ["Gateway", "Not required", "External registration does not automatically provide throttling or blocking."],
      ["Operations", "Observe and evaluate", "Use it for fleet inventory and telemetry, not Foundry compute lifecycle."]
    ]
  }
};

const demoSteps = [
  {
    title: "Orient the audience",
    duration: "2 min",
    copy: "Open this page and establish the three agent ownership models before entering the portal.",
    checks: ["Show the architecture strip", "Call out prompt, hosted, and external boundaries"]
  },
  {
    title: "Show fleet inventory",
    duration: "3 min",
    copy: "Open Foundry Operate and compare type, state, version, identity, and endpoint status.",
    checks: ["Prompt v2 enabled", "Hosted v2 enabled", "External v1 enabled"]
  },
  {
    title: "Explain prompt anatomy",
    duration: "3 min",
    copy: "Open the prompt agent and show model, instructions, immutable versions, and the version selector.",
    checks: ["Compare v1 and v2", "Explain rollback to version 1", "Show unique agent identity"]
  },
  {
    title: "Explain hosted anatomy",
    duration: "4 min",
    copy: "Use the portal for runtime metadata, then switch to source control for configuration the UI does not expose.",
    checks: ["Open azure.yaml", "Open main.py", "Show Responses endpoint and version 2"]
  },
  {
    title: "Demonstrate gateway governance",
    duration: "3 min",
    copy: "Call the protected APIM Responses endpoint and show managed identity, subscription-key access, and token headers.",
    checks: ["HTTP 200", "consumed-tokens header", "remaining-tokens header"]
  },
  {
    title: "Trigger throttling",
    duration: "2 min",
    copy: "Run a short burst and show successful requests followed by HTTP 429 Token limit is exceeded.",
    checks: ["100 TPM policy", "429 response", "GatewayLlmLogs enabled"]
  },
  {
    title: "Show security and data controls",
    duration: "4 min",
    copy: "Open Compliance Policies, Security posture, and Data security and governance. Then show Defender plan extensions and the Purview billing link.",
    checks: ["Defender AI Standard", "Model scanner enabled", "Purview toggle enabled", "Policy violations visible"]
  },
  {
    title: "Prove the kill switch",
    duration: "2 min",
    copy: "Disable the prompt agent, show HTTP 403 AgentDisabled, then enable and retry successfully.",
    checks: ["Traffic rejected", "Versions retained", "Traffic restored"]
  },
  {
    title: "Show observability and evaluation",
    duration: "5 min",
    copy: "Use the operations matrix, then open prompt, hosted, and external traces, the completed red-team report, continuous evaluation, hosted smoke results, and Agent Insights.",
    checks: ["12 prompt v2 spans", "191 hosted v2 events", "5 external spans", "72 red-team failures", "11 of 15 hosted checks"]
  }
];

function renderAgent(agentKey) {
  const agent = agents[agentKey];
  document.querySelectorAll(".agent-tab").forEach((tab) => {
    const selected = tab.dataset.agent === agentKey;
    tab.classList.toggle("active", selected);
    tab.setAttribute("aria-selected", String(selected));
  });

  document.querySelector("#agent-kind").textContent = agent.kind;
  document.querySelector("#agent-name").textContent = agent.name;
  document.querySelector("#agent-status").textContent = agent.status;
  document.querySelector("#agent-summary").textContent = agent.summary;
  document.querySelector("#source-title").textContent = agent.sourceTitle;
  document.querySelector("#source-copy").textContent = agent.sourceCopy;
  document.querySelector("#source-link").href = agent.sourceLink;

  const anatomyGrid = document.querySelector("#anatomy-grid");
  anatomyGrid.replaceChildren(
    ...agent.items.map(([label, title, copy]) => {
      const item = document.createElement("div");
      item.className = "anatomy-item";
      const labelElement = document.createElement("span");
      labelElement.textContent = label;
      const titleElement = document.createElement("strong");
      titleElement.textContent = title;
      const copyElement = document.createElement("p");
      copyElement.textContent = copy;
      item.append(labelElement, titleElement, copyElement);
      return item;
    })
  );
}

function renderDemoSteps() {
  const demoGrid = document.querySelector("#demo-grid");
  demoGrid.replaceChildren(
    ...demoSteps.map((step, index) => {
      const article = document.createElement("article");
      article.className = "demo-step";

      const checkbox = document.createElement("input");
      checkbox.type = "checkbox";
      checkbox.id = `demo-step-${index}`;
      checkbox.setAttribute("aria-label", `Mark ${step.title} complete`);
      checkbox.addEventListener("change", () => {
        article.classList.toggle("complete", checkbox.checked);
      });

      const content = document.createElement("div");
      const header = document.createElement("div");
      header.className = "demo-step-head";
      const title = document.createElement("h3");
      title.textContent = `${index + 1}. ${step.title}`;
      const time = document.createElement("time");
      time.textContent = step.duration;
      const copy = document.createElement("p");
      copy.textContent = step.copy;
      const checks = document.createElement("ul");
      step.checks.forEach((check) => {
        const item = document.createElement("li");
        item.textContent = check;
        checks.append(item);
      });
      header.append(title, time);
      content.append(header, copy, checks);
      article.append(checkbox, content);
      return article;
    })
  );
}

document.querySelectorAll(".agent-tab").forEach((tab) => {
  tab.addEventListener("click", () => renderAgent(tab.dataset.agent));
});

document.querySelectorAll(".filter").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".filter").forEach((filter) => filter.classList.remove("active"));
    button.classList.add("active");
    const selected = button.dataset.filter;
    document.querySelectorAll(".security-card").forEach((card) => {
      card.hidden = selected !== "all" && card.dataset.category !== selected;
    });
  });
});

document.querySelector("#reset-demo").addEventListener("click", () => {
  document.querySelectorAll(".demo-step input").forEach((checkbox) => {
    checkbox.checked = false;
    checkbox.closest(".demo-step").classList.remove("complete");
  });
});

renderAgent("prompt");
renderDemoSteps();
