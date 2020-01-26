from __future__ import print_function
"""
Code that goes along with the Airflow tutorial located at:
https://github.com/apache/airflow/blob/master/airflow/example_dags/tutorial.py
"""
from airflow import DAG
from airflow.operators.bash_operator import BashOperator
from airflow.operators.python_operator import PythonVirtualenvOperator,PythonOperator
from datetime import datetime, timedelta


default_args = {
    'owner': 'Airflow',
    'depends_on_past': False,
    'start_date': datetime(2020, 1, 13),
    'email': ['airflow@example.com'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
    # 'queue': 'bash_queue',
    # 'pool': 'backfill',
    # 'priority_weight': 10,
    # 'end_date': datetime(2016, 1, 1),
}

dag = DAG('tutorial27', default_args=default_args, schedule_interval=timedelta(days=1))

# t1, t2 and t3 are examples of tasks created by instantiating operators
t1 = BashOperator(
    task_id='print_date2',
    bash_command='date;echo Asaf is awesome',
    dag=dag)

def my_code(**kwargs):
    import sys
    import platform
    #import ipython
    print (sys.version)
    print (platform.python_version())
    

t2 = PythonVirtualenvOperator(
    task_id='print_version_dill_27',
    provide_context=False,
    python_version=2,
    requirements=["dill>=0.2.2, <0.4"],
    python_callable=my_code,
    use_dill=True,
    dag=dag
)

t3 = PythonVirtualenvOperator(
    task_id='print_version_dill_37',
    provide_context=False,
    requirements=["dill>=0.2.2, <0.4"],
    python_callable=my_code,
    python_version=3,
    use_dill=True,
    dag=dag
)

t4 = PythonVirtualenvOperator(
    task_id='print_version_37',
    provide_context=False,
    python_callable=my_code,
    python_version=3,
    use_dill=False,
    dag=dag
)

t5 = PythonVirtualenvOperator(
    task_id='print_version_27',
    provide_context=False,
    python_version=2,
    use_dill=False,
    python_callable=my_code,
    dag=dag
)


t6 = PythonOperator(
    task_id='PythonOperator_dill',
    provide_context=False,
    requirements=["dill>=0.2.2, <0.4"],
    python_callable=my_code,
    dag=dag
)

t7 = PythonOperator(
    task_id='PythonOperator',
    provide_context=False,
    python_callable=my_code,
    dag=dag
)

t6 >> t7
t5 >> t4
t2 >> t3
