# CloudBase CloudRun 部署助手（PowerShell 版本）

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CloudBase CloudRun 部署助手" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Docker
$dockerExists = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerExists) {
    Write-Host "错误: Docker 未安装" -ForegroundColor Red
    Write-Host "请先安装 Docker: https://docs.docker.com/get-docker/"
    exit 1
}

Write-Host "✓ Docker 已安装" -ForegroundColor Green

# 检查 Maven
$mavenExists = Get-Command mvn -ErrorAction SilentlyContinue
if (-not $mavenExists) {
    Write-Host "错误: Maven 未安装" -ForegroundColor Red
    Write-Host "请先安装 Maven: https://maven.apache.org/install.html"
    exit 1
}

Write-Host "✓ Maven 已安装" -ForegroundColor Green
Write-Host ""

# 检查配置文件
if (-not (Test-Path "application.yml")) {
    Write-Host "错误: application.yml 文件不存在" -ForegroundColor Red
    exit 1
}

# 检查 API Key 配置
$config = Get-Content "application.yml" -Raw
if ($config -match "your-api-key-here") {
    Write-Host "⚠️  警告: 尚未配置 CloudBase API Key" -ForegroundColor Yellow
    Write-Host "请先在 application.yml 中配置实际的 API Key"
    Write-Host ""
    $continue = Read-Host "是否继续？(y/n)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        exit 1
    }
}

# 询问部署方式
Write-Host "请选择部署方式："
Write-Host "1) 本地 Docker 运行"
Write-Host "2) 构建 Docker 镜像"
Write-Host "3) 使用 Maven 构建 JAR"
Write-Host ""

$option = Read-Host "请输入选项 (1-3)"

switch ($option) {
    "1" {
        Write-Host ""
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host "本地 Docker 运行" -ForegroundColor Cyan
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host ""

        # 检查是否已构建镜像
        $imageExists = docker images consultant:latest --format "{{.Repository}}:{{.Tag}}"
        if ($imageExists -eq "consultant:latest") {
            Write-Host "镜像已存在" -ForegroundColor Green
        } else {
            Write-Host "构建 Docker 镜像..."
            docker build -t consultant:latest .
        }

        Write-Host ""
        Write-Host "启动容器..."

        # 检查容器是否已运行
        $containerRunning = docker ps -q -f name=consultant
        if ($containerRunning) {
            Write-Host "停止已运行的容器..."
            docker stop consultant
            docker rm consultant
        }

        # 启动新容器
        docker run -d `
            -p 8080:8080 `
            --name consultant `
            -e SPRING_PROFILES_ACTIVE=prod `
            consultant:latest

        Write-Host ""
        Write-Host "✓ 部署成功！" -ForegroundColor Green
        Write-Host ""
        Write-Host "访问地址: http://localhost:8080"
        Write-Host "健康检查: http://localhost:8080/actuator/health"
        Write-Host ""
        Write-Host "查看日志: docker logs -f consultant"
        Write-Host "停止容器: docker stop consultant"
        Write-Host "删除容器: docker rm consultant"
    }

    "2" {
        Write-Host ""
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host "构建 Docker 镜像" -ForegroundColor Cyan
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "构建镜像中..."
        docker build -t consultant:latest .

        Write-Host ""
        Write-Host "✓ 镜像构建完成" -ForegroundColor Green
        Write-Host ""
        Write-Host "镜像名称: consultant:latest"
        Write-Host ""
        Write-Host "下一步："
        Write-Host "1. 登录腾讯云镜像仓库: docker login ccr.ccs.tencentyun.com"
        Write-Host "2. 标记镜像: docker tag consultant:latest ccr.ccs.tencentyun.com/your-namespace/consultant:latest"
        Write-Host "3. 推送镜像: docker push ccr.ccs.tencentyun.com/your-namespace/consultant:latest"
    }

    "3" {
        Write-Host ""
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host "使用 Maven 构建 JAR" -ForegroundColor Cyan
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "清理并构建项目..."
        mvn clean package -DskipTests

        Write-Host ""
        Write-Host "✓ 构建完成" -ForegroundColor Green
        Write-Host ""
        Write-Host "JAR 文件位置: target\consultant-0.0.1-SNAPSHOT.jar"
        Write-Host ""
        Write-Host "运行命令: java -jar target\consultant-0.0.1-SNAPSHOT.jar"
    }

    default {
        Write-Host "无效的选项" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "完成！" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
