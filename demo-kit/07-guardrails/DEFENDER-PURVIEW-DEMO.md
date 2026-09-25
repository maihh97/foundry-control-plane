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
- The DLP policy **Zava AI sensitive data protection** has been created.

## Deployed Zava DLP policy

| Setting | Value |
|---|---|
| Name | `Zava AI sensitive data protection` |
| Description | Audit sensitive personal, payment, identity, and credential data used with Zava AI apps and agents before enabling user restrictions. |
| Template | Custom policy |
| Admin units | Full directory |
| Location | Microsoft Foundry only |
| Mode | On |
| Rule | `Detect Zava sensitive AI prompts and responses` |
| Sensitive information types | Credit Card Number; All Credential Types |
| Action | Restrict Microsoft Foundry Apps: block matching text prompts |
| Incident reports | Admin alert for every matching activity |

Open **Microsoft Purview > Data Loss Prevention > Policies**, select the Zava policy, and show:

- Only **Microsoft Foundry** appears under Locations.
- The rule condition contains the two deployed sensitive-information types.
- **Restrict Microsoft Foundry Apps** is the selected action.
- DLP alerts are enabled so policy matches can be investigated.

## Data flow to explain

1. A user interacts with a Foundry application or agent.
2. Defender for AI Services captures enabled AI prompt evidence.
3. `AIPromptSharingWithPurview` makes eligible evidence available to Purview.
4. Purview evaluates Foundry-scoped DLP conditions.
5. Matching Foundry text prompts are blocked and generate an administrator alert.
6. Administrators investigate matches in Purview DLP alerts and tune the rule if required.

## Important caveats

- DLP enforcement for Foundry is metered through Purview pay-as-you-go.
- Policy propagation and evidence ingestion are not instantaneous.
- Agent-level security inventory and risk signals might require Microsoft Agent 365 licensing.
- Foundry DLP documentation scopes enforcement to supported user-context inference paths; verify the exact client path before claiming that every agent protocol is blocked.
- Do not present **No recommendations found** as proof that no threats exist. It means Defender found no current configuration recommendations for the selected filters.
