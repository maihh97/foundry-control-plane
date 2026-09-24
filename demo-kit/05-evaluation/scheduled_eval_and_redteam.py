# Foundry Control Plane demo kit — 05 scheduled dataset evaluation AND scheduled red-team run (beta.schedules, Preview)
# Derived from (verbatim API usage):
#   https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/evaluations/sample_scheduled_evaluations.py
#   https://ai.azure.com/api-reference/llm/schedules/create-or-update.md  (PUT /schedules/{id}; header Foundry-Features: Schedules=V1Preview -> preview)
# Verify against source before running: https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/samples/evaluations/sample_scheduled_evaluations.py
#   This sample keeps the published imports, assign_rbac() key lines, both schedule bodies, and _get_agent_safety_evaluation_criteria()
#   verbatim, but ELIDED: (1) the dataset upload that yields `dataset.id`, and (2) the `_get_tool_descriptions(agent_version)` helper.
#   This kit therefore (1) reads DATASET_FILE_ID from env instead of uploading, and (2) defines _get_tool_descriptions() to return []
#   for the tool-less prompt agent — confirm both against the source file.
# Install (sample docstring): pip install "azure-ai-projects>=2.0.0" python-dotenv azure-mgmt-authorization azure-mgmt-resource
# Changes vs the sample: targets the existing prompt agent; the sample's `schedules.delete(...)` teardown is REMOVED so the schedules
# stay visible in Build > Agents > <agent> > Monitor > gear icon (Recurring evaluations / Red team scans).
# Red-team caveat: run against the PROMPT agent; hosted-agent cloud red teaming is not consistently documented.
#
# USAGE: python 05-evaluation/scheduled_eval_and_redteam.py [--skip-dataset] [--skip-redteam]
# ENV: FOUNDRY_PROJECT_ENDPOINT, FOUNDRY_MODEL_NAME, FOUNDRY_AGENT_NAME, DATASET_FILE_ID (for the dataset schedule)

import argparse
import os
import time
from pprint import pprint
from typing import Union
from dotenv import load_dotenv
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    AgentVersionDetails,
    AzureAIDataSourceConfig,
    EvaluationTaxonomy,
    AzureAIAgentTarget,
    AgentTaxonomyInput,
    TestingCriterionAzureAIEvaluator,
    RedTeamEvalRunDataSource,
    Schedule,
    RecurrenceTrigger,
    DailyRecurrenceSchedule,
    EvaluationScheduleTask,
    RiskCategory,
)
from openai.types.evals.create_eval_jsonl_run_data_source_param import CreateEvalJSONLRunDataSourceParam, SourceFileID
from openai.types.eval_create_params import DataSourceConfigCustom

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
        TestingCriterionAzureAIEvaluator(
            type="azure_ai_evaluator",
            name="Self Harm",
            evaluator_name="builtin.self_harm",
            evaluator_version="1",
        ),
        TestingCriterionAzureAIEvaluator(
            type="azure_ai_evaluator",
            name="Violence",
            evaluator_name="builtin.violence",
            evaluator_version="1",
        ),
        TestingCriterionAzureAIEvaluator(
            type="azure_ai_evaluator", name="Sexual", evaluator_name="builtin.sexual", evaluator_version="1"
        ),
        TestingCriterionAzureAIEvaluator(
            type="azure_ai_evaluator",
            name="Hate Unfairness",
            evaluator_name="builtin.hate_unfairness",
            evaluator_version="1",
        ),
    ]


def _get_tool_descriptions(agent_version: AgentVersionDetails):
    # The abbreviated official sample omits this helper body. The demo prompt agent has no tools.
    # Verify against source before running.
    return []


