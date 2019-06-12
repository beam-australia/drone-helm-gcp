FROM google/cloud-sdk:alpine

ARG HELM_VERSION=v2.14.0

COPY auth /root/.config/gcloud

RUN apk --update --no-cache add openjdk7-jre curl

RUN gcloud components install app-engine-java kubectl

COPY plugin.sh /builder/plugin.sh

RUN chmod +x /builder/plugin.sh && \
  mkdir -p /builder/helm && \
  curl -SL https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz -o helm.tar.gz && \
  tar zxvf helm.tar.gz --strip-components=1 -C /builder/helm linux-amd64/helm linux-amd64/tiller && \
  rm helm.tar.gz

ENV PATH=/builder/helm/:$PATH

ENTRYPOINT ["/builder/plugin.sh"]
