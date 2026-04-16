# Docker 与本机跑 Rabbit API

## Docker daemon 是什么？

**Docker daemon**（`dockerd`）是运行在电脑上的**后台服务进程**：负责拉镜像、建容器、挂卷、连网络等。你打开的 **Docker Desktop** 本质上就是在本机启动并托管这个 daemon；终端里执行的 `docker`、`docker compose` 命令都是通过 **Docker 客户端** 去跟 daemon 通信。

若出现 `Cannot connect to the Docker daemon`，说明 daemon 没在跑——请先打开 Docker Desktop（或 Linux 上的 `sudo systemctl start docker`）。

## 本机需要准备什么？

- 已安装 **Docker Desktop**（macOS/Windows）或 Docker Engine + Compose 插件（Linux）。
- 本仓库路径包含 `rabbit_server/` 与 `Rabbit_iOS/Rabbit_iOS/rabbit_seed.json`（构建镜像时会 `COPY` 该文件）。

## 一键启动 API（推荐）

在**仓库根目录** `/Users/huchenyi/Desktop/rabbit` 执行：

```bash
docker compose -f rabbit_server/docker-compose.yml up -d --build
```

验证：

```bash
curl -s http://127.0.0.1:8000/healthz
curl -s http://127.0.0.1:8000/v1/rescues | head -c 200; echo
```

## 环境变量（`docker-compose.yml` 已写好）

| 变量 | 含义 |
|------|------|
| `DATABASE_URL` | SQLite 文件路径（容器内 `sqlite:////data/rabbit.db`） |
| `SEED_JSON_PATH` | 种子 JSON 在容器内的路径 |
| `RUN_SEED_ON_EMPTY` | 仅在空库时导入种子，`true` / `false` |

## 常用命令

```bash
# 查看日志
docker compose -f rabbit_server/docker-compose.yml logs -f

# 停止并删容器（保留数据卷里的数据库）
docker compose -f rabbit_server/docker-compose.yml down

# 连数据卷一起删（清空库，下次启动会重新种子导入）
docker compose -f rabbit_server/docker-compose.yml down -v
```

## 若启动报错「容器名 / 网络已存在」

多半是上次未正常 `down` 留下的资源，可先清理再启动：

```bash
docker rm -f rabbit_server-rabbit-api-1 2>/dev/null || true
docker compose -f rabbit_server/docker-compose.yml down
docker compose -f rabbit_server/docker-compose.yml up -d --build
```

当前 Compose 已设置 `name: rabbit-stack`，新项目下的容器名形如 `rabbit-stack-rabbit-api-1`，与旧默认名错开。

## 仅构建镜像（不启动）

```bash
docker build -f rabbit_server/Dockerfile -t rabbit-api:latest .
```
