# Architecture Diagram

This document shows the deployed Zava Microsoft Foundry control plane and the configuration boundaries for each agent type. It separates platform-managed runtime behavior from source-controlled definitions and the externally hosted LangGraph runtime.

## Application Architecture

<!-- mermaid-checked: no \n, no em-dash/en-dash, no {} in labels, subgraphs are id["label"], arrows are -->|"label"|, all subgraphs closed by end, ids unique -->
```mermaid
flowchart TD
    subgraph DemoEntry["Demo entry points"]
        Audience["Demo audience"]
        Showcase["GitHub Pages showcase"]
        Operator["Demo operator"]
    end
    subgraph Delivery["Source and delivery"]
        Repository["GitHub repository"]
        Workflow["Evaluation gate"]
    end
    subgraph ControlPlane["Microsoft Foundry control plane"]
        Project["Zava Foundry project"]
        Inventory["Operate agent inventory"]
        Evaluations["Evaluation service"]
        RaiPolicy["RAI guardrail policy"]
    end
    subgraph AgentFleet["Agent fleet"]
        PromptAgent["Prompt agent latest v4"]
        HostedAgent["Hosted agent v2"]
        ExternalAgent["External registration v2"]
    end
    subgraph ExternalHosting["External LangGraph hosting"]
        ExternalRuntime["Container Apps runtime"]
        RuntimeIdentity["User-assigned identity"]
        Registry["Private container registry"]
    end
    subgraph ModelGateway["Model and gateway"]
        ApimGateway["API Management gateway"]
        ModelDeployment["gpt-4.1 deployment"]
    end
    subgraph Observability["Observability"]
        AppInsights["Application Insights"]
        LogWorkspace[("Log Analytics")]
    end
    subgraph SecurityServices["Security and data governance"]
        Defender["Defender for AI Services"]
        Purview["Microsoft Purview DLP"]
        Compliance["Compliance policies"]
    end

    Audience -->|"opens"| Showcase
    Operator -->|"navigates"| Showcase
    Showcase -->|"links to"| Repository
    Repository -->|"deploys and evaluates"| Workflow
    Operator -->|"manages"| Project
    Project -->|"lists"| Inventory
    Project -->|"hosts metadata"| PromptAgent
    Project -->|"hosts runtime"| HostedAgent
    Project -->|"registers metadata"| ExternalAgent
    PromptAgent -->|"invokes"| ModelDeployment
    HostedAgent -->|"invokes"| ModelDeployment
    ApimGateway -->|"managed identity"| ModelDeployment
    ApimGateway -->|"routes governed invoke"| ExternalRuntime
    Registry -->|"supplies image"| ExternalRuntime
    RuntimeIdentity -.->|"authenticates"| ExternalRuntime
    ExternalRuntime -->|"managed identity"| ModelDeployment
    RaiPolicy -.->|"blocks unsafe input"| HostedAgent
    PromptAgent -->|"emits traces"| AppInsights
    HostedAgent -->|"emits traces"| AppInsights
    ExternalAgent -.->|"correlates agent ID"| AppInsights
    ExternalRuntime -->|"emits OpenTelemetry"| AppInsights
    AppInsights -->|"stores records"| LogWorkspace
    Evaluations -->|"reads traces"| AppInsights
    Workflow -->|"runs evaluations"| Evaluations
    Project -->|"shares prompt evidence"| Defender
    Defender -->|"shares evidence"| Purview
    Purview -.->|"evaluates DLP policy"| Project
    Compliance -.->|"checks guardrail posture"| Inventory
```

### Technology Stack Summary

| Layer | Technology | Version | Purpose |
|---|---|---:|---|
| Showcase | HTML, CSS, JavaScript | Browser-native | Public anatomy, security, and demo walkthrough |
| Control plane | Microsoft Foundry Agent Service | Current service API | Agent inventory, immutable versions, endpoints, identities, evaluations |
| Prompt agent | Foundry prompt agent | Latest version 4 | Model plus instructions managed by Foundry |
| Hosted agent | Agent Framework and ResponsesHostServer | Python 3.13 runtime | Custom code hosted and built by Foundry |
| External agent | FastAPI and LangGraph on Azure Container Apps | Registration version 2; runtime image 1.0.0 | Real HTTP runtime correlated to Foundry through an OpenTelemetry agent ID |
| Gateway | Azure API Management Developer | Current Azure API | Model Responses route plus external-agent health and invoke routes |
| External runtime identity | User-assigned managed identity | Current Entra identity | Calls the Foundry model without a model key |
| Container registry | Azure Container Registry Basic | Image 1.0.0 | Private external-agent image |
| Model | Azure AI Services OpenAI | gpt-4.1 2025-04-14 | Shared model deployment |
| Observability | Application Insights and Log Analytics | Workspace-based | Requests, dependencies, events, traces, exceptions |
| Threat protection | Defender for AI Services | Standard plan | Model scanning, prompt evidence, and Purview evidence sharing |
| Data security | Microsoft Purview | Pay-as-you-go connected | DLP policy evaluation for Foundry interactions |
| Delivery | GitHub Actions | Workflow actions | Evaluation gate using project-scoped Azure credentials |

### Data Storage & External Services

The active Foundry project uses Basic Agent Setup, so agent state is stored in Microsoft-managed multitenant resources rather than customer-managed Cosmos DB, Storage, or AI Search. Application telemetry is written to workspace-based Application Insights and Log Analytics. API Management forwards model requests by managed identity and routes external-agent requests to a Container App whose public ingress accepts only the APIM public IP. The external runtime uses its own managed identity for model inference. Defender for AI captures prompt evidence and shares enabled evidence with Microsoft Purview. Purview enforces the Foundry-only Zava sensitive-data policy.

