#!/bin/bash

# The script can be invoked with -u, -l, and -m options

# -u USERNAME specifies the username to be used in the Docker image (which must be tied to your MATLAB license)
# If not specified, the script will try to use your current username

# -m MAC_ADDRESS specifies the MAC address (which must be tied to your MATLAB license)
# If not specified, the script will try to guess a default address

# -l path/to/matlab.lic specifies the full path to the MATLAB network license
# The username and MAC address above must be tied to your MATLAB license

# run example (with MATLAB license tied to current user):
# setup.sh -l path/to/matlab.lic -m MAC_ADDRESS

# run example (without MATLAB license):
# setup.sh -m MAC_ADDRESS

set -e

while getopts "l:m:u:" flag; do
    case $flag in
        l) license=${OPTARG};;
        m) macaddr=${OPTARG};;
        u) user=${OPTARG};;
    esac
done

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    # *)          machine="UNKNOWN:${unameOut}"
esac
echo "Running on $machine"
case "$machine" in
  Linux)  ethif=eth0;;
  Mac)    ethif=en0;;
esac


if [ -z "$user" ]
then
  user="$(whoami)"
  if [ -z "$user" ]
  then
    echo "Failed to detect \$user for setup and licenses. Provide username with -u."
    exit 1
  fi
fi

if [ -z "$macaddr" ]
then
  macaddr="$(ifconfig $ethif | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')"
  if [ -z "$macaddr" ]
  then
    echo "Failed to detect \$macaddr for setup and licenses. Provide MAC address with -m."
    exit 1
  fi
fi

if [ -z "$license" ]
then
  echo "WARNING: MATLAB license path is empty. MATLAB will not be enabled unless a path to your license file is provided with -l."
  # make a dummy file
  touch matlab.lic
else
  echo "Using Matlab license tied to:"
  echo $user
  echo $macaddr
  echo $license
  # copy license file into current directory, Docker container has only access to local files
  cp "$license" matlab.lic
fi

# Set up licensing for WolframEngine
# The folder for Licensing is given lax permissions so that WolframEngine's activation process inside Docker can write to it
mkdir -p Licensing
chmod -R 757 "$PWD/Licensing"


docker rm -f kyx
docker build --platform linux/amd64 \
  --build-arg LICENSE_FILE=matlab.lic \
  --build-arg USER_NAME=$user \
  -t keymaerax .
docker create --platform linux/amd64 \
  --mac-address $macaddr -it \
  -v $PWD/Licensing:/$user/.WolframEngine/Licensing \
  -w /$user/ -p 8090:8090 --name kyx keymaerax bash
docker start kyx

# # uncomment below to run with locally compiled jar
# #sbt clean assembly
docker cp keymaerax-core*.jar kyx:/$user/keymaerax.jar

docker cp ./keymaerax.math.conf kyx:/${user}/keymaerax.conf

docker exec kyx sed -i 's|Z3_PATH = .*$|Z3_PATH = /usr/bin/z3|' \
             /${user}/keymaerax.conf

# # initialize .keymaerax directory with Z3
docker exec -it kyx bash -c 'java -da -jar keymaerax.jar setup --launch --z3path /usr/bin/z3'

# # add and modify configuration
docker cp ./keymaerax.math.conf kyx:/$user/keymaerax.conf


docker exec -it kyx bash -c 'rm .keymaerax/keymaerax.conf;cp keymaerax.conf .keymaerax/keymaerax.conf'

docker exec -it kyx bash -c 'echo "IS_DOCKER = true" >> .keymaerax/keymaerax.conf'


# # store the changes before exiting
docker commit kyx

docker stop kyx
