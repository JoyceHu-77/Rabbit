#!/usr/bin/env bash
# 在仓库根目录启动 Rabbit API（Docker Compose）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
docker compose -f rabbit_server/docker-compose.yml up -d --build
echo ""
echo "健康检查: curl -s http://127.0.0.1:8000/healthz"
curl -sS "http://127.0.0.1:8000/healthz" && echo ""
