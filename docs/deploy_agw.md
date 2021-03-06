# AGW deployment ([Reference](https://magma.github.io/magma/docs/lte/setup_deb)):


## Add magma user:
```bash
useradd -m magma -s /bin/bash
```

## Download the agw script from magma repository and execute:
```bash
wget https://raw.githubusercontent.com/facebookincubator/magma/v1.3/lte/gateway/deploy/agw_install.sh
bash agw_install.sh
```

## After reboot, follow the installation:
```bash
journalctl -fu agw_installation
```

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
```

[<< Back](../README.md)



## To reintegrate AGW with another orc8r:

```bash
apt purge -y magma
rm -rfv /var/opt/magma/
rm -rfv /etc/hagma
apt install -y magma
```

Repeat the steps above (for integration)