#!/usr/bin/env bash
set -euo pipefail

# 默认值，避免变量未设置时报错
: "${SSH_PORT:=8890}"
: "${ROOT_PASSWORD:=}"
: "${SSH_PUBLIC_KEY:=}"

# 确保 sshd 运行需要的目录/密钥存在
mkdir -p /var/run/sshd
ssh-keygen -A >/dev/null 2>&1 || true

# 如果有自定义密码环境变量，设置它
if [ -n "${ROOT_PASSWORD}" ]; then
  echo "root:${ROOT_PASSWORD}" | chpasswd
  echo "Root password has been updated."
fi

# 如果有公钥环境变量，添加到 authorized_keys（去重）
if [ -n "${SSH_PUBLIC_KEY}" ]; then
  install -d -m 700 /root/.ssh
  touch /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys

  if ! grep -Fxq "${SSH_PUBLIC_KEY}" /root/.ssh/authorized_keys; then
    echo "${SSH_PUBLIC_KEY}" >> /root/.ssh/authorized_keys
  fi
  echo "SSH public key has been added."
fi

echo ""
echo "Starting SSH server on port ${SSH_PORT}..."
/usr/sbin/sshd -e

echo "[entrypoint] sshd started, now sleeping..."
exec sleep infinity
