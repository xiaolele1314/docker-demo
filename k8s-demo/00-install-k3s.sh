#!/bin/bash
# K3s 安装脚本（单节点，适合学习）
# 在阿里云服务器上执行

echo "=== 1. 安装 K3s ==="
# 国内用镜像加速安装
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | \
  INSTALL_K3S_MIRROR=cn sh -

echo "=== 2. 等待 K3s 就绪 ==="
sleep 10

echo "=== 3. 验证安装 ==="
kubectl get nodes
kubectl get pods -A

echo "=== 4. 设置 kubectl 自动补全 ==="
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc

echo ""
echo "安装完成！常用命令："
echo "  kubectl get nodes        # 查看节点"
echo "  kubectl get pods -A      # 查看所有 Pod"
echo "  kubectl get svc          # 查看 Service"
echo ""
echo "卸载命令：/usr/local/bin/k3s-uninstall.sh"
