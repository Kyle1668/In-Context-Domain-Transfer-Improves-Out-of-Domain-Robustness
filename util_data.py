from sklearn.metrics import classification_report, confusion_matrix, ConfusionMatrixDisplay
from datasets import load_dataset, Dataset, DatasetDict
from util_metrics import SquadMetrics
from datasets import load_dataset
from wilds import get_dataset
from tqdm import tqdm
import plotly.express as px
import pandas as pd
import numpy as np
import json
import os


def qa_report(model_answers, gold_answers):
    f1s = ems = []
    for model_answer, gold_answer in zip(model_answers, gold_answers):
        f1s.append(SquadMetrics.f1_score(model_answer, gold_answer))
        ems.append(SquadMetrics.exact_match_score(model_answer, gold_answer))

    mean_f1 = np.mean(f1s)
    exact_match_rate = np.sum(ems) / len(ems)
    return {"f1-score": mean_f1, "exact match rate": exact_match_rate}


def get_split_log_name(eval_set, adaptive_method_name):
    if eval_set == "validation":
        return "In-Distribution"
    elif "Test-Time Augmentation" in adaptive_method_name:
        return adaptive_method_name.replace("Test-Time Augmentation", "OOD w/ TTA")
    elif "MEMO" in adaptive_method_name:
        return adaptive_method_name.replace("MEMO", "OOD w/ MEMO")
    elif adaptive_method_name == "Fine-Tuning":
        return "OOD w/ Fine-Tuning"
    elif adaptive_method_name == "MEMO":
        return "OOD w/ MEMO"
    elif adaptive_method_name == "No Adaptation":
        return "OOD"
    else:
        return "OOD w/ Style Transfer"


