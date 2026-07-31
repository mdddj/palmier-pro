# Palmier Pro 后端 API 替换指南

> **目标**：将 Palmier Pro 的 AI 生成后端从 Convex 替换为我们自己的模型服务，使视频/图片/音频生成、转译、Agent 对话等能力全部走自建 API。

---

## 一、整体架构概览

```
┌──────────────────────────────┐
│   Palmier Pro macOS App      │
│                              │
│  ┌─────────────────────────┐ │
│  │ GenerationBackend.swift │ │──── HTTP ────┐
│  │ TranscriptionBackend    │ │              │
│  │ ModelCatalog            │ │         ┌────▼──────────┐
│  │ AgentService            │ │         │  我们的后端     │
│  │ BackendStorage          │ │         │  (需实现)       │
│  └─────────────────────────┘ │         └───────────────┘
└──────────────────────────────┘
```

项目中所有后端调用都集中在少数几个文件中，替换它们即可完成迁移。

---

## 二、需要实现的 API 端点

### 2.1 文件上传

用于将用户本地媒体文件上传到云端，供生成任务引用。

#### 2.1.1 获取上传凭证

```
POST /api/uploads/ticket
Content-Type: application/json
Authorization: Bearer <jwt>

请求体: {}
```

响应：

```json
{
  "uploadUrl": "https://upload.our-domain.com/upload/abc-123",
  "storageId": "abc-123"
}
```

#### 2.1.2 上传文件

客户端拿到 `uploadUrl` 后会以 **HTTP POST** 直接上传文件（multipart/form-data 或者直接 binary body，Content-Type 为文件实际 MIME 类型）。

你的上传服务需要：
- 接收文件并存储到你自己的 OSS/CDN
- 保留 `storageId` 与最终公开 URL 的映射

#### 2.1.3 确认上传完成

```
POST /api/uploads/commit
Content-Type: application/json
Authorization: Bearer <jwt>

请求体: {
  "storageId": "abc-123"
}
```

响应：

```json
{
  "url": "https://cdn.our-domain.com/files/abc-123/final.mp4"
}
```

返回的 `url` 必须是**可公开访问的 URL**，后续会作为生成任务的输入引用。

---

### 2.2 模型列表

```
GET /api/models?catalogVersion=3
Authorization: Bearer <jwt>
```

响应为一个 JSON 数组 `CatalogEntry[]`，下面给出一个完整示例。**你可以根据自己的模型服务返回实际支持的模型**，不需要完全复制 Palmier 的模型 ID。

