# GymLog — 专业健身管理 APP

深色专业风格的健身记录与营养管理应用，基于 Flutter 构建。

---

## 功能模块

| 模块 | 内容 |
|------|------|
| 🏠 主页 | 当前轮次、今日营养目标、累计数据 |
| 💪 训练记录 | 动作选择、组数/重量/次数/RPE 记录、PR 自动检测 |
| 📅 历史 | 日历打点、训练详情查看 |
| 🥗 营养 | 基于 Mifflin-St Jeor 的 BMR/TDEE 计算、宏量目标、食物推荐 |
| 📊 数据分析 | PR 记录、动作进步曲线图 |
| 👤 个人资料 | 身体数据管理、体重日志、数据导出 |

---

## 通过 GitHub Actions 构建 APK（推荐方式）

### 第一步：上传代码到 GitHub

1. 打开 [github.com](https://github.com) 并登录
2. 点击右上角 **+** → **New repository**
3. 填写仓库名（例如 `gymlog`），选择 **Private**，点击 **Create repository**
4. 在仓库页面点击 **uploading an existing file**
5. 把本项目文件夹内的**所有文件**拖入上传区域（包括隐藏的 `.github` 文件夹）
6. 点击 **Commit changes**

### 第二步：触发自动构建

代码上传后，GitHub Actions 会**自动开始构建**（约需 5-8 分钟）。

查看进度：
- 点击仓库页面顶部的 **Actions** 标签
- 看到绿色 ✅ 表示构建成功

### 第三步：下载 APK

1. 在 **Actions** 页面点击最新的构建记录
2. 页面底部找到 **Artifacts** 区域
3. 点击 **GymLog-APK** 下载压缩包
4. 解压后得到 `app-debug.apk`

### 第四步：安装到手机

1. 将 APK 文件传输到安卓手机（微信、数据线均可）
2. 手机上打开文件管理器找到 APK
3. 点击安装（需在设置中开启"允许安装未知来源应用"）

---

## 技术栈

- **框架**: Flutter 3.22
- **状态管理**: Riverpod 2
- **数据库**: SQLite (sqflite)
- **图表**: fl_chart
- **日历**: table_calendar

---

## 营养计算依据

- BMR: Mifflin-St Jeor 公式
- 蛋白质: 2.2 g/kg（Morton 2018 元分析）
- 脂肪: ≥ 0.85 g/kg（ISSN 立场声明）
- 增肌减脂同步热量: TDEE - 150 kcal（Barakat 2020）
