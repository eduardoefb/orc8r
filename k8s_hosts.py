#!/usr/bin/python3

import sys, yaml

d = None
with open(sys.argv[1], "r") as file:
    d = yaml.load(file, Loader=yaml.FullLoader)

master = []
worker = []
nfs = []
registery = []
agw = []
dns = []



for n in d['nodes']:
    if "master" in n['name']:
        master.append(n)
    elif "worker" in n['name']:
        worker.append(n) 
    elif "nfsreg" in n['name']:
        nfs.append(n)  
        registery.append(n)   
        dns.append(n) 
    elif "agw" in n['name']:
        agw.append(n)                 

print("[MASTER]")
for n in master:
    print(n['oam_ip'])
print("\n[WORKER]")
for n in worker:
    print(n['oam_ip'])

print("\n[NFS]")
for n in nfs:
    print(n['oam_ip'])

print("\n[DNS]")
for n in nfs:
    print(n['oam_ip'])    

print("\n[REGISTERY]")
for n in registery:
    print(n['oam_ip'])    

for i, n in enumerate(master):
    print("\n[MASTER" + str(i + 1) + "]" )
    print(n['oam_ip'])


print("\n[AGW]")
for n in agw:
    print(n['oam_ip'])    

print("\n[nodes]" )
for n in master:
    print(n['oam_ip'])

for n in worker:
    print(n['oam_ip'])

for n in nfs:
    print(n['oam_ip'])

for n in registery:
    print(n['oam_ip'])  

for n in agw:
    print(n['oam_ip'])


print("\n[hypervisor]")
print(d['hypervisor']['ip'])
