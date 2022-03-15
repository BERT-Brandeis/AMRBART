
#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

GPUID=$2
MODEL=$1
eval_beam=5
modelcate=base
modelcate=large

lr=8e-6

datacate=AMR17-full
#datacate=AMR20-full
#datacate=AMR17-silver
#datacate=Giga
#datacate=New3
#datacate=TLP
#datacate=Bio

Tokenizer=../../../data/pretrained-model/bart-$modelcate

export OUTPUT_DIR_NAME=outputs/Eval-${datacate}-AMRBart-${modelcate}-amrparsing-6taskPLMTAPT

export CURRENT_DIR=${ROOT_DIR}
export OUTPUT_DIR=${CURRENT_DIR}/${OUTPUT_DIR_NAME}
cache=../../../data/.cache/

if [ ! -d $OUTPUT_DIR ];then
  mkdir -p $OUTPUT_DIR
else
  echo "${OUTPUT_DIR} already exists, change a new one or delete origin one"
  exit 0
fi

export OMP_NUM_THREADS=10
export CUDA_VISIBLE_DEVICES=${GPUID}
python -u ${ROOT_DIR}/run_amrparsing.py \
    --data_dir=../data/$datacate \
    --train_data_file=../data/$datacate/train.jsonl \
    --eval_data_file=../data/$datacate/val.jsonl \
    --test_data_file=../data/$datacate/test.jsonl \
    --model_type ${MODEL} \
    --model_name_or_path=${MODEL} \
    --tokenizer_name_or_path=${Tokenizer} \
    --val_metric "smatch" \
    --learning_rate=${lr} \
    --max_epochs 1 \
    --max_steps -1 \
    --per_gpu_train_batch_size=4 \
    --per_gpu_eval_batch_size=4 \
    --accumulate_grad_batches 2 \
    --unified_input \
    --early_stopping_patience 10 \
    --gpus 1 \
    --output_dir=${OUTPUT_DIR} \
    --cache_dir ${cache} \
    --num_sanity_val_steps 0 \
    --src_block_size=512 \
    --tgt_block_size=1024 \
    --eval_max_length=1024 \
    --train_num_workers 8 \
    --eval_num_workers 4 \
    --process_num_workers 8 \
    --do_eval \
    --seed 42 \
    --fp16 \
    --eval_beam ${eval_beam} 2>&1 | tee $OUTPUT_DIR/Eval.log