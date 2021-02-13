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

## Expose the services:
```bash
kubectl delete service nginx-proxy-exposed
kubectl delete service fluentd-exposed
kubectl expose service nginx-proxy --type=LoadBalancer --name=nginx-proxy-exposed
kubectl expose service fluentd --type=LoadBalancer --name=fluentd-exposed
```

## Get the IPs and names:
```bash
export DOMAIN="orc8r.int"
echo ${DOMAIN}
nms=`kubectl get services | grep nginx-proxy-exposed | awk '{print $4}'` && echo $nms
controller=`kubectl get services ssl-http2-legacy | grep LoadBalancer | awk '{print $4}'` && echo $controller
api=`kubectl get services clientcert-legacy | grep LoadBalancer | awk '{print $4}'` && echo $api
bootstrapper=`kubectl get services bootstrap-legacy | grep LoadBalancer | awk '{print $4}'` && echo $bootstrapper
fluentd=`kubectl get service fluentd-exposed | grep LoadBalancer | awk '{print $4}'` && echo $fluentd
```

## Configure DNS
```bash
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts configure_dns.yml
```

# Create test subscribers:

```bash
cd /tmp/magma/
cd certs/


cat << EOF > to_bin.c
# include <stdio.h>
# include <string.h>

int main(int argc, char **argv){
   int i, c, d;
   char *f = argv[1];
      
   for(i = 0; i < strlen(f); i++){
      if(f[i] >= 'a' && f[i] <= 'f'){
         c = f[i] - 'a' + 10;
      }
      
      else if(f[i] >= 'A' && f[i] <= 'F'){
         c = f[i] - 'a' + 10;
      }      
      
      else if(f[i] >= '0' && f[i] <= '9'){
         c = f[i] - '0';         
      }
      
      if(i % 2 == 0){
         d = c;
      }
      else{
         d = d*0x10 + c;
         printf("%c", d);
      }
      
   }
}
EOF

yum install -y gcc
gcc to_bin.c -o to_bin

# APN:
unalias curl
alias curl="curl --cacert rootCA.pem  --cert admin_operator.pem --key admin_operator.key.pem"

# Delete if exists:
curl -X DELETE "https://api.orc8r.int/magma/v1/lte/oi/apns/${apn}" -H "accept: application/json"

apn="orc8r.int"
# Create:
cat << EOF > apn.json
{
  "apn_configuration": {
    "ambr": {
      "max_bandwidth_dl": 20000000,
      "max_bandwidth_ul": 10000000
    },
    "qos_profile": {
      "class_id": 9,
      "preemption_capability": true,
      "preemption_vulnerability": false,
      "priority_level": 15
    }
  },
  "apn_name": "${apn}"
}
EOF

curl -X POST "https://api.orc8r.int/magma/v1/lte/oi/apns" -H "accept: application/json" -H "content-type: application/json" -d @apn.json


### Subscriber 1:
key="00000000000000000000000000000001"
opc="00000000000000000000000000000001"
id="IMSI724310000000001"
apn="orc8r.int"

opc_encoded=`./to_bin $opc | base64` && echo $opc_encoded
key_encoded=`./to_bin $key | base64` && echo $key_encoded

cat << EOF > subscriber.json
  {
    "active_apns": [
      "orc8r.int"
    ],
    "id": "${id}",
    "lte": {
      "auth_algo": "MILENAGE",
      "auth_key": "${key_encoded}",
      "auth_opc": "${opc_encoded}",
      "state": "ACTIVE",
      "sub_profile": "default"
    }
  }
EOF

# Delete subscriber if exists:
curl \
    -X DELETE "https://api.orc8r.int/magma/v1/lte/oi/subscribers/${id}" \
    -H "accept: application/json"

# Create
curl -X POST "https://api.orc8r.int/magma/v1/lte/oi/subscribers" \
   -H "accept: application/json" \
   -H "content-type: application/json" \
   -d @subscriber.json


### Subscriber 2:
key="00000000000000000000000000000002"
opc="00000000000000000000000000000002"
id="IMSI724310000000002"
apn="orc8r.int"

opc_encoded=`./to_bin $opc | base64` && echo $opc_encoded
key_encoded=`./to_bin $key | base64` && echo $key_encoded

cat << EOF > subscriber.json
  {
    "active_apns": [
      "orc8r.int"
    ],
    "id": "${id}",
    "lte": {
      "auth_algo": "MILENAGE",
      "auth_key": "${key_encoded}",
      "auth_opc": "${opc_encoded}",
      "state": "ACTIVE",
      "sub_profile": "default"
    }
  }
EOF

# Delete subscriber if exists:
curl \
    -X DELETE "https://api.orc8r.int/magma/v1/lte/oi/subscribers/${id}" \
    -H "accept: application/json"

# Create
curl -X POST "https://api.orc8r.int/magma/v1/lte/oi/subscribers" \
   -H "accept: application/json" \
   -H "content-type: application/json" \
   -d @subscriber.json


### Subscriber 3:
key="00000000000000000000000000000003"
opc="00000000000000000000000000000003"
id="IMSI724310000000003"
apn="orc8r.int"

opc_encoded=`./to_bin $opc | base64` && echo $opc_encoded
key_encoded=`./to_bin $key | base64` && echo $key_encoded

cat << EOF > subscriber.json
  {
    "active_apns": [
      "orc8r.int"
    ],
    "id": "${id}",
    "lte": {
      "auth_algo": "MILENAGE",
      "auth_key": "${key_encoded}",
      "auth_opc": "${opc_encoded}",
      "state": "ACTIVE",
      "sub_profile": "default"
    }
  }
EOF

# Delete subscriber if exists:
curl \
    -X DELETE "https://api.orc8r.int/magma/v1/lte/oi/subscribers/${id}" \
    -H "accept: application/json"

# Create
curl -X POST "https://api.orc8r.int/magma/v1/lte/oi/subscribers" \
   -H "accept: application/json" \
   -H "content-type: application/json" \
   -d @subscriber.json


### Subscriber 4:
key="00000000000000000000000000000004"
opc="00000000000000000000000000000004"
id="IMSI724310000000004"
apn="orc8r.int"

opc_encoded=`./to_bin $opc | base64` && echo $opc_encoded
key_encoded=`./to_bin $key | base64` && echo $key_encoded

cat << EOF > subscriber.json
  {
    "active_apns": [
      "orc8r.int"
    ],
    "id": "${id}",
    "lte": {
      "auth_algo": "MILENAGE",
      "auth_key": "${key_encoded}",
      "auth_opc": "${opc_encoded}",
      "state": "ACTIVE",
      "sub_profile": "default"
    }
  }
EOF

# Delete subscriber if exists:
curl \
    -X DELETE "https://api.orc8r.int/magma/v1/lte/oi/subscribers/${id}" \
    -H "accept: application/json"

# Create
curl -X POST "https://api.orc8r.int/magma/v1/lte/oi/subscribers" \
   -H "accept: application/json" \
   -H "content-type: application/json" \
   -d @subscriber.json
```

[<< Back](../README.md)