def generate_evaluation_Report(experiment_id, model_name, dataset_name, icl_method, eval_set, dataset, inference_log_frame, adaptive_method_name, num_shots=None, num_failed_generations=None, trim_exemplars=None, temperature=None, inference_method=None):
    formatted_model_name = model_name.replace("/", "-")
    output_file_name = f"set={dataset_name}_split={eval_set}_method={icl_method}_model={formatted_model_name}"
    experiment_directory = f"results/{experiment_id}"
    if not os.path.exists(experiment_directory):
        os.makedirs(experiment_directory)

    original_judgments = None
    rewrite_rate = None
    if inference_method == "entropy threshold best":
        original_judgments, rewrite_rate = calculate_entropy_threshold_jugments(inference_log_frame, output_file_name, experiment_directory)
    elif inference_method == "entropy threshold half":
        original_judgments, rewrite_rate = calculate_entropy_threshold_jugments(inference_log_frame, output_file_name, experiment_directory, half=True)
    elif inference_method == "lowest entropy":
        rewrite_rate = 1.0
        original_judgments = inference_log_frame.apply(lambda row: np.array(row["all probs"][np.array(row["all entropies"]).argmin().item()]).argmax().item(), axis=1)
    elif inference_method == "entropy threshold+lowest":
        threshold_judgments, rewrite_rate = calculate_entropy_threshold_jugments(inference_log_frame, output_file_name, experiment_directory)
        lowest_entropy_judgments = inference_log_frame.apply(lambda row: np.array(row["all probs"][np.array(row["all entropies"]).argmin().item()]).argmax().item(), axis=1)
        original_judgments = []
        for index, row in inference_log_frame.iterrows():
            if threshold_judgments[index] != row["original judgment"]:
                original_judgments.append(lowest_entropy_judgments[index])
            else:
                original_judgments.append(threshold_judgments[index])
    elif inference_method == "single rewrite":
        if "all probs" in inference_log_frame.columns:
            original_judgments = inference_log_frame.apply(lambda row: np.array(row["all probs"][0]).argmax().item(), axis=1)
        else:
            original_judgments = inference_log_frame.apply(lambda row: row["predicted_classes"][0] if isinstance(row["predicted_classes"], list) else -1 if str(row["predicted_classes"]) == "nan" else row["predicted_classes"], axis=1).values
    else:
        rewrite_rate = None if adaptive_method_name == "No Adaptation" else 1.0
        original_judgments = [judgment for judgment, logits in inference_log_frame["judgment"]] if isinstance(inference_log_frame["judgment"][0], tuple) else inference_log_frame["judgment"]

    gold_labels = inference_log_frame["label"]
    is_qa_task = dataset_name.startswith("squad")
    report_dict = qa_report(original_judgments, gold_labels) if is_qa_task else classification_report(gold_labels, original_judgments, output_dict=True)
    formatted_split_name = get_split_log_name(eval_set, adaptive_method_name)

    icl_report = {
        "dataset": dataset_name,
        "split": formatted_split_name,
        "dataset size": len(dataset[eval_set.replace("+adaptive", "")]),
        "inference method": inference_method,
        "icl_method": icl_method,
        "task model": formatted_model_name,
        "style transfer model": adaptive_method_name if "original_input" in inference_log_frame.columns else None,
        "exemplar count": num_shots,
        "temperature": temperature,
        "trim exemplars": trim_exemplars,
        "accuracy": report_dict["accuracy"] if not is_qa_task else None,
        "avg precision": report_dict["macro avg"]["precision"] if not is_qa_task else None,
        "avg recall": report_dict["macro avg"]["recall"] if not is_qa_task else None,
        "avg f1": report_dict["macro avg"]["f1-score"] if not is_qa_task else report_dict["f1-score"],
        "rewrite rate": rewrite_rate,
        "avg latency": round(inference_log_frame["latency"].mean(), 3),
        "num failed generations": num_failed_generations,
        "exact match rate": report_dict["exact match rate"] if is_qa_task else None,
    }

    if eval_set == "prod":
        json.dump(icl_report, open(f"results/{experiment_id}/{output_file_name}_report.json", "w+"), indent=4)
        print(f"Classification Results: {formatted_model_name} {dataset_name} {icl_method}")
        print(classification_report(data_reader.references, original_judgments))
        confusion_matrix_fig = ConfusionMatrixDisplay(confusion_matrix=confusion_matrix(data_reader.references, original_judgments))
        confusion_matrix_fig.figure_.savefig(f"results/{experiment_id}/{output_file_name}_confusion_matrix.png")

    return icl_report


def calculate_entropy_threshold_jugments(inference_log_frame, output_file_name, experiment_directory, half=False):
    thresholds = np.arange(0, 1, 0.0005)
    threshold_scores = []
    threshold_rewrite_rates = []

    for t in tqdm(thresholds, desc="Calculating entropy threshold scores"):
        t_perf, t_rate = get_threshold_f1(t, inference_log_frame)
        threshold_scores.append(t_perf)
        threshold_rewrite_rates.append(t_rate)

    thresholds_frame = pd.DataFrame({"threshold": thresholds, "f1": threshold_scores, "rewrite_rate": threshold_rewrite_rates})
    thresholds_frame.to_csv(f"{experiment_directory}/{output_file_name}-entropy-f1-thresholds.csv", index=False)
    threshold_fscore_curve = px.line(thresholds_frame, x="rewrite_rate", y="f1", title="IMDB --> Rotten Tomatoes Rewrite-Rate-F1 Curve")
    threshold_fscore_curve.write_image(f"{experiment_directory}/{output_file_name}-entropy_threshold_fscore_curve.png")
    threshold_fscore_curve.write_html(f"{experiment_directory}/{output_file_name}-entropy_threshold_fscore_curve.html")

    target_threshold = None
    if half is False:
        target_threshold = thresholds_frame[thresholds_frame["f1"] == thresholds_frame.max()["f1"]].sort_values("rewrite_rate").iloc[-1]
    else:
        thresholds_deltas_list = abs(thresholds_frame["rewrite_rate"] - 50).tolist()
        closest_half_delta = min(thresholds_deltas_list)
        closest_threshold_index = thresholds_deltas_list.index(closest_half_delta)
        target_threshold = thresholds_frame.iloc[closest_threshold_index]
        # target_threshold = thresholds_frame[thresholds_frame["rewrite_rate"] == thresholds_frame["rewrite_rate"].median()].sort_values("f1").iloc[-1]

    rewrite_rate = target_threshold["rewrite_rate"] / 100
    original_judgments = inference_log_frame.apply(lambda row: row["original judgment"] if row["original entropy"] < target_threshold["threshold"] else row["judgment"], axis=1)
    return original_judgments, rewrite_rate


