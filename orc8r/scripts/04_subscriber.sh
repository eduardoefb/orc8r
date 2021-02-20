#!/bin/bash

source source-rc


cat << EOF > to_bin.c
# include <stdio.h>
# include <string.h>

int main(int argc, char **argv){
   int i, c, d;
   char *f = argv[1];
      
   for(i = 0; i < strlen(f); i++){
      if(f[i] >= 'a' && f[i] <= 'f'){
         c = f[i] - 'a' + 10;
      }
      
      else if(f[i] >= 'A' && f[i] <= 'F'){
         c = f[i] - 'a' + 10;
      }      
      
      else if(f[i] >= '0' && f[i] <= '9'){
         c = f[i] - '0';         
      }
      
      if(i % 2 == 0){
         d = c;
      }
      else{
         d = d*0x10 + c;
         printf("%c", d);
      }
      
   }
}
EOF

gcc to_bin.c -o to_bin

for l in `cat subscriber_list.csv | grep -v 'imsi,key,opc,apn'`; do 
  imsi=`echo $l | awk -F ',' '{print $1}'`
  key=`echo $l | awk -F ',' '{print $2}'`
  opc=`echo $l | awk -F ',' '{print $3}'`
  apn=`echo $l | awk -F ',' '{print $4}'`
  id="IMSI${imsi}"
  echo ${id}
  opc_encoded=`./to_bin $opc | tr '[:upper:]' '[:lower:]' | base64` 
  key_encoded=`./to_bin $key | tr '[:upper:]' '[:lower:]' | base64` 


  cat << EOF > subscriber_${id}.json
  {
    "active_apns": [
      "${apn_name}"
    ],
    "id": "${id}",
    "lte": {
      "auth_algo": "MILENAGE",
      "auth_key": "${key_encoded}",
      "auth_opc": "${opc_encoded}",
      "state": "ACTIVE",
      "sub_profile": "default"
    }
  }
EOF


  # Delete subscriber if exists:
  curl  --cacert ${CA_CERT} --cert ${CERT} --key ${KEY} \
      -X DELETE "https://${API_URL}/magma/v1/lte/${network_id}/subscribers/${id}" \
      -H "accept: application/json"

  # Create
  curl  --cacert ${CA_CERT} --cert ${CERT} --key ${KEY} -X POST "https://${API_URL}/magma/v1/lte/${network_id}/subscribers" \
    -H "accept: application/json" \
    -H "content-type: application/json" \
    -d @subscriber_${id}.json 

done 
