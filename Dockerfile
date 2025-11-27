# 必须指定基础镜像，这里选用兼容性最好的 Temurin JDK 8
# 它支持 linux/arm64 架构
FROM eclipse-temurin:8-jdk-jammy

# 设置环境变量，防止交互式安装卡住
ENV DEBIAN_FRONTEND=noninteractive

# 1. 更新源并安装必要的依赖
# graphviz: 提供 dot 命令 (画图)
# binutils: 提供 objdump, addr2line (解析符号)
# perl: jeprof 是 perl 脚本
# wget: 用于下载 jeprof
RUN apt-get update && \
    apt-get install -y \
    graphviz \
    binutils \
    perl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# 2. 【关键步骤】欺骗 jeprof 的路径
# 你的报错显示 jeprof 去找 /usr/local/openjdk-8/...
# 我们把当前镜像的 JDK 路径 (默认为 /opt/java/openjdk) 软链接过去
RUN ln -s /opt/java/openjdk /usr/local/openjdk-8

# 3. 安装 jeprof
# 直接从 GitHub 下载原始脚本，并赋予执行权限
RUN wget -O /usr/local/bin/jeprof https://raw.githubusercontent.com/jemalloc/jemalloc/dev/bin/jeprof.in && \
    chmod +x /usr/local/bin/jeprof

# 4. 创建一个工作目录
WORKDIR /data

# 默认入口（可选，方便测试）
CMD ["jeprof", "--help"]
