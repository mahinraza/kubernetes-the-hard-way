```bash
sudo ETCDCTL_API=3 etcdctl member list \
    --endpoints=https://192.168.56.41:2379,https://192.168.56.42:2379 \
    --cacert=/etc/kubernetes/pki/etcd/etcd-ca.crt \
    --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
    --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
    --write-out=table

sudo ETCDCTL_API=3 etcdctl endpoint status \
    --endpoints=https://192.168.56.41:2379,https://192.168.56.42:2379 \
    --cacert=/etc/kubernetes/pki/etcd/etcd-ca.crt \
    --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
    --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
    --write-out=table
```