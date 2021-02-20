#!/bin/bash

source source-rc


unalias curl 2>/dev/null

if [ "$1" == "delete" ]; then
   curl --cacert ${CA_CERT} --cert ${CERT} --key ${KEY} -X DELETE "https://${API_URL}/magma/v1/lte/${network_id}" -H "accept: application/json" 
fi
cat << EOF > network_${network_id}.json
{
  "default_rule_id": "default_rule_1",
  "gx_gy_relay_enabled": false,
  "hss_relay_enabled": false,
  "lte_auth_amf": "gAA=",
  "lte_auth_op": "EREREREREREREREREREREQ==",
  "mcc": "724",
  "mnc": "17",
  "mobility": {
    "ip_allocation_mode": "NAT",
    "reserved_addresses": null
  },
  "network_services": [
    "policy_enforcement"
  ],
  "sub_profiles": {
    "1M": {
      "max_dl_bit_rate": 1000000,
      "max_ul_bit_rate": 1000000
    },
    "5M": {
      "max_dl_bit_rate": 5000000,
      "max_ul_bit_rate": 5000000
    },
    "10M": {
      "max_dl_bit_rate": 10000000,
      "max_ul_bit_rate": 10000000
    },
    "20M": {
      "max_dl_bit_rate": 20000000,
      "max_ul_bit_rate": 20000000
    },  
    "50M": {
      "max_dl_bit_rate": 50000000,
      "max_ul_bit_rate": 50000000
    },  
    "100M": {
      "max_dl_bit_rate": 100000000,
      "max_ul_bit_rate": 100000000
    },
    "200M": {
      "max_dl_bit_rate": 200000000,
      "max_ul_bit_rate": 200000000
    },
    "500M": {
      "max_dl_bit_rate": 500000000,
      "max_ul_bit_rate": 500000000
    }
  },
  "tac": 100
}
EOF

curl --cacert ${CA_CERT} --cert ${CERT} --key ${KEY} -X PUT "https://${API_URL}/magma/v1/lte/${network_id}/cellular/epc" -H "accept: application/json" -H "content-type: application/json"  -d @network_${network_id}.json
