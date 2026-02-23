FROM --platform=linux/amd64 ubuntu:20.04

ENV JAVA_HOME=/usr/local/java/jdk1.6.0_30
ENV PATH=$JAVA_HOME/bin:$PATH

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y wget tar unzip nginx curl && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------
# JDK installation
# ---------------------------
WORKDIR /tmp
ADD jdk-6u30-linux-x64.bin /tmp/
RUN chmod +x jdk-6u30-linux-x64.bin && \
    ./jdk-6u30-linux-x64.bin && \
    mkdir -p /usr/local/java && \
    mv jdk1.6.0_30 /usr/local/java/ && \
    rm -f jdk-6u30-linux-x64.bin

# ---------------------------
# Maven 3.2.5
# ---------------------------
RUN cd /opt && \
    curl -fsSL https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.2.5/apache-maven-3.2.5-bin.tar.gz -o maven.tar.gz && \
    tar -xzf maven.tar.gz && \
    rm -f maven.tar.gz

# ---------------------------
# Nginx configuration
# ---------------------------
RUN cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    location / {
        proxy_pass https://repo.maven.apache.org;
        proxy_set_header Host repo.maven.apache.org;
        proxy_ssl_verify off;
        proxy_ssl_server_name on;
    }
}
EOF

# ---------------------------
# Copy project files
# ---------------------------
WORKDIR /workspace
COPY . /workspace/

# ---------------------------
# Build xstream
# ---------------------------
RUN --mount=type=cache,target=/root/.m2 nginx & \
    /opt/apache-maven-3.2.5/bin/mvn install -s settings.xml -pl "!xstream-distribution"