```json
[
  {
    "id": "our-video-model-1",
    "kind": "video",
    "displayName": "Our Video Gen v1",
    "providerName": "OurCompany",
    "description": "Text-to-video generation",
    "allowedEndpoints": ["generations:submit"],
    "responseShape": "video",
    "uiCapabilities": {
      "supportsPrompt": true,
      "durations": [5, 10],
      "resolutions": ["1080p", "720p"],
      "aspectRatios": ["16:9", "9:16", "1:1"],
      "supportsFirstFrame": false,
      "supportsLastFrame": false,
      "maxReferenceImages": 3,
      "maxReferenceVideos": 0,
      "maxReferenceAudios": 0,
      "maxTotalReferences": 3,
      "maxCombinedVideoRefSeconds": null,
      "maxCombinedAudioRefSeconds": null,
      "framesAndReferencesExclusive": false,
      "referenceTagNoun": "reference",
      "requiresSourceVideo": false,
      "maxSourceVideoSeconds": null,
      "maxSourceVideoResolution": null,
      "requiredSourceVideoEncoding": null,
      "requiresReferenceImage": false,
      "requiresReferenceAudio": false
    },
    "creditsPerSecond": {"1080p": 0, "720p": 0},
    "paidOnly": false
  },
  {
    "id": "our-image-model-1",
    "kind": "image",
    "displayName": "Our Image Gen v1",
    "providerName": "OurCompany",
    "description": "Text-to-image generation",
    "allowedEndpoints": ["generations:submit"],
    "responseShape": "images",
    "uiCapabilities": {
      "resolutions": ["1920x1080", "1080x1920", "1024x1024"],
      "aspectRatios": ["16:9", "9:16", "1:1"],
      "qualities": ["standard", "high"],
      "supportsImageReference": true,
      "maxImages": 4
    },
    "creditsPerImage": {"1024x1024": 0},
    "paidOnly": false
  },
  {
    "id": "our-audio-model-1",
    "kind": "audio",
    "displayName": "Our TTS v1",
    "providerName": "OurCompany",
    "description": "Text-to-speech",
    "allowedEndpoints": ["generations:submit"],
    "responseShape": "audio",
    "uiCapabilities": {
      "category": "tts",
      "voices": ["male-1", "female-1"],
      "defaultVoice": "female-1",
      "supportsLyrics": false,
      "supportsInstrumental": false,
      "supportsStyleInstructions": false,
      "durations": [10, 30, 60],
      "minPromptLength": 1,
      "maxReferenceImages": 0,
      "maxReferenceAudios": 0,
      "inputs": ["text"]
    },
    "audioPricing": {"mode": "perThousandChars", "rate": 0},
    "paidOnly": false
  },
  {
    "id": "our-upscale-model-1",
    "kind": "upscale",
    "displayName": "Our Upscaler v1",
    "providerName": "OurCompany",
    "description": "Video and image upscaling",
    "allowedEndpoints": ["generations:submit"],
    "responseShape": "upscaledImage",
    "uiCapabilities": {
      "speed": "Fast",
      "p75DurationSeconds": 60,
      "maximumUpscaleFactor": 4.0,
      "supportedTypes": ["video", "image"],
      "selectSettings": [
        {
          "id": "model",
          "label": "AI Model",
          "options": [
            {"label": "Fast", "value": "fast", "description": "Quick results", "group": null, "groupDescription": null},
            {"label": "Quality", "value": "quality", "description": "Best visual quality", "group": null, "groupDescription": null}
          ],
          "defaultValue": "fast"
        }
      ],
      "numericSettings": [
        {
          "id": "scale",
          "label": "Upscale Factor",
          "minimum": 1.0,
          "maximum": 4.0,
          "step": 0.5
        }
      ],
      "toggleSettings": [
        {
          "id": "denoise",
          "label": "Reduce Noise",
          "defaultValue": false
        }
      ]
    },
    "creditsPerSecondUpscale": 0,
    "paidOnly": false
  }
]
```

#### 字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | string | 模型唯一标识 |
| `kind` | `"video" \| "image" \| "audio" \| "upscale"` | 模型类型 |
| `displayName` | string | UI 中显示的名称 |
| `providerName` | string? | 模型提供商名称，显示在 UI 中 |
| `description` | string? | 模型描述文本 |
| `allowedEndpoints` | string[] | 模型可用于哪些操作的白名单，目前唯一有效值是 `["generations:submit"]` |
| `responseShape` | `"video" \| "images" \| "audio" \| "upscaledImage"` | 生成结果的媒体类型 |
| `uiCapabilities` | object | 前端 UI 控制参数（分辨率、时长等可选项），根据 `kind` 对应不同结构 |
| `creditsPerSecond` | object? | 视频模型按秒计费（key 为分辨率，value 为每秒钟积分数） |
| `audioDiscountRate` | object? | 视频模型生成音频的折扣率（key 为分辨率，value 为折扣系数，1.0 = 原价） |
| `creditsPerImage` | object? | 图片模型按张计费（key 为分辨率，value 为每张积分数） |
| `qualities` | string[]? | 顶层质量选项列表（与 `uiCapabilities.qualities` 独立，目前 UI 未使用顶层值） |
| `audioPricing` | object? | 音频模型计费模式，见下方 AudioPricing 格式 |
| `creditsPerSecondUpscale` | number? | 超分模型每秒积分速率 |
| `upscalePricing` | object? | 超分模型详细计费，见下方 UpscalePricing 格式 |
| `paidOnly` | bool | 是否仅付费用户可用（自用填 false） |