def schedule_dataset_evaluation(project_client: AIProjectClient, client, dataset_file_id: str):
    data_source_config = DataSourceConfigCustom(
        type="custom",
        item_schema={
            "type": "object",
            "properties": {
                "query": {"type": "string"},
                "response": {"type": "string"},
                "context": {"type": "string"},
                "ground_truth": {"type": "string"},
            },
            "required": [],
        },
        include_sample_schema=True,
    )

    testing_criteria = [
        TestingCriterionAzureAIEvaluator(
            type="azure_ai_evaluator",
            name="violence",
            evaluator_name="builtin.violence",
            data_mapping={"query": "{{item.query}}", "response": "{{item.response}}"},
            initialization_parameters={"model": "{{aoai_deployment_and_model}}"},
        ),
        TestingCriterionAzureAIEvaluator(type="azure_ai_evaluator", name="f1", evaluator_name="builtin.f1_score"),
        TestingCriterionAzureAIEvaluator(
            type="azure_ai_evaluator",
            name="coherence",
            evaluator_name="builtin.coherence",
            initialization_parameters={"model": "{{aoai_deployment_and_model}}"},
        ),
    ]

    print("Creating evaluation")
    eval_object = client.evals.create(
        name="Zava Returns Assistant - scheduled dataset evaluation",
        data_source_config=data_source_config,  # type: ignore
        testing_criteria=testing_criteria,  # type: ignore
    )

    # NOTE: the full sample uploads a dataset here and uses `dataset.id`; that block is omitted from this abbreviated example.
    # Provide the uploaded dataset's file id via DATASET_FILE_ID (see .env.example) — e.g. the dataset registered from 08-cicd/data.
    eval_run_object = {
        "eval_id": eval_object.id,
        "name": "dataset_id_run",
        "metadata": {"team": "zava-returns-demo", "scenario": "dataset-id-v1"},
        "data_source": CreateEvalJSONLRunDataSourceParam(
            type="jsonl", source=SourceFileID(type="file_id", id=dataset_file_id if dataset_file_id else "")
        ),
    }

    print("Eval Run:")
    pprint(eval_run_object)
    print("Creating Schedule for dataset evaluation")
    schedule = Schedule(
        display_name="Dataset Evaluation Eval Run Schedule",
        enabled=True,
        trigger=RecurrenceTrigger(interval=1, schedule=DailyRecurrenceSchedule(hours=[9])),  # Every day at 9 AM
        task=EvaluationScheduleTask(eval_id=eval_object.id, eval_run=eval_run_object),
    )
    schedule_response = project_client.beta.schedules.create_or_update(
        schedule_id="zava-returns-dataset-eval-run-schedule-9am", schedule=schedule
    )

    print(f"Schedule created for dataset evaluation: {schedule_response.schedule_id}")
    pprint(schedule_response)

    time.sleep(5)  # Wait for schedule to be fully created
    schedule_runs = project_client.beta.schedules.list_runs(schedule_response.schedule_id)
    print(f"Listing schedule runs for schedule id: {schedule_response.schedule_id}")
    for run in schedule_runs:
        pprint(run)


def schedule_redteam_evaluation(project_client: AIProjectClient, client, agent_name: str):
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

    eval_run_object = {
        "eval_id": eval_object.id,
        "name": eval_run_name,
        "data_source": RedTeamEvalRunDataSource(
            type="azure_ai_red_team",
            item_generation_params={
                "type": "red_team_taxonomy",
                "attack_strategies": ["Flip", "Base64"],
                "num_turns": 5,
                "source": {"type": "file_id", "id": taxonomy.id},
            },
            target=target.as_dict(),
        ),
    }

    print("Creating Schedule for RedTeaming Eval Run")
    schedule = Schedule(
        display_name="RedTeam Eval Run Schedule",
        enabled=True,
        trigger=RecurrenceTrigger(interval=1, schedule=DailyRecurrenceSchedule(hours=[9])),  # Every day at 9 AM
        task=EvaluationScheduleTask(eval_id=eval_object.id, eval_run=eval_run_object),
    )
    schedule_response = project_client.beta.schedules.create_or_update(
        schedule_id="zava-returns-redteam-eval-run-schedule-9am", schedule=schedule
    )
    print(f"Schedule created for red teaming: {schedule_response.schedule_id}")
    pprint(schedule_response)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--skip-dataset", action="store_true")
    parser.add_argument("--skip-redteam", action="store_true")
    args = parser.parse_args()

    endpoint = os.environ["FOUNDRY_PROJECT_ENDPOINT"]
    agent_name = os.environ.get("FOUNDRY_AGENT_NAME", "zava-returns-assistant")
    dataset_file_id = os.environ.get("DATASET_FILE_ID", "")

    with (
        DefaultAzureCredential() as credential,
        AIProjectClient(endpoint=endpoint, credential=credential) as project_client,
        project_client.get_openai_client() as client,
    ):
        # RBAC: the sample's assign_rbac() grants the project managed identity "Azure AI User" (id 53ca6127-db72-4b80-b1b0-d745d6d5456d)
        # at project scope via AuthorizationManagementClient (ARM api_version 2025-06-01). Do this once in the portal (IAM) or via the sample.
        if not args.skip_dataset:
            if not dataset_file_id:
                print("DATASET_FILE_ID not set — skipping the dataset schedule (see header note).")
            else:
                schedule_dataset_evaluation(project_client, client, dataset_file_id)
        if not args.skip_redteam:
            schedule_redteam_evaluation(project_client, client, agent_name)

    print("Portal: Build > Agents > agent > Monitor > gear icon > Recurring evaluations (preview) / Red team scans (preview).")


if __name__ == "__main__":
    main()
