<!--
Foundry Control Plane demo kit — 09 identity story: portal paths in Entra admin center and Microsoft 365 admin center (Agent 365)
Derived from (verbatim):
  https://learn.microsoft.com/en-us/entra/agent-id/manage-agent-identities-admin            (Entra ID > Agents > Agent identities; roles; disable scopes; incident sequence)
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/how-to-manage-agents         (Entra ID column)
  https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/agent-identity              (agent identity concept; older path "Entra ID > Agent ID > All agent identities")
  https://learn.microsoft.com/en-us/azure/foundry/control-plane/govern-agent-infrastructure-entra-admin  (Agent 365 registry linkage; Block vs infrastructure actions)
  https://learn.microsoft.com/en-us/microsoft-365/admin/manage/agent-registry?view=o365-worldwide      (Agents > All Agents > Registry)
  Defender for Cloud / Defender XDR licensing pages (Agent 365 licensing, effective 1 July 2026)
-->
# 09 · Identity — where the agent shows up outside Foundry

## 1. Start in Control Plane

**Operate > Assets > Agents** → **Entra ID** column: "The Microsoft Entra Agent ID application and object ID associated with the agent." Concept (verbatim): "Newly created agents receive a unique Entra Agent Blueprint and Entra Agent Identity by default." Legacy agents (`instance_identity` null) use the shared project identity. Cross-check the object id with `agent_identity_rbac.sh`.

## 2. Microsoft Entra admin center

Path (verbatim): "Sign in to the Microsoft Entra admin center. Browse to **Entra ID > Agents > Agent identities**. Select any agent identity to view its details, including name, description, status, owners, sponsors, granted permissions, and sign-in logs. To search for a specific agent, enter the name or object ID in the search box, or add the Blueprint App ID filter."

- Columns: "Name, Created On, Status, Object ID, View Access, Blueprint App ID, Owners and Sponsors, and Uses agent identity."
- Blueprints: "Browse to **Entra ID > Agents > Agent blueprints**." (Preview)
- ⚠ Path difference: the Foundry concept page says "Entra ID > Agent ID > All agent identities". Prefer the Entra documentation, which is closer to the UI owner, and re-check the live path because portal labels can change.
- Roles (verbatim): "View agent identities — Microsoft Entra user account — No admin role needed for viewing. · Manage agent identities — Agent ID Administrator or Cloud Application Administrator… · Configure Conditional Access policies — Conditional Access Administrator — Requires Microsoft Entra ID P1 license. · View ID Protection risk reports — Security Administrator, Security Operator, or Security Reader — Requires Microsoft Entra ID P2 license during preview."
- Owners vs sponsors: "Owners handle technical administration, while sponsors are accountable for the agent's purpose and lifecycle decisions." "If a sponsor leaves the organization, Microsoft Entra ID automatically reassigns sponsorship to the sponsor's manager."
- Sign-in logs: "Browse to Entra ID > Monitoring & health > Sign-in logs. Use the following filters: Agent type: Choose from Agent ID user, Agent Identity, Agent Identity Blueprint, or Not Agentic. Is Agent: Choose from No or Yes."
- Conditional Access for agents: "Policies can scope to All agent identities or All agent users with a Block grant control… Agent risk conditions (high, medium, low)… Policies support Report-only mode".

### Identity-level kill switch (complements module 09 scripts)

Disable scopes (verbatim): "Individual agent… Administrators use the admin center; owners and sponsors use the My Account portal. · Blueprint-level — Disable an agent identity blueprint from its management page. This prevents new agent identities from being created from that blueprint and blocks existing ones. · Tenant-wide — Block all agent identity authentication using Conditional Access policies, and optionally block creation of new agent identities through product-specific controls (Microsoft Entra ID, Security Copilot, Copilot Studio, **Azure AI Foundry**, Microsoft Teams)." Caution: "Globally disabling agent identities can cause existing agents to fail".

Incident sequence (verbatim): "Detect: Review the Risky Agents report… Respond: Confirm compromise… Disable… Investigate… Recover: If false positive: dismiss the risk and re-enable the agent. If true compromise: rotate credentials before re-enabling, or retire the agent identity."

## 3. Microsoft 365 admin center — Agent 365 registry

Path (verbatim): "Sign in to the Microsoft 365 admin center. In the left navigation pane, select **Agents > All Agents > Registry**."

- Foundry linkage (verbatim): "Foundry automatically registers each agent with the Agent 365 registry using the agent's unique identity." · "Don't use project endpoints for production. Foundry doesn't create more registrations in Agent 365 for project endpoints or project identities." · Published agents: "Foundry also registers the application in the Agent 365 registry using the application's unique identity."
- Filters include **Platform** — "indicates which platform or product was used to create the agent." Summary tiles: "Total agents · Agents without owners · Unmanaged agents".
- Block ≠ kill switch (verbatim): "Block actions in Microsoft 365 Admin Center and Teams Admin Center affect agent visibility to users: Scope: Only affects agent projection in Teams and Microsoft 365 Copilot… The agent remains fully functional in Foundry portal and other integration points; Infrastructure: No impact on underlying Azure resources or compute." → for a real kill switch use `disable_enable_agent.sh` (Foundry agent) / Stop (agent application) / Block (custom agent).
- Agent-application Stop/Start from M365 admin center: "a **Stop** or **Start** button appears at the top of the page based on the application's current state" (Global Administrators may be prompted to elevate and are granted Foundry Owner on the application; remove elevation afterwards).
- Risk signals: "Your tenant must have an E7 or A365 license." "The risk signal counts in the Microsoft 365 admin center might be up to an hour behind what the security portals show."

## 4. ⚠ Agent 365 licensing note (effective 1 July 2026) — say this proactively

Verbatim: "Effective July 1, 2026, AI agent discovery and security posture for Microsoft Foundry agents and third-party cloud agents require a Microsoft Agent 365 license. These capabilities were previously available through the Defender CSPM plan in Microsoft Defender for Cloud. Defender CSPM continues to discover Microsoft Foundry accounts and projects, but agent-level capabilities now require Agent 365."

Defender XDR page (verbatim): "Effective July 1, 2026, AI agent security capabilities for Microsoft Copilot Studio and Microsoft Foundry agents require a Microsoft Agent 365 license. These capabilities are no longer covered by existing Defender for Cloud Apps or Defender for Cloud licenses. Tenants without an Agent 365-eligible license lose access to these capabilities on July 1, 2026." · "Agent 365 admin-led trials are available for 25 seats for 30 days."

Status nuance: Agent 365 itself is GA, while the **Foundry ↔ Agent 365 autopilot/data-flow integration is preview**. Positioning: Control Plane is for developers and AI engineers; Agent 365 is for IT and security admins.

## Suggested 3-minute walk

1. Assets → Entra ID column (Foundry).
2. `bash 09-identity-killswitch/agent_identity_rbac.sh` → same principal id.
3. Entra admin center → **Entra ID > Agents > Agent identities** → search by object id → owners/sponsors, sign-ins.
4. (If licensed) M365 admin center → **Agents > All Agents > Registry** → Platform filter.
5. Kill switch: `bash 09-identity-killswitch/disable_enable_agent.sh disable` → traffic rejected → `enable`.
