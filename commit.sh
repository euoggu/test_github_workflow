#!/bin/bash

# 设置代理
export https_proxy=http://192.168.8.1:7897 http_proxy=http://192.168.8.1:7897 all_proxy=socks5://192.168.8.1:7897

# 获取最新的标签版本并递增
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
MAJOR=$(echo $LATEST_TAG | sed 's/v\([0-9]*\).\([0-9]*\).\([0-9]*\)/\1/')
MINOR=$(echo $LATEST_TAG | sed 's/v\([0-9]*\).\([0-9]*\).\([0-9]*\)/\2/')
PATCH=$(echo $LATEST_TAG | sed 's/v\([0-9]*\).\([0-9]*\).\([0-9]*\)/\3/')

# 递增补丁版本号
PATCH=$((PATCH + 1))
VERSION="v$MAJOR.$MINOR.$PATCH"

echo "上一个版本: $LATEST_TAG"
echo "新版本: $VERSION"

# 拉取最新代码
git pull

# 确保所有更改都已提交
git add --all
git commit -m "准备发布 $VERSION"

# 推送代码到远程仓库
git push origin main

# 创建新的标签
git tag $VERSION
# 推送标签到远程仓库，这将触发 GitHub Actions
git push origin $VERSION

echo "已创建并推送标签 $VERSION，GitHub Actions 工作流程将自动开始"
