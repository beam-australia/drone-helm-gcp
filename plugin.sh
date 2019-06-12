#!/bin/sh

set -e

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

# This tries to read environment variables. If not set, it grabs from gcloud
cluster=${PLUGIN_CLUSTER:-$(gcloud config get-value container/cluster 2> /dev/null)}
region=${PLUGIN_REGION:-$(gcloud config get-value compute/region 2> /dev/null)}
zone=${PLUGIN_ZONE:-$(gcloud config get-value compute/zone 2> /dev/null)}
project=${PLUGIN_PROJECT:-$(gcloud config get-value core/project 2> /dev/null)}

function var_usage() {
    cat <<EOF
No cluster is set. To set the cluster (and the region/zone where it is found), set the environment variables
  COMPUTE_REGION=<cluster region> (regional clusters)
  COMPUTE_ZONE=<cluster zone> (zonal clusters)
  CONTAINER_CLUSTER=<cluster name>
EOF
    exit 1
}

[[ -z "$cluster" ]] && var_usage
[ ! "$zone" -o "$region" ] && var_usage

if [ -n "$region" ]; then
  echo "Running: gcloud config set container/use_v1_api_client false"
  gcloud config set container/use_v1_api_client false
  echo "Running: gcloud beta container clusters get-credentials --project=\"$project\" --region=\"$region\" \"$cluster\""
  gcloud beta container clusters get-credentials --project="$project" --region="$region" "$cluster" || exit
else
  echo "Running: gcloud container clusters get-credentials --project=\"$project\" --zone=\"$zone\" \"$cluster\""
  gcloud container clusters get-credentials --project="$project" --zone="$zone" "$cluster" || exit
fi

echo "Running: kubectl config current-context"
kubectl config current-context

echo "Running: helm init --client-only"
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
