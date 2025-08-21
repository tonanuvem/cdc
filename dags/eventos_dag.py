from __future__ import annotations

import pendulum

from airflow.models.dag import DAG
from airflow.providers.http.operators.http import SimpleHttpOperator
from airflow.providers.kafka.operators.kafka import KafkaConsumerOperator

with DAG(
    dag_id="kafka_to_teams_notifications",
    start_date=pendulum.datetime(2025, 1, 1, tz="UTC"),
    schedule=None,
    catchup=False,
    tags=["kafka", "teams", "cdc"],
) as dag:
    
    # 1. Tarefa para ler eventos do Kafka
    # Usamos o KafkaConsumerOperator para ler eventos do tópico
    # O parametro "apply_async" armazena o resultado no XComs
    read_kafka_events = KafkaConsumerOperator(
        task_id="read_kafka_events",
        topics=["relatorios"],  # Nome do seu tópico. Se for 'cdc_server.public.produtos', use esse.
        kafka_conn_id="kafka_airflow_teams",  # Usa a conexão que você já configurou
        consumer_timeout=30.0, # Timeout para o consumidor
        max_messages=1, # Lê apenas 1 mensagem por execução
        apply_async=True # Salva o resultado no XComs
    )

    # 2. Tarefa para enviar a mensagem para o Teams
    # A mensagem é um string que acessa o resultado da tarefa anterior via XComs
    send_to_teams = SimpleHttpOperator(
        task_id="send_to_teams",
        http_conn_id="teams_webhook_conn", # Usa a conexão do Teams que você criou
        endpoint="", # O endpoint já está no Host da conexão
        method="POST",
        headers={"Content-type": "application/json"},
        data='{{ {"text": "Novo evento CDC no Kafka: " + task_instance.xcom_pull(task_ids="read_kafka_events", key="return_value") | string | replace("\\"", "") } }}',
        log_response=True,
    )

    # Definir a ordem de execução das tarefas
    read_kafka_events >> send_to_teams
