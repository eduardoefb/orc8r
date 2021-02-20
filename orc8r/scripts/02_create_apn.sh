#!/bin/bash

source source-rc

unalias curl 2>/dev/null
curl \
   --cacert ${CA_CERT}  \
   --cert ${CERT} --key ${KEY} \
   -X DELETE "https://${API_URL}/magma/v1/lte/${apn_name}" \
   -H "accept: application/json" 


if [ "$1" == "delete" ]; then
   curl --cacert ${CA_CERT} --cert ${CERT} --key ${KEY} -X DELETE "https://${API_URL}/magma/v1/lte/${network_id}/apns/${apn_name}" -H "accept: application/json"
fi
cat << EOF > apn_${apn_name}.json
{
  "apn_configuration": {
    "ambr": {
      "max_bandwidth_dl": ${apn_max_bandwidth_dl},
      "max_bandwidth_ul": ${apn_max_bandwidth_ul}
    },
    "qos_profile": {
      "class_id": ${apn_qos},
      "preemption_capability": true,
      "preemption_vulnerability": false,
      "priority_level": 15
    }
  },
  "apn_name": "${apn_name}"
}
EOF

curl --cacert ${CA_CERT} --cert ${CERT} --key ${KEY} -X POST "https://${API_URL}/magma/v1/lte/${network_id}/apns" -H "accept: application/json" -H "content-type: application/json" -d @apn_${apn_name}.json
