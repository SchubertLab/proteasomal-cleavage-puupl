rule all:
    input:
        expand("logs/{c}-puupl-r{r}.out", c=['cterm', 'nterm'], r=range(10))


rule run_on_slurm:
    shell: """
NAME="{wildcards.config}-{params.method}"
sbatch -p mcml-dgx-a100-40x8 --gres=gpu:1 -t 2-00:00:00 --qos=mcml --ntasks 1 --cpus-per-task 10 --mem 64G \
    --wait --array 0-9 --job-name "proc-$NAME" -o "logs/$NAME-r%a.out" -e "logs/$NAME-r%a.err" << EOF
#!/bin/bash
set -x
source ~/.bashrc
conda activate pucu
mkdir -p ./checkpoints/$NAME-r\$SLURM_ARRAY_TASK_ID
python -u src/puupl/run.py {input} \
    cv_current_fold:\$SLURM_ARRAY_TASK_ID cv_total_folds:\$SLURM_ARRAY_TASK_COUNT \
    exp_params.model_checkpoint_path:./checkpoints/$NAME-r\$SLURM_ARRAY_TASK_ID \
    {params.puupl_args}
EOF
    """


use rule run_on_slurm as puupl with:
    input:
        "configs/{config}.yaml"
    output:
        expand("logs/{config}-puupl-r{r}.out", r=range(10), allow_missing=True)
    params:
        puupl_args="oversampled_prior:0.5",
        method="puupl"


use rule run_on_slurm as imbnnpu with:
    input:
        "configs/{config}.yaml"
    output:
        expand("logs/{config}-imbnnpu-r{r}.out", r=range(10), allow_missing=True)
    params:
        puupl_args="ensemble_size:1 uncertainty_type:predictions oversampled_prior:0.5",
        method="imbnnpu"

