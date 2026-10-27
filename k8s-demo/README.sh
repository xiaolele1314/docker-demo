# K8s 学习实操指南
# 按顺序执行，每一步都有注释说明

# ============================================
# 第一步：安装 K3s（在阿里云服务器上执行）
# ============================================
bash 00-install-k3s.sh

# 验证集群状态
kubectl get nodes
# 输出类似：
# NAME        STATUS   ROLES                  AGE   VERSION
# aliyun-01   Ready    control-plane,master   1m    v1.28.x+k3s1


# ============================================
# 第二步：创建 Namespace（资源隔离）
# ============================================
kubectl apply -f 01-namespace.yaml
kubectl get ns


# ============================================
# 第三步：部署 ConfigMap 和 Secret
# ============================================
kubectl apply -f 02-configmap.yaml
kubectl apply -f 03-secret.yaml

# 查看（Secret 的值是 base64 编码的）
kubectl get configmap -n demo
kubectl get secret -n demo


# ============================================
# 第四步：部署 MySQL
# ============================================
kubectl apply -f 04-mysql.yaml

# 等待 Pod 就绪
kubectl get pods -n demo -w
# 按 Ctrl+C 退出 watch


# ============================================
# 第五步：部署 Redis
# ============================================
kubectl apply -f 05-redis.yaml
kubectl get pods -n demo


# ============================================
# 第六步：部署 API
# ============================================
kubectl apply -f 06-api.yaml
kubectl get pods -n demo


# ============================================
# 第七步：部署 Nginx
# ============================================
kubectl apply -f 07-nginx.yaml
kubectl get pods -n demo
kubectl get svc -n demo


# ============================================
# 访问测试
# ============================================
# Nginx Service 用了 NodePort，直接访问：
# http://47.116.210.32:30080

# 查看所有资源
kubectl get all -n demo


# ============================================
# 常用调试命令
# ============================================

# 查看 Pod 日志
kubectl logs -f <pod-name> -n demo

# 进入 Pod 内部
kubectl exec -it <pod-name> -n demo -- /bin/sh

# 查看 Pod 详情（排查启动失败）
kubectl describe pod <pod-name> -n demo

# 查看 Pod 被调度到哪个节点
kubectl get pods -n demo -o wide

# 查看资源使用量
kubectl top pods -n demo

# 扩缩容
kubectl scale deployment api --replicas=3 -n demo
kubectl get pods -n demo    # 会看到 3 个 api Pod

# 缩回来
kubectl scale deployment api --replicas=1 -n demo


# ============================================
# 清理
# ============================================
kubectl delete namespace demo    # 删除整个 namespace，里面的资源全部清掉
