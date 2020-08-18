# David's Code Base For AI2 Commonsense Leaderboard

## Install Dependencies and Set Up

Create and run a virtual environment with Python 3.7 using anaconda. Make sure to use conda version `>=4.8.2`.

```bash
conda create --name ai2_updated python=3.7
conda activate ai2_updated
pip install -r requirements.txt
```

This repo uses Facebook's Hydra module to handle configuration and script result storage. The config files are in the yaml 
format, and the results are stored in `multirun/` or `outputs/` folder based on the time when the script is executed. 
For more information in how to use Hydra please reference their website: https://hydra.cc/

## Onboarding (On Saga HPC)
Log on to Saga HPC and navigate to the root folder of this project, and submit the follow task to Slurm Workload
Manager: https://slurm.schedmd.com/documentation.html

```bash
sbatch slurm/onboarding.sh
```

This script will first call a script that downloads all pretrained model weights in to the `model_cache/` folder, then
submit an array of task that fine tunes roberta-large model on the four AI2 tasks with NLP focus, with 
respective training time listed in the following table:

|Model|AlphaNLI|HellaSwag|PhysicalIQA|SocialIQA|
|:---:|:---:|:---:|:---:|:---:| 
|Roberta-Large|~20hr|~7.5hr|~2.5hr|~6hr|


Given Enough Resources, roughly 3 hrs after submitting the job, fine tuning for Physical IQA should have finished and 
the evaluation result should be at the end of `outputs/BASELINE-$SLURM_ID.out` file in the project root directory. 
The result should be the same as the following (rounded to 3 digits of accuracy): 

### Baseline Result for Replicability Test (Random Seed 42):

|Model|AlphaNLI|HellaSwag|PhysicalIQA|SocialIQA|
|:---:|:---:|:---:|:---:|:---:| 
|Roberta-Large|Acc: 81.7%-85.4% Avg-83.5%; Loss: 0.977|Acc: 83.4%-84.8% Avg-84.1%; Loss: 0.552|Acc: 77.9%-81.5% Avg-79.7%; Loss: 0.631|Acc: 74.2%-77.9% Avg-76.0%; Loss: 0.961|

Further more, when running the following diff command on the loss log file, there should be no output result when you 
execute the following command (for Physical IQA, for other task simply replace the task name in the diff command)

```bash
diff -q \
<(cut -d, -f1,3 PATH_TO_YOUR_metrics.csv_FILE_IN_OUTPUTS_FOLDER) \
<(cut -d, -f1,3 /nas/minlp/users/mics/dwangli/ai2_stable/outputs/baseline-ai2-roberta-large/roberta-large-[TASK_NAME]-s42/[TASK_NAME]/version_0/metrics.csv)
```

In case of failing replication - try resubmitting `baseline.sh` sbatch job again first to make sure that your current
state is reproducible. This codebase relies on many libraries and some of them are managed by Saga (eg. cudnn), which 
may result in minor changes in accuracy. However, if a second run of baseline tasks yields different result than the
first, there is a bug in the code base.

## Folder Structure
    .
    ├── config                      # Configuration Files
    │   ├── task                    # Configuration for each task, with train/dev file locations
    │   ├── model                   # Configuration files for each model, with max epoch, learning rate, etc.
    │   ├── checkpoint_list         # Lists of location where checkpoint files are located
    │   └── Core Config             # Config files for core python scripts
    ├── model_cache                 # Pretrained Model Cache for Transformers 
    ├── multirun or outputs         # Hydra python package output folders - this is where script output will be
    ├── slurm                       # Slurm job sbatch submission scripts for HPC
    ├── task_data                   # Data folder for AI2 challenges
    ├── utilities                   # Helper classes for core python scripts and one off scripts
    ├── Conda Environment Files     # requirements.txt (pip format) and environment.yml (conda format)
    ├── Core Python Scripts         # model.py, train.py, eval.py, embed.py, closest.py
    └── README.md

## model.py

This is the self-defined model class extending pytorch-lightning's Lightning Module: 
https://pytorch-lightning.readthedocs.io/en/latest/lightning-module.html. The classifier is designed to 
utilize the pretrained models to embed a given text, and pass it through a classifier layer for results.

## train.py

This script is the script that fine tunes a model on a specific dataset. It can also handle loading in an existing 
model and further fine tune it with more data. 

## eval.py

This script is used to evaluate a checkpoint file trained by the train script. The script uses the trained model and
evaluate it on it's dev stories. It writes out the accuracy and the loss of the model, as well as two files containing
prediction and confidence of each choice.

## embed.py

This script uses the checkpoint files provided (or an out of box model if requested) to parse the train and dev entries 
for a given task. The script output a pickled dictionary consist of the metadata for the embeddings and embedding 
tuples in the form of (Name of Checkpoint File, Train Embedding, Dev Embedding). Currently the script 
supports these feature types when parsing the embeddings:
- AVG_MEAN: Average embedding of all tokens, and average of all possible answers

These features are yet to be developed:
- AVG_CORRECT: Average embedding of all tokens, and choose the one parsed with correct answer
- AVG_NULL: Average embedding of all tokens, without the options embedded in it
- CLS_MEAN, CLS_CORRECT, CLS_NULL

## closest.py

This file takes the output generated by `embed.py` and output a tsv file that lists the nearest sentences to each dev
sentence of interest using the specified distance calculation function. It can also find the farthest sentences to 
each dev sentence. You can also specify a subset of train or dev that you are interested in, or get statistics on if 
the closest samples is in a designated influential range using these two formats: (x, m-n). 
Currently the script supports the following distance functions:
- cosine
- l-p norms