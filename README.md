# 数据驱动社团生态平台（高校）

以数据采集、指标计算、可视化、智能推荐、风险预警贯穿全流程的高校社团管理平台。
技术栈：**FastAPI (Python) + Vue 3 / Element Plus + MySQL 8**，JWT 鉴权，四类角色（平台管理员 / 社长 / 干事 / 普通成员）。

## 功能模块（8 大模块 + 2 个增值亮点）

| 模块 | 内容 |
|---|---|
| 身份权限与账号体系 | 学号登录、JWT、RBAC 分级权限、操作日志审计 |
| 社团组织管理 | 社团成立审批、信息档案、年审星级评级（自动算分）、社团广场 |
| 成员人才管理 | 招新计划与申请审核、成员档案、异动（转部门/退社/换届）、活跃度模型、沉睡成员、人才推荐 |
| 活动全流程管理 | 立项审批、发布报名、口令签到+自动发积分、总结归档、满意度问卷、活动指标统计 |
| 资源物资财务 | 场地预约（冲突检测+利用率）、物资台账（领用归还+闲置预警）、经费流水（报销审批+图表+超支预警）、积分/荣誉 |
| 内容互动生态 | 公告、作品成果库（获奖归档）、讨论区（帖子/评论/点赞）、问卷、消息中心、文件云盘 |
| **数据智能分析（核心）** | 校级/社团/个人三级看板、社团健康分与星级、活跃度排行、趋势分析、社团健康预警、成员流失预测、智能推荐（社团/活动/人才）、同类对比、CSV 报表导出 |
| 系统基础支撑 | 全局搜索、消息通知、文件云盘、数据脱敏 |
| 增值亮点① 联合项目管理 | 跨社团项目立项、任务拆解分工、进度看板 |
| 增值亮点② AI 辅助 | 活动方案生成、活动总结自动生成、活动效果智能诊断（数据驱动规则实现，无外部依赖） |

## 目录结构

```
club_platform/
├── backend/            # FastAPI 后端
│   ├── app/
│   │   ├── main.py         # 应用入口
│   │   ├── core/           # 配置、安全(JWT/密码)
│   │   ├── db/             # engine/session/Base
│   │   ├── models/         # 26 张表 ORM 模型
│   │   ├── schemas/        # Pydantic 模型
│   │   ├── api/            # 路由 + 权限依赖
│   │   └── services/       # 通知/日志/积分/分析/推荐/AI
│   ├── scripts/
│   │   ├── init_db.py      # 建库建表
│   │   └── seed_data.py    # 虚拟数据生成（可复现）
│   ├── uploads/            # 上传文件（自动创建）
│   └── requirements.txt
├── frontend/           # Vue3 前端
│   └── src/ (views/ components/ api/ stores/ router/)
├── docs/api.md         # API 契约（前后端开发依据）
└── README.md
```

## 快速开始（本机运行）

### 0. 前置要求

- Python 3.11+、Node.js 18+、MySQL 8.0
- MySQL 已启动，且知道 root 密码

### 1. 配置数据库连接

```bash
# backend/.env 已有模板（.env.example），修改 DB_PASSWORD 为你的 MySQL 密码
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=你的密码
DB_NAME=club_platform
```

### 2. 初始化数据库 + 灌入虚拟数据

```bash
cd backend
python -m pip install -r requirements.txt
python scripts/init_db.py        # 建库建表
python scripts/seed_data.py      # 灌入虚拟数据（重新生成一遍完整数据）
```

虚拟数据规模：320 用户 / 24 社团 / 140 活动（覆盖过去 12 个月，含报名签到反馈）/ 招新、场地、物资、经费、作品、帖子、项目等全量数据，随机种子固定可复现。其中故意包含 3 个"不健康"社团，用于演示健康预警与流失预测。

### 3. 启动后端

```bash
cd backend
python -m uvicorn app.main:app --reload --port 8000
# 接口文档：http://127.0.0.1:8000/docs
```

### 4. 启动前端

```bash
cd frontend
npm install
npm run dev
# 访问：http://localhost:5173
```

### 演示账号

| 角色 | 账号 | 密码 |
|---|---|---|
| 平台管理员（校团委） | admin | admin123 |
| 普通学生 | student | 123456 |

> 社长/干事账号可在"用户管理"或数据库 users 表中查看（虚拟用户密码均为 123456）。

## 公网访问（内网穿透，零成本方案）

以 [cpolar](https://www.cpolar.com/) 为例（natapp / 花生壳同理）：

1. 注册 cpolar 并下载 Windows 客户端，在官网拿到 authtoken
2. 本机先按上面步骤把前后端跑起来
3. 开两条隧道：

```bash
cpolar http 5173        # 前端 → 得到公网地址 A，如 https://abc123.cpolar.cn
cpolar http 8000        # 后端 → 得到公网地址 B，如 https://xyz789.cpolar.cn
```

4. 修改两处配置让公网用户可用：
   - `backend/.env` 的 `CORS_ORIGINS` 加入公网前端地址 A（JSON 数组格式）
   - `frontend/vite.config.js`（或构建产物 `.env.production`）把后端地址指向公网地址 B
5. 重启前后端，把地址 A 发给同学即可访问

> 免费版 cpolar 地址每次重启会变，演示前重新生成即可；要固定域名/自定义域名可升级或改用云服务器部署（学生机 9.9 元/月起）。

## 后续可扩展方向

- 阿里云/腾讯云学生机正式部署（Nginx + systemd/pm2），绑定域名 + HTTPS
- 对接学校统一身份认证、第二课堂学分导出
- 移动端适配深化 / 微信小程序端
- 消息推送升级（邮件/短信）
- 数据大屏（可视化大屏展示全校社团实时概况）
