#!/bin/sh

set -e
set -v

###
# PLUGIN_JSON_KEY
# PLUGIN_CLUSTER
# PLUGIN_COMPUTE_REGION
# PLUGIN_COMPUTE_ZONE
# PLUGIN_PROJECT
# PLUGIN_DEBUG
# PLUGIN_RELEASE
# PLUGIN_RELEASE
# PLUGIN_CHART
# PLUGIN_NAMESPACE
# PLUGIN_VALUES
# PLUGIN_VERSION
###

echo "Setting auth key from environment"
echo "${PLUGIN_JSON_KEY:-"{}"}" > /var/svc_account.json
cat /var/svc_account.json
gcloud auth activate-service-account --key-file=/var/svc_account.json

echo "Setting cluster context"
gcloud config set container/use_v1_api_client false
gcloud beta container clusters get-credentials --project="$PLUGIN_PROJECT" --zone="$PLUGIN_ZONE" "$PLUGIN_CLUSTER" || exit
kubectl config current-context

echo "Initializing helm"
helm init --client-only

if [ "$PLUGIN_DEBUG" = true ]; then
    echo "Running: helm upgrade $PLUGIN_RELEASE $PLUGIN_CHART \
            --install \
            --recreate-pods \
            --namespace=${PLUGIN_NAMESPACE:-default} \
            --values=${PLUGIN_CHART}/values.yaml,${PLUGIN_CHART}/${PLUGIN_VALUES} \
            --set version=${PLUGIN_VERSION}"
fi

helm upgrade $PLUGIN_RELEASE $PLUGIN_CHART \
  --install \
  --recreate-pods \
  --namespace=${PLUGIN_NAMESPACE:-default} \
  --values=${PLUGIN_CHART}/values.yaml,${PLUGIN_CHART}/${PLUGIN_VALUES} \
  --set version=${PLUGIN_VERSION}
