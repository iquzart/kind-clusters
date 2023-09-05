curl \
    --request POST \
    --data @payload.json \
    http://vault.testbox.pod/v1/auth/kubernetes/devops_cluster/login


# KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
# curl --insecure --request POST --data '{"jwt": "'"$KUBE_TOKEN"'", "role": "demo-role"}' https://vault-dev:8200/v1/auth/kubernetes/login
