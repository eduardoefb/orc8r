## Create the vms for k8s and register

Install the required packages on your computer:
```bash
pip3 install pyaml
sudo apt install -y ansible
ansible-galaxy collection install community.libvirt
```

Deploy the virtual machines (edit the file k8s_vm_config.yml first):
```bash
cd magma
cat k8s_vm_config.yml > libvirt-lab-debian/config.yml
python3 k8s_hosts.py k8s_vm_config.yml > libvirt-lab-debian/hosts
cd libvirt-lab-debian
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts create_vm.yml

```

After vm initialization, start the magma image compilation:

```bash 
cd magma
python3 k8s_hosts.py k8s_vm_config.yml > k8s/hosts
cat k8s_vm_config.yml > k8s/config.yml
cd k8s
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts 01_compile.yml
```

Prepare register to upload the images:
```bash
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts 01_prepare_registery.yml
```

Connect to the register and upload the images manually:
```
ssh debian@10.5.0.32 
sudo su - 
bash /tmp/upload.sh upload
exit
```

Deploy k8s cluster:
```bash
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts 02_install_k8s_with_docker.yml
```

Once k8s is installed, copy kubeconfig to your kube directory:
```bash
cp kubeconfig ~/.kube/config
```

To enable autocompletion:
```bash
source <(kubectl completion bash)
```

Once k8s cluster is running, deploy magma using the follwing guide:

