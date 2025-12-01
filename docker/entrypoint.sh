#!/bin/bash
set -e

# 如果有自定义密码环境变量，设置它
if [ -n "$ROOT_PASSWORD" ]; then
    echo "root:$ROOT_PASSWORD" | chpasswd
    echo "Root password has been updated."
fi

# 如果有公钥环境变量，添加到 authorized_keys
if [ -n "$SSH_PUBLIC_KEY" ]; then
    mkdir -p /root/.ssh
    echo "$SSH_PUBLIC_KEY" >> /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
    echo "SSH public key has been added."
fi

# 启动 SSH 服务
echo ""
echo "Starting SSH server on port ${SSH_PORT:-8890}..."
exec /usr/sbin/sshd -D -e
