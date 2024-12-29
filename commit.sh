# export https_proxy="http://172.20.10.1:1082"
# export http_proxy="http://172.20.10.1:1082"
export https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897

# Git 操作
echo "开始 Git 操作..."

# 添加所有更改的文件
git add .

# 获取当前时间作为提交信息和标签
current_time=$(date "+%Y-%m-%d %H:%M:%S")
version_tag="v$(date "+%Y%m%d%H%M%S")"  # 创建一个基于时间戳的版本标签

# 添加触发 GitHub Action 的关键词
commit_message="[action] 自动提交 - ${current_time}"

# 提交更改
git commit -m "$commit_message"

# 创建标签
git tag -a $version_tag -m "Release $version_tag"

# 推送到远程仓库（包括标签）
git push origin main --tags

echo "Git 操作完成！"
