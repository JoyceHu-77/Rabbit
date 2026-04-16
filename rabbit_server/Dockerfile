# 在仓库根目录执行：
#   docker build -f rabbit_server/Dockerfile -t rabbit-api:latest .
# 将种子 JSON 打入镜像（源文件在 rabbit_server/seed/）；数据库文件挂载到 /data。
FROM python:3.12-slim

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    PIP_TRUSTED_HOST=mirrors.aliyun.com

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY rabbit_server/requirements.txt /app/requirements.txt
RUN python -m pip install --upgrade pip \
  && python -m pip install -r /app/requirements.txt

COPY rabbit_server/app /app/app
RUN mkdir -p /app/seed /data

COPY rabbit_server/seed/rabbit_seed.json /app/seed/rabbit_seed.json

ENV DATABASE_URL=sqlite:////data/rabbit.db
ENV SEED_JSON_PATH=/app/seed/rabbit_seed.json
ENV RUN_SEED_ON_EMPTY=true

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
