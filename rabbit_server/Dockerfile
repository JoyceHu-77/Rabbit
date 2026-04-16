# 在仓库根目录执行：
#   docker build -f rabbit_server/Dockerfile -t rabbit-api:latest .
# 将 iOS 种子 JSON 打入镜像；数据库文件挂载到 /data。
FROM python:3.12-slim

WORKDIR /app

COPY rabbit_server/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY rabbit_server/app /app/app
RUN mkdir -p /app/seed /data

COPY Rabbit_iOS/Rabbit_iOS/rabbit_seed.json /app/seed/rabbit_seed.json

ENV DATABASE_URL=sqlite:////data/rabbit.db
ENV SEED_JSON_PATH=/app/seed/rabbit_seed.json
ENV RUN_SEED_ON_EMPTY=true

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