### Key Architectural Decisions

- Basic Agent Setup avoids weakening the tenant policy that disables public Cosmos DB access.
- Prompt, hosted, and external agents intentionally demonstrate three different ownership and runtime boundaries.
- Source-controlled hosted-agent code is authoritative because the portal shows deployed runtime metadata, not the complete application source.

## Component Relationships

<!-- mermaid-checked: no \n, no em-dash/en-dash, no {} in labels, subgraphs are id["label"], arrows are -->|"label"|, all subgraphs closed by end, ids unique -->
```mermaid
flowchart LR
    subgraph cPromptLayer["Prompt agent anatomy"]
        cPromptName["Agent name and versions"]
        cPromptRules["Instructions and safety rules"]
        cPromptSelector["Version selector"]
    end
    subgraph cHostedLayer["Hosted agent anatomy"]
        cManifest["azure.yaml manifest"]
        cSource["main.py source"]
        cBuild["Remote code build"]
        cServer["Responses host server"]
    end
    subgraph cExternalLayer["External agent anatomy"]
        cExternalMetadata["External registration"]
        cOtelId["OpenTelemetry agent ID"]
        cExternalRuntime["Azure Container Apps runtime"]
        cExternalIdentity["User-assigned managed identity"]
        cExternalRegistry["Private container registry"]
        cExternalGateway["Stable APIM invoke route"]
    end
    subgraph cSecurityLayer["Security controls"]
        cEntra["Entra identities and RBAC"]
        cRai["RAI content policy"]
        cApim["APIM subscription and token limit"]
        cKill["Disable and enable endpoint"]
        cDefender["Defender prompt evidence"]
        cPurview["Purview DLP policy"]
    end
    subgraph cOpsLayer["Operations"]
        cTrace["Application Insights traces"]
        cEval["Continuous and batch evaluations"]
        cCi["GitHub evaluation gate"]
    end

    cPromptName -->|"contains"| cPromptRules
    cPromptSelector -->|"pins version 2"| cPromptName
    cManifest -->|"defines runtime"| cBuild
    cSource -->|"packaged by"| cBuild
    cBuild -->|"activates"| cServer
    cExternalMetadata -->|"matches"| cOtelId
    cExternalRegistry -->|"supplies image"| cExternalRuntime
    cExternalIdentity -.->|"authenticates model calls"| cExternalRuntime
    cExternalGateway -->|"routes requests"| cExternalRuntime
    cExternalRuntime -->|"emits spans with"| cOtelId
    cEntra -.->|"authorizes"| cPromptName
    cEntra -.->|"authorizes"| cServer
    cRai -.->|"filters"| cServer
    cApim -.->|"governs model traffic"| cServer
    cApim -.->|"governs external traffic"| cExternalGateway
    cKill -.->|"controls traffic"| cPromptName
    cDefender -.->|"inspects evidence"| cPromptName
    cDefender -.->|"inspects evidence"| cServer
    cPurview -.->|"governs sensitive data"| cPromptName
    cPromptName -->|"records"| cTrace
    cServer -->|"records"| cTrace
    cOtelId -.->|"correlates"| cTrace
    cTrace -->|"feeds"| cEval
    cCi -->|"gates with"| cEval
```

### Component Inventory

| Component | Layer | Type | Responsibility |
|---|---|---|---|
| Agent name and versions | Prompt | Foundry resource | Holds immutable prompt-agent versions and endpoint metadata |
| Instructions and safety rules | Prompt | Configuration | Defines behavior, privacy rules, and response constraints |
| Version selector | Prompt | Endpoint rule | Sends all prompt-agent traffic to version 2 |
| `azure.yaml` manifest | Hosted | Source configuration | Defines runtime, resources, protocol, environment, and RAI policy |
| `main.py` source | Hosted | Python code | Constructs the Agent Framework agent and Responses host |
| Remote code build | Hosted | Foundry build | Resolves dependencies and creates the hosted runtime |
| Responses host server | Hosted | Runtime | Exposes the OpenAI Responses-compatible endpoint |
| External registration | External | Foundry metadata | Registers the external agent without moving its runtime |
| OpenTelemetry agent ID | External | Correlation key | Joins external spans to the Foundry inventory item |
| Azure Container Apps runtime | External | FastAPI and LangGraph | Serves health and invoke operations |
| User-assigned managed identity | External | Entra workload identity | Authenticates the runtime to the Foundry model |
| Private container registry | External | Azure Container Registry | Stores the versioned external-agent image |
| Stable APIM invoke route | External | Governed API | Requires a subscription key, rate limits callers, and is the only allowed backend source |
| Entra identities and RBAC | Security | Identity control | Separates project, agent, gateway, user, and CI permissions |
| RAI content policy | Security | Runtime policy | Blocks jailbreak, harmful, protected, Purview, and Defender signals |
| APIM subscription and token limit | Security | Gateway policy | Authenticates callers and enforces a 100 TPM budget |
| Disable and enable endpoint | Security | Lifecycle control | Takes the prompt-agent endpoint offline without deleting versions |
| Defender prompt evidence | Security | Threat protection | Collects AI prompt evidence, scans models, and shares enabled evidence with Purview |
| Purview DLP policy | Security | Data governance | Evaluates sensitive information conditions for the Microsoft Foundry location |
| Application Insights traces | Operations | Telemetry | Stores requests, dependencies, events, traces, and exceptions |
| Evaluations | Operations | Quality control | Scores continuous prompt traffic and hosted-agent datasets |
| GitHub evaluation gate | Delivery | CI workflow | Authenticates to Azure and compares prompt-agent versions |
