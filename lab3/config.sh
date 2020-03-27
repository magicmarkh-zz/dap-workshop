#!/bin/bash

#get the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#retrieve the certificate for the dap master container
openssl s_client -showcerts -connect dap-master:443 </dev/null 2> /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > $DIR/ssl-certificate

#update the configmaps with the certificate value
kubectl create configmap -n dap k8s-app-ssl --from-file $DIR/ssl-certificate -o yaml --dry-run | kubectl replace -f -
kubectl create configmap -n lab3 k8s-app-ssl --from-file $DIR/ssl-certificate -o yaml --dry-run | kubectl replace -f -
kubectl create configmap -n lab4 k8s-app-ssl --from-file $DIR/ssl-certificate -o yaml --dry-run | kubectl replace -f -
kubectl create configmap -n lab5 k8s-app-ssl --from-file $DIR/ssl-certificate -o yaml --dry-run | kubectl replace -f -

#retrieve the name of the secret that stores the service account token
TOKEN_SECRET_NAME="$(kubectl get secrets -n dap | grep 'conjur.*service-account-token' | head -n1 | awk '{print $1}')"

#update DAP with the certificate of the namespace service account
docker exec dap-cli conjur variable values add conjur/authn-k8s/k8s-follower/kubernetes/ca-cert \
  "$(kubectl get secret -n dap $TOKEN_SECRET_NAME -o json | jq -r '.data["ca.crt"]' | base64 --decode)"

#update DAP with the namespace service account token
docker exec dap-cli conjur variable values add conjur/authn-k8s/k8s-follower/kubernetes/service-account-token \
  "$(kubectl get secret -n dap $TOKEN_SECRET_NAME -o json | jq -r .data.token | base64 --decode)"

#update DAP with the URL of the Kubernetes API
docker exec dap-cli conjur variable values add conjur/authn-k8s/k8s-follower/kubernetes/api-url \
  "$(kubectl config view --minify -o json | jq -r '.clusters[0].cluster.server')"

#delete the pods in the DAP namespace so that they can restart with the appropriate values
kubectl delete pods -n dap --all