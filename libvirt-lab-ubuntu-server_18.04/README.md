# Define your config file:

Use the example below as reference:
```bash
cat << EOF > config.yml
---

  root_pw_hash: #PWD_HASH#
  # To generate a password hash:
  # python3 -c 'import crypt; import os; print(crypt.crypt("root_password", crypt.mksalt(crypt.METHOD_SHA512)))'

  authorized_keys: 
    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4tzrayU6ahMhmWuicy+oFfy//9oB+2EdbbmDfA0d+k3SpYjWVqho64/L+sQIAN0RGBJx42GkbKi8B6AriPw8omLOCk2WSYW3ymEC7n3l32M5T4cLr8LIYwoMOBZkMtRc3H62PrHgDoTJLhUOvT2ewj1SLl7iU5gQuInwPE6jWooIb8R6KMUl31qNpkafCVPz5ovw0iYbDamHQF6sq081Xl39px2345T8TofIAocyBUfCOstmAvPaD9lXIV3j9JmPhAy0oweXpxdPiQzBHXepLh/jrvHrV5ggl2iwmLgF3uzwYdFlQN6eCniBtBEcGqEacb6oP2KHfHer04WIbAMHZ eduardoefb@efb
    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEogQQvxuvrZQZY7mNRxWTQ2KM+BzggtaGbckhevJiOXHbN1TyJZNFXMHz3ZH2g913uXCD31hikSwhWQdGPDCIy8KRPdaDsa9zVhZJ5e/WQ9/g2OYaZDlL1ESQtJvCCubo7XDxHkOPxrjaIJrt8sAJRCBO3GIoY+Ush+tqG7KnGuj3Z9MkunaRmNKmaOrRQtxAhGW0na6mRltdpkdVvSrER1MIh4dipr6CAm79xcdqzq64qkYLPq31AQs8A4B8rIPcZipaxBFi5KARC9PvEJ4pkAvaGFnPmFY1v1FUGSsuF0hRZiqa/gUU1QGKvT2UlA1dvbU6gY2rohilMiDtQOaD eduardoefb@efb
  
  timezone: Brazil/East
  hypervisor:
    name: hypervisor
    ip: 10.2.1.31
    workdir: /srv/lab     
  
  network:
    domain: openstack.int
    ntp_servers:      
      - 0.centos.pool.ntp.org
      - 1.centos.pool.ntp.org
      - 2.centos.pool.ntp.org
      - 3.centos.pool.ntp.org
      
    oam:
      name: lab_oam
      external_vlan: 60
      external_interface: eth0
      network: 10.6.0.0
      broadcast: 10.6.0.255
      gateway: 10.6.0.1
      netmask: 255.255.255.0
      netmask_len: 24
      dns: 8.8.8.8
      dev: "vnet0"
      alias: "net0"
      slot: "0x10"
      type: "rtl8139"
 
    external:
      - name: extnet01
        external_vlan: 62
        external_interface: eth0
        network: 10.7.0.0        
        broadcast: 10.7.0.255        
        netmask: 255.255.255.0
        netmask_len: 24
        dev: "vnet1"
        alias: "net1"
        slot: "0x11" 
        type: "rtl8139"   

      - name: extnet02
        external_vlan: 63
        external_interface: eth0
        network: 10.8.0.0        
        broadcast: 10.8.0.255        
        netmask: 255.255.255.0
        netmask_len: 24
        dev: "vnet2"
        alias: "net2"
        slot: "0x12" 
        type: "rtl8139"          

  iso_image:
    url: http://ftp.unicamp.br/pub/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso
    #url: http://10.2.1.32/images/CentOS-7-x86_64-Minimal-2009.iso
    filename: centos_7.iso

  nodes:  
    - name: controller01
      hypervisor: "{{ hypervisor }}"
      ram: 8192000
      cpus: 4      
      disk: 
        - name: "controller01_disk_0.qcow2"
          size: "40G"
          dev: "sda"
          unit: 1
          bus: "sata"
      oam_ip: "10.6.0.10"      
      external_ips:
        - 10.7.0.10
        - 10.8.0.10
		
      vnc: 
        port: 26010

    - name: compute01
      hypervisor: "{{ hypervisor }}"
      ram: 8192000
      cpus: 4       
      disk: 
        - name: "compute01_disk_0.qcow2"
          size: "40G"
          dev: "sda"
          unit: 1
          bus: "sata"
      oam_ip: "10.6.0.20"      
      external_ips:
        - 10.7.0.20
        - 10.8.0.20

      vnc: 
        port: 26020   

    - name: compute02
      hypervisor: "{{ hypervisor }}"
      ram: 8192000
      cpus: 4       
      disk: 
        - name: "compute02_disk_0.qcow2"
          size: "40G"
          dev: "sda"
          unit: 1
          bus: "sata"
      oam_ip: "10.6.0.21"      
      external_ips:
        - 10.7.0.21
        - 10.8.0.21
      
      vnc: 
        port: 26021  
        
    - name: compute03
      hypervisor: "{{ hypervisor }}"
      ram: 8192000
      cpus: 4       
      disk: 
        - name: "compute03_disk_0.qcow2"
          size: "40G"
          dev: "sda"
          unit: 1
          bus: "sata"
      oam_ip: "10.6.0.22"      
      external_ips:
        - 10.7.0.22
        - 10.8.0.22
      
      vnc: 
        port: 26022        
                
    - name: storage01
      hypervisor: "{{ hypervisor }}"
      ram: 8192000
      cpus: 4      
      disk: 
        - name: "storage01_disk_0.qcow2"
          size: "40G"
          dev: "sda"
          unit: 1
          bus: "sata"
        - name: "storage01_disk_1.qcow2"
          size: "40G"
          dev: "sdb"
          unit: 2
          bus: "sata"          
      oam_ip: "10.6.0.30"      
      external_ips:
        - 10.7.0.30
        - 10.8.0.30
      
      vnc: 
        port: 26030     

    - name: storage02
      hypervisor: "{{ hypervisor }}"
      ram: 8192000
      cpus: 4      
      disk: 
        - name: "storage02_disk_0.qcow2"
          size: "40G"
          dev: "sda"
          unit: 1
          bus: "sata"
        - name: "storage02_disk_1.qcow2"
          size: "40G"
          dev: "sdb"
          unit: 2
          bus: "sata"          
      oam_ip: "10.6.0.31"      
      external_ips:
        - 10.7.0.31
        - 10.8.0.31
      
      vnc: 
        port: 26031
  
EOF
```

# Define the root password:

Replace "root_pw" to your password:

```bash
sha=`python3 -c 'import crypt; import os; print(crypt.crypt("root_pw", crypt.mksalt(crypt.METHOD_SHA512)))'`
sed -i "s|#PWD_HASH#|${sha}|g" config.yml
```

# Create the virtual machines:

```bash
time ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts create_vm.yml 
```
