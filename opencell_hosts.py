#!/usr/bin/python3

import sys, yaml

d = None
with open(sys.argv[1], "r") as file:
    d = yaml.load(file, Loader=yaml.FullLoader)

enodeb = []
ue = []


for n in d['nodes']:
    if "enodeb" in n['name']:
        enodeb.append(n)
    elif "ue" in n['name']:
        ue.append(n) 
             

print("[enodeb]")
for n in enodeb:
    print(n['oam_ip'])
print("\n[ue]")
for n in ue:
    print(n['oam_ip'])
 

print("\n[nodes]" )
for n in enodeb:
    print(n['oam_ip'])

for n in ue:
    print(n['oam_ip'])


print("\n[hypervisor]")
print(d['hypervisor']['ip'])