def get_threshold_f1(threshold, inference_logs_frame):
    threshold_judgments = inference_logs_frame.apply(lambda row: row["original judgment"] if row["original entropy"] < threshold else row["judgment"], axis=1)
    report = classification_report(inference_logs_frame["label"], threshold_judgments, digits=4, output_dict=True)
    llm_call_count = (inference_logs_frame["original entropy"] >= threshold).sum()
    llm_call_rate = 100 * llm_call_count / len(inference_logs_frame)
    return 100 * report["macro avg"]["f1-score"], llm_call_rate


def get_num_labels(dataset_name):
    dataset_num_labels = {
        "sst2": 2,
        "adv_sst2": 2,
        "imdb": 2,
        "squad": 1,
        "ag_news": 4,
        "ag_news_twitter": 4,
        "boss_sentiment": 3,
        "boss_toxicity": 2,
        "boss_nli": 3,
        "toxigen": 2,
        "disaster_tweets": 2,
        "wilds_civil_comments": 2,
        "civil_toxigen": 2,
        "rotten_tomatoes_imdb": 2,
        "imdb_rotten_tomatoes": 2,
        "wilds_amazon": 5,
        "scotus": 11,
    }
    return dataset_num_labels[dataset_name]


def get_formatted_dataset(set_name, max_examples=None):
    hf_paths = {"sst2": "sst2", "toxigen": "skg/toxigen-data", "disaster_tweets": "venetis/disaster_tweets"}
    hf_sets_columns_mappings = {
        "toxigen": ("prompt", "prompt_label"),
        "disaster_tweets": ("text", "target"),
        "amazon_polarity": ("content", "label"),
        "imdb": ("text", "label"),
        "adv_sst2": ("sentence", "label"),
        "sst2": ("sentence", "label"),
        "imdb_rotten_tomatoes": ("sentence", "label"),
        "ag_news": ("text", "label"),
        "squad": ("context", "answers", "question"),
        "ag_news_twitter": ("tweet summary", "label"),
        "boss_sentiment": ("Text", "Label"),
        "boss_nli": ("text", "Label"),
        "boss_toxicity": ("Text", "Label"),
    }

    hf_dataset = None
    hf_path = hf_paths[set_name] if set_name in hf_paths else set_name
    if set_name.startswith("wilds_"):
        hf_dataset = load_wilds_dataset(hf_path)
    elif is_corrupted_set := set_name.startswith("datasets/corruped/"):
        hf_dataset = load_corrupted_dataset(hf_path)
    elif set_name == "boss_sentiment":
        hf_dataset = load_boss_sentiment_task()
    elif set_name == "boss_toxicity":
        hf_dataset = load_boss_toxicity_task()
    elif set_name == "boss_nli":
        hf_dataset = load_boss_nli_task()
    elif set_name == "scotus":
        hf_dataset = load_scotus_dataset()
    elif set_name == "civil_toxigen":
        hf_dataset = load_civil_comments_and_toxigen_dataset()
    elif set_name == "adv_sst2":
        hf_dataset = load_adv_sst2()
    elif set_name == "ag_news_twitter":
        hf_dataset = load_ag_news_twitter()
    elif set_name == "rotten_tomatoes_imdb":
        hf_dataset = DatasetDict({"train": load_dataset("rotten_tomatoes", split="train"), "validation": load_dataset("rotten_tomatoes", split="test"), "test": load_dataset("imdb", split="test")})
    elif set_name == "imdb_rotten_tomatoes":
        hf_dataset = DatasetDict({"train": load_dataset("imdb", split="train"), "validation": load_dataset("imdb", split="test"), "test": load_dataset("sst2", split="validation")})
    elif set_name.startswith("squadshifts_"):
        test_set_name = set_name.split("_")[1]
        train_set = load_dataset("squad", split="train")
        validaiton_set = load_dataset("squad", split="validation")
        test_set = load_dataset("squadshifts", test_set_name, split="test")
        hf_dataset = DatasetDict({"train": train_set, "validation": validaiton_set, "test": test_set})
    else:
        hf_dataset = load_dataset(hf_path)

    is_qa_task = "squad" in set_name
    set_name = "squad" if set_name.startswith("squadshifts_") else set_name
    for split in hf_dataset.keys():
        if "text" not in hf_dataset[split][0].keys():
            hf_dataset[split] = hf_dataset[split].rename_column(hf_sets_columns_mappings[set_name][0], "text")
        if "label" not in hf_dataset[split][0].keys():
            hf_dataset[split] = hf_dataset[split].rename_column(hf_sets_columns_mappings[set_name][1], "label")
        if is_qa_task:
            # hf_dataset["train"] = hf_dataset["train"].rename_column(hf_sets_columns_mappings[set_name][2], "question")
            # hf_dataset["test"] = hf_dataset["test"].rename_column(hf_sets_columns_mappings[set_name][2], "question")
            # For Q&A tasks, the label columns may have multiple answers, so we need to convert them to a single answer
            # TODO: Verify best way to combine answers: " ".join(hf_dataset["test"][0]["label"]["text"])
            hf_dataset[split] = hf_dataset[split].map(lambda x: {"label": x["label"]["text"][0]})

    # Create a validation set from the same dist as the train set - if none already exist
    if "validation" not in hf_dataset.keys():
        train_set = hf_dataset["train"].to_pandas()
        validation_set = train_set.sample(frac=0.2)
        train_set = train_set.drop(validation_set.index)
        hf_dataset["train"] = Dataset.from_pandas(train_set)
        hf_dataset["validation"] = Dataset.from_pandas(validation_set)

    if max_examples is not None:
        for split in hf_dataset.keys():
            if max_examples >= len(hf_dataset[split]):
                print(f"WARNING: max_examples ({max_examples}) is greater than the number of examples in the {split} set ({len(hf_dataset[split])}).")
                continue

            new_frame = None
            split_frame = hf_dataset[split].to_pandas()
            if is_qa_task or is_corrupted_set:
                new_frame = split_frame.sample(max_examples)
            else:
                labels = split_frame["label"].unique()
                max_examples_per_label = max_examples // len(labels)
                for label in labels:
                    current_label_sample_size = max_examples_per_label if len(split_frame[split_frame["label"] == label]) > max_examples_per_label else len(split_frame[split_frame["label"] == label])
                    label_samples = split_frame[split_frame["label"] == label].sample(current_label_sample_size)
                    if new_frame is None:
                        new_frame = label_samples
                    else:
                        new_frame = pd.concat([new_frame, label_samples])

            new_frame = new_frame.sample(frac=1)
            new_frame = new_frame.drop(columns=["__index_level_0__"]) if "__index_level_0__" in new_frame.columns else new_frame
            hf_dataset[split] = Dataset.from_pandas(new_frame)


    return hf_dataset


