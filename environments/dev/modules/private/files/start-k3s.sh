#!/bin/bash -xe

docker images | grep -q 'coredns/coredns' || (
    find /opt -maxdepth 2 -name 'k3s*.tar.gz' | xargs -r -L 1 docker load -i
)

pgrep -f 'k3s server' >/dev/null || (
    if [ -f /etc/systemd/system/k3s.service ]; then
        systemctl start k3s
    else
        k3s server --disable-agent &
    fi
)
timeout 30 sh -c "until test -f /var/lib/rancher/k3s/server/node-token >/dev/null 2>&1; do sleep 1; done"
timeout 30 sh -c "until nc -zv localhost 6443 >/dev/null 2>&1; do sleep 1; done"

pgrep -f 'k3s agent' >/dev/null || (
    if [ ! -f /etc/systemd/system/k3s.service ]; then
        k3s agent --server https://localhost:6443 --token "$(</var/lib/rancher/k3s/server/node-token)" --docker &
    fi
)
timeout 30 sh -c "until k3s kubectl get node | grep -qi ready >/dev/null 2>&1; do sleep 1; done"

k3s kubectl get storageclass local-path >/dev/null 2>&1 || (
    k3s kubectl apply -f /opt/k3s/local-path-storage.yaml
    k3s kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
)

helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
