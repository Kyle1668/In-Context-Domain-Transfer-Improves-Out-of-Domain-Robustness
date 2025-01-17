########## Configure Environment ##########

create_env:
	conda create -n llm-tta python=3.10

install_depends:
	pip install -r requirements.txt
	mkdir datasets; cd datasets && wget https://huggingface.co/datasets/Kyle1668/BOSS-Robustness-Benchmark/resolve/main/BOSS.zip && unzip BOSS.zip
	mv datasets/process datasets/boss_benchmark

download_rewrites_cache:
	python populate_cache.py

clear_rewrites_cache:
	rm -rf cached_rewrites

########## Primary Experiment Sweeps ##########

SEED ?= 42

main_results_sync:
	python evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	python evaluate_styling.py --dataset=boss_sentiment --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	python evaluate_styling.py --dataset=ag_news_twitter --evaluate_id_adaptation --model=Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_async:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --evaluate_id_adaptation --model=Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_async_insert:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_insert --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_insert --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --evaluate_id_adaptation --model=Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_insert --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_async_substitute:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_substitute --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_substitute --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --evaluate_id_adaptation --model=Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_substitute --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_async_back_translate:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --evaluate_id_adaptation --model=Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_async_llmtta_sentiment:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_async_llmtta_toxicity:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_async_llmtta_news:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --evaluate_id_adaptation --model=Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_sentiment:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_toxicity:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_news:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --evaluate_id_adaptation --model=Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_id_sentiment:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_id_sentiment_llm-tta:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_id_sentiment_baseline-tta:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_id_toxicity:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_id_toxicity_llm-tta:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_id_toxicity_baseline-tta:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_id_news:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=validation --evaluate_id_adaptation --model=Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_ood_sentiment:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_ood_sentiment_translate:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_ood_translate_bert:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_ood_toxicity:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_ood_toxicity_translate:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_ood_news:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_ood_news_translate:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

ablate_model_size:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=EleutherAI/pythia-1.4b,EleutherAI/pythia-2.8b,EleutherAI/pythia-6.9b,EleutherAI/pythia-12b --adaptive_model=aug_back-translate,aug_insert,aug_substitute,stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5 --model=EleutherAI/pythia-1.4b,EleutherAI/pythia-2.8b,EleutherAI/pythia-6.9b,EleutherAI/pythia-12b --adaptive_model=aug_back-translate,aug_insert,aug_substitute,stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen --model=EleutherAI/pythia-1.4b,EleutherAI/pythia-2.8b,EleutherAI/pythia-6.9b,EleutherAI/pythia-12b --adaptive_model=aug_back-translate,aug_insert,aug_substitute,stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

ablate_rewrite_lm:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5 --model=Kyle1668/boss-sentiment-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-13B --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	python evaluate_styling.py --dataset=boss_sentiment --split=sst5 --model=Kyle1668/boss-sentiment-bert-base-uncased --adaptive_model=stabilityai/StableBeluga2 --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen --model=Kyle1668/boss-toxicity-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-13B --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	python evaluate_styling.py --dataset=boss_toxicity --split=toxigen --model=Kyle1668/boss-toxicity-bert-base-uncased --adaptive_model=stabilityai/StableBeluga2 --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-13B --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	python evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-bert-base-uncased --adaptive_model=stabilityai/StableBeluga2 --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

rewriter_model_ood_eval:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

rewriter_model_eval_sync:
	python evaluate_styling.py --dataset=boss_sentiment --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	python evaluate_styling.py --dataset=boss_toxicity --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	python evaluate_styling.py --dataset=ag_news_twitter --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

rewriter_model_eval_topk_nearest:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=0,16 --icl_method=topk_nearest,random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=0,16 --icl_method=topk_nearest,random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=0,16 --icl_method=topk_nearest,random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

rewriter_model_id_eval:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=validation --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=validation --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=validation --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

########## Data Ablations ##########

ablate_data_ood:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-3000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-6000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-12000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-24000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-48000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-1500-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-3000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-6000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-12000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-24000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-4800-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-9600-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-19200-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-38400-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-76800-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

