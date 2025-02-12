import airflow
from airflow.models import DAG
from airflow.operators.bash import BashOperator
from airflow.models.baseoperator import chain

from datetime import datetime

import os

# below step is necessary for airflow to know which userlist and webserver config to use
# export AIRFLOW_HOME=`pwd`/airflow do this in Project directory

# define default arguments
args = {
    'owner': 'vis_tmz',
    'start_date': airflow.utils.dates.days_ago(2),
    #'depends_on_past': False,
    #'start_date': datetime(2025, 1, 1),
    #'retries': 1,
}
# Initialize the DAG 
dag = DAG(
    dag_id='ds_jobs',
    default_args=args,
    schedule_interval=None
    #schedule_interval='0 0 28-31 * *',  #run every month end after we have collected enough scraped data
    #catchup=False,
)
# Define the 4 tasks
A = BashOperator(
    task_id='clean_data',
    bash_command='cd /mnt/d/UE\ Applied\ Sciences/Semester\ I/Data\ Engineering/Project/airflow/scripts && /mnt/c/Program\ Files/R/R-4.4.2/bin/Rscript.exe clean_scraped_data.R',
    dag=dag,
    )
B = BashOperator(
    task_id='fill_domain',
    bash_command='cd /mnt/d/UE\ Applied\ Sciences/Semester\ I/Data\ Engineering/Project/airflow/scripts && python fill_domain.py',
    dag=dag,
    )
C = BashOperator(
    task_id='merge_push',
    bash_command='cd /mnt/d/UE\ Applied\ Sciences/Semester\ I/Data\ Engineering/Project/airflow/scripts && /mnt/c/Program\ Files/R/R-4.4.2/bin/Rscript.exe merge_push_data_3nf.R',
    dag=dag,
    )
command_line = 'cd /mnt/d/UE\ Applied\ Sciences/Semester\ I/Data\ Engineering/Project/airflow/scripts && /mnt/c/Program\ Files/R/R-4.4.2/bin/Rscript.exe -e "quarto::quarto_render('+ "'" + 'report_3nf.qmd' + "')" + '"'
D = BashOperator(
    task_id='quarto_html_report',
    bash_command=f'{command_line}',
    dag=dag,
    )

# Define the task dependencies
chain(A, B, C, D)