# Magma installation in a k8s cluster

## Deploy orchestrator:
```bash 
cat k8s_vm_config.yml > orc8r/config.yml
python3 k8s_hosts.py k8s_vm_config.yml > orc8r/hosts
cd orc8r
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts deploy_orc8r.yml
```

## Check orc8r installation:
```bash
helm list
kubectl get pods
```

## Generate admin_operator certificate to nms deployment:
```bash
pod=`kubectl get pods -l io.kompose.service=controller -o jsonpath='{.items[0].metadata.name}'` && echo $pod
kubectl exec -it ${pod} -- bash
cd /var/opt/magma/bin
envdir /var/opt/magma/envdir ./accessc add-admin -cert admin_operator admin_operator
openssl pkcs12 -export -out admin_operator.pfx -inkey admin_operator.key.pem -in admin_operator.pem
exit
```

## Copy admin_operator certificate your local disk and create the secrets:
```bash
cd orc8r_deployment/certs

for certfile in admin_operator.pem admin_operator.key.pem admin_operator.pfx
do
    kubectl cp ${pod}:/var/opt/magma/bin/${certfile} ./${certfile}
done
```

## Deploy nms:
```bash 
cd magma
cd orc8r
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts deploy_nms.yml
```

## Check:
```bash
helm list
kubectl get pods
```

## Once magmalte pod is up and running, change the admin password:
```bash
pod=`kubectl get pod -l io.kompose.service=magmalte -o jsonpath='{.items[0].metadata.name}'` && echo $pod
kubectl exec -it ${pod} -- yarn setAdminPassword master admin@magma Magma123#
```

## Configure DNS
```bash
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts configure_dns.yml
```

# Create test subscribers:

Install gcc:
``` bash
apt install -y gcc 
```

# In the scripts directory, edit the two files:  source-rc  and subscriber_list.csv

And execute:

Create the APN:
```bash
bash 02_create_apn.sh
```

Create the subscribers:
```bash 
bash 03_subscriber.sh
```

[<< Back](../README.md)