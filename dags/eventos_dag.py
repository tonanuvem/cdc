### CONFIGURAR A LINHA 27:      webhook_url = "INSERIR_WEBHOOK"

from __future__ import annotations

import pendulum
import pymsteams

from airflow.models.dag import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.apache.kafka.operators.consume import ConsumeFromTopicOperator


# 🔔 Função para enviar mensagem ao Microsoft Teams
def send_to_teams_func(**context):
    kafka_msg = context['ti'].xcom_pull(
        task_ids="read_kafka_events",
        key="return_value"
    )

    if not kafka_msg:
        context['ti'].log.info("Nenhuma mensagem Kafka recebida, nada será enviado ao Teams.")
        return

    context['ti'].log.info(f"Mensagem Kafka recebida: {kafka_msg}")

    # 🔁 Insira aqui o webhook do Teams
    webhook_url = "INSERIR_WEBHOOK"

    teams_message = pymsteams.connectorcard(webhook_url)
    teams_message.text(
        f"📢 Novo evento Kafka no tópico `postgresdb.public.products`:\n\n{str(kafka_msg)}"
    )
    teams_message.send()
    context['ti'].log.info("Mensagem enviada ao Teams com sucesso.")


with DAG(
    dag_id="kafka_to_teams_notifications",
    start_date=pendulum.datetime(2025, 1, 1, tz="UTC"),
    schedule=None,
    catchup=False,
    tags=["kafka", "teams", "cdc"],
) as dag:
    
    # 1. Ler mensagem do Kafka
    read_kafka_events = ConsumeFromTopicOperator(
        task_id="read_kafka_events",
        topics=["postgresdb.public.products"],
        kafka_config_id="kafka_airflow_teams",   # conexão configurada no Airflow
        apply_function=lambda msg: msg.value().decode("utf-8"),  # transforma bytes em string
        max_messages=1,
        poll_timeout=30,
    )


    # 2. Enviar mensagem ao Teams
    send_to_teams = PythonOperator(
        task_id="send_to_teams",
        python_callable=send_to_teams_func,
    )

    # Ordem de execução
    read_kafka_events >> send_to_teams
