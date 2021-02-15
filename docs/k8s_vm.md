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

### Deploy the virtual machines (edit the file k8s_vm_config.yml first):
```bash
cd magma
cat k8s_vm_config.yml > libvirt-lab-debian/config.yml
python3 k8s_hosts.py k8s_vm_config.yml > libvirt-lab-debian/hosts
cd libvirt-lab-debian
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts create_vm.yml

```

### After vm initialization, compile, build and upload images to the registery:

```bash 
cd magma
python3 k8s_hosts.py k8s_vm_config.yml > k8s/hosts
cat k8s_vm_config.yml > k8s/config.yml
cd k8s
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts 01_compile.yml
```

### To confirm that image is uploaded, check if they are available in registery url:

Example:
```bash
 curl http://10.5.0.32:5000/v2/_catalog
{"repositories":["controller","magmalte","nginx"]}

```


### Deploy k8s cluster:
```bash
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts 02_install_k8s_with_docker.yml
```

### Once k8s is installed, copy kubeconfig to your kube directory:
```bash
cp kubeconfig ~/.kube/config
```

### To enable autocompletion:
```bash
source <(kubectl completion bash)
```

### Once k8s cluster is running, [deploy magma](deploy_magma.md)

[<< Back](../README.md)