**AudioPricing 格式**（用于 `audioPricing` 字段）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `mode` | `"perThousandChars" \| "perSecond" \| "flat"` | 计费模式 |
| `rate` | number | 费率（perThousandChars: 每千字符积分；perSecond: 每秒积分；flat: 固定积分） |
| `textRate` | number? | 仅 `perSecond` 模式下，文本输入的特殊费率（可选） |
| `price` | number? | 仅 `flat` 模式下的固定价格 |

示例：
```json
{ "mode": "perThousandChars", "rate": 5 }
{ "mode": "perSecond", "rate": 2, "textRate": 1 }
{ "mode": "flat", "price": 10 }
```

**UpscalePricing 格式**（用于 `upscalePricing` 字段）：

```json
{
  "mode": "perSecond",
  "ratesByResolution": { "1080p": 2.0, "4k": 4.0 },
  "sourceResolutionFloor": true,
  "fpsMultipliers": { "30": 1.0, "60": 1.5 }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `mode` | `"perSecond" \| "flat"` | 计费模式 |
| `ratesByResolution` | object? | perSecond 模式下按分辨率费率 |
| `sourceResolutionFloor` | bool? | 是否按源分辨率兜底计费 |
| `fpsMultipliers` | object? | 帧率倍率 |
| `tierMultipliers` | object? | 套餐倍率 |
| `megapixelRates` | object[]? | 按目标像素面积计费（`[{upTo: number, credits: number}]`） |

> **重要**：如果你的模型不支持某些能力，把对应字段设为 `false` / `null` / 空数组即可，客户端会自动隐藏不可用的 UI 选项。

---

### 2.3 提交生成任务（核心接口）

```
POST /api/generations/submit
Content-Type: application/json
Authorization: Bearer <jwt>

