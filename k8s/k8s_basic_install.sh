swapoff -a
sed -e '/.*none.*swap.*/ s/^#*/#/' -i /etc/fstab
mount -a

apt-get update && apt-get install -y apt-transport-https curl gnupg
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
systemctl enable kubelet
#apt-mark hold kubelet kubeadm kubectl
