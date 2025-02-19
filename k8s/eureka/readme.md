### k8s eureka高可用服务部署

1.注册中心

1.1 eureka

1. 准备eureka-server镜像，并推送到私有仓库

    > PS: Dockerfile内容不要强指定运行环境，指定环境可通过环境变量配置  
    私有仓库专注于存放包，具体配置在各环境里托管。
    

2. 服务配置文件可使用ConfigMap托管，如直接打在包里，发布不同环境需要重复打包

3. eureka服务部署资源类型选择：服务地址需要固定，供其他服务注册->StatefulSet，并通过Service统一提供K8s内部访问地址
    > PS:  
    Service: Expose an application running in your cluster behind a single outward-facing endpoint, even when the workload is split across multiple backends.  
    Service Type:
    todo...

### K8s常用命令
 ```bash
# 部署/更新应用
kubectl apply -f <>.yaml -n <namespace>
# 滚动更新
kubectl rollout ...
 ``` 

 Watting Update...  