ablate_data_ood_translate:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-3000-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-6000-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-12000-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-24000-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-48000-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-1500-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-3000-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-6000-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-12000-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-24000-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-4800-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-9600-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-19200-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-38400-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-76800-bert-base-uncased --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

ablate_data_toxicity:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-3000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-6000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-12000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-24000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-48000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

ablate_data_sentiment:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-1500-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-3000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-6000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-12000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-24000-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

ablate_data_ag_news:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-4800-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-9600-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-19200-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-38400-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-76800-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

# 30000 training examples
train_ablate_data_boss_sentiment:
	python train_model.py --dataset=boss_sentiment --num_labels=3 --base_model=bert-base-uncased --max_examples=1500 --push_to_hub --use_wandb --seed=$(SEED)
	python train_model.py --dataset=boss_sentiment --num_labels=3 --base_model=bert-base-uncased --max_examples=3000 --push_to_hub --use_wandb --seed=$(SEED)
	python train_model.py --dataset=boss_sentiment --num_labels=3 --base_model=bert-base-uncased --max_examples=6000 --push_to_hub --use_wandb --seed=$(SEED)
	python train_model.py --dataset=boss_sentiment --num_labels=3 --base_model=bert-base-uncased --max_examples=12000 --push_to_hub --use_wandb --seed=$(SEED)
	python train_model.py --dataset=boss_sentiment --num_labels=3 --base_model=bert-base-uncased --max_examples=24000 --push_to_hub --use_wandb --seed=$(SEED)

# 60000 training examples
train_ablate_data_boss_toxicity:
	python train_model.py --dataset=boss_toxicity --num_labels=2 --base_model=bert-base-uncased --max_examples=3000 --push_to_hub --use_wandb --seed=$(SEED)
	python train_model.py --dataset=boss_toxicity --num_labels=2 --base_model=bert-base-uncased --max_examples=6000 --push_to_hub --use_wandb --seed=$(SEED)
	python train_model.py --dataset=boss_toxicity --num_labels=2 --base_model=bert-base-uncased --max_examples=12000 --push_to_hub --use_wandb --seed=$(SEED)
	python train_model.py --dataset=boss_toxicity --num_labels=2 --base_model=bert-base-uncased --max_examples=24000 --push_to_hub --use_wandb --seed=$(SEED)
	python train_model.py --dataset=boss_toxicity --num_labels=2 --base_model=bert-base-uncased --max_examples=48000 --push_to_hub --use_wandb --seed=$(SEED)

# 96000 training examples
train_ablate_data_ag_news:
	python train_model.py --dataset=ag_news_twitter --num_labels=4 --base_model=bert-base-uncased --max_examples=4800 --push_to_hub --use_wandb --seed=$(SEED)
	python train_model.py --dataset=ag_news_twitter --num_labels=4 --base_model=bert-base-uncased --max_examples=9600 --push_to_hub --use_wandb --seed=$(SEED)
	python train_model.py --dataset=ag_news_twitter --num_labels=4 --base_model=bert-base-uncased --max_examples=19200 --push_to_hub --use_wandb --seed=$(SEED)
	python train_model.py --dataset=ag_news_twitter --num_labels=4 --base_model=bert-base-uncased --max_examples=38400 --push_to_hub --use_wandb --seed=$(SEED)
	python train_model.py --dataset=ag_news_twitter --num_labels=4 --base_model=bert-base-uncased --max_examples=76800 --push_to_hub --use_wandb --seed=$(SEED)

########## Falcon Evals ##########

falcon_toxicity_insert:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct --adaptive_model=aug_insert --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

falcon_toxicity_substitute:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct --adaptive_model=aug_substitute --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

falcon_toxicity_back_translate:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct --adaptive_model=aug_back-translate --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

falcon_toxicity_paraphrase:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

falcon_toxicity_icr:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

########## 11/10 Reruns ##########

main_results_ood_low_compute:
	# torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	# torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	# torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wand

