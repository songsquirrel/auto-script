#!/usr/bin/env bash

# TODO cleanup if exec mult

# 配置dnf仓库
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' \
    -i.bak \
    /etc/yum.repos.d/Rocky-*.repo

dnf makecache
dnf update
dnf -y install curl

# install and set rust enviroment automatically.
set -e

# 添加国内字节镜像源 (https://rsproxy.cn/#getStarted)
echo 'export RUSTUP_DIST_SERVER="https://rsproxy.cn"' >> ~/.bashrc

echo 'export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"' >> ~/.bashrc

# 安装rust
curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | sh

# 配置carte.io镜像-字节 
cat carte_io-image-repo-content.txt > ~/.cargo/config

# 安装交叉编译环境 TODO
# build exe on linux
# install mingw64-gcc

# yum添加eple源(https://developer.aliyun.com/mirror/epel?spm=a2c6h.13651102.0.0.3e221b11RQTQB6)
# 安装 epel 配置包
yum install -y https://mirrors.aliyun.com/epel/epel-release-latest-8.noarch.rpm
# 执行完可能会有提示：It is recommended that you run /usr/bin/crb enable to enable the CRB repository.
# bash /usr/bin/crb enable
# 将 repo 配置中的地址替换为阿里云镜像站地址
sed -i 's|^#baseurl=https://download.example/pub|baseurl=https://mirrors.aliyun.com|' /etc/yum.repos.d/epel*
sed -i 's|^metalink|#metalink|' /etc/yum.repos.d/epel*
# epel(RHEL7)
wget -O /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo

yum makecache
yum install -y mingw64-gcc 
#还需要安装以下依赖，否则可能会缺少依赖
yum install mingw64-winpthreads-static mingw32-winpthreads-static

rustup target add x86_64-pc-windows-gnu
# cargo build --target x86_64-pc-windows-gnu --release