def load_corrupted_dataset(set_name):
    corruped_set = pd.read_csv(set_name)
    train_set = corruped_set.iloc[:int(len(corruped_set) * 0.8)]
    validation_set = corruped_set.iloc[int(len(corruped_set) * 0.8):int(len(corruped_set) * 0.9)]
    test_set = corruped_set.iloc[int(len(corruped_set) * 0.9):]
    return DatasetDict({
        "train": Dataset.from_pandas(train_set),
        "validation": Dataset.from_pandas(validation_set),
        "test": Dataset.from_pandas(test_set)
    })


def load_boss_sentiment_task():
    """
    Boss sentiment ananlysis taks is composed of a single ID set and three OOD sets
    ID: Amazon Review Data (2018)
    OOD: DynaSent, SemEval, and SST
    """
    amazon_eval = pd.read_csv("datasets/boss_benchmark/SentimentAnalysis/amazon/test.tsv", sep="\t").dropna()
    amazon_train = pd.read_csv("datasets/boss_benchmark/SentimentAnalysis/amazon/train.tsv", sep="\t").dropna()
    dynasent = pd.read_csv("datasets/boss_benchmark/SentimentAnalysis/dynasent/test.tsv", sep="\t").dropna()
    semeval = pd.read_csv("datasets/boss_benchmark/SentimentAnalysis/semeval/test.tsv", sep="\t").dropna()
    sst5 = pd.read_csv("datasets/boss_benchmark/SentimentAnalysis/sst5/test.tsv", sep="\t").dropna()

    return DatasetDict(
        {
            "train": Dataset.from_pandas(amazon_train),
            "validation": Dataset.from_pandas(amazon_eval),
            "sst5": Dataset.from_pandas(sst5),
            "semval": Dataset.from_pandas(semeval),
            "dynasent": Dataset.from_pandas(dynasent),
        }
    )


