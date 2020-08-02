swapoff -a
sed -e '/.*none.*swap.*/ s/^#*/#/' -i /etc/fstab
mount -a

apt-get update && apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2 > /dev/null 2>&1

# docker
curl -fsSL https://get.docker.com | sh; > /dev/null 2>&1
sudo usermod -aG docker $USER
groupadd -g 500000 dockremap && 
groupadd -g 501000 dockremap-user && 
useradd -u 500000 -g dockremap -s /bin/false dockremap && 
useradd -u 501000 -g dockremap-user -s /bin/false dockremap-user

echo "dockremap:500000:65536" >> /etc/subuid && 
echo "dockremap:500000:65536" >>/etc/subgid

echo "
  {
   \"userns-remap\": \"default\"
  }
" > /etc/docker/daemon.json

systemctl daemon-reload && systemctl restart docker > /dev/null 2>&1


# k8s install
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
add-apt-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt-get update > /dev/null 2>&1
apt-get install -y kubelet kubeadm kubectl kubernetes-cni > /dev/null 2>&1
systemctl enable kubelet
apt-mark hold kubelet kubeadm kubectl kubernetes-cni
