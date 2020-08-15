# master

echo "10.2.6.74 k8s-master" >> /etc/hosts
 
kubeadm init --apiserver-advertise-address=10.2.6.74 --pod-network-cidr=192.168.0.0/16 --apiserver-cert-extra-sans=10.2.6.74

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl get nodes
kubectl get pods --all-namespaces
sysctl net.bridge.bridge-nf-call-iptables=1

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml # pod network

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.3/aio/deploy/recommended.yaml # dashboard

kubectl proxy
Starting to serve on 127.0.0.1:8001

ssh root@83.136.252.230 -L 8001:localhost:8001

http://127.0.0.1:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/cluster?namespace=default

# get token or create : https://stackoverflow.com/questions/46664104/how-to-sign-in-kubernetes-dashboard
kubectl -n kube-system describe secret $(kubectl -n kubernetes-dashboard get secret | awk '/^deployment-controller-token-/{print $1}') | awk '$1=="token:"{print $2}'

#node
echo "10.2.6.74 k8s-node1" >> /etc/hosts

kubeadm join 10.2.7.247:6443 --token 9l260m.suummq7k5ydce44i --discovery-token-ca-cert-hash sha256:a2aae9d37b1bd15d8cd8926f2d41dc54fe1bed092976e86831d3b12db5b102f7

## More

https://kubernetes.io/docs/reference/kubectl/cheatsheet/

kubectl get nodes
kubectl get nodes -o wide
kubectl get nodes --all-namespaces
kubectl get services --all-namespaces
kubectl get pods --all-namespaces
kubectl get service my-nginx
KUBE_EDITOR="nano" kubectl edit deploy/hello-world
kubectl edit node k8s-master
kubectl edit service my-nginx
kubectl logs PODNAE -n namespace
kubectl describe service my-nginx
