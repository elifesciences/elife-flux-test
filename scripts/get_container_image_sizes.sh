#!/bin/bash
for container in $(kubectl get pods --all-namespaces -o json | jq -r '.items[].spec.containers[].image' | sort | uniq); do
    # skip the AWS images, we don't have permission to pull
    if [[ "$container" =~ .*"amazonaws.com".* ]]; then
        continue
    fi

    docker pull -q $container > /dev/null
    size=$(docker image inspect $container | jq -r '.[0].Size')
    size_in_mb=$(docker image inspect $container | jq -r '.[0].Size/1024/1024')
    echo "$container,$size,$size_in_mb"
done;
