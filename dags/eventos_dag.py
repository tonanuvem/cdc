from __future__ import annotations

import pendulum
import pymsteams

from airflow.models.dag import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.kafka.operators.kafka import KafkaConsumerOperator

# Função para enviar mensagem ao Microsoft Teams
def send_to_teams_func(**context):
    kafka_msg = context['ti'].xcom_pull(task_ids="read_kafka_events", key="return_value")

    # 🔁 Insira aqui seu webhook do Teams
    webhook_url = "https://outlook.office.com/webhook/..."  # <- Substitua por seu Webhook real

    teams_message = pymsteams.connectorcard(webhook_url)
    teams_message.text(f"📢 Novo evento Kafka no tópico `postgresdb.public.products`:\n\n{str(kafka_msg)}")
    teams_message.send()

with DAG(
    dag_id="kafka_to_teams_notifications",
    start_date=pendulum.datetime(2025, 1, 1, tz="UTC"),
    schedule=None,
    catchup=False,
    tags=["kafka", "teams", "cdc"],
) as dag:
    
    # 1. Ler mensagem do Kafka
    read_kafka_events = KafkaConsumerOperator(
        task_id="read_kafka_events",
        topics=["postgresdb.public.products"],
        kafka_conn_id="kafka_airflow_teams",
        consumer_timeout=30.0,
        max_messages=1,
        apply_async=True
    )

    # 2. Enviar mensagem ao Teams via pymsteams
    send_to_teams = PythonOperator(
        task_id="send_to_teams",
        python_callable=send_to_teams_func,
        provide_context=True,
    )

    # Ordem de execução
    read_kafka_events >> send_to_teams
