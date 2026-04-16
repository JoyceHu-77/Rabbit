# Uvicorn 是什么？如何改成「域名 + HTTPS」？

## Uvicorn 是什么？

**Uvicorn** 是一个用 Python 写的 **ASGI 服务器**：负责运行 FastAPI 应用，把 HTTP 请求交给框架处理，再把响应发回客户端。

- 你现在的 Docker 命令 `uvicorn app.main:app --host 0.0.0.0 --port 8000` 表示：在本机 **8000 端口** 上提供 **普通 HTTP**（明文）。
- Uvicorn **可以**自己挂 TLS 证书跑 HTTPS，但生产环境更常见做法是：**前面再放一层 Nginx / Caddy** 做证书与域名，后面仍用 Uvicorn 只监听内网端口（例如 127.0.0.1:8000）。这样证书续期、限流、静态资源都更好做。

一句话：**Uvicorn = 跑 FastAPI 的 Web 进程；HTTPS 通常由前面的反向代理 + 证书来完成。**

---

## 改成「域名 + HTTPS」的总体思路

1. 买一个**域名**（任意注册商）。
2. 在域名 DNS 里加 **A 记录**：主机名如 `api` 或 `@`，值填你 **ECS 公网 IP**（例如 `47.111.225.11`）。生效后外网可通过 `https://api.你的域名.com` 解析到你的机器。
3. 在 ECS 上安装 **Nginx** 或 **Caddy**，监听 **443**，申请并自动续期 **Let’s Encrypt** 证书，把请求**反向代理**到本机 `http://127.0.0.1:8000`（Uvicorn）。
4. 阿里云 **安全组** 放行 **TCP 443**（可保留 8000 仅内网调试，对外只开 443 更安全）。
5. **iOS**：把 `RABBIT_API_BASE_URL` 改成 `https://api.你的域名.com`（**不要**末尾斜杠），并**删掉**仅针对 IP 的 HTTP 明文例外（`NSExceptionAllowsInsecureHTTPLoads` 等），避免审核风险。

---

## 方案 A：Caddy（证书自动申请，配置少）

适合单机、想少写配置。示例（Caddy 监听 443，反代到 Uvicorn）：

```caddyfile
api.你的域名.com {
    reverse_proxy 127.0.0.1:8000
}
```

把 Docker 里的 Uvicorn 改为只绑定本机（避免公网直连 8000，可选）：

```yaml
# docker-compose 中仅本机可访问容器端口时，可用 profiles 或改端口映射为 127.0.0.1:8000:8000
ports:
  - "127.0.0.1:8000:8000"
```

Caddy 会自动向 Let’s Encrypt 申请证书（需 80 端口也可达用于 HTTP-01，或配置 DNS 插件做 DNS-01）。具体安装见 [Caddy 文档](https://caddyserver.com/docs/install)。

---

## 方案 B：Nginx + Certbot（常见组合）

1. 安装 Nginx、Certbot（以 Ubuntu 为例）：

   ```bash
   sudo apt update
   sudo apt install -y nginx certbot python3-certbot-nginx
   ```

2. 先保证 `http://api.你的域名.com` 能打开到 Nginx 默认页（DNS 已指向本机，安全组放行 80）。

3. 申请证书并让 Certbot 写入 Nginx 配置：

   ```bash
   sudo certbot --nginx -d api.你的域名.com
   ```

4. 在 Nginx 的 `server` 里增加反代到 Uvicorn（证书块由 certbot 生成后，你补充 `location /`）：

   ```nginx
   location / {
       proxy_pass http://127.0.0.1:8000;
       proxy_http_version 1.1;
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;
   }
   ```

5. `sudo nginx -t && sudo systemctl reload nginx`。

---

## iOS 侧要改什么？

1. `Info.plist` 里 **`RABBIT_API_BASE_URL`** 改为：  
   `https://api.你的域名.com`  
   （与 Nginx/Caddy 里证书域名一致，无尾部 `/`）。
2. **移除**为纯 IP + HTTP 配的 ATS 例外；标准 HTTPS 走系统默认信任链即可。
3. 重新编译运行 App。

---

## 自检清单

| 检查项 | 说明 |
|--------|------|
| DNS | `dig api.你的域名.com` 或在线 DNS 检测，应指向 ECS 公网 IP |
| 443 | `curl -I https://api.你的域名.com/healthz` 返回 200 |
| 反代 | 同上路径应看到 `{"status":"ok"}` |
| 安全组 | 入站 443（及 certbot 首次需要的 80）已放行 |

完成以上后，API 仍是 **Uvicorn 在跑**；对外用户看到的是 **域名 + HTTPS**，由反向代理与证书负责。
