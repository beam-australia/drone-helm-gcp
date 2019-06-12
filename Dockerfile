FROM gcr.io/cloud-builders/gcloud-slim

RUN gcloud components install kubectl

ARG HELM_VERSION=v2.14.0

COPY plugin.bash /builder/plugin.bash

RUN chmod +x /builder/plugin.bash && \
  mkdir -p /builder/helm && \
  apt-get update && \
  apt-get install -y curl && \
  curl -SL https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz -o helm.tar.gz && \
  tar zxvf helm.tar.gz --strip-components=1 -C /builder/helm linux-amd64/helm linux-amd64/tiller && \
  rm helm.tar.gz && \
  apt-get --purge -y autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

ENV PATH=/builder/helm/:$PATH

ENTRYPOINT ["/builder/plugin.bash"]
