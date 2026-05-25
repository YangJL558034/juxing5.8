#!/bin/bash

#========================================
# CRM 系统自动化部署脚本
# 服务器: 154.40.45.133
# 域名: test.shanzesz.com
#========================================

echo "========================================"
echo "     CRM 系统自动化部署"
echo "========================================"

# 1. 更新系统
echo "[1/10] 更新系统..."
yum update -y

# 2. 安装依赖
echo "[2/10] 安装依赖..."
yum install -y git nodejs pnpm nginx certbot python3-certbot-nginx

# 3. 创建项目目录
echo "[3/10] 创建项目目录..."
mkdir -p /var/www/juxing3.0
cd /var/www/juxing3.0

# 4. 克隆代码
echo "[4/10] 克隆代码..."
rm -rf .git
git clone https://github.com/YangJL558034/juxing3.0.git .

# 5. 安装项目依赖
echo "[5/10] 安装项目依赖..."
pnpm install

# 6. 创建数据目录
echo "[6/10] 创建数据目录..."
mkdir -p data uploads
chmod -R 755 data uploads

# 7. 构建项目
echo "[7/10] 构建项目..."
pnpm run build

# 8. 安装 PM2
echo "[8/10] 安装 PM2..."
npm install -g pm2

# 9. 停止旧服务并启动新服务
echo "[9/10] 启动服务..."
pm2 stop all
pm2 start "pnpm run start" --name crm-system
pm2 save
pm2 startup

# 10. 配置 Nginx
echo "[10/10] 配置 Nginx..."

cat > /etc/nginx/conf.d/crm.conf << 'EOF'
server {
    listen 80;
    server_name test.shanzesz.com 154.40.45.133;

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

# 重启 Nginx
systemctl restart nginx

echo "========================================"
echo "     部署完成！"
echo "========================================"
echo "访问地址: http://test.shanzesz.com"
echo "查看日志: pm2 logs crm-system"
echo "管理命令: pm2 status | pm2 restart crm-system"
