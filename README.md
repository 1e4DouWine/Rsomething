# RS 智能助手

智能个人知识助手，深度融入系统分享机制，利用 AI 自动分析分享内容并执行记账、添加待办、创建日程等操作。

vibe coding 项目

## 功能特性

### 记忆流

- 通过系统分享将任意 App 的内容发送至 RS，AI 自动识别并分类
- 支持文本和图片的多模态分析
- 按类型筛选（账单 / 待办 / 日程 / 摘要）和模糊搜索
- 手动输入文本，由 AI 自动分析识别类型

### 账本

- 月度消费总额统计（数字滚动动画）
- 按分类统计消费占比（进度条 + 百分比）
- 支持餐饮、交通、购物、娱乐、住房等分类

### 待办

- 添加待办事项（支持截止日期时间）
- 完成状态切换、滑动删除
- 本地通知提醒（提前可配置分钟数）
- 过期标识、已完成项显示/隐藏

### AI 模型配置

- 支持多份 AI 配置档案并存
- 兼容 OpenAI 格式 API（默认使用 OpenRouter）
- 测试连接功能
- API Key 安全存储在系统 Keychain/Keystore

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter (Dart ^3.11.5) |
| 状态管理 | Provider + ChangeNotifier |
| 本地数据库 | SQLite (sqflite) |
| 网络请求 | Dio |
| 安全存储 | flutter_secure_storage |
| 本地通知 | flutter_local_notifications |
| 系统分享 | share_handler |
| 自适应布局 | NavigationBar / NavigationRail (600px 断点) |

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # 根组件（Provider 配置、主题、分享监听）
├── models/                      # 数据模型（memory, expense, todo, calendar_event, ai_config_profile）
├── providers/                   # 状态管理（memory, expense, todo, ai）
├── services/                    # 服务层（ai, database, settings, notification, permission）
├── screens/                     # 页面（记忆流、账本、待办、设置、分享接收）
├── theme/                       # Material 3 主题配置
├── utils/                       # 工具函数
└── widgets/                     # 公共组件（自适应布局、记忆卡片）
```

## 数据库结构

SQLite 数据库，启用外键约束，包含 4 张表：

- **memories** — 核心记忆表
- **expenses** — 消费记录表（外键关联 memories）
- **todos** — 待办事项表（外键关联 memories）
- **calendar_events** — 日程事件表（外键关联 memories）

## 平台支持

| 平台 | 状态 |
|------|------|
| Android | ✅ 主要目标平台 |
| iOS | 未测试 |
| Web | 未测试 |
| Windows | 未测试 |
| macOS | 未测试 |
| Linux | 未测试 |

## 快速开始

### 环境要求

- Flutter SDK (Dart ^3.11.5)
- 各平台对应的开发环境（Android Studio / Xcode / Visual Studio 等）

### 安装与运行

```bash
# 克隆项目
git clone <repository-url>

# 进入项目目录
cd flutter_app

# 安装依赖
flutter pub get

# 运行项目
flutter run
```

### AI 配置

1. 进入 **我的 → 通用设置 → AI 模型配置**
2. 添加配置档案，填入 API Base URL、API Key 和模型名称
3. 默认使用 OpenRouter API（`https://openrouter.ai/api/v1/chat/completions`）

## 测试

```bash
flutter test
```

## 版权

© 2026 RS Team
