# Foundry Control Plane demo kit — 05 ON-DEMAND red-team run against the PROMPT agent (evals API, azure_ai_red_team data source)
# ⚠ Run against the PROMPT agent (02). Hosted-agent cloud red teaming is contradicted between official sources:
#   Learn lists targets as "Foundry Agents (prompt and container agents)" but Azure-Samples/foundry-hosted-agentframework-demos says
#   "Hosted-agent cloud red teaming is not supported yet for Foundry hosted agents."
# Derived from (verbatim API usage):
#   https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/evaluations/sample_redteam_evaluations.py
#   https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/evaluations/sample_scheduled_evaluations.py (shared helpers)
#   https://github.com/Azure-Samples/get-started-with-ai-agents/blob/main/tests/test_red_teaming.py (same pattern; num_turns 1; report_url)
# Verify against source before running: https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/evaluations/sample_redteam_evaluations.py
#   `_get_tool_descriptions` and `_to_json_primitive` are omitted from the abbreviated sample; this kit returns [] for the tool-less prompt
#   agent and writes output items with a plain str() fallback.
# The OTHER official red-team surface — samples/red_team/sample_red_team.py — uses `project_client.beta.red_teams.create(...)` against a
# MODEL DEPLOYMENT (AzureOpenAIModelConfiguration + model-endpoint/model-api-key headers), not an agent; REST: POST /redTeams/runs:run with
# header Foundry-Features: RedTeams=V1Preview. Use it only if you want to show model-level scans.
# Status: Build > Red teaming = GA (Foundry GA readiness table); the evals-based agent target uses preview surfaces where marked.
#
# USAGE: python 05-evaluation/red_team_prompt_agent.py
# ENV: FOUNDRY_PROJECT_ENDPOINT, FOUNDRY_AGENT_NAME

import json
import os
import time
from typing import Union
from dotenv import load_dotenv
from azure.identity import AzureCliCredential
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    AgentVersionDetails,
    AzureAIDataSourceConfig,
    EvaluationTaxonomy,
    AzureAIAgentTarget,
    AgentTaxonomyInput,
    TestingCriterionAzureAIEvaluator,
    RedTeamEvalRunDataSource,
    RiskCategory,
)

load_dotenv()


def _get_agent_safety_evaluation_criteria():
    return [
        TestingCriterionAzureAIEvaluator(
            type="azure_ai_evaluator",
            name="Prohibited Actions",
            evaluator_name="builtin.prohibited_actions",
            evaluator_version="1",
        ),
        TestingCriterionAzureAIEvaluator(
            type="azure_ai_evaluator",
            name="Task Adherence",
            evaluator_name="builtin.task_adherence",
            evaluator_version="1",
        ),
        TestingCriterionAzureAIEvaluator(
            type="azure_ai_evaluator",
            name="Sensitive Data Leakage",
            evaluator_name="builtin.sensitive_data_leakage",
            evaluator_version="1",
        ),
    ]


def _get_tool_descriptions(agent_version: AgentVersionDetails):
    # The abbreviated official sample omits this helper body; the demo prompt agent has no tools. Verify against source.
    return []


def _to_json_primitive(value):
    # The abbreviated official sample omits this helper; use a minimal fallback so output items can be written to disk.
    try:
        return json.loads(json.dumps(value, default=str))
    except TypeError:
        return str(value)


def main():
    endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
    agent_name = os.environ.get("FOUNDRY_AGENT_NAME", "zava-returns-assistant")

    with (
        AzureCliCredential(process_timeout=60) as credential,
        AIProjectClient(endpoint=endpoint, credential=credential) as project_client,
        project_client.get_openai_client() as client,
    ):
        agent_version = project_client.agents.get_version(
            agent_name=agent_name, agent_version=project_client.agents.get(agent_name).versions.latest.version
        )

        eval_group_name = "Red Team Agent Safety Evaluation -" + str(int(time.time()))
        eval_run_name = f"Red Team Agent Safety Eval Run for {agent_name} -" + str(int(time.time()))
        data_source_config = AzureAIDataSourceConfig(type="azure_ai_source", scenario="red_team")

        testing_criteria = _get_agent_safety_evaluation_criteria()
        eval_object = client.evals.create(
            name=eval_group_name,
            data_source_config=data_source_config,
            testing_criteria=testing_criteria,
        )
        print(f"Red team evaluation created: {eval_group_name}")

        risk_categories_for_taxonomy: list[Union[str, RiskCategory]] = [RiskCategory.PROHIBITED_ACTIONS]
        target = AzureAIAgentTarget(
            name=agent_name, version=agent_version.version, tool_descriptions=_get_tool_descriptions(agent_version)
        )
        agent_taxonomy_input = AgentTaxonomyInput(risk_categories=risk_categories_for_taxonomy, target=target)
        print("Creating Eval Taxonomies")
        eval_taxonomy_input = EvaluationTaxonomy(
            description="Taxonomy for red teaming evaluation", taxonomy_input=agent_taxonomy_input
        )
        taxonomy = project_client.beta.evaluation_taxonomies.create(name=agent_name, taxonomy=eval_taxonomy_input)

        print("Creating red teaming Eval Run")
        eval_run_response = client.evals.runs.create(
            eval_id=eval_object.id,
            name=eval_run_name,
            data_source=RedTeamEvalRunDataSource(
                type="azure_ai_red_team",
                item_generation_params={
                    "type": "red_team_taxonomy",
                    "attack_strategies": ["Flip", "Base64"],
                    "num_turns": 1,  # number of interaction turns per item (5 in the SDK sample; 1 keeps the demo short)
                    "source": {"type": "file_id", "id": taxonomy.id},
                },
                target=target.as_dict(),
            ),
        )
        print(f"Eval Run created for red teaming: {eval_run_name}")

        while True:
            run = client.evals.runs.retrieve(run_id=eval_run_response.id, eval_id=eval_object.id)
            if run.status in ("completed", "failed"):
                output_items = list(client.evals.runs.output_items.list(run_id=run.id, eval_id=eval_object.id))
                output_items_path = os.path.join(os.getcwd(), f"redteam_eval_output_items_{agent_name}.json")
                with open(output_items_path, "w", encoding="utf-8") as f:
                    f.write(json.dumps(_to_json_primitive(output_items), indent=2))
                print(
                    f"RedTeam Eval Run completed with status: {run.status}. Output items written to {output_items_path}"
                )
                break
            time.sleep(5)
            print(f"Waiting for eval run to complete... {run.status}")

        if run.result_counts.failed > 0:
            print(f"Failed items: {run.result_counts.failed}. Some vulnerability has been exposed by red-teaming attacks in your application.")
        print("Review evaluation results in this report:")
        print(f"{run.report_url}\n")
        print("Portal: Build > Agents > agent > Monitor tab (red-teaming data); Operate > Assets > agent > Active alerts.")


if __name__ == "__main__":
    main()
