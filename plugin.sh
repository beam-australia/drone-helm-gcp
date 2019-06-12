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

if [ "${PLUGIN_JSON_KEY:-}" ];then
    echo "${PLUGIN_JSON_KEY}" > /tmp/certs/svc_account.json
    gcloud auth activate-service-account --key-file=/tmp/certs/svc_account.json
fi

# If there is no current context, get one.
if [[ $(kubectl config current-context 2> /dev/null) == "" ]]; then
    # This tries to read environment variables. If not set, it grabs from gcloud
    cluster=${PLUGIN_CLUSTER:-$(gcloud config get-value container/cluster 2> /dev/null)}
    region=${PLUGIN_COMPUTE_REGION:-$(gcloud config get-value compute/region 2> /dev/null)}
    zone=${PLUGIN_COMPUTE_ZONE:-$(gcloud config get-value compute/zone 2> /dev/null)}
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
fi

echo "Running: helm init --client-only"
helm init --client-only

# if GCS_PLUGIN_VERSION is set, install the plugin
if [[ -n $GCS_PLUGIN_VERSION ]]; then
  echo "Installing helm GCS plugin version $GCS_PLUGIN_VERSION "
  helm plugin install https://github.com/nouney/helm-gcs --version $GCS_PLUGIN_VERSION
fi

# if DIFF_PLUGIN_VERSION is set, install the plugin
if [[ -n $DIFF_PLUGIN_VERSION ]]; then
  echo "Installing helm DIFF plugin version $DIFF_PLUGIN_VERSION "
  helm plugin install https://github.com/databus23/helm-diff --version $DIFF_PLUGIN_VERSION
fi

# check if repo values provided then add that repo
if [[ -n $HELM_REPO_NAME && -n $HELM_REPO_URL ]]; then
  echo "Adding chart helm repo $HELM_REPO_URL "
  helm repo add $HELM_REPO_NAME $HELM_REPO_URL
fi

echo "Running: helm repo update"
helm repo update

if [ "$PLUGIN_DEBUG" = true ]; then
    echo "helm upgrade $PLUGIN_RELEASE $PLUGIN_CHART \
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
