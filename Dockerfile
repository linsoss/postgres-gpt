FROM ankane/pgvector:v0.4.1

RUN apt update && \
    apt install -y postgresql-plpython3-15 python3-pip && \
    pip install 'openai[datalib]' markdown-it-py

COPY postgres_gpt/*.sql /docker-entrypoint-initdb.d/
