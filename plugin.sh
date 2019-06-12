#!/bin/sh

set -e
set -v

GCP_KEY=${PLUGIN_JSON_KEY:-"{}"}
PROJECT=${PLUGIN_PROJECT:-$PROJECT}
ZONE=${PLUGIN_ZONE:-$ZONE}
CLUSTER=${PLUGIN_CLUSTER:-$CLUSTER}
NAMESPACE=${PLUGIN_NAMESPACE:-default}
VERSION=${PLUGIN_VERSION:-latest}

echo "Setting auth key from environment"
echo "$GCP_KEY" > /var/svc_account.json
cat /var/svc_account.json
gcloud auth activate-service-account --key-file=/var/svc_account.json

echo "Setting cluster context"
gcloud config set container/use_v1_api_client false
gcloud beta container clusters get-credentials --project="$PROJECT" --zone="$ZONE" "$CLUSTER" || exit
kubectl config current-context

echo "Initializing helm"
helm init --client-only

helm upgrade $PLUGIN_RELEASE $PLUGIN_CHART \
  --install \
  --recreate-pods \
  --namespace=${PLUGIN_NAMESPACE:-default} \
  --values=${PLUGIN_CHART}/values.yaml,${PLUGIN_CHART}/${PLUGIN_VALUES} \
  --set version=${PLUGIN_VERSION}
