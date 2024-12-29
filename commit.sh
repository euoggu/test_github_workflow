# export https_proxy="http://172.20.10.1:1082"
# export http_proxy="http://172.20.10.1:1082"
export https_proxy=http://127.0.0.1:7897 http_proxy=http://127.0.0.1:7897 all_proxy=socks5://127.0.0.1:7897

# Git 操作
echo "开始 Git 操作..."

# 添加所有更改的文件
git add .

# 获取当前时间作为提交信息
current_time=$(date "+%Y-%m-%d %H:%M:%S")
# 添加触发 GitHub Action 的关键词
commit_message="[action] 自动提交 - ${current_time}"

# 提交更改
git commit -m "$commit_message"

# 推送到远程仓库
git push origin main

echo "Git 操作完成！"
