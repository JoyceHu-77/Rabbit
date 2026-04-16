# 在仓库根目录执行：
#   docker build -f rabbit_server/Dockerfile -t rabbit-api:latest .
# 将 iOS 种子 JSON 打入镜像；数据库文件挂载到 /data。
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirrors.aliyun.com/ubuntu/|g' /etc/apt/sources.list \
  && sed -i 's|http://security.ubuntu.com/ubuntu|http://mirrors.aliyun.com/ubuntu|g' /etc/apt/sources.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
     ca-certificates \
     python3 python3-pip python3-venv \
  && rm -rf /var/lib/apt/lists/*

COPY rabbit_server/requirements.txt /app/requirements.txt
RUN python3 -m pip install --upgrade pip \
  && python3 -m pip install -r /app/requirements.txt

COPY rabbit_server/app /app/app
RUN mkdir -p /app/seed /data

COPY Rabbit_iOS/Rabbit_iOS/rabbit_seed.json /app/seed/rabbit_seed.json

ENV DATABASE_URL=sqlite:////data/rabbit.db
ENV SEED_JSON_PATH=/app/seed/rabbit_seed.json
ENV RUN_SEED_ON_EMPTY=true

EXPOSE 8000

CMD ["python3", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
