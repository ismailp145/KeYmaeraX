#!/bin/bash

echo "
*******************************************************************************
KeYmaera X repeatability evaluation.
*******************************************************************************
"

set -e

while getopts "u:" flag; do
    case $flag in
        u) user=${OPTARG};;
    esac
done

if [ -z "$user" ]
then
  user="$(whoami)"
  if [ -z "$user" ]
  then
    echo "Failed to detect \$user for licenses. Provide username with -u."
    exit 1
  fi
fi

docker start kyx

mkdir -p results

docker exec -it -w /$user kyx bash "./runKeYmaeraX5Benchmarks"
docker exec -w /$user kyx bash -c "mkdir -p results; mv *.csv results"
mkdir -p results
docker cp kyx:/$user/results ./results

docker stop kyx
