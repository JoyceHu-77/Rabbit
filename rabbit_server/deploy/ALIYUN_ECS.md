# 在阿里云 ECS 上部署 Rabbit API（FastAPI + SQLite）

公网 IP 示例：`47.111.225.11`。请把下文中的 IP 换成你控制台里的实际公网地址。

## 1. 你需要完成什么才能「和手机 App 联起来」

| 步骤 | 说明 |
|------|------|
| ECS 安全组 | 入方向放行 **TCP 8000**（或你改为 80/443 后放行对应端口）。 |
| 运行 API 容器或进程 | 本仓库提供 Docker 镜像，监听 `0.0.0.0:8000`。 |
| iOS `Info.plist` | 设置 `RABBIT_API_BASE_URL` 为 `http://47.111.225.11:8000`（无尾部斜杠）。 |
| ATS（若用 HTTP） | 纯 IP + HTTP 需为该机配置 **例外**，否则 iOS 默认拦截明文流量。工程里已增加对 `47.111.225.11` 的例外示例，上线商店前建议改为 **HTTPS + 域名**。 |

数据库：当前默认 **SQLite 文件**在容器卷 `/data/rabbit.db`，首次启动空库会自动从镜像内 `rabbit_seed.json` 导入救援数据，并写入 4 条示例捐换。

## 2. ECS 上安装 Docker（Alibaba Cloud Linux / CentOS 系示例）

```bash
sudo yum install -y docker
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
# 重新登录后再执行 docker
```

## 3. 把代码放到服务器

任选其一：

- `git clone` 本仓库到 `/opt/rabbit`；
- 或用 `scp -r` 将整个 `rabbit` 目录拷到 ECS。

以下假定项目根目录为 `/opt/rabbit`。

## 4. 构建并启动（Docker Compose）

```bash
cd /opt/rabbit
sudo docker compose -f rabbit_server/docker-compose.yml up -d --build
sudo docker compose -f rabbit_server/docker-compose.yml ps
curl -s http://127.0.0.1:8000/healthz
```

在**你本地电脑**浏览器或 `curl` 测公网：

```bash
curl -s http://47.111.225.11:8000/healthz
curl -s http://47.111.225.11:8000/v1/rescues | head -c 300
```

若此处不通：检查安全组、ECS 是否绑定公网 IP、本机防火墙（`firewalld`/`iptables`）是否放行 8000。

## 5. 不用 Docker、直接 Python 运行（备选）

```bash
cd /opt/rabbit/rabbit_server
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
mkdir -p data
cp ../Rabbit_iOS/Rabbit_iOS/rabbit_seed.json data/
export DATABASE_URL=sqlite:///./data/rabbit.db
export SEED_JSON_PATH=./data/rabbit_seed.json
nohup .venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 &
```

生产环境建议用 **systemd** 托管上述命令，并设置开机自启。

## 6. iOS 端配置

1. `Rabbit_iOS/Rabbit_iOS/Info.plist` 中 `RABBIT_API_BASE_URL` 填：`http://47.111.225.11:8000`  
2. 若使用 HTTP，确认 `NSAppTransportSecurity` 下已为该 IP 配置 `NSExceptionAllowsInsecureHTTPLoads`（仓库中已加示例域 `47.111.225.11`，可按需修改）。  
3. 重新编译运行 App：救援/捐换列表与发布应走云端。

## 7. 是否「完全可用」

在以下前提下，**列表 + 新建救援/捐换** 与当前 iOS 实现一致，可端到端使用：

- 安全组与端口已通；  
- Base URL 与 ATS 配置正确；  
- **救援详情里仅改状态** 仍主要是 **客户端本地 `upsertRescue`**，尚未对接 `PUT /v1/rescues/{id}`；若需要多端同步状态，需再加接口与客户端调用。

上架 App Store 前强烈建议：**域名 + HTTPS（Nginx/Caddy + Let’s Encrypt）**，并去掉明文 HTTP 例外。
