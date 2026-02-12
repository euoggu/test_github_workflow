# task_action_runner

本任务提供一个本地脚本 `action.sh`，用于交互式触发 GitHub Actions：

- 列出支持 `workflow_dispatch` 的 Action
- 选择 Action 并输入参数（如有）
- 支持复用上一次参数（会先展示上一次参数）
- 实时跟踪执行状态
- 失败时输出失败步骤和失败日志片段
- 成功时自动用 Google Chrome 打开执行结果页面

## 使用

```bash
./task_action_runner/action.sh
```

> 运行前请先完成 GitHub CLI 登录：`gh auth login`

建议第一次先选一个无参数的 Action（例如 `build-pinpoint-boot-17.yml`）做验证。

参数缓存文件默认保存在当前目录：`./.action_runner_last_params.json`。
