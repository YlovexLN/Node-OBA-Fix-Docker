# 第一阶段：构建阶段
FROM debian:bullseye-slim AS builder

# 设置工作目录
WORKDIR /opt/openbmclapi

# 安装必要的工具（curl、tar 和 unzip）
RUN apt-get update && \
    apt-get install -y curl tar xz-utils bash unzip && \
    rm -rf /var/lib/apt/lists/*

# 根据架构设置下载地址
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        ARCH_URL="https://github.com/Zhang12334/Node-OBA-Fix/releases/latest/download/Node-OBA-Fix-linux-x64.tar.xz.zip"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        ARCH_URL="https://github.com/Zhang12334/Node-OBA-Fix/releases/latest/download/Node-OBA-Fix-linux-arm64.tar.xz.zip"; \
    else \
        echo "Unsupported architecture: $TARGETARCH"; exit 1; \
    fi && \
    curl -L -o Node-OBA-Fix.tar.xz.zip "$ARCH_URL"

# 解压文件
RUN unzip Node-OBA-Fix.tar.xz.zip && \
    tar -xvf Node-OBA-Fix-*.tar.xz && \
    chmod +x run.sh node && \
    rm Node-OBA-Fix.tar.xz.zip Node-OBA-Fix-*.tar.xz

# 第二阶段：运行阶段
FROM debian:bullseye-slim

# 设置工作目录
WORKDIR /opt/openbmclapi

# 安装必要的依赖
RUN apt-get update && \
    apt-get install -y bash && \
    rm -rf /var/lib/apt/lists/*

# 从构建阶段复制 /opt/openbmclapi 下的内容
COPY --from=builder /opt/openbmclapi/ ./

# 验证 node 是否可用
RUN ./node --version || echo "Node.js is not working!"

# 设置环境变量
ENV CLUSTER_PORT=4000
EXPOSE $CLUSTER_PORT

# 定义卷（持久化缓存和配置）
VOLUME ["/opt/openbmclapi/cache", "/opt/openbmclapi/.env", "/opt/openbmclapi/data"]

# 启动脚本
CMD ["./run.sh"]