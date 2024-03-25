#!/bin/bash
# 此脚本在安装目录下执行
# 脚本出现错误立刻退出，可使用set +e临时关闭该选项
set -e
# 解析命令行参数
# ngrok支持公开证书和私有证书两种，如不需要https通道，则使用私有证书就可以。
# ssl=public/private 如public需指定pem及key，private脚本自动生成私有证书
# todo 解析参数并相应处理

# 安装git、go
yum install -y git go
# 克隆源码
git clone https://github.com/inconshreveable/ngrok.git
# 编译服务端，客户端
cd ngrok
make release-server
make release-client

# 生成启动脚本