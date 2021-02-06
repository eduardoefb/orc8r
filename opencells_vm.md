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


To connect enodeb with agw, execute the following command:
```bash
/root/openairinterface5g/cmake_targets/ran_build/build/lte-softmodem --rfsim -O ~/opencells-mods/enb.sample --log_config.hw_log_level error
```

To connect UE to enodeb, execute (Considering enodeb ip = 10.10.1.20):
```bash
cd ~
rm -rf ~/ue01
mkdir ~/ue01
cd ~/ue01
~/openairinterface5g/cmake_targets/nas_sim_tools/build/conf2uedata -c ~/opencells-mods/sim_modified.conf -o .
cd ~/ue01 && /root/openairinterface5g/cmake_targets/ran_build/build/lte-uesoftmodem -C 2685000000 -r 50 --rfsim --rfsimulator.serveraddr 10.10.1.20
```

Once UE is attached, create the static route to your computer to avoid connection loss:
```bash
ip route add 10.2.1.0/24 via 10.10.1.1 dev eth0
ip route del default
ip route add default dev oaitun_ue1
```

Install speedtest in UE:
```bash
apt-get install gnupg1 apt-transport-https dirmngr -y
export INSTALL_KEY=379CE192D401AB61
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $INSTALL_KEY
echo "deb https://ookla.bintray.com/debian generic main" | tee  /etc/apt/sources.list.d/speedtest.list
apt-get update
apt-get install speedtest -y
speedtest
```