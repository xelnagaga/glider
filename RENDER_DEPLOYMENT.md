# Glider Render 部署指南

## 🚀 当前配置

你的 glider 服务已配置为：
- **监听**: HTTP 代理 on port 10000
- **转发**: 所有流量通过你的 SOCKS5 residential 代理
- **上游代理**: `proxy.hideiqxshlgvjk.com:5050`

## 📝 支持的协议

### ✅ 在 Render 上可用的协议

由于 Render Web Service 只支持 HTTP(S) 路由，以下协议可以正常工作：

1. **HTTP 代理** (当前配置)
   ```bash
   listen=http://:10000
   ```

2. **Mixed 模式** (HTTP + SOCKS5 自动检测)
   ```bash
   listen=mixed://:10000
   ```
   - 客户端可以用 HTTP 或 SOCKS5 协议连接
   - Render 会将其作为 HTTP 流量路由

3. **WebSocket 代理**
   ```bash
   listen=ws://:10000
   ```
   - 适合需要穿透防火墙的场景
   - 客户端需要支持 WS 协议

### ❌ 在 Render 上不可用的协议

以下协议需要原生 TCP/UDP 支持，Render 不支持：

- SOCKS5 (socks5://)
- Shadowsocks (ss://)
- Trojan (trojan://)
- VMess (vmess://)
- VLESS (vless://)
- SSR (ssr://)

**替代方案**: 使用支持原生 TCP 的平台：
- Railway (推荐，支持 TCP)
- Fly.io (支持 TCP/UDP)
- DigitalOcean App Platform
- Koyeb

## 🔧 使用方法

### 方法 1: HTTP 代理模式 (推荐)

```bash
# 你的 Render 服务地址
PROXY_URL="http://your-service.onrender.com"

# 使用 curl
curl -x $PROXY_URL http://ipinfo.io/ip

# 使用 wget
wget -e use_proxy=yes -e http_proxy=$PROXY_URL http://example.com

# 浏览器配置
# HTTP Proxy: your-service.onrender.com
# Port: 80 (或 443 for HTTPS)
```

### 方法 2: 系统全局代理

#### macOS
```bash
export http_proxy=http://your-service.onrender.com
export https_proxy=http://your-service.onrender.com
export ALL_PROXY=http://your-service.onrender.com
```

#### Windows (PowerShell)
```powershell
$env:http_proxy="http://your-service.onrender.com"
$env:https_proxy="http://your-service.onrender.com"
```

#### Linux
```bash
export http_proxy=http://your-service.onrender.com
export https_proxy=http://your-service.onrender.com
export no_proxy=localhost,127.0.0.1
```

### 方法 3: 编程语言中使用

#### Python
```python
import requests

proxies = {
    'http': 'http://your-service.onrender.com',
    'https': 'http://your-service.onrender.com',
}

response = requests.get('http://ipinfo.io/ip', proxies=proxies)
print(response.text)
```

#### Node.js
```javascript
const axios = require('axios');

axios.get('http://ipinfo.io/ip', {
  proxy: {
    host: 'your-service.onrender.com',
    port: 80
  }
}).then(response => {
  console.log(response.data);
});
```

#### Go
```go
package main

import (
    "fmt"
    "net/http"
    "net/url"
)

func main() {
    proxyURL, _ := url.Parse("http://your-service.onrender.com")
    client := &http.Client{
        Transport: &http.Transport{
            Proxy: http.ProxyURL(proxyURL),
        },
    }
    
    resp, _ := client.Get("http://ipinfo.io/ip")
    // ... handle response
}
```

## 🔄 切换到 Mixed 模式

如果你想让服务同时支持 HTTP 和 SOCKS5 客户端：

1. 编辑 `glider.conf`：
   ```conf
   # 注释掉这行
   # listen=http://:10000
   
   # 启用这行
   listen=mixed://:10000
   ```

2. 提交并推送：
   ```bash
   git add glider.conf
   git commit -m "Switch to mixed mode"
   git push
   ```

3. 使用时：
   ```bash
   # HTTP 客户端仍然可以连接
   curl -x http://your-service.onrender.com http://example.com
   
   # SOCKS5 客户端也可以连接（通过 HTTP 隧道）
   curl --socks5 your-service.onrender.com http://example.com
   ```

## 🐛 故障排查

### 错误: "connection refused"
- **原因**: 目标服务器拒绝连接或上游代理不可用
- **解决**: 
  1. 检查上游 SOCKS5 代理是否正常
  2. 测试: `curl --socks5 bfmedia-type-residential-location-US-isp-T%20Mobile%20USA%2C%20Inc.:52545856@proxy.hideiqxshlgvjk.com:5050 http://ipinfo.io/ip`

### 错误: "can not parse request ... EOF"
- **原因**: 客户端直接访问 Render URL 而不是作为代理使用
- **解决**: 不要在浏览器直接打开链接，而是配置为代理服务器

### 错误: "407 Proxy Authentication Required"
- **原因**: 如果配置了认证，客户端需要提供用户名密码
- **解决**: 在 glider.conf 中添加：
  ```conf
  listen=http://user:pass@:10000
  ```

### Render 服务休眠 (Free Plan)
- **问题**: 15分钟无流量会休眠，首次访问需要等待
- **解决**: 
  - 升级到付费计划
  - 或使用定时 ping 保持活跃（违反 ToS，不推荐）

## 📊 性能优化

### 调整超时设置
```conf
dialtimeout=10      # 连接超时（秒）
relaytimeout=300    # 数据传输超时（秒），0=无限制
checkinterval=30    # 健康检查间隔（秒）
```

### 添加多个上游代理
```conf
# 负载均衡多个 SOCKS5 代理
forward=socks5://proxy1:5050
forward=socks5://proxy2:5050
forward=socks5://proxy3:5050

# 策略
strategy=rr         # rr=轮询, ha=高可用, lha=延迟高可用, dh=目标哈希
```

## 🔒 安全建议

1. **添加认证**：
   ```conf
   listen=http://admin:your-strong-password@:10000
   ```

2. **使用 HTTPS**：Render 自动提供 SSL
   ```bash
   curl -x https://your-service.onrender.com http://example.com
   ```

3. **IP 白名单**：在上游 SOCKS5 代理商后台配置

4. **监控流量**：定期检查 Render 日志和流量使用

## 📈 监控和日志

### 查看实时日志
在 Render Dashboard → 你的服务 → Logs

### 关键日志信息
```
# 成功连接
[http] <client_ip> <-> <target> via DIRECT

# 连接失败
[http] ... error in dial: ...

# 解析错误
[http] can not parse request from ...
```

## 💰 成本估算

- **Free Plan**: 750小时/月，512MB RAM，会休眠
- **Starter ($7/月)**: 始终在线，512MB RAM
- **Standard ($25/月)**: 2GB RAM，更好性能

带宽没有限制，但滥用可能被暂停。

## 🚀 进阶配置

### 添加规则转发
创建 `rules.d/bypass.rule`：
```conf
# 直连国内网站
domain=baidu.com
domain=taobao.com
forward=direct://
```

更新 `glider.conf`：
```conf
rules-dir=rules.d
```

### WebSocket 模式（穿透防火墙）
```conf
listen=ws://:10000
```

客户端连接：
```bash
# 使用支持 WS 的客户端
# 例如 V2Ray、Clash 等
```

## 📚 更多资源

- [Glider 官方文档](https://github.com/nadoo/glider)
- [Render 文档](https://render.com/docs)
- [配置示例](https://github.com/nadoo/glider/tree/master/config/examples)

---

**部署时间**: 2025-10-04  
**版本**: Glider 0.17.0  
**平台**: Render Web Service

