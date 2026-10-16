# 书法字帖 shufa_practice

全新独立的 Flutter 项目，与汉字找字涂色项目分开。

## 第一版功能
- 内置常见古诗词
- 描红、临摹、混合模式
- 可调每个诗句字符对应的练习格数
- 可控制诗题、作者、原诗与田字格辅助线
- 生成 A4 PDF，支持预览/打印与分享

## 在 GitHub 手机上创建项目
1. 新建一个空仓库，建议命名 `shufa_practice`。
2. 上传本包内的所有文件和目录。
3. `.github/workflows/build-apk.yml` 必须放在这个准确路径。
4. 打开仓库的 Actions，选择 `Build Shufa Practice APK`，点击运行。
5. 构建成功后打开该次运行，在 Artifacts 中下载 `shufa-practice-apk`。

## 重要说明
- Actions 会通过 `flutter create --platforms=android --org com.example .` 自动生成 Android 工程文件。
- 第一版尚未嵌入专用楷体字体。PDF 内置字体对中文的支持在不同设备上可能不同；发布前应加入可合法再分发的中文楷体字体，并验证 PDF 输出。
- 目前诗词以常见公版古诗为主，版本与标点可继续校对。