def load_boss_toxicity_task():
    """
    Boss toxicity ananlysis taks is composed of a single ID set and three OOD sets
    ID: Civil Comments
    OOD: Adversarial Civil Comments, Implicit Hate, and Toxigen
    """
    civil_comments_train = pd.read_csv("datasets/boss_benchmark/ToxicDetection/civil_comments/train.tsv", sep="\t").dropna()
    civil_comments_eval = pd.read_csv("datasets/boss_benchmark/ToxicDetection/civil_comments/test.tsv", sep="\t").dropna()
    adv_civil = pd.read_csv("datasets/boss_benchmark/ToxicDetection/adv_civil/test.tsv", sep="\t").dropna()
    implicit_hate = pd.read_csv("datasets/boss_benchmark/ToxicDetection/implicit_hate/test.tsv", sep="\t").dropna()
    toxigen = pd.read_csv("datasets/boss_benchmark/ToxicDetection/toxigen/test.tsv", sep="\t").dropna()

    return DatasetDict(
        {
            "train": Dataset.from_pandas(civil_comments_train),
            "validation": Dataset.from_pandas(civil_comments_eval),
            "toxigen": Dataset.from_pandas(toxigen),
            "adv_civil": Dataset.from_pandas(adv_civil),
            "implicit_hate": Dataset.from_pandas(implicit_hate),
        }
    )


def load_boss_nli_task():
    """
    Boss natural language inference taks is composed of a single ID set and three OOD sets
    ID: MNLI
    OOD: ANLI, ContractNLI, WANLI
    """
    mnli_eval = pd.read_csv("datasets/boss_benchmark/NaturalLanguageInference/mnli/test.tsv", sep="\t").dropna()
    mnli_eval["text"] = mnli_eval["Premise"] + " / " + mnli_eval["Hypothesis"]
    mnli_train = pd.read_csv("datasets/boss_benchmark/NaturalLanguageInference/mnli/train.tsv", sep="\t").dropna()
    mnli_train["text"] = mnli_train["Premise"] + " / " + mnli_train["Hypothesis"]
    anli = pd.read_csv("datasets/boss_benchmark/NaturalLanguageInference/anli/test.tsv", sep="\t").dropna()
    anli["text"] = anli["Premise"] + " / " + anli["Hypothesis"]
    contract_nli = pd.read_csv("datasets/boss_benchmark/NaturalLanguageInference/contract_nli/test.tsv", sep="\t").dropna()
    contract_nli["text"] = contract_nli["Premise"] + " / " + contract_nli["Hypothesis"]
    wanli = pd.read_csv("datasets/boss_benchmark/NaturalLanguageInference/wanli/test.tsv", sep="\t").dropna()
    wanli["text"] = wanli["Premise"] + " / " + wanli["Hypothesis"]

    return DatasetDict(
        {
            "train": Dataset.from_pandas(mnli_train),
            "validation": Dataset.from_pandas(mnli_eval),
            "wanli": Dataset.from_pandas(wanli),
            "anli": Dataset.from_pandas(anli),
            "contractnli": Dataset.from_pandas(contract_nli),
        }
    )


