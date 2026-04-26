# autoGenImageSkill

<div align="center">

**让 OpenClaw / Hermes 通过 GPT-Image-2 稳定生成图片：官方权限码、自定义代理、预留购买能力三路入口。**

![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-1D4ED8?style=flat-square)
![ClawHub](https://img.shields.io/badge/Registry-ClawHub-0F766E?style=flat-square)
![Hermes](https://img.shields.io/badge/Agent-Hermes-7C3AED?style=flat-square)
![GPT Image](https://img.shields.io/badge/Image-GPT--Image--2-C62828?style=flat-square)
![Node](https://img.shields.io/badge/Runtime-Node-339933?style=flat-square)

GPT-Image-2 · Responses API · SSE 解码 · 文生图 · 图生图

[Skill 定义](gpt-image-relay/SKILL.md) · [接入模式](gpt-image-relay/references/access-modes.md) · [运行时说明](gpt-image-relay/references/runtime.md) · [赞助支持](#donate)

</div>

## <a id="donate"></a>赞助支持

如果这个项目对你有帮助，欢迎赞助支持继续迭代。

- 爱发电：`https://ifdian.net/a/etherstrings`
- 国内付款方式：直接使用下方收款码

<div>
  <img src="docs/assets/donate/alipay.jpg" alt="Alipay QR" width="260" />
  <img src="docs/assets/donate/wechat.jpg" alt="WeChat Pay QR" width="260" />
</div>

支持会优先用于 GPT Image 额度、代理可用性维护和后续功能迭代。

## 1. 能力简介

`gpt-image-relay` 是一个面向 OpenClaw、Hermes Agent 和其它终端 Agent 的 GPT Image 生图 skill。

目标很直接：

- 当用户有官方 OpenAI 权限码 / API key 时，直接走官方 Responses API。
- 当用户有自定义代理或兼容 OpenAI Responses 的聚合服务时，使用代理参数调用。
- 当用户要使用我预留的购买能力时，走 relay 服务的 session、key、quota、job polling 和图片下载接口。
- 对 Agent 暴露稳定 CLI，不让 Agent 每次重写 SSE 解析、base64 解码和图生图 payload。

当前稳定覆盖：

- 文生图
- 图生图
- 官方权限码 / API key
- 自定义 Responses-compatible proxy
- 预留购买能力 relay
- session 创建 / 复用
- purchase key 兑换
- quota 查询

## 2. Skill 地址

当前 publishable skill root：

```text
gpt-image-relay/
```

ClawHub / OpenClaw 页面：

```text
https://clawhub.ai/Etherstrings/gpt-image-relay
```

Hermes / GitHub skill 源：

```text
https://github.com/Etherstrings/autoGenImageSkill/tree/main/gpt-image-relay
```

ClawHub 发布时使用同一个 skill root：

```bash
clawhub publish gpt-image-relay \
  --slug gpt-image-relay \
  --name "GPT Image Relay" \
  --version 0.1.1 \
  --changelog "Add README and ClawHub donation support links and QR assets."
```

本仓库只交付 OpenClaw skill 源码，不包含安装脚本，也不会把文件复制到本机 OpenClaw skills 目录。

## 3. 命令面

主入口是：

```bash
node gpt-image-relay/scripts/gpt_image_cli.js generate
```

辅助入口：

```bash
node gpt-image-relay/scripts/gpt_image_cli.js session
node gpt-image-relay/scripts/gpt_image_cli.js redeem
node gpt-image-relay/scripts/gpt_image_cli.js quota
```

OpenClaw 运行 skill 时，`SKILL.md` 内使用 `{baseDir}/scripts/gpt_image_cli.js`，避免路径依赖当前工作目录。

## 4. 三种接入模式

### 4.1 官方权限码

```bash
node gpt-image-relay/scripts/gpt_image_cli.js generate \
  --mode official \
  --permission-code "$OPENAI_API_KEY" \
  --prompt "一张电影感的雨夜赛博城市街景" \
  --output output/cyber-rain.png
```

### 4.2 自定义代理参数

```bash
node gpt-image-relay/scripts/gpt_image_cli.js generate \
  --mode proxy \
  --base-url "$GPT_IMAGE_BASE_URL" \
  --api-key "$GPT_IMAGE_API_KEY" \
  --prompt "透明背景的可爱机器人贴纸" \
  --size 1024x1024 \
  --output output/robot-sticker.png
```

### 4.3 购买 / 预留能力

```bash
node gpt-image-relay/scripts/gpt_image_cli.js generate \
  --mode reserved \
  --service-url "$GPT_IMAGE_RELAY_URL" \
  --purchase-key "$GPT_IMAGE_PURCHASE_KEY" \
  --prompt "国风水墨质感的未来城市海报" \
  --output output/ink-future-city.png
```

## 5. 运行时合同

官方和代理模式使用同一条 Responses API 合同：

```json
{
  "model": "gpt-5.4",
  "input": "prompt or multimodal user content",
  "tools": [
    {
      "type": "image_generation",
      "model": "gpt-image-2",
      "size": "1024x1536",
      "quality": "high",
      "output_format": "png"
    }
  ],
  "tool_choice": { "type": "image_generation" },
  "stream": true
}
```

预留能力 relay 约定接口：

- `POST /api/session`
- `POST /api/session/register`
- `POST /api/keys`
- `POST /api/generate/jobs`
- `GET /api/generate/jobs/:jobId`
- `GET /api/generate/jobs/:jobId/image`

## 6. 安全边界

- 不把真实 API key、provider key、purchase key 写进仓库。
- 不回显权限码、购买码或 provider token。
- `.gitignore` 默认排除 `.env*`、输出图片和构建产物。
- 仓库里的示例都通过环境变量传入密钥。

## 7. 验证

```bash
bash scripts/validate_skill.sh
```

验证会检查：

- OpenClaw skill root 和 `SKILL.md`
- semver `version`
- `metadata.openclaw.requires.bins`
- `agents/openai.yaml`
- 引用文件完整性
- ClawHub-friendly 文本文件扩展名
- CLI 语法和帮助入口

## 8. 项目结构

```text
gpt-image-relay/
├── SKILL.md
├── agents/openai.yaml
├── references/access-modes.md
├── references/runtime.md
└── scripts/gpt_image_cli.js
```
