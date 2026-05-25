#!/bin/bash

#========================================
# CRM 系统安全部署脚本
# 服务器: 154.40.45.133
# 域名: test.shanzesz.com
# 注意: 不会破坏现有服务器结构
#========================================

echo "========================================"
echo "     CRM 系统安全部署"
echo "========================================"

# 1. 检查项目目录是否已存在
echo "[1/9] 检查项目目录..."
PROJECT_DIR="/var/www/juxing3.0"
if [ -d "$PROJECT_DIR" ]; then
    echo "项目目录已存在，跳过克隆..."
else
    echo "[1/9] 创建项目目录..."
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    echo "[2/9] 克隆代码..."
    git clone https://github.com/YangJL558034/juxing3.0.git .
fi

cd "$PROJECT_DIR"

# 2. 更新代码（如果已存在）
echo "[2/9] 更新代码..."
git pull origin main

# 3. 安装项目依赖
echo "[3/9] 安装项目依赖..."
pnpm install

# 4. 创建数据目录
echo "[4/9] 创建数据目录..."
mkdir -p data uploads
chmod -R 755 data uploads

# 5. 构建项目
echo "[5/9] 构建项目..."
pnpm run build

# 6. 安装 PM2（如果未安装）
echo "[6/9] 检查 PM2..."
if ! command -v pm2 &> /dev/null; then
    echo "安装 PM2..."
    npm install -g pm2
fi

# 7. 检查并启动服务
echo "[7/9] 检查服务状态..."
pm2 describe crm-system &> /dev/null
if [ $? -eq 0 ]; then
    echo "服务已存在，重启..."
    pm2 restart crm-system
else
    echo "启动新服务..."
    pm2 start "pnpm run start" --name crm-system
    pm2 save
    pm2 startup
fi

# 8. 配置 Nginx（安全模式：不覆盖现有配置）
echo "[8/9] 配置 Nginx..."
NGINX_CONFIG="/etc/nginx/conf.d/crm.conf"

# 检查配置文件是否已存在
if [ -f "$NGINX_CONFIG" ]; then
    echo "Nginx 配置已存在，跳过..."
else
    cat > "$NGINX_CONFIG" << 'EOF'
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
    # 测试并重启 Nginx
    nginx -t && systemctl reload nginx
fi

# 9. 检查服务状态
echo "[9/9] 检查服务状态..."
pm2 status

echo "========================================"
echo "     部署完成！"
echo "========================================"
echo "访问地址: http://test.shanzesz.com"
echo "查看日志: pm2 logs crm-system"
echo "注意: 不会影响您服务器上的其他项目"
