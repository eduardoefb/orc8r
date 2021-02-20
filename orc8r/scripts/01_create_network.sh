#!/bin/bash

source source-rc

echo "Create and edit network using NMS GUI!!!!!"
exit 0

unalias curl 2>/dev/null

if [ "$1" == "delete" ]; then
   curl --cacert ${CA_CERT} --cert ${CERT} --key ${KEY} -X DELETE "https://${API_URL}/magma/v1/lte/${network_id}" -H "accept: application/json" 
fi
cat << EOF > network_${network_id}.json
{
    "cellular": {
      "epc": {
        "default_rule_id": "default_rule_1",
        "gx_gy_relay_enabled": false,
        "hss_relay_enabled": false,
        "lte_auth_amf": "gAA=",
        "lte_auth_op": "EREREREREREREREREREREQ==",
        "mcc": "${network_mcc}",
        "mnc": "${network_mnc}",
        "network_services": [
          "policy_enforcement"
        ],
        "tac": ${network_tac}
      },
      "ran": {
        "bandwidth_mhz": 20,
        "tdd_config": {
          "earfcndl": 44590,
          "special_subframe_pattern": 7,
          "subframe_assignment": 2
        }
      }
    },
    "description": "${network_desc}",
    "dns": {
      "enable_caching": false,
      "local_ttl": 0
    },
    "features": {
      "features": {
        "placeholder": "true"
      }
    },
    "id": "${network_id}",
    "name": "${network_name}"
  }
}
EOF


curl --cacert ${CA_CERT} --cert ${CERT} --key ${KEY} -X POST "https://${API_URL}/magma/v1/lte" -H "accept: application/json" -H "content-type: application/json"  -d @network_${network_id}.json
