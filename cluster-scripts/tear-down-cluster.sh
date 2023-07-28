#!/bin/bash

# Get a list of all Kind clusters on the system
CLUSTER_NAMES=$(kind get clusters)

# Prompt the user to select a Kind cluster to tear down
PS3="Select a Kind cluster to tear down or enter 'All': "
select name in $CLUSTER_NAMES "All"
do
    # Check if a valid cluster name was selected or "All" was entered
    if [[ -n "$name" ]]; then
        if [[ "$name" == "All" ]]; then
            read -p "Are you sure you want to delete all Kind clusters? (y/n): " confirm
            if [[ "$confirm" == "y" ]]; then
                for cluster_name in $CLUSTER_NAMES; do
                    echo "Deleting Kind cluster $cluster_name"
                    kind delete cluster --name $cluster_name
                done
            fi
        else
            echo "Deleting Kind cluster $name"
            kind delete cluster --name $name
        fi
        break
    fi
done