请求体: {
  "model": "our-video-model-1",
  "params": { ... },
  "projectId": "optional-project-id"
}
```

响应：

```json
{
  "jobId": "job-abc-123"
}
```

#### 2.3.1 Video 生成参数格式

`params` 示例（由客户端的 `VideoGenerationParams` 序列化而来）：

```json
{
  "kind": "video",
  "prompt": "A golden retriever running on a beach at sunset",
  "duration": 5,
  "sourceVideoDuration": null,
  "aspectRatio": "16:9",
  "resolution": "1080p",
  "sourceVideoURL": null,
  "startFrameURL": null,
  "endFrameURL": null,
  "referenceImageURLs": ["https://cdn.our-domain.com/ref1.jpg"],
  "referenceVideoURLs": [],
  "referenceAudioURLs": [],
  "generateAudio": true
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `kind` | string | ✅ | 固定 `"video"` |
| `prompt` | string | ✅ | 文本提示词 |
| `duration` | int | ✅ | 生成视频时长（秒） |
| `aspectRatio` | string | ✅ | 宽高比，如 `"16:9"` `"9:16"` `"1:1"` |
| `resolution` | string | ❌ | 分辨率标签，如 `"1080p"` `"720p"` |
| `sourceVideoURL` | string | ❌ | 视频编辑模式下，原始视频的 URL |
| `sourceVideoDuration` | float | ❌ | 原始视频时长 |
| `startFrameURL` | string | ❌ | 起始帧图片 URL |
| `endFrameURL` | string | ❌ | 结束帧图片 URL |
| `referenceImageURLs` | string[] | ❌ | 参考图片 URL 列表 |
| `referenceVideoURLs` | string[] | ❌ | 参考视频 URL 列表 |
| `referenceAudioURLs` | string[] | ❌ | 参考音频 URL 列表 |
| `generateAudio` | bool | ✅ | 是否同时生成音频 |

#### 2.3.2 Image 生成参数格式

```json
{
  "kind": "image",
  "prompt": "A serene mountain lake at dawn",
  "aspectRatio": "16:9",
  "resolution": "1920x1080",
  "quality": "high",
  "imageURLs": ["https://cdn.our-domain.com/ref1.jpg"],
  "numImages": 2
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `kind` | string | ✅ | 固定 `"image"` |
| `prompt` | string | ✅ | 文本提示词 |
| `aspectRatio` | string | ✅ | 如 `"16:9"` `"1:1"` `"9:16"` |
| `resolution` | string | ❌ | 如 `"1920x1080"` |
| `quality` | string | ❌ | 如 `"standard"` `"high"` |
| `imageURLs` | string[] | ❌ | 参考图 URL 列表 |
| `numImages` | int | ✅ | 生成图片数量，1-4 |

#### 2.3.3 Audio 生成参数格式

```json
{
  "kind": "audio",
  "prompt": "A gentle piano lullaby",
  "voice": null,
  "lyrics": null,
  "styleInstructions": null,
  "instrumental": true,
  "durationSeconds": 30,
  "videoURL": null,
  "sourceURL": null,
  "targetLanguage": null,
  "referenceImageURL": null,
  "referenceAudioURLs": null,
  "multilingual": null
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `kind` | string | ✅ | 固定 `"audio"` |
| `prompt` | string | 条件 | 文本提示（TTS/音乐/SFX 都支持） |
| `voice` | string | ❌ | TTS 语音 ID |
| `instrumental` | bool | ✅ | 是否纯音乐 |
| `durationSeconds` | int | ❌ | 目标时长 |
| `sourceURL` | string | ❌ | 输入音频 URL（语音克隆等场景） |
| `videoURL` | string | ❌ | 输入视频 URL（提取音频用） |
| `referenceAudioURLs` | string[] | ❌ | 参考音频 |
| `targetLanguage` | string | ❌ | 目标语言（配音场景） |

#### 2.3.4 Upscale（超分）参数格式

```json
{
  "kind": "upscale",
  "sourceURL": "https://cdn.our-domain.com/source.mp4",
  "durationSeconds": 10,
  "sourceWidth": 1920,
  "sourceHeight": 1080,
  "sourceFPS": 24.0,
  "settings": {
    "selections": {"model": "fast"},
    "numbers": {"scale": 2.0},
    "toggles": {"denoise": true}
  }
}
```

---

### 2.4 查询任务状态（轮询）

```
GET /api/generations/jobs/{jobId}
Authorization: Bearer <jwt>
```

响应（任务未完成时 `resultUrls` 为 `null`）：

```json
{
  "_id": "job-abc-123",
  "status": "running",
  "resultUrls": null,
  "errorMessage": null,
  "costCredits": 0,
  "completedAt": null
}
```

任务成功时：

```json
{
  "_id": "job-abc-123",
  "status": "succeeded",
  "resultUrls": ["https://cdn.our-domain.com/output/gen-abc.mp4"],
  "errorMessage": null,
  "costCredits": 0,
  "completedAt": 1690000000.123
}
```

任务失败时：

```json
{
  "_id": "job-abc-123",
  "status": "failed",
  "resultUrls": null,
  "errorMessage": "GPU out of memory",
  "costCredits": 0,
  "completedAt": 1690000000.123
}
```

**状态流转**：`queued` → `running` → `succeeded` 或 `failed`

**客户端轮询策略**：客户端会持续轮询此接口直到状态变为终态。建议轮询间隔 1-2 秒。

> **可选优化**：如果你想减少轮询开销，可以支持 SSE 推送，但这需要额外改造客户端代码。轮询方式完全可用，客户端已有处理逻辑。

---

### 2.5 转录 API

#### 2.5.1 提交转录任务

```
POST /api/transcriptions/submit
Content-Type: application/json
Authorization: Bearer <jwt>

请求体: {
  "storageId": "abc-123",
  "durationSeconds": 120.5,
  "model": "cloud",
  "languageMode": "auto",
  "language": "en-US",
  "projectId": "optional"
}
```

响应：

```json
{
  "jobId": "trans-job-xyz"
}
```

#### 2.5.2 查询转录任务状态

```
GET /api/transcriptions/jobs/{jobId}
Authorization: Bearer <jwt>
```

响应：

```json
{
  "id": "trans-job-xyz",
  "status": "succeeded",
  "errorMessage": null
}
```

状态：`queued` → `running` → `succeeded` / `failed`

#### 2.5.3 获取转录结果

```
POST /api/transcriptions/result
Content-Type: application/json
Authorization: Bearer <jwt>

请求体: {
  "id": "trans-job-xyz"
}
```

响应：

```json
{
  "resultUrl": "https://cdn.our-domain.com/transcripts/xyz.json"
}
```

`resultUrl` 指向一个 JSON 文件，内容格式：

```json
{
  "text": "Today we're going to talk about...",
  "language": "en",
  "words": [
    {"text": "Today", "start": 0.0, "end": 0.5, "speaker": "SPEAKER_1"},
    {"text": "we're", "start": 0.5, "end": 0.7, "speaker": "SPEAKER_1"}
  ],
  "segments": [
    {"text": "Today we're going to talk about...", "start": 0.0, "end": 3.5, "speaker": "SPEAKER_1"}
  ]
}
```

---

### 2.6 Agent（大语言模型对话）API

```
POST /api/agent/stream
Content-Type: application/json
Authorization: Bearer <jwt>
Accept: text/event-stream

请求体: {
  "model": "claude-sonnet-5",
  "max_tokens": 8192,
  "stream": true,
  "system": [
    {"type": "text", "text": "You are a helpful video editor assistant...", "cache_control": {"type": "ephemeral"}}
  ],
  "messages": [
    {"role": "user", "content": [{"type": "text", "text": "Add a fade transition"}]}
  ],
  "tools": [
    {
      "name": "add_transition",
      "description": "Add a transition between clips",
      "input_schema": {
        "type": "object",
        "properties": {
          "clipId": {"type": "string"},
          "type": {"type": "string", "enum": ["fade", "dissolve"]}
        },
        "required": ["clipId", "type"]
      }
    }
  ]
}
```

#### 响应格式（SSE 流）

```
data: {"type":"message_start","message":{"usage":{"input_tokens":100,"output_tokens":0}}}

data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"I'll add "}}

data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"a fade transition."}}

data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_01","name":"add_transition"}}

data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\"clipId\":"}}

data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"\"abc\",\"type\":\"fade\"}"}}

data: {"type":"content_block_stop","index":1}

data: {"type":"message_delta","delta":{"stop_reason":"tool_use"}}
```

SSE 事件类型总结：

| `type` | 作用 |
|--------|------|
| `message_start` | 流开始，包含 usage 信息 |
| `content_block_start` | 开始一个新的内容块（文本或 tool_use） |
| `content_block_delta` | 内容块的增量数据 |
| `content_block_stop` | 内容块结束 |
| `message_delta` | 消息级 delta，包含 `stop_reason` |
| `error` | 错误事件，包含 `{"error": {"message": "..."}}` |

`stop_reason` 取值：
- `"end_turn"` — 正常结束
- `"tool_use"` — 需要执行工具调用
- `"max_tokens"` — 达到 token 限制
- `"stop_sequence"` — 遇到停止序列

> **兼容方案**：你可以把任意 LLM（GPT、DeepSeek 等）包装成 Anthropic SSE 格式输出。关键要点：
> 1. 请求体兼容 Anthropic Messages API 格式
> 2. 响应以 `data: <json>\n\n` 的 SSE 格式流式输出
> 3. `stream` 字段始终为 `true`（客户端强制流式）

---

### 2.7 账户 API（可返回固定值）

如果你是自用不涉及付费，返回固定假数据即可：

```
GET /api/account
→
{
  "user": {
    "email": "dev@ourcompany.com",
    "name": "Dev User",
    "image": null,
    "tier": "max",
    "currentPeriodEnd": null,
    "cancelAtPeriodEnd": false,
    "spentCreditsThisPeriod": 0,
    "purchasedCredits": 999999
  },
  "plan": {
    "tier": "max",
    "monthlyPriceUsd": 0,
    "monthlyBudgetCredits": 999999
  }
}
```

```
GET /api/billing/plans
→ []
```

---

## 三、需要修改的客户端文件

在员工实现好上述 API 后，需要修改以下 Swift 文件来对接新后端：

| 文件路径 | 改动说明 | 优先级 |
|----------|----------|--------|
| `Sources/PalmierPro/Backend/BackendConfig.swift` | 修改 `convexDeploymentURL` 和 `convexHttpURL` 指向你的 API 地址 | 🔴 最高 |
| `Sources/PalmierPro/Generation/GenerationBackend.swift` | 替换 Convex 调用为标准 HTTP 调用 | 🔴 最高 |
| `Sources/PalmierPro/Transcription/TranscriptionBackend.swift` | 同上 | 🟡 高 |
| `Sources/PalmierPro/Backend/BackendStorage.swift` | 替换文件上传逻辑 | 🟡 高 |
| `Sources/PalmierPro/Agent/Clients/PalmierClient.swift` | 修改 Agent API 端点 | 🟡 高 |
| `Sources/PalmierPro/Generation/Catalog/ModelCatalog.swift` | 修改模型列表的数据源 | 🟢 中 |
| `Sources/PalmierPro/Account/AccountService.swift` | 简化账户逻辑，返回固定假用户 | 🟢 中 |
| `Sources/PalmierPro/Transcription/CloudTranscription.swift` | 可保留，后端替换后自动生效 | 🟢 低 |

### 关键注意事项

1. **认证方式**：如果你的后端不需要 Clerk 认证，需要修改 `PalmierClient.swift` 去掉 `Clerk.shared.session.getToken()` 调用，改为你自己的 token 方式（或直接移除认证）
2. **Subscription → 轮询**：Convex 用的是 WebSocket 实时订阅，改成 REST 后需要改为 HTTP 轮询（客户端已有 `AsyncStream` 模式，只需把 `AnyPublisher` 改成轮询循环）
3. **Agent API**：`PalmierClient.swift` 调的是 `POST /v1/agent/stream`（SSE），你需要提供一个兼容 Anthropic 消息格式的 SSE 端点
4. **不要修改** `Sources/PalmierPro/Generation/Catalog/ModelCatalog.swift` 中的 `CatalogEntry` 和 `VideoCaps`/`ImageCaps`/`AudioCaps` 等 Decodable 模型结构，它们定义了客户端如何解析模型配置——只改数据来源（从 Convex subscription 改为 HTTP GET）

---

## 四、分阶段实施建议

### 第一阶段：最小可用（生成功能）

1. 先实现 **模型列表** + **提交任务** + **查询状态** 3 个接口
2. 修改 `GenerationBackend.swift` 对接你的 API
3. 用户可以在 UI 中选择模型、输入 prompt、点击生成，拿到结果

### 第二阶段：文件上传 + 转录

1. 实现文件上传和转录 API
2. 修改 `BackendStorage.swift` 和 `TranscriptionBackend.swift`

### 第三阶段：Agent 对话

1. 实现 SSE Agent 端点
2. 修改 `PalmierClient.swift`

### 第四阶段：清理

1. 移除 Clerk 依赖
2. 移除 ConvexMobile 依赖
3. 清理未使用的代码

---

## 五、快速参考：curl 测试命令

```bash
BASE="https://your-api.example.com/api"

# 1. 获取模型列表
curl -H "Authorization: Bearer YOUR_TOKEN" "$BASE/models?catalogVersion=3"

# 2. 提交视频生成任务
curl -X POST "$BASE/generations/submit" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "our-video-model-1",
    "params": {
      "kind": "video",
      "prompt": "A sunset beach",
      "duration": 5,
      "aspectRatio": "16:9",
      "resolution": "1080p",
      "generateAudio": true
    }
  }'

# 3. 查询任务状态
curl -H "Authorization: Bearer YOUR_TOKEN" "$BASE/generations/jobs/{jobId}"

# 4. Agent 聊天（SSE）
curl -N -X POST "$BASE/agent/stream" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "model": "claude-sonnet-5",
    "max_tokens": 1024,
    "stream": true,
    "system": [{"type":"text","text":"You are a helpful assistant."}],
    "messages": [{"role":"user","content":[{"type":"text","text":"Hello!"}]}]
  }'
```

---

> 如有任何字段或格式问题，参考本文档中的示例 JSON 即可。客户端完全按照这些结构进行编解码。
