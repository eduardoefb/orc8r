# AGW deployment:


## Add magma user:
```bash
useradd -m magma -s /bin/bash
```

## Download the agw script from magma repository and execute:
```bash
wget https://raw.githubusercontent.com/facebookincubator/magma/v1.3/lte/gateway/deploy/agw_install.sh
bash agw_install.sh
```
journalctl -fu agw_installation

## Create the certs directory and copy the rootCA.pem (from orc8r) into it:
```bash
mkdir -p /var/opt/magma/tmp/certs/
mv /tmp/rootCA.pem /var/opt/magma/tmp/certs/
```

## Point your AGW to your Orchestrator:
```bash
mkdir -p /var/opt/magma/configs
cd /var/opt/magma/configs
cat << EOF > control_proxy.yml
cloud_address: controller.orc8r.int
cloud_port: 443
bootstrap_address: bootstrapper-controller.orc8r.int
bootstrap_port: 443

rootca_cert: /var/opt/magma/tmp/certs/rootCA.pem
EOF

## Edit etc/hosts 
Example:

```bash
cat << EOF >> /etc/hosts
10.5.0.132 master.nms.orc8r.int
10.5.0.131 controller.orc8r.int
10.5.0.130 bootstrapper-controller.orc8r.int
10.5.0.129 api.orc8r.int
10.5.0.133 fluentd.orc8r.int
10.5.0.132 org01.nms.orc8r.int
10.5.0.132 org02.nms.orc8r.int
10.5.0.132 org03.nms.orc8r.int
EOF
```

## Display information from agw and create it into orchestrator:
```bash
show_gateway_info.py
```

## Restart agw service and verify the integration:
```bash
sudo service magma@* stop
sudo service magma@magmad restart
journalctl -u magma@magmad -f
```

## Check magma version:
```bash
dpkg -l magma
bash

