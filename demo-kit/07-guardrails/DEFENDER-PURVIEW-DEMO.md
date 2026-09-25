# Defender and Purview demo

## Deployed Defender state

The subscription uses **Defender for AI Services Standard** with these extensions enabled:

- `AIModelScanner`
- `AIPromptEvidence`
- `AIPromptSharingWithPurview`

In Microsoft Foundry, open **Operate > Compliance > Security posture**, choose the demo subscription and `zavabasicjhca`, and show the current result:

> No recommendations found

This is a healthy security-posture result, not an unavailable integration. If Defender finds a configuration issue, recommendations appear in this grid with remediation guidance.

## Show risk evidence, not only posture

The posture view checks configuration health; it is not the only security signal. For a stronger demo, open the completed prompt-agent red-team evaluation:

- Categories: prohibited actions, violence, sexual, self-harm, and hate or unfairness
- Result: 72 failed attack items
- Interpretation: the scan found behavioral cases that require investigation and guardrail or instruction tuning

Also open **Operate > Compliance > Policies** and show the detected prompt-injection and healthcare-policy violations. Present these alongside the healthy posture view: configuration can be healthy while behavioral and data-policy findings still require action.

## Deployed Purview state

In Microsoft Foundry, open **Operate > Compliance > Data security and governance**:

- **Enable Purview** is on.
- The Foundry page confirms Purview is connected.
- The tenant is linked to Azure subscription billing through the `zava-purview-billing` Purview account in `rg-foundry-control-plane`.

Microsoft Purview states that entitlement changes can take up to a few hours to appear. Until propagation completes, the DLP wizard shows **Microsoft Foundry** but does not allow the location to be selected.

## Zava DLP policy design

Create this policy after the Microsoft Foundry location becomes selectable:

| Setting | Value |
|---|---|
| Name | `Zava AI sensitive data protection` |
| Description | Audit sensitive personal and payment information used with Zava AI apps and agents before enforcing user restrictions. |
| Template | Custom policy |
| Admin units | Full directory |
| Location | Microsoft Foundry only |
| Mode | Simulation first |

Suggested sensitive information conditions:

- Credit card number
- UK National Insurance number
- Passport number
- Bank account number
- Credentials or secrets where an available classifier exists

Start in simulation mode without user notifications. Use policy matches and false-positive review to establish a baseline before moving to user warnings or blocking.

## Data flow to explain

1. A user interacts with a Foundry application or agent.
2. Defender for AI Services captures enabled AI prompt evidence.
3. `AIPromptSharingWithPurview` makes eligible evidence available to Purview.
4. Purview evaluates Foundry-scoped DLP conditions.
5. Audit-first policy matches appear in Purview for investigation.
6. After validation, administrators can move from simulation to enforcement.

## Important caveats

- DLP enforcement for Foundry is metered through Purview pay-as-you-go.
- Policy propagation and evidence ingestion are not instantaneous.
- Agent-level security inventory and risk signals might require Microsoft Agent 365 licensing.
- Foundry DLP documentation scopes enforcement to supported user-context inference paths; verify the exact client path before claiming that every agent protocol is blocked.
- Do not present **No recommendations found** as proof that no threats exist. It means Defender found no current configuration recommendations for the selected filters.