def load_ag_news_twitter():
    ag_news = load_dataset("ag_news")
    tweets = load_dataset("Kyle1668/AG-Tweets")["test"].rename_column("tweet summary", "text")
    return DatasetDict({"train": ag_news["train"], "validation": ag_news["test"], "test": tweets})


def load_civil_comments_and_toxigen_dataset() -> DatasetDict:
    civil_comments = load_wilds_dataset("wilds_civil_comments")
    toxigen = load_dataset("skg/toxigen-data", "train", use_auth_token=True).rename_column("generation", "text").rename_column("prompt_label", "label")
    formatted_toxigen = toxigen["train"].map(lambda x: {"text": x["text"].replace("- ", "").split("\\n")[0]})
    return DatasetDict(
        {
            "train": formatted_toxigen,
            "test": civil_comments["test"],
        }
    )


def load_adv_sst2() -> DatasetDict:
    original_dist_train = load_dataset("sst2", split="train")
    original_dist_eval = load_dataset("sst2", split="validation")
    adversarial_dist = load_dataset("adv_glue", "adv_sst2")["validation"]
    return DatasetDict(
        {
            "train": original_dist_train,
            "validation": original_dist_eval,
            "test": adversarial_dist,
        }
    )


def load_scotus_dataset():
    train_set = pd.read_csv("datasets/scotus_train.csv")
    test_set = pd.read_csv("datasets/scotus_test.csv")
    full_dataset = DatasetDict()
    full_dataset["train"] = Dataset.from_pandas(train_set)
    full_dataset["test"] = Dataset.from_pandas(test_set)
    return full_dataset


def load_wilds_dataset(dataset_name):
    if dataset_name == "wilds_civil_comments":
        dataset = get_dataset(dataset="civilcomments", download=True)
        train_dict = {"text": [], "label": [], "group": []}
        for text, label, group in dataset.get_subset("train"):
            train_dict["text"].append(text)
            train_dict["label"].append(label.item())
            train_dict["group"].append(group.tolist())

        test_dict = {"text": [], "label": [], "group": []}
        for text, label, group in dataset.get_subset("test"):
            test_dict["text"].append(text)
            test_dict["label"].append(label.item())
            test_dict["group"].append(group.tolist())

        full_dataset = DatasetDict()
        full_dataset["train"] = Dataset.from_pandas(pd.DataFrame(train_dict))
        full_dataset["test"] = Dataset.from_pandas(pd.DataFrame(test_dict))
        return full_dataset
    elif dataset_name == "wilds_amazon":
        dataset = get_dataset(dataset="amazon", download=True)
        train_dict = {"text": [], "label": [], "group": []}
        for content, label, group in dataset.get_subset("train"):
            train_dict["text"].append(content)
            train_dict["label"].append(label.item())
            train_dict["group"].append(group.tolist())

        test_dict = {"text": [], "label": [], "group": []}
        for content, label, group in dataset.get_subset("test"):
            test_dict["text"].append(content)
            test_dict["label"].append(label.item())
            test_dict["group"].append(group.tolist())

        full_dataset = DatasetDict()
        full_dataset["train"] = Dataset.from_pandas(pd.DataFrame(train_dict))
        full_dataset["test"] = Dataset.from_pandas(pd.DataFrame(test_dict))
        return full_dataset
    else:
        raise Exception("Invalid WILDS dataset")
