# Replit Proxy

Replit Proxy 是一个基于 FastAPI 的中转服务，用于把 Replit 应用访问外部接口的流量统一收口到代理层，便于集中日志记录和统一控制。

## 功能概览

- 统一代理 `api/eagle-pms` 相关请求
- 提供健康检查接口 `GET /health`
- 记录请求日志（来源 IP、方法、路径、状态码、耗时）
- 使用应用级 `httpx.AsyncClient`，支持连接复用与超时控制

## 环境要求

- Python 3.10+
- [uv](https://github.com/astral-sh/uv)
- （可选）Windows 服务安装需要 [NSSM](https://nssm.cc/download)
- （可选）Linux 服务安装需要 `systemd`

## 安装教程

### 1) 克隆并进入项目

```bash
git clone <your-repo-url>
cd replit-proxy
```

### 2) 安装依赖

```bash
uv sync
```

### 3) 启动服务

#### 通用方式（推荐）

```bash
uv run uvicorn main:app --host 0.0.0.0 --port 8080
```

#### 脚本方式

- Linux/macOS:
  ```bash
  ./scripts/run.sh
  ```
- Windows:
  ```bat
  scripts\run.bat
  ```

### 4) 验证是否启动成功

```bash
curl http://127.0.0.1:8080/health
```

返回示例：

```json
{"status":"ok","service":"replit-proxy"}
```

## 卸载教程

按你的部署方式选择对应卸载步骤。

### A. 仅本地运行（未安装系统服务）

1. 停止当前运行进程（在终端中 `Ctrl + C`）
2. （可选）清理虚拟环境和缓存：

```bash
rm -rf .venv .ruff_cache
```

Windows 可手动删除对应目录。

### B. Linux/macOS（systemd 服务）卸载

#### 用户级服务（默认）

```bash
./scripts/remove-service.sh
```

#### 系统级服务（使用 `--system` 安装过）

```bash
./scripts/remove-service.sh --system
```

如果你还未安装但需要先安装服务，可用：

```bash
./scripts/install-service.sh
# 或
./scripts/install-service.sh --system
```

### C. Windows（NSSM 服务）卸载

```bat
scripts\remove-service.bat
```

如果你还未安装但需要先安装服务，可用：

```bat
scripts\install-service.bat
```

## 文件结构说明

```text
replit-proxy/
├─ main.py                     # FastAPI 入口，代理路由与日志中间件
├─ config.py                   # 服务配置（端口、上游地址、超时等）
├─ keyvox.py                   # KeyVox/eagle-pms HMAC 签名调用示例客户端
├─ pyproject.toml              # 项目元数据与依赖定义
├─ uv.lock                     # 依赖锁文件
├─ scripts/
│  ├─ run.sh                   # Linux/macOS 启动脚本
│  ├─ run.bat                  # Windows 启动脚本
│  ├─ install-service.sh       # Linux/macOS systemd 服务安装脚本
│  ├─ remove-service.sh        # Linux/macOS systemd 服务卸载脚本
│  ├─ install-service.bat      # Windows NSSM 服务安装脚本
│  ├─ remove-service.bat       # Windows NSSM 服务卸载脚本
│  ├─ replit-proxy.service     # systemd 单元模板
│  └─ service.bat              # Windows 服务辅助脚本
├─ .gitignore                  # Git 忽略规则
└─ README.md                   # 项目说明文档
```

## 常用开发命令

```bash
# 启动（开发模式，自动重载）
uv run uvicorn main:app --host 0.0.0.0 --port 8080 --reload

# 运行测试
uv run pytest

# 代码检查与格式化
uv run ruff check .
uv run ruff format .
```

## 代理接口示例

- Replit 应用请求代理地址：
  `http://<proxy-host>:8080/api/eagle-pms/...`
- 服务会转发到上游：
  `https://eco.blockchainlock.io/api/eagle-pms/...`

