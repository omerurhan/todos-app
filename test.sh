#!/bin/sh

set -x

namespace="dev"
appname="nginx"

sleep 1
kubectl -n ${namespace} rollout status deploy ${appname} --timeout 2s
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Deployment ${appname} Rollout has Failed. Rolling back deployment!"
    kubectl -n ${namespace} rollout undo deploy ${appname}
fi
exit $retVal
