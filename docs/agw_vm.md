# Create the vms for k8s and register

### As root user, install the pyaml and ansible:
```bash 
pip3 install pyaml
pip3 install ansible

```

### Install libvirt community:
```bash
ansible-galaxy collection install community.libvirt
```

### Deploy the virtual machines (edit the file agw_vm_config.yml first):
```bash
cd magma
cat agw_vm_config.yml > libvirt-lab-debian9/config.yml
python3 k8s_hosts.py k8s_vm_config.yml > libvirt-lab-debian9/hosts
cd libvirt-lab-debian9
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts create_vm.yml

```


[<< Back](../README.md)