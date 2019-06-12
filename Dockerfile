FROM google/cloud-sdk:alpine

# configure gcloud kubectl
COPY auth /root/.config/gcloud
RUN mkdir -p /tmp/certs
RUN gcloud components install kubectl
COPY plugin.sh /var/plugin.sh

# Install Helm
ARG HELM_VERSION=v2.14.0
ENV FILENAME helm-${HELM_VERSION}-linux-amd64.tar.gz
ENV HELM_URL https://storage.googleapis.com/kubernetes-helm/${FILENAME}
RUN echo $HELM_URL
RUN apk --update --no-cache add curl \ 
  && curl -o /tmp/$FILENAME ${HELM_URL} \
  && tar -zxvf /tmp/${FILENAME} -C /tmp \
  && mv /tmp/linux-amd64/helm /bin/helm \
  && rm -rf /tmp

ENTRYPOINT ["/var/plugin.sh"]
