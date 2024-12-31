#!/bin/bash

# 设置代理（保留原有的代理设置）
export https_proxy=http://192.168.8.1:7897 http_proxy=http://192.168.8.1:7897 all_proxy=socks5://192.168.8.1:7897

# 定义版本号
VERSION="v1.0.0"

# 确保所有更改都已提交
git add .
git commit -m "准备发布 $VERSION"

# 推送代码到远程仓库
git push origin main

# 创建新的标签
git tag $VERSION
git push
# 推送标签到远程仓库，这将触发 GitHub Actions
git push origin $VERSION

echo "已创建并推送标签 $VERSION，GitHub Actions 工作流程将自动开始"