########## 12/19 Reruns ##########

toxicity_t5_ood_falcon_id:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-t5-large --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

########## 11/1 Reruns ##########

falcon_id_tta_baselines:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=validation --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct --adaptive_model=aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=validation --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct --adaptive_model=aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

########## 10/29 Reruns ##########

# RTX A6000 - 48gb VRAM
id_sentiment_llm_tta_bert_t5:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16,0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

# A100 80gb VRAM - Min 8 GPUs
id_sentiment_llm_tta_falcon:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=validation --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16,0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

# RTX A6000 - 48gb VRAM
id_toxicity_llm_tta_bert_t5:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16,0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

# A100 80gb VRAM - Min 8 GPUs
id_toxicity_llm_tta_falcon:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=validation --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16,0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

########## 10/23 Reruns ##########

single_node_id_sentiment_toxicity_no_paraphrase_icr:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-t5-large,Kyle1668/boss-toxicity-bert-base-uncased --adaptive_model=aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-t5-large,Kyle1668/boss-sentiment-bert-base-uncased --adaptive_model=aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	# screen -S eval_falcon_toxicity -d -m conda activate llm-tta && CUDA_VISIBLE_DEVICES=1,2,3 python evaluate_styling.py --dataset=boss_toxicity --split=validation --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct --adaptive_model=aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0
	# screen -S eval_falcon_sentiment -d -m conda activate llm-tta && CUDA_VISIBLE_DEVICES=4,5,6 python evaluate_styling.py --dataset=boss_sentiment --split=validation --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct --adaptive_model=aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars &

main_results_id_sentiment_llm:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16,0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_id_toxicity_llm:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16,0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_sentiment_tta_llama2:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct,Kyle1668/boss-sentiment-t5-large,Kyle1668/boss-sentiment-bert --adaptive_model=NousResearch/Llama-2-7b-chat-hf --skip_style_model_eval --num_shots=16,0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_results_toxicity_tta_llama2:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --evaluate_id_adaptation --model=tiiuae/falcon-7b-instruct,Kyle1668/boss-toxicity-t5-large,Kyle1668/boss-toxicity-bert --adaptive_model=NousResearch/Llama-2-7b-chat-hf --skip_style_model_eval --num_shots=16,0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

########## 10/23 Reruns ##########

boss_sentiment_ood_bert_icr:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=semval,dynasent --model=Kyle1668/boss-sentiment-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

########## 10/20 Reruns ##########

ablate_model_size_paraphrase:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=EleutherAI/pythia-1.4b,EleutherAI/pythia-2.8b,EleutherAI/pythia-6.9b,EleutherAI/pythia-12b --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5 --model=EleutherAI/pythia-1.4b,EleutherAI/pythia-2.8b,EleutherAI/pythia-6.9b,EleutherAI/pythia-12b --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen --model=EleutherAI/pythia-1.4b,EleutherAI/pythia-2.8b,EleutherAI/pythia-6.9b,EleutherAI/pythia-12b --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

irc_ood_news:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large,tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

########## 10/14 Reruns ##########

# Falcon for semval and dynasent and T5 and BERT for the whole sweep
10_14_rerun_main_results_ood_sentiment:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=semval,dynasent --model=tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --model=Kyle1668/boss-sentiment-t5-large,Kyle1668/boss-sentiment-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

# Falcon for implicit_hate and T5/BERT for the whole sweep
10_14_rerun_main_results_ood_toxicity:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=implicit_hate --model=tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --model=Kyle1668/boss-toxicity-t5-large,Kyle1668/boss-toxicity-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

# Falcon ICR for test split and T5/BERT for the whole sweep
10_14_rerun_main_results_ood_news:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=tiiuae/falcon-7b-instruct --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --model=Kyle1668/ag-news-t5-large,Kyle1668/ag-news-bert-base-uncased --adaptive_model=stabilityai/StableBeluga-7b,aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0,16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

########## Targeted Experiments ##########

