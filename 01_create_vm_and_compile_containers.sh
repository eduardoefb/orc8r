#!/bin/bash

# Create the vms for k8s cluster
cd ~/scripts/ansible/magma
cat k8s_vm_config.yml > libvirt-lab-debian/config.yml
python3 k8s_hosts.py k8s_vm_config.yml > libvirt-lab-debian/hosts
cd libvirt-lab-debian
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts create_vm.yml
cd ..

# 06 - Create the inventory file
cd ~/scripts/ansible/magma
python3 k8s_hosts.py k8s_vm_config.yml > k8s/hosts
cat k8s_vm_config.yml > k8s/config.yml
cd k8s
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts 01_compile.yml
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts 01_upload_images.yml

ssh debian@10.5.0.32 
sudo su - 
bash /tmp/upload.sh
exit

#time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts 02_install_k8s_with_crio.yml

# or
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts 02_install_k8s_with_docker.yml


# OPENCELLS VM:
cd ~/scripts/ansible/magma
cat enodeb_ue_vm_config.yml > libvirt-lab-ubuntu-server_18.04/config.yml
cd libvirt-lab-ubuntu-server_18.04
cat << EOF > hosts
[hypervisor]
10.2.1.31

[nodes]
10.10.1.20
10.10.1.21
EOF

time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts create_vm.yml

# If above step fails in update, execute:
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts update_vms.yml

cd /home/eduardoefb/scripts/ansible/magma
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

time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts install_opencells.yml
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts configure.yml

# 


## Enodeb:
/root/openairinterface5g/cmake_targets/ran_build/build/lte-softmodem --rfsim -O ~/opencells-mods/enb.sample --log_config.hw_log_level error

## UE:
cd ~
rm -rf ~/ue01
mkdir ~/ue01
cd ~/ue01
~/openairinterface5g/cmake_targets/nas_sim_tools/build/conf2uedata -c ~/opencells-mods/sim_modified.conf -o .
cd ~/ue01 && /root/openairinterface5g/cmake_targets/ran_build/build/lte-uesoftmodem -C 2685000000 -r 50 --rfsim --rfsimulator.serveraddr 10.10.1.20

# Create routes to test:
ip route add 10.2.1.0/24 via 10.10.1.1 dev eth0
ip route del default
ip route add default dev oaitun_ue1

# Speedtest:
apt-get install gnupg1 apt-transport-https dirmngr -y
export INSTALL_KEY=379CE192D401AB61
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $INSTALL_KEY
echo "deb https://ookla.bintray.com/debian generic main" | tee  /etc/apt/sources.list.d/speedtest.list
apt-get update
apt-get install speedtest -y
speedtest
