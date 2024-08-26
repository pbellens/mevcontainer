#!/bin/bash

Help()
{
    echo "Enter a semi-functional shell of a container."
    echo
    echo "Syntax: $( basename ${0} ) id [-h]"
    echo "id                   ID of image."
    echo "options:"
    echo "-d, --dir            Path to directory mounted in image."
    echo "-u, --user           Use uid/guid of current user."
    echo "-h, --help           Print this help."
    echo "-l, --lawless        Skip ssh-agent checks."
    echo "-p, --proxies        Use the proxies from the local environment"
    echo
}

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -d|--dir)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        dir="${2}"
        shift 2
      else
        echo "Error: not enough arguments for $1" >&2
        exit 1
      fi
      ;;
    -p|--proxies)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        echo "Error: too many arguments for $1" >&2
        exit 1
      else
        proxies=1
        shift 1
      fi
      ;;
    -l|--lawless)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        echo "Error: too many arguments for $1" >&2
        exit 1
      else
        lawless=1
        shift 1
      fi
      ;;
    -u|--user)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        echo "Error: too many arguments for $1" >&2
        exit 1
      else
        user=1
        shift 1
      fi
      ;;
    -h|--help)
        Help
        exit 0
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      Help
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# set positional arguments in their proper place
eval set -- "$PARAMS"

if [ $# -ne 1 ]; then
    Help
    exit 2
fi

imageID=${1}
if [ -z ${imageID+x} ]; then
    echo "Missing image ID." 1>&2
    exit 3
fi

if [ ! -z ${dir+x} ]; then 
    devdir=$( readlink -f ${dir} )
    if [ ! -d ${devdir} ]; then 
        echo "\"${devdir}\" is not a valid directory." 1>&2
        exit 5
    fi
fi

# We can t proactively start ssh-agent. If it is already running, 
# we will just create a new instance withouth any registered keys.
# https://stackoverflow.com/questions/40549332/how-to-check-if-ssh-agent-is-already-running-in-bash
if [ -z ${lawless+x} ]; then 
    ssh-add -l &>/dev/null
    addret=$?
    if [ "${addret}" == 2 ]; then
        echo "Please start an SSH agent (e.g. eval \`ssh-agent\`) and add the keys required inside the container." 1>&2
        exit 6
    fi
    if [ "${addret}" == 1 ]; then
        echo "Your SSH agent has no identities and will be useless inside the container." 1>&2
        exit 7
    fi
fi

if docker --version | grep -i podman; then 

    podman run -it --rm \
        --mount type=bind,source=$SSH_AUTH_SOCK,target=/ssh-agent \
        --env SSH_AUTH_SOCK=/ssh-agent \
        --env "TERM=xterm-256color" \
        --security-opt label=disable \
        --userns=keep-id \
        ${devdir:+-v ${devdir}:"/$(basename ${devdir}):Z"} \
        ${proxies:+-e http_proxy=${http_proxy} -e https_proxy=${https_proxy} -e no_proxy=${no_proxy}} \
        --entrypoint /bin/bash \
        ${imageID}

else

    docker run -it --rm \
        --mount type=bind,source=$SSH_AUTH_SOCK,target=/ssh-agent \
        --env SSH_AUTH_SOCK=/ssh-agent \
        --env "TERM=xterm-256color" \
        ${user:+--user $(id -u):$(id -g)} \
        ${devdir:+--mount type=bind,source=${devdir},target="/$(basename ${devdir})"} \
        --mount type=bind,source=/tmp,target="/opt/s7" \
        --shm-size=4gb \
        ${proxies:+-e http_proxy=${http_proxy} -e https_proxy=${https_proxy} -e no_proxy=${no_proxy}} \
        --entrypoint /bin/bash \
        ${imageID}

fi
