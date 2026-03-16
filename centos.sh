#!/bin/bash

# 0.遇到错误即停止运行
set -e

# 1.定义带颜色的日志输出格式，方便查看进度
function print_step() {
    echo -e "\e[34m\n======================================================\e[0m"
    echo -e "\e[34m [STEP] $1...\e[0m"
    echo -e "\e[34m======================================================\e[0m"
}

function print_success() {
    echo -e "\e[32m[✔] $1\e[0m\n"
}

function print_warning() {
    echo -e "\e[33m[!] $1\e[0m"
}



# 2.换源
print_step "开始换源！"
cd /etc/yum.repos.d/
mkdir -p backup_old
mv CentOS-* backup_old/
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo
wget -O /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-archive-8.repo
yum clean all
yum makecache
print_success "换源成功！"


# 3.安装python3.13
print_step "开始安装 Python 3.13"
yum update -y
sudo yum install -y gcc make epel-release zlib-devel libffi-devel bzip2-devel perl-core
mkdir /python3.13
cd /python3.13
wget https://mirrors.huaweicloud.com/python/3.13.0/Python-3.13.0.tgz
chmod +x Python-3.13.0.tgz
tar -zxvf Python-3.13.0.tgz
cd Python-3.13.0
./configure --with-ensurepip=install
make -j $(nproc)
sudo make altinstall
if ! grep -q "/usr/local/bin" /etc/profile; then
    echo 'export PATH=/usr/local/bin:$PATH' >> /etc/profile
    print_success "Python 环境变量配置成功！"
fi
source /etc/profile
python3.13 --version
pip3.13 --version
print_success "Python 3.13 安装完成！"


# 4.安装java
print_step "开始安装 Java 17"
cd /usr/local
wget https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-x64_bin.tar.gz
tar -zxvf jdk-17.0.12_linux-x64_bin.tar.gz
mv jdk-17.0.12 jdk-17
if ! grep -q "JAVA_HOME=/usr/local/jdk-17" /etc/profile; then
    echo 'export JAVA_HOME=/usr/local/jdk-17' >> /etc/profile
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile
    echo "Java 17 环境变量配置成功！"
fi
source /etc/profile
rm -f jdk-17.0.12_linux-x64_bin.tar.gz
java -version
print_success "Java 17 安装完成！"

# 5.docker安装
print_step "开始安装 Docker"

print_warning "准备环境检测..."
read -p "是否需要卸载旧版本的 Docker？(y/n) [默认 n]: " uninstall_choice
if [[ "$uninstall_choice" == "y" || "$uninstall_choice" == "Y" ]]; then
    echo "正在卸载旧版本docker"
    yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
    print_success "卸载旧版本完成！"
else
    echo "跳过卸载旧版本步骤。"
fi

yum install -y yum-utils
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker
docker --version
print_success "Docker 安装并启动完成！"

print_step "所有基础环境初始化完毕！"