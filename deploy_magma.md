# Magma installation in a k8s cluster


## Clear pvs and pvcs:
```bash
for f in `kubectl get pvc | awk '{print $1}' | grep -v NAME`; do kubectl delete pvc $f; done
for f in `kubectl get pv | awk '{print $1}' | grep -v NAME`; do kubectl delete pv $f; done
```


## Define the NFS_IP variable with the nfs server IP:
```bash
export NFS_IP="10.5.0.32"
```

## Clear nfs shared directory:
```bash
ssh debian@${NFS_IP} 'sudo rm -rfv /srv/k8s_volume/*'
```

## Add [bitnami](https://charts.bitnami.com/bitnami) repository to your helm:
Obs: If helm is not installed, install it first: [helm installation gide](https://helm.sh/docs/intro/install/)
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

## Install postgresql chart:
```bash
helm install psql bitnami/postgresql
```

## Create the postgresql directory in nfs server
```bash
ssh debian@${NFS_IP} 'sudo rm -rfv /srv/k8s_volume/psql_0 && sudo mkdir -pv /srv/k8s_volume/psql_0 && sudo chmod -R 770 /srv/k8s_volume/psql_0'
```

## Create the pv:
```bash
fp=`mktemp`
cat << EOF > ${fp}
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-ha-0
  labels:
    app.kubernetes.io/component: postgresql
    app.kubernetes.io/instance: my-release
    app.kubernetes.io/name: postgresql-ha  
spec:
  capacity:
    storage: 8Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle
  nfs:
    path: /srv/k8s_volume/psql_0
    server: ${NFS_IP}
EOF

kubectl apply -f ${fp}
rm ${fp}
```

## Check:
```bash
kubectl get pvc
kubectl get pv
kubectl get pods
```
## Test the connection with psql:
```bash
kubectl delete service psql-postgresql-exposed
kubectl expose service psql-postgresql --type=LoadBalancer --name=psql-postgresql-exposed
psql_ip=`kubectl get service psql-postgresql-exposed | awk '/psql/ {print $4}'` && echo $psql_ip
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default psql-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
psql -h ${psql_ip} -p 5432 -U postgres -d postgres
```

## Define magma orchestrator domain (ex: orc8r.int)
```bash
export DOMAIN="orc8r.int"
echo ${DOMAIN}
```

## Create Self sign certs:
```bash
mkdir orc8r_deployment
cd orc8r_deployment
rm -rfv certs
mkdir -pv certs
cd certs
touch /root/.rnd
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem -subj "/C=US/CN=rootca.${DOMAIN}"
openssl genrsa -out controller.key 2048
openssl req -new -key controller.key -out controller.csr -subj "/C=US/CN=*.${DOMAIN}"
openssl x509 -req -in controller.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out controller.crt -days 3650 -sha256
rm -f controller.csr rootCA.key rootCA.srl
openssl genrsa -out certifier.key 2048
openssl req -x509 -new -nodes -key certifier.key -sha256 -days 3650 -out certifier.pem -subj "/C=US/CN=certifier.${DOMAIN}"
openssl genrsa -out bootstrapper.key 2048
openssl genrsa -out fluentd.key 2048
openssl req -x509 -new -nodes -key fluentd.key -sha256 -days 3650 -out fluentd.pem -subj "/C=US/CN=fluentd.${DOMAIN}"
```

## Add certificates and keys into the secret:
```bash
rm -rf secrets
rm -rf fluentd
mkdir -pv secrets
mkdir -pv fluentd
cp -v controller* secrets
cp -v rootCA.pem secrets
cp -v bootstrapper.key secrets
cp -v certifier* secrets
ls -lhtr secrets
cp -v fluentd* fluentd
cp -v certifier.pem fluentd
kubectl delete secret orc8r-certs
kubectl create secret generic orc8r-certs --from-file=secrets/
kubectl delete secret fluentd-certs
kubectl create secret generic fluentd-certs --from-file=fluentd/
kubectl describe secret orc8r-certs
kubectl describe secret fluentd-certs
cd ..
```

## Define a dummy docker secret:
```bash
GITHUB_USER="foo"
GITHUB_TOKEN="foo"

kubectl delete secret regcred
kubectl create secret docker-registry regcred \
    --docker-server="docker.pkg.github.com" \
    --docker-username=${GITHUB_USER} \
    --docker-password=${GITHUB_TOKEN}     
kubectl describe secret regcred
```

## Create psql database:
```bash
export POSTGRES_DB="orc8r"
export POSTGRES_USER="postgres"
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default psql-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
psql_ip=`kubectl get service psql-postgresql-exposed | awk '/psql/ {print $4}'` && echo $psql_ip
P_PW=$(kubectl get secret --namespace default psql-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
PGPASSWORD=${POSTGRES_PASSWORD} psql -h ${psql_ip} -p 5432 -U ${POSTGRES_USER} -c "drop database if exists ${POSTGRES_DB};"
PGPASSWORD=${POSTGRES_PASSWORD} psql -h ${psql_ip} -p 5432 -U ${POSTGRES_USER} -c "create database ${POSTGRES_DB};";
PGPASSWORD=${POSTGRES_PASSWORD} psql -h ${psql_ip} -p 5432 -U ${POSTGRES_USER} -c "grant all privileges on database ${POSTGRES_DB} to ${POSTGRES_USER};"
```

## Check:
```bash
PGPASSWORD=${POSTGRES_PASSWORD} psql -h ${psql_ip} -p 5432 -U ${POSTGRES_USER} ${POSTGRES_DB}
```

## Delete  psql-postgresql-exposed service
```bash
kubectl delete service psql-postgresql-exposed
```

## Create database secrets:
```bash
rm -rfv db_secrets
mkdir db_secrets
cd db_secrets
echo -n "dbname=${POSTGRES_DB} user=${POSTGRES_USER} password=${POSTGRES_PASSWORD} host=postgres sslmode=disable" > DATABASE_SOURCE
echo -n ${POSTGRES_DB} > POSTGRES_DB
echo -n ${POSTGRES_PASSWORD} > POSTGRES_PASSWORD
echo -n ${POSTGRES_USER} > POSTGRES_USER
MYSQL_DATABASE=${POSTGRES_DB}
MYSQL_PASSWORD=`openssl rand -hex 10`
MYSQL_ROOT_PASSWORD=`openssl rand -hex 10`
MYSQL_USER="mysql"
echo -n ${MYSQL_DATABASE} > MYSQL_DATABASE
echo -n ${MYSQL_PASSWORD} > MYSQL_PASSWORD
echo -n ${MYSQL_ROOT_PASSWORD} > MYSQL_ROOT_PASSWORD
echo -n ${MYSQL_USER} > MYSQL_USER
kubectl delete secret controller
kubectl delete secret postgres
kubectl delete secret mysql
kubectl create secret generic controller --from-file=DATABASE_SOURCE=./DATABASE_SOURCE
kubectl create secret generic postgres \
        --from-file=POSTGRES_DB=./POSTGRES_DB \
        --from-file=POSTGRES_USER=./POSTGRES_USER \
        --from-file=POSTGRES_PASSWORD=./POSTGRES_PASSWORD

kubectl create secret generic mysql \
        --from-file=MYSQL_DATABASE=./MYSQL_DATABASE \
        --from-file=MYSQL_PASSWORD=./MYSQL_PASSWORD \
        --from-file=MYSQL_ROOT_PASSWORD=./MYSQL_ROOT_PASSWORD \
        --from-file=MYSQL_USER=./MYSQL_USER

kubectl describe secret controller
kubectl describe secret postgres
kubectl describe secret mysql
```

## Clear master mount directory:
```bash
cd ..
cat << EOF > hosts
[MASTER]
${NFS_IP}
EOF
```

## Copy the files to nfs server:
```bash
cp -v ../packages/config.tar.gz .
tar -xvf config.tar.gz
cp config/* /tmp/

cat << EOF > prepare_files.yml
- 
   name: Prepare NFS server
   hosts: MASTER
   remote_user: debian
   become: true
   tasks:
      - name: NFS Server 01
        shell: |          
          rm -rf /srv/k8s_volume/elasticsearch/
          rm -rf /srv/k8s_volume/alertmanager-configurer-claim0/            
          rm -rf /srv/k8s_volume/alertmanager-claim0/
          rm -rf /srv/k8s_volume/prometheus-claim0/
          rm -rf /srv/k8s_volume/prometheus-configurer-claim0/
          rm -rf /srv/k8s_volume/magmalte-claim0/
          rm -rf /srv/k8s_volume/magmalte-claim1/
          rm -rf /srv/k8s_volume/magmalte-claim2/
          rm -rf /srv/k8s_volume/magmalte-claim3/
          rm -rf /srv/k8s_volume/nginx-proxy-claim0/
                    
          mkdir -pv /srv/k8s_volume/elasticsearch
          chmod -R 775 /srv/k8s_volume/elasticsearch
          mkdir /srv/k8s_volume/alertmanager-configurer-claim0
          mkdir /srv/k8s_volume/alertmanager-claim0
          mkdir /srv/k8s_volume/prometheus-claim0
          mkdir /srv/k8s_volume/prometheus-configurer-claim0
                            
          rm -rfv /root/magma 2>/dev/null
          rm -f /root/v1.1.0.tar.gz 2>/dev/null
          wget https://github.com/magma/magma/archive/v1.1.0.tar.gz -O /root/v1.1.0.tar.gz
          cd /root/
          tar -xvf v1.1.0.tar.gz -C /root/
          mv /root/magma-1.1.0 /root/magma
          cp -rfv /root/magma/symphony/app/fbcnms-packages /srv/k8s_volume/magmalte-claim0
          ls -lhtr /srv/k8s_volume/magmalte-claim0
          cp -rfv /root/magma/symphony/app/fbcnms-projects/magmalte/app /srv/k8s_volume/magmalte-claim1
          ls -lhtr /srv/k8s_volume/magmalte-claim1
          cp -rfv /root/magma/symphony/app/fbcnms-projects/magmalte/scripts/ /srv/k8s_volume/magmalte-claim2
          ls -lhtr /srv/k8s_volume/magmalte-claim2
          cp -rfv /root/magma/symphony/app/fbcnms-projects/magmalte/server/ /srv/k8s_volume/magmalte-claim3
          ls -lhtr /srv/k8s_volume/magmalte-claim3
          rm -rf /root/magma 2>/dev/null
          rm -f /root/v1.1.0.tar.gz 2>/dev/null

        args:
           warn: no

      - name: Copy alertmanager-configurer configuration file
        copy:
           src: /tmp/alertmanager.yml
           dest: /srv/k8s_volume/alertmanager-configurer-claim0/alertmanager.yml

      - name: Copy alertmanager configuration file
        copy:
           src: /tmp/alertmanager.yml
           dest: /srv/k8s_volume/alertmanager-claim0/alertmanager.yml
           
      - name: Copy prometheus configuration file
        copy:
           src: /tmp/prometheus.yml
           dest: /srv/k8s_volume/prometheus-claim0/prometheus.yml

      - name: Copy prometheus-configurer configuration file
        copy:
           src: /tmp/prometheus-configurer.yml
           dest: /srv/k8s_volume/prometheus-configurer-claim0/prometheus.yml  
           
      - name: Grafana
        shell: |
          docker run --name=tmp_grafana -t -d grafana/grafana:6.6.2;
          rm -rfv /srv/k8s_volume/user-grafana/ 2>/dev/null
          docker cp tmp_grafana:/var/lib/grafana /srv/k8s_volume/user-grafana/
          chmod -R 777 /srv/k8s_volume/user-grafana/
          docker stop tmp_grafana
          docker rm tmp_grafana
        
        args:
           warn: no
           executable: /bin/bash
                      
EOF
```

## Execute the playbook:
```bash
ansible-playbook -i hosts  prepare_files.yml
```

## Copy templates to the corrent directory and do the following modifications in volumes:
```bash
cp -r ../packages/helm .

export REGISTERY="10.5.0.32:5000"
sed -i "s|#REGISTERY#|${REGISTERY}|g" helm/orc8r/templates/*
sed -i "s|#REGISTERY#|${REGISTERY}|g" helm/nms/templates/*


cat << EOF > helm/orc8r/templates/alertmanager-claim0-spersistentvolume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: alertmanager-claim0
  labels:
    type: local
spec:  
  capacity:
    storage: 100Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: alertmanager-claim0
    namespace: default    
  accessModes:
    - ReadOnlyMany 
  nfs:
    path: /srv/k8s_volume/alertmanager-claim0
    server: ${NFS_IP}
EOF


cat << EOF > helm/orc8r/templates/alertmanager-configurer-claim0-spersistentvolume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: alertmanager-configurer-claim0
  labels:
    type: local
spec:  
  capacity:
    storage: 100Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: alertmanager-configurer-claim0
    namespace: default
  accessModes:
    - ReadWriteOnce
  nfs:
    path: /srv/k8s_volume/alertmanager-configurer-claim0
    server: ${NFS_IP}
EOF


cat << EOF > helm/orc8r/templates/elasticsearch-persistentvolume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: elasticsearch
  labels:
    type: local
spec:  
  capacity:
    storage: 100Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: elasticsearch
    namespace: default       
  accessModes:
    - ReadWriteOnce
  nfs:
    path: /srv/k8s_volume/elasticsearch
    server: ${NFS_IP}
EOF

cat << EOF > helm/orc8r/templates/grafana-spersistentvolume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: user-grafana
  labels:
    type: local
spec:  
  capacity:
    storage: 100Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: user-grafana
    namespace: default    
  accessModes:
    - ReadWriteOnce
  nfs:
    path: /srv/k8s_volume/user-grafana
    server: ${NFS_IP}
EOF


cat << EOF > helm/orc8r/templates/prometheus-claim0-spersistentvolume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus-claim0
  labels:
    type: local
spec:  
  capacity:
    storage: 100Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: prometheus-claim0
    namespace: default    
  accessModes:
    - ReadOnlyMany
  nfs:
    path: /srv/k8s_volume/prometheus-claim0
    server: ${NFS_IP}
EOF

cat << EOF > helm/orc8r/templates/prometheus-configurer-claim0-spersistentvolume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: prometheus-configurer-claim0
  labels:
    type: local
spec:  
  capacity:
    storage: 100Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: prometheus-configurer-claim0
    namespace: default    
  accessModes:
    - ReadWriteOnce
  nfs:
    path: /srv/k8s_volume/prometheus-configurer-claim0
    server: ${NFS_IP}
EOF
```

## Modify the DNS and psql IP on templates:
```bash
dns=`kubectl get service kube-dns -n kube-system | grep ClusterIP | awk '{print $3}'`
psql_ip=`kubectl get services psql-postgresql | grep ClusterIP | awk '{print $3}'`
sed -i "s|#PSQL_HA_IP#|${psql_ip}|g" helm/orc8r/templates/controller-deployment.yaml
sed -i "s|#CONTROLLER_HOSTNAME#|controller\.${DOMAIN}|g" helm/orc8r/templates/nginx-deployment.yaml
sed -i "s|#RESOLVER#|${dns}|g"  helm/orc8r/templates/nginx-deployment.yaml
```

## Install orc8r:
```bash
helm install orc8r helm/orc8r/
```

## Install orc8r:
```bash
helm list
kubectl get pods
```

## Define magmalte/nms mysql database secrets:
```bash
rm -rfv magmadb_secrets
mkdir magmadb_secrets
cd magmadb_secrets
echo -n ${MYSQL_DATABASE} > MYSQL_DATABASE
echo -n ${MYSQL_PASSWORD} > MYSQL_PASSWORD
echo -n ${MYSQL_ROOT_PASSWORD} > MYSQL_ROOT_PASSWORD
echo -n ${MYSQL_USER} > MYSQL_USER
kubectl delete secret nmsdb
kubectl create secret generic nmsdb \
        --from-file=MYSQL_DATABASE=./MYSQL_DATABASE \
        --from-file=MYSQL_PASSWORD=./MYSQL_PASSWORD \
        --from-file=MYSQL_ROOT_PASSWORD=./MYSQL_ROOT_PASSWORD \
        --from-file=MYSQL_USER=./MYSQL_USER

kubectl describe secret nmsdb
cd ..
rm -rfv magmadb_secrets
```

## Generate admin_operator certificate:
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
cd certs
for certfile in admin_operator.pem admin_operator.key.pem admin_operator.pfx
do
    kubectl cp ${pod}:/var/opt/magma/bin/${certfile} ./${certfile}
done
rm -rf nms-certs
mkdir nms-certs
cp controller.key nms-certs
cp admin_operator.key.pem nms-certs/api_key
cp admin_operator.pem nms-certs/api_cert
cp controller.crt nms-certs

kubectl delete secret nms-certs
kubectl create secret generic nms-certs --from-file=nms-certs/

kubectl describe secret nms-certs 
cd ..
```


## Create mariadb directory in nfs server:
```bash
ssh debian@${NFS_IP} 'sudo rm -rfv /srv/k8s_volume/mariadb_0 && sudo mkdir -pv /srv/k8s_volume/mariadb_0 && sudo chmod -R 770 /srv/k8s_volume/mariadb_0'
```

## Modify the volume templates for nms:
```bash
cat << EOF > helm/nms/templates/mariadb_spersistentvolume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nmsdb
  labels:
    type: local
spec:  
  capacity:
    storage: 1000Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: nmsdb
    namespace: default       
  accessModes:
    - ReadWriteOnce  
  nfs:
    path: /srv/k8s_volume/mariadb_0
    server: ${NFS_IP}
EOF


cat << EOF > helm/nms/templates/magmalte-claim0-spersistentvolume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: magmalte-claim0
  labels:
    type: local
spec:  
  capacity:
    storage: 100Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: magmalte-claim0
    namespace: default      
  accessModes:
    - ReadWriteOnce
  nfs:
    path: /srv/k8s_volume/magmalte-claim0
    server: ${NFS_IP}
EOF

cat << EOF > helm/nms/templates/magmalte-claim1-spersistentvolume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: magmalte-claim1
  labels:
    type: local
spec:  
  capacity:
    storage: 100Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: magmalte-claim1
    namespace: default    
  accessModes:
    - ReadWriteOnce
  nfs:
    path: /srv/k8s_volume/magmalte-claim1
    server: ${NFS_IP}
EOF

cat << EOF > helm/nms/templates/magmalte-claim2-spersistentvolume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: magmalte-claim2
  labels:
    type: local
spec:  
  capacity:
    storage: 100Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: magmalte-claim2
    namespace: default      
  accessModes:
    - ReadWriteOnce
  nfs:
    path: /srv/k8s_volume/magmalte-claim2
    server: ${NFS_IP}
EOF

rm helm/nms/templates/magmate-claim3-spersistentvolume.yaml
cat << EOF > helm/nms/templates/magmalte-claim3-spersistentvolume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: magmalte-claim3
  labels:
    type: local
spec:  
  capacity:
    storage: 100Mi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: magmalte-claim3
    namespace: default      
  accessModes:
    - ReadWriteOnce
  nfs:
    path: /srv/k8s_volume/magmalte-claim3
    server: ${NFS_IP}
EOF
```


## Create the templates to expose the required services:
```bash
cat << EOF > clientcert-legacy-service.yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    kompose.cmd: kompose convert
    kompose.version: 1.21.0 (992df58d8)
  creationTimestamp: null
  labels:
    io.kompose.service: nginx
  name: clientcert-legacy
spec:
  ports:
  - name: "clientcert"
    port: 443
    targetPort: 9443
  selector:
    io.kompose.service: nginx
  type: LoadBalancer
status:
  loadBalancer: {}
EOF

cat << EOF > ssl-http2-service.yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    kompose.cmd: kompose convert
    kompose.version: 1.21.0 (992df58d8)
  creationTimestamp: null
  labels:
    io.kompose.service: nginx
  name: ssl-http2-legacy
spec:
  ports:
  - name: "clientcert"
    port: 443
    targetPort: 8443
  selector:
    io.kompose.service: nginx
  type: LoadBalancer
status:
  loadBalancer: {}
EOF


cat << EOF > bootstrap-service.yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    kompose.cmd: kompose convert
    kompose.version: 1.21.0 (992df58d8)
  creationTimestamp: null
  labels:
    io.kompose.service: nginx
  name: bootstrap-legacy
spec:
  ports:
  - name: "open"
    port: 443
    targetPort: 8444
  selector:
    io.kompose.service: nginx
  type: LoadBalancer
status:
  loadBalancer: {}
EOF
```

## Apply the templates (delete first if exists)
```bash
kubectl delete -f clientcert-legacy-service.yaml
kubectl delete -f bootstrap-service.yaml
kubectl delete -f ssl-http2-service.yaml
kubectl apply -f clientcert-legacy-service.yaml
kubectl apply -f bootstrap-service.yaml
kubectl apply -f ssl-http2-service.yaml
```


controller=`kubectl get services clientcert-legacy | grep LoadBalancer | awk '{print $4}'` && echo $controller

## Add controller hostname to magmalte /etc/hosts:
```bash
controller=`kubectl get services clientcert-legacy | grep LoadBalancer | awk '{print $4}'` && echo $controller
cat helm/nms/templates/magmalte-deployment.yaml
sed -i "s|#CONTROLLER_EXTERNAL_IP#|${controller}|g" helm/nms/templates/magmalte-deployment.yaml
sed -i "s|#CONTROLLER_HOSTNAME#|api.${DOMAIN}|g" helm/nms/templates/magmalte-deployment.yaml
cat helm/nms/templates/magmalte-deployment.yaml
```

## Install nms:
```bash
helm install orc8r-nms helm/nms/
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
nms=`kubectl get services | grep nginx-proxy-exposed | awk '{print $4}'` && echo $nms
controller=`kubectl get services ssl-http2-legacy | grep LoadBalancer | awk '{print $4}'` && echo $controller
api=`kubectl get services clientcert-legacy | grep LoadBalancer | awk '{print $4}'` && echo $api
bootstrapper=`kubectl get services bootstrap-legacy | grep LoadBalancer | awk '{print $4}'` && echo $bootstrapper
fluentd=`kubectl get service fluentd-exposed | grep LoadBalancer | awk '{print $4}'` && echo $fluentd
```

## Add the entries to /etc/hosts
```bash
org_list=("org01" "org02" "org03")
cat << EOF > etc_hosts
${nms} master.nms.${DOMAIN}
${controller} controller.${DOMAIN}
${bootstrapper} bootstrapper-controller.${DOMAIN}
${api} api.${DOMAIN}
${fluentd} fluentd.${DOMAIN}
EOF

for o in ${org_list[*]}; do
   echo "${nms} ${o}.nms.${DOMAIN}" >> etc_hosts
done
echo "https://master.nms.${DOMAIN}" 
```
## Important: Add the entries of etc_hosts to your /etc/hosts

# Create test subscribers:

```bash
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
