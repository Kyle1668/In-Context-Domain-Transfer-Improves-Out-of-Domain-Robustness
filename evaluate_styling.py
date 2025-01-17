from datetime import datetime, timedelta
import torch.distributed as dist
import pandas as pd
import traceback
import argparse
import random
import numpy as np
import transformers
import torch
import wandb
import time
import json
import os

from adaptive_methods import evaluate_test_time_augmentation, evaluate_style_transfer, evaluate_fine_tuning, evaluate_memo, evaluate_without_adaptation
from util_data import get_formatted_dataset, get_num_labels
from util_modeling import get_model_objects, is_large_language_model



def parse_arguments() -> argparse.Namespace:
    """Parse command line arguments.

    `--seed`: Set the random seed for reproducibility.
    `--dataset`: The HuggingFace or custom supported dataset to evaluate on.
    `--model`: The HuggingFace `AutoModelForSequenceClassification` model trained on the original distribution.
    `--splits`: The splits of the dataset to evaluate on. If not specified, all splits will be evaluated.
    `--baseline`: The baselines to evaluate. If not specified, all baselines will be evaluated. Supported baselines are: `fine-tuning`, `test_time_augmentation`, `memo`, `skip`.
    `--icl_method`: The ICL method to use for style transfer. If not specified, all ICL methods will be evaluated. Supported ICL methods are: `random`, `topk_nearest`.
    `--temperature`: The temperature to use for style transfer. If not specified, 0.0 and 0.7 are evaluated.
    `--num_shots`: The number of shots to use for style transfer. If not specified, 32, 16, and 8 are evaluated.
    `--adaptive_model`: The HuggingFace LLM that will rewrite each example. Multiple models can be specified by separating them with a comma.
    `--max_examples`: The maximum number of examples to evaluate on. If not specified, all examples will be evaluated.
    `--use_wandb`: Whether to use wandb to log results.
    `--skip_eval_styling`: Whether to skip evaluating the style transfer methods.
    `--skip_style_model_eval`: Whether to skip evaluating the style transfer models.
    `--evaluate_id_adaptation`: Whether to evaluate the style transfer models on the in-dsitribution test set.
    `--transfer_prompt`: The transfer prompt to use for style transfer.
    """

    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--dataset", type=str, default=None)
    parser.add_argument("--model", type=str, default=None)
    parser.add_argument("--splits", type=str, default=None)
    parser.add_argument("--baseline", type=str, default="skip")
    parser.add_argument("--icl_method", type=str, default=None)
    parser.add_argument("--temperature", type=str, default=None)
    parser.add_argument("--num_shots", type=str, default=None)
    parser.add_argument("--trim_exemplars", action="store_true")
    parser.add_argument("--adaptive_model", type=str, default=None)
    parser.add_argument("--max_examples", type=int, default=None)
    parser.add_argument("--use_wandb", action="store_true")
    parser.add_argument("--skip_eval_styling", action="store_true")
    parser.add_argument("--skip_style_model_eval", action="store_true")
    parser.add_argument("--evaluate_id_adaptation", action="store_true")
    parser.add_argument("--transfer_prompt", type=str, default="domain_transfer_no_aug_tasks_v5")
    return parser.parse_args()


def init_distributed(rank: int, world_size: int):
    """Initializes torch distributed group

    Args:
        rank (int): Rank of current process
        world size (int): Total number of processes
    """
    print(f"Initializing distributed group with rank {rank} and world size {world_size}")
    dist.init_process_group(backend="nccl", timeout=timedelta(minutes=180), rank=rank, world_size=world_size)
    torch.cuda.set_device(rank)


def main():
    args = parse_arguments()
    rank = int(os.environ.get("RANK", "0"))
    world_size = int(os.environ.get("WORLD_SIZE", "-1"))
    if world_size == -1:
        print("Running without distributed inference")
    else:
        init_distributed(rank, world_size)

    # Set random seeds
    random.seed(args.seed)
    np.random.seed(args.seed)
    torch.manual_seed(args.seed)

    # Create expeirment directory
    experiment_id = f"{datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}_{args.dataset}_{args.model.replace('/', '-')}_seed={args.seed}"
    time.sleep(5)
    if rank == 0:
        if not os.path.exists("results"):
            os.mkdir("results")
        if not os.path.exists(f"results/{experiment_id}"):
            os.mkdir(f"results/{experiment_id}")
            json.dump(vars(args), open(f"results/{experiment_id}/args.json", "w", encoding="utf-8"), indent=4)

    dataset_names = (
        args.dataset.split(",")
        if args.dataset is not None
        else [
            "squadshifts_reddit",
            "squadshifts_amazon",
            "imdb_rotten_tomatoes",
            "rotten_tomatoes_imdb",
            "civil_toxigen",
            "scotus",
            "ag_news",
            "wilds_amazon",
            "wilds_civil_comments",
        ]
    )
    icl_methods = args.icl_method.split(",") if args.icl_method is not None else ["random", "topk_nearest"]
    domain_transfer_temperatures = [float(char) for char in args.temperature.split(",")] if args.temperature is not None else [0.3]
    num_shots = [int(char) for char in args.num_shots.split(",")] if args.num_shots is not None else [32, 0]
    splits = args.splits.split(",") if args.splits is not None else None
    adaptive_model_names = (
        args.adaptive_model.split(",")
        if args.adaptive_model is not None
        else [
            "Salesforce/xgen-7b-8k-inst",
            "TheBloke/vicuna-7B-1.1-HF",
         ]
    )
    baselines = args.baseline.split(",") if args.baseline is not None else [] if args.baseline == "skip" else ["fine-tuning", "test_time_augmentation", "memo"]

    model_names = (
        args.model.split(",")
        if args.model is not None
        else [
            "csarron/bert-base-uncased-squad-v1",
            "TheBloke/vicuna-13B-1.1-HF",
            "decapoda-research/llama-65b-hf",
            "decapoda-research/llama-30b-hf",
            "decapoda-research/llama-7b-hf",
            "EleutherAI/pythia-2.8b",
            "EleutherAI/pythia-1b",
            "EleutherAI/pythia-410m",
            "tomh/toxigen_roberta",
        ]
    )

    # Evalaute with baselines
    adaptive_methods = ["No Adaptation"] + [method for method in baselines if method != "skip"] + ([] if args.skip_eval_styling else adaptive_model_names)

    if rank == 0:
        print("--------------------------------------------------")
        print("Running experiment with the following parameters:")
        print(f"Experiment ID: {experiment_id}")
        print(f"Dataset Names: {dataset_names}")
        print(f"ICL Methods: {icl_methods}")
        print(f"Task Model Names: {model_names}")
        print(f"Style Model Names: {adaptive_model_names}")
        print(f"Max Examples: {args.max_examples}")
        print(f"Transformers version: {transformers.__version__}")
        print(args)
        print("--------------------------------------------------\n")

    wandb_run = None
    if rank == 0:
        wandb_enabled = args.use_wandb
        if wandb_enabled:
            wandb_config = {
                "dataset_names": dataset_names,
                "icl_methods": icl_methods,
                "task_model_names": model_names,
                "style_model_names": adaptive_model_names,
                "max_examples": args.max_examples,
                "baslines": baselines,
                "adaptive_methods": adaptive_methods,
            }
            project_name = "In-Context Domain Transfer Improves Out-of-Domain Robustness"
            wandb_run = wandb.init(project=project_name, name=experiment_id, config=wandb_config)

    reports = []
    try:
        for dataset_name in dataset_names:
            print(f"Loading dataset {dataset_name}...")
            dataset = get_formatted_dataset(dataset_name, max_examples=args.max_examples)
            splits = splits if splits is not None else [split for split in dataset.keys() if split != "train"]

            for model_name in model_names:
                print(f"Loading model {model_name}...")
                num_labels = get_num_labels(dataset_name)
                tokenizer, model = get_model_objects(model_name, num_labels)
                adaptive_tokenizer = adaptive_model = None
                is_llm = is_large_language_model(model_name)

                for evaluation_set in splits:
                    for icl_method in icl_methods if is_llm else ["static"]:
                        # Evaluate style model on the task
                        if not args.skip_style_model_eval:
                            for adaptive_model_name in adaptive_model_names:
                                for style_icl_method in icl_methods:
                                    for shots in num_shots:
                                        if adaptive_model is None:
                                            adaptive_tokenizer, adaptive_model = get_model_objects(adaptive_model_name, num_labels)

                                        current_report = evaluate_without_adaptation(
                                            rank, world_size, experiment_id, adaptive_model_name, adaptive_model, adaptive_tokenizer, dataset_name, dataset, style_icl_method, evaluation_set, shots
                                        )
                                        if rank == 0:
                                            reports.append(current_report)
                                            all_reports = pd.DataFrame(reports).drop_duplicates()
                                            print(all_reports[["dataset", "split", "task model", "icl_method", "exemplar count", "style transfer model", "dataset size", "accuracy"]])
                                            all_reports.to_csv(f"results/{experiment_id}/reports.csv", index=False)
                                            if wandb_enabled:
                                                wandb.log(current_report)
                                                wandb_run.log({"reports": wandb.Table(dataframe=all_reports)})

                                            adaptive_tokenizer = None
                                            adaptive_model = None

                        if args.evaluate_id_adaptation or evaluation_set not in ["validation"]:
                            for adaptive_method in adaptive_methods:
                                if adaptive_method == "No Adaptation":
                                    # Evaluate the task model
                                    for shot_count in [16] if is_llm else [0]:
                                        current_report = evaluate_without_adaptation(rank, world_size, experiment_id, model_name, model, tokenizer, dataset_name, dataset, icl_method, evaluation_set, shot_count)
                                        if rank == 0:
                                            reports.append(current_report)
                                            all_reports = pd.DataFrame(reports).drop_duplicates()
                                            print(all_reports[["dataset", "split", "task model", "icl_method", "exemplar count", "style transfer model", "dataset size", "accuracy"]])
                                            all_reports.to_csv(f"results/{experiment_id}/reports.csv", index=False)
                                            if wandb_enabled:
                                                wandb.log(current_report)
                                                wandb_run.log({"reports": wandb.Table(dataframe=all_reports)})
                                else:
                                    for style_icl_method in icl_methods:
                                        is_icr = adaptive_method != "No Adaptation" and not adaptive_method.startswith("aug")
                                        for shots in num_shots if is_icr else [16]:
                                            is_zero_shot = shots == 0
                                            is_first_icl_run = style_icl_method == icl_methods[0]
                                            if is_zero_shot and not is_first_icl_run:
                                                continue

                                            print(f"Evaluating style transfer with {shots} shots")

                                            for temperature in domain_transfer_temperatures:
                                                transfer_prompt = args.transfer_prompt
                                                if is_zero_shot:
                                                    if temperature != domain_transfer_temperatures[0]:
                                                        continue
                                                    transfer_prompt = "baseline_zero_shot"

                                                rewriting_report = evaluate_style_transfer(
                                                    rank,
                                                    world_size,
                                                    args.seed,
                                                    experiment_id,
                                                    model_name,
                                                    model,
                                                    tokenizer,
                                                    dataset_name,
                                                    dataset,
                                                    style_icl_method,
                                                    evaluation_set,
                                                    adaptive_method,
                                                    shots,
                                                    bool(args.trim_exemplars),
                                                    temperature,
                                                    transfer_prompt,
                                                )

                                                if rank == 0:
                                                    style_inference_log_frame, current_reports = rewriting_report

                                                    for report in current_reports:
                                                        reports.append(report)

                                                    all_reports = pd.DataFrame(reports).drop_duplicates()
                                                    print(
                                                        all_reports[
                                                            ["dataset", "split", "task model", "icl_method", "exemplar count", "trim exemplars", "style transfer model", "dataset size", "inference method", "accuracy"]
                                                        ]
                                                    )
                                                    all_reports.to_csv(f"results/{experiment_id}/reports.csv", index=False)
                                                    if wandb_enabled:
                                                        wandb.log(current_report)
                                                        wandb_run.log({"reports": wandb.Table(dataframe=all_reports)})
                                                        wandb_run.log({f"{evaluation_set}_{adaptive_method}_{style_icl_method}_{shots}_{model_name}_style_logs": wandb.Table(dataframe=style_inference_log_frame)})
                        else:
                            if is_llm:
                                for shots in [16]:
                                    current_report = evaluate_without_adaptation(rank, world_size, experiment_id, model_name, model, tokenizer, dataset_name, dataset, icl_method, evaluation_set, num_shots=shots)
                                    if rank == 0:
                                        reports.append(current_report)
                                        all_reports = pd.DataFrame(reports).drop_duplicates()
                                        print(all_reports[["dataset", "split", "task model", "icl_method", "exemplar count", "style transfer model", "dataset size", "accuracy"]])
                                        all_reports.to_csv(f"results/{experiment_id}/reports.csv", index=False)
                                        if wandb_enabled:
                                            wandb.log(current_report)
                                            wandb_run.log({"reports": wandb.Table(dataframe=all_reports)})
                            else:
                                current_report = evaluate_without_adaptation(rank, world_size, experiment_id, model_name, model, tokenizer, dataset_name, dataset, "static", evaluation_set)
                                if rank == 0:
                                    reports.append(current_report)
                                    all_reports = pd.DataFrame(reports).drop_duplicates()
                                    print(all_reports[["dataset", "split", "task model", "icl_method", "exemplar count", "style transfer model", "dataset size", "accuracy"]])
                                    all_reports.to_csv(f"results/{experiment_id}/reports.csv", index=False)
                                    if wandb_enabled:
                                        wandb.log(current_report)
                                        wandb_run.log({"reports": wandb.Table(dataframe=all_reports)})
    except Exception as e:
        detailed_exception_dict = {
            "error": str(e),
            "traceback": traceback.format_exc(),
        }
        if wandb_run is not None:
            crash_table = wandb.Table(columns=["error", "traceback"])
            crash_table.add_data(detailed_exception_dict["error"], detailed_exception_dict["traceback"])
            wandb_run.log({"crash": crash_table})
            wandb_run.finish(exit_code=1)     

        print("An exception occurred while running the experiment. The exception has been logged to wandb.")
        print(json.dumps(detailed_exception_dict, indent=4))   


if __name__ == "__main__":
    main()