main_results_id_no_llm:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large --adaptive_model=aug_insert,aug_substitute --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=validation --evaluate_id_adaptation --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large --adaptive_model=aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=validation --evaluate_id_adaptation --model=kyle1668/ag-news-bert-base-uncased,kyle1668/ag-news-t5-large --adaptive_model=aug_insert,aug_substitute,aug_back-translate --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_icr_results:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=tiiuae/falcon-7b-instruct,Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=tiiuae/falcon-7b-instruct,Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=tiiuae/falcon-7b-instruct,Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_icr_results_no_falcon:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

main_paraphrase_results:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --model=tiiuae/falcon-7b-instruct,Kyle1668/boss-sentiment-bert-base-uncased,Kyle1668/boss-sentiment-t5-large --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --model=tiiuae/falcon-7b-instruct,Kyle1668/boss-toxicity-bert-base-uncased,Kyle1668/boss-toxicity-t5-large --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --model=tiiuae/falcon-7b-instruct,Kyle1668/ag-news-bert-base-uncased,Kyle1668/ag-news-t5-large --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

falcon_main_results_ood_no_icr:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --model=tiiuae/falcon-7b-instruct --adaptive_model=aug_back-translate,aug_insert,aug_substitute,stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --model=tiiuae/falcon-7b-instruct --adaptive_model=aug_back-translate,aug_insert,aug_substitute,stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --model=tiiuae/falcon-7b-instruct --adaptive_model=aug_back-translate,aug_insert,aug_substitute,stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

ablate_model_size:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5 --model=EleutherAI/pythia-1.4b,EleutherAI/pythia-2.8b,EleutherAI/pythia-6.9b,EleutherAI/pythia-12b --adaptive_model=aug_back-translate,aug_insert,aug_substitute,stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen --model=EleutherAI/pythia-1.4b,EleutherAI/pythia-2.8b,EleutherAI/pythia-6.9b,EleutherAI/pythia-12b --adaptive_model=aug_back-translate,aug_insert,aug_substitute,stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=EleutherAI/pythia-1.4b,EleutherAI/pythia-2.8b,EleutherAI/pythia-6.9b,EleutherAI/pythia-12b --adaptive_model=aug_back-translate,aug_insert,aug_substitute,stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

rewriter_model_eval:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)


rewriter_model_eval_llama2:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --model=NousResearch/Llama-2-7b-hf --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --model=NousResearch/Llama-2-7b-hf --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --model=NousResearch/Llama-2-7b-hf --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

rewriter_model_eval_topk_nearest:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_sentiment --split=sst5,semval,dynasent --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=topk_nearest --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=boss_toxicity --split=toxigen,adv_civil,implicit_hate --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=topk_nearest --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=ag_news_twitter --split=test --model=stabilityai/StableBeluga-7b --adaptive_model=aug_back-translate --skip_style_model_eval --skip_eval_styling --num_shots=16 --icl_method=topk_nearest --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

imdb_rotten_tomatoes:
	torchrun --nproc-per-node=gpu evaluate_styling.py --dataset=imdb_rotten_tomatoes --model=Kyle1668/imdb-bert-base-uncased,Kyle1668/imdb-t5-large --adaptive_model=stabilityai/StableBeluga-7b --skip_style_model_eval --num_shots=16,0 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)

gpt3_baseline_eval:
	python evaluate_styling.py --dataset=ag_news_twitter --model=gpt-3.5-turbo --split=test --adaptive_model=aug_back-translate,aug_insert,aug_substitute --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	python evaluate_styling.py --dataset=boss_toxicity --split=toxigen --model=gpt-3.5-turbo --adaptive_model=aug_back-translate,aug_insert,aug_substitute --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)
	python evaluate_styling.py --dataset=boss_sentiment --split=sst5 --model=gpt-3.5-turbo --adaptive_model=aug_back-translate,aug_insert,aug_substitute --skip_style_model_eval --num_shots=16 --icl_method=random --temperature=0 --trim_exemplars --use_wandb --seed=$(SEED)