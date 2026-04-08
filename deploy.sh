#!/bin/bash

# 部署脚本 - CloudBase CloudRun 部署助手

set -e  # 遇到错误立即退出

echo "=========================================="
echo "CloudBase CloudRun 部署助手"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装${NC}"
    echo "请先安装 Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

echo -e "${GREEN}✓ Docker 已安装${NC}"

# 检查 Maven
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}错误: Maven 未安装${NC}"
    echo "请先安装 Maven: https://maven.apache.org/install.html"
    exit 1
fi

echo -e "${GREEN}✓ Maven 已安装${NC}"
echo ""

# 检查配置文件
if [ ! -f "application.yml" ]; then
    echo -e "${RED}错误: application.yml 文件不存在${NC}"
    exit 1
fi

# 检查 API Key 配置
if grep -q "your-api-key-here" application.yml; then
    echo -e "${YELLOW}⚠️  警告: 尚未配置 CloudBase API Key${NC}"
    echo "请先在 application.yml 中配置实际的 API Key"
    echo ""
    read -p "是否继续？(y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 询问部署方式
echo "请选择部署方式："
echo "1) 本地 Docker 运行"
echo "2) 构建 Docker 镜像"
echo "3) 使用 Maven 构建 JAR"
echo ""
read -p "请输入选项 (1-3): " option

case $option in
    1)
        echo ""
        echo "=========================================="
        echo "本地 Docker 运行"
        echo "=========================================="
        echo ""

        # 检查是否已构建镜像
        if docker image inspect consultant:latest &> /dev/null; then
            echo -e "${GREEN}镜像已存在${NC}"
        else
            echo "构建 Docker 镜像..."
            docker build -t consultant:latest .
        fi

        echo ""
        echo "启动容器..."
        docker run -d \
            -p 8080:8080 \
            --name consultant \
            -e SPRING_PROFILES_ACTIVE=prod \
            consultant:latest

        echo ""
        echo -e "${GREEN}✓ 部署成功！${NC}"
        echo ""
        echo "访问地址: http://localhost:8080"
        echo "健康检查: http://localhost:8080/actuator/health"
        echo ""
        echo "查看日志: docker logs -f consultant"
        echo "停止容器: docker stop consultant"
        echo "删除容器: docker rm consultant"
        ;;

    2)
        echo ""
        echo "=========================================="
        echo "构建 Docker 镜像"
        echo "=========================================="
        echo ""

        echo "构建镜像中..."
        docker build -t consultant:latest .

        echo ""
        echo -e "${GREEN}✓ 镜像构建完成${NC}"
        echo ""
        echo "镜像名称: consultant:latest"
        echo ""
        echo "下一步："
        echo "1. 登录腾讯云镜像仓库: docker login ccr.ccs.tencentyun.com"
        echo "2. 标记镜像: docker tag consultant:latest ccr.ccs.tencentyun.com/your-namespace/consultant:latest"
        echo "3. 推送镜像: docker push ccr.ccs.tencentyun.com/your-namespace/consultant:latest"
        ;;

    3)
        echo ""
        echo "=========================================="
        echo "使用 Maven 构建 JAR"
        echo "=========================================="
        echo ""

        echo "清理并构建项目..."
        mvn clean package -DskipTests

        echo ""
        echo -e "${GREEN}✓ 构建完成${NC}"
        echo ""
        echo "JAR 文件位置: target/consultant-0.0.1-SNAPSHOT.jar"
        echo ""
        echo "运行命令: java -jar target/consultant-0.0.1-SNAPSHOT.jar"
        ;;

    *)
        echo -e "${RED}无效的选项${NC}"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "完成！"
echo "=========================================="
