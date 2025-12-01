FROM arm64v8/ubuntu:22.04

LABEL maintainer="your-email@example.com"
LABEL description="Ubuntu ARM64 Jump Server with SSH and Port Forwarding Tools"

# 构建参数
ARG SSH_PORT=8890
ARG ROOT_PASSWORD=changeme123

# 环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV SSH_PORT=${SSH_PORT}

# 安装必要的软件包
RUN apt-get update && apt-get install -y \
    # SSH 服务
    openssh-server \
    # 端口转发工具
    socat \
    rinetd \
    ncat \
    # 网络工具
    iproute2 \
    iputils-ping \
    net-tools \
    curl \
    wget \
    dnsutils \
    traceroute \
    tcpdump \
    iptables \
    # 实用工具
    vim \
    nano \
    htop \
    tmux \
    screen \
    # 清理
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 创建 SSH 运行目录
RUN mkdir -p /var/run/sshd

# 配置 root 密码
RUN echo "root:${ROOT_PASSWORD}" | chpasswd

# 复制 SSH 配置
COPY sshd_config /etc/ssh/sshd_config

# 替换 SSH 端口
RUN sed -i "s/^Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config

# 生成 SSH 主机密钥
RUN ssh-keygen -A

# 创建端口转发配置目录
RUN mkdir -p /etc/portforward

# 创建示例 rinetd 配置
RUN echo "# rinetd 端口转发配置示例" > /etc/rinetd.conf && \
    echo "# 格式: 绑定地址 绑定端口 目标地址 目标端口" >> /etc/rinetd.conf && \
    echo "# 0.0.0.0 8080 192.168.1.100 80" >> /etc/rinetd.conf

# 创建 socat 转发脚本示例
RUN echo '#!/bin/bash' > /usr/local/bin/forward-port.sh && \
    echo '# 使用方法: forward-port.sh <本地端口> <目标地址> <目标端口>' >> /usr/local/bin/forward-port.sh && \
    echo 'socat TCP-LISTEN:$1,fork,reuseaddr TCP:$2:$3 &' >> /usr/local/bin/forward-port.sh && \
    chmod +x /usr/local/bin/forward-port.sh

# 复制启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 暴露 SSH 端口
EXPOSE ${SSH_PORT}

# 启动入口
ENTRYPOINT ["/entrypoint.sh"]
