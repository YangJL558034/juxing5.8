#!/bin/bash

# ========================================
# CRM 系统一键部署脚本
# 执行方式: bash -c "$(curl -fsSL https://raw.githubusercontent.com/YangJL558034/juxing3.0/main/scripts/deploy-oneclick.sh)"
# ========================================

echo "========================================"
echo "     🚀 CRM 系统一键部署"
echo "========================================"

# 配置变量
PROJECT_DIR="/var/www/juxing3.0"
DOMAIN="test.shanzesz.com"

# 1. 安装依赖
echo "[1/6] 安装必要依赖..."
yum install -y git nodejs pnpm nginx > /dev/null 2>&1
echo "✓ 依赖安装完成"

# 2. 创建项目目录
echo "[2/6] 准备项目目录..."
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 3. 克隆或更新代码
echo "[3/6] 获取代码..."
if [ -d ".git" ]; then
    git pull origin main > /dev/null 2>&1
else
    git clone https://github.com/YangJL558034/juxing3.0.git . > /dev/null 2>&1
fi
echo "✓ 代码获取完成"

# 4. 安装依赖和构建
echo "[4/6] 安装依赖并构建..."
pnpm install > /dev/null 2>&1
mkdir -p data uploads
chmod -R 755 data uploads
pnpm run build > /dev/null 2>&1
echo "✓ 构建完成"

# 5. 启动服务
echo "[5/6] 启动服务..."
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2 > /dev/null 2>&1
fi

pm2 describe crm-system &> /dev/null
if [ $? -eq 0 ]; then
    pm2 restart crm-system > /dev/null 2>&1
else
    pm2 start "pnpm run start" --name crm-system > /dev/null 2>&1
    pm2 save > /dev/null 2>&1
    pm2 startup > /dev/null 2>&1
fi
echo "✓ 服务启动完成"

# 6. 配置 Nginx
echo "[6/6] 配置 Nginx..."
cat > /etc/nginx/conf.d/crm.conf << 'EOF'
server {
    listen 80;
    server_name test.shanzesz.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF
nginx -t > /dev/null 2>&1 && systemctl reload nginx > /dev/null 2>&1
echo "✓ Nginx 配置完成"

echo "========================================"
echo "     ✅ 部署成功！"
echo "========================================"
echo "📦 项目目录: $PROJECT_DIR"
echo "🌐 访问地址: http://$DOMAIN"
echo "🔑 默认账户: admin / admin"
echo "📊 服务状态:"
pm2 status
echo ""
echo "📝 常用命令:"
echo "  查看日志: pm2 logs crm-system"
echo "  重启服务: pm2 restart crm-system"
echo "  停止服务: pm2 stop crm-system"
