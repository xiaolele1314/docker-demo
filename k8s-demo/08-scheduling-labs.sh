# K8s 调度进阶实验
# 在基础部署跑通后，逐个实验下面的调度特性

# ============================================
# 实验 1：扩缩容 + 负载均衡
# ============================================

# 扩到 3 个 API 副本
kubectl scale deployment api --replicas=3 -n demo

# 观察 Pod 分布
kubectl get pods -n demo -o wide

# 多次访问，观察返回的 pod 名称变化（说明 Service 在做负载均衡）
for i in $(seq 1 10); do
  curl -s http://localhost:30080/api/health | grep -o '"pod":"[^"]*"'
done

# 缩回 1 个
kubectl scale deployment api --replicas=1 -n demo


# ============================================
# 实验 2：滚动更新（零停机）
# ============================================

# 修改 API 的环境变量触发滚动更新
kubectl set env deployment/api APP_VERSION=v2 -n demo

# 实时观察：旧 Pod 逐个替换为新 Pod
kubectl rollout status deployment/api -n demo
kubectl get pods -n demo -w

# 回滚到上一个版本
kubectl rollout undo deployment/api -n demo

# 查看更新历史
kubectl rollout history deployment/api -n demo


# ============================================
# 实验 3：资源限制（requests / limits）
# ============================================

# 查看 Pod 实际资源使用
kubectl top pods -n demo

# 查看节点资源情况
kubectl top nodes

# 尝试设置超大的 requests，观察 Pod 无法调度（Pending）
# kubectl edit deployment api -n demo
# 把 requests.memory 改成 8Gi，保存后观察：
kubectl get pods -n demo
# STATUS 会变成 Pending
kubectl describe pod <pending-pod-name> -n demo
# Events 里会看到：Insufficient memory（资源不足，无法调度）


# ============================================
# 实验 4：节点标签 + nodeSelector
# ============================================

# 给节点打标签
kubectl label node <node-name> disk=ssd

# 查看标签
kubectl get nodes --show-labels

# 在 Deployment 的 spec.template.spec 里加 nodeSelector
# nodeSelector:
#   disk: ssd
# 这样 Pod 只会调度到有 disk=ssd 标签的节点

# 删除标签
kubectl label node <node-name> disk-


# ============================================
# 实验 5：污点和容忍（Taints / Tolerations）
# ============================================

# 给节点打污点（"这个节点有问题，别往这调度"）
kubectl taint nodes <node-name> env=test:NoSchedule

# 此时新 Pod 不会调度到这个节点，除非 Pod 有对应的容忍
# 在 Deployment 的 spec.template.spec 里加：
# tolerations:
#   - key: "env"
#     operator: "Equal"
#     value: "test"
#     effect: "NoSchedule"

# 移除污点
kubectl taint nodes <node-name> env=test:NoSchedule-


# ============================================
# 实验 6：自动扩缩容（HPA）
# ============================================

# 创建 HPA：CPU 超过 50% 自动扩容，最少 1 个，最多 5 个
kubectl autoscale deployment api -n demo --min=1 --max=5 --cpu-percent=50

# 查看 HPA 状态
kubectl get hpa -n demo

# 压测触发扩容（在服务器上执行）
# 需要先安装：yum install -y httpd-tools
# ab -n 10000 -c 100 http://localhost:30080/api/health

# 观察 Pod 数量变化
kubectl get pods -n demo -w
kubectl get hpa -n demo -w

# 停止压测后，几分钟内会自动缩回

# 删除 HPA
kubectl delete hpa api -n demo


# ============================================
# 实验 7：Pod 自愈
# ============================================

# 手动删除一个 Pod，观察 Deployment 自动拉起新的
kubectl delete pod <api-pod-name> -n demo
kubectl get pods -n demo -w
# 新 Pod 会在几秒内自动创建
