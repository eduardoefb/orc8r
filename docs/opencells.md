# Create the vms for opencells enodeb and ue

Execute the following commands to deploy the enodeb and ue virtual machines (edit enodeb_ue_vm_config.yml first):

```bash
cd magma
cat enodeb_ue_vm_config.yml > libvirt-lab-ubuntu-server_18.04/config.yml
cd libvirt-lab-ubuntu-server_18.04
```

Create the inventory file containing the IPs of enodeb and ue:

```bash
cat << EOF > hosts
[hypervisor]
10.2.1.31

[nodes]
10.10.1.20
10.10.1.21
EOF
```

Execute the playbook:
``` bash 
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts create_vm.yml
```

Update vms:
``` bash 
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts update_vm.yml
```

Enter create the configuration file and inventory file for opencells nodes:
```bash
cd magma
cat enodeb_ue_vm_config.yml > opencells/config.yml
cd opencells
cat << EOF > hosts
[hypervisor]
10.2.1.31

[enodeb]
10.10.1.20

[ue]
10.10.1.21

[nodes]
10.10.1.20
10.10.1.21

EOF
```

Build opencells:
``` bash 
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts install_opencells.yml
```


Configure ue and enodeb:
``` bash 
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts configure.yml
```


To connect enodeb to agw, execute the following command:
```bash
connect_to_mme.sh
```

To connect UE to enodeb:

Obs.:  The scripts will be generated based on your opencells config file:
```bash
connect_ue01.sh
```

Once PDP context is created, open the ue namespace, and add the default route:
```bash
ip netns exec ue01 bash
ip route add default dev oaitun_ue1
```

To install speedtest in UE:
```bash
apt-get install gnupg1 apt-transport-https dirmngr -y
export INSTALL_KEY=379CE192D401AB61
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $INSTALL_KEY
echo "deb https://ookla.bintray.com/debian generic main" | tee  /etc/apt/sources.list.d/speedtest.list
apt-get update
apt-get install speedtest -y
speedtest
```

[<< Back](../README.md)