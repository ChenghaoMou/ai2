#!/bin/sh
#SBATCH --account=mics
#SBATCH --partition=mics                # The partition of HPC of this job.
#SBATCH --ntasks=1                      # Number of instances launched of this job.
#SBATCH --time=24:00:00                 # Acceptable format: MM, MM:SS, HH:MM:SS, DD-HH", DD-HH:MM, DD-HH:MM:SS.
#SBATCH --mem-per-cpu=4G                # Memory allocated per cpu
#SBATCH --cpus-per-task=4               # CPU Allocated
#SBATCH --gpus-per-task=1               # GPU Allocated
#SBATCH --job-name=BASELINE             # The name of this job. If removed the job will have name of your shell script.
#SBATCH --output=%x-%j.out              # The name of the file output. %x-%j means JOB_NAME-JOB_ID. If removed output will be in file slurm-JOB_ID.
#SBATCH --export=NONE                   # Ensure job gets a fresh login environment
#SBATCH --array=0-3%1                   # Submitting an array of (n-m+1) jobs, with $SLURM_ARRAY_TASK_ID ranging from n to m. Add %1 if you only want one jobs running at one time.


### Load the conda environment of your choosing
source ~/.bashrc
conda activate ai2_updated

. /nas/gaia/shared/cluster/spack/share/spack/setup-env.sh
# When using `tensorflow-gpu`, paths to CUDA and CUDNN libraries are required
# by symbol lookup at runtime even if a GPU isn't going to be used.
spack load cuda@9.0.176
spack load cudnn@7.6.5.32-9.0-linux-x64

echo ""
echo "Current working directory: $(pwd)"
echo "Starting run at: $(date)"
echo "Job Array ID / Job ID: $SLURM_ARRAY_JOB_ID / $SLURM_JOB_ID"
echo "This is job $SLURM_ARRAY_TASK_ID out of $SLURM_ARRAY_TASK_COUNT jobs."
echo ""

# All Tasks
allTask=(physicaliqa socialiqa hellaswag alphanli)
modelTask=${allTask[${SLURM_ARRAY_TASK_ID}]}
echo ""
echo "This is for AI2 Task: $modelTask"
python train.py task="$modelTask" progress_bar_refresh_rate=0
echo ""

### Finishing up the job and copy the output off of staging
echo "Job finished with exit code $? at: $(date)"
