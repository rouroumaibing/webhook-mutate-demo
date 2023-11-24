# Admission Webhook Demo

该demo主要为MutatingAdmissionWebhook，实现给pod打注解。

## 什么是AdmissionWebhook

什么是AdmissionWebhook，就要先了解K8S中的admission controller, 按照官方的解释是： admission controller是拦截(经过身份验证)API Server请求的网关，并且可以修改请求对象或拒绝请求。

## admission-plugins分为三大类：

1.修改类型(mutating)

2.验证类型(validating)

3.既是修改又是验证类型(mutating&validating)

## MutatingAdmissionWebhook: 做修改操作的AdmissionWebhook

## ValidatingAdmissionWebhook: 做验证操作的AdmissionWebhook

### Install：

1 创建k8s集群

2 节点已配置kubectl

3 上传脚本执行

3.1 构建镜像

`bash build/image-build.sh pod-annotate  v0.0.1`

3.2 查看镜像、推送镜像

```
docker images

docker tag pod-annotate:v0.0.1  xxx.com/xx/pod-annotate:v0.0.1

docker push xxx.com/xx/pod-annotate:v0.0.1
```

3.2 部署webhook到集群命名空间demo

```
kubectl create ns demo

#deploy-in-k8s.sh pod-annotate  version namespace registry.com/organization  IP-whitelist

bash build/deploy-in-k8s.sh pod-annotate  v0.0.1 demo  xxx.com/xx

#bash build/deploy-in-k8s.sh pod-annotate  v0.0.1  demo  xxx.com/xx  192.168.0.1
```

4 在命名空间test查看效果
```

kubectl create ns test 

kubectl label namespace test pod-annotate-webhook=enabled

kubectl -n test create deployment nginx --image=nginx

kubectl -n test get  pod nginx-xxx -ojsonpath='{.metadata.annotations}'
```

# mutatingwebhook.yaml.tpl 模版说明

使用k8s域名：
```
    clientConfig:
      service:
        name: pod-annotate-webhook-svc
        namespace: demo
        path: "/mutate"
```
      
使用IP地址访问：
```
    clientConfig:
      # nodeport/loadbalance service IP address, The certificate must contain the IP address.
      # ex. https://ip:port/mutate
      url: https://192.168.0.1:443/mutate
```

