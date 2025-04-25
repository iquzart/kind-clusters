#!/bin/bash

set -euo pipefail

CLUSTER_NAMES=$(kind get clusters)

if [[ -z "$CLUSTER_NAMES" ]]; then
  echo "No Kind clusters found."
  exit 0
fi

echo "Available Kind clusters:"
select name in $CLUSTER_NAMES "All"; do
  if [[ -z "$name" ]]; then
    echo "Invalid selection. Try again."
    continue
  fi

  if [[ "$name" == "All" ]]; then
    read -rp "Are you sure you want to delete ALL Kind clusters? (y/n): " confirm
    if [[ "${confirm,,}" == "y" ]]; then
      for cluster in $CLUSTER_NAMES; do
        echo "Deleting Kind cluster: $cluster"
        kind delete cluster --name "$cluster"
      done
      echo "All clusters deleted."
    else
      echo "Aborted deletion of all clusters."
    fi
  else
    echo "Deleting Kind cluster: $name"
    kind delete cluster --name "$name"
    echo "Cluster '$name' deleted."
  fi
  break
done

