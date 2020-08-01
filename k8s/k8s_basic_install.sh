swapoff -a
sed -e '/.*none.*swap.*/ s/^#*/#/' -i /etc/fstab
mount -a

# docker install
apt-get install curl -y
curl -fsSL https://get.docker.com | sh;
sudo usermod -aG docker $USER

systemctl daemon-reload && systemctl restart docker

# k8s install
apt-get update && apt-get install -y apt-transport-https gnupg software-properties-common
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
add-apt-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
systemctl enable kubelet
apt-mark hold kubelet kubeadm kubectl kubernetes-cni
