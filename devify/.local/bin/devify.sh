#!/bin/bash

Help()
{
    echo "Extend an existing Docker image with dev stuff."
    echo
    echo "Syntax: $( basename ${0} ) base [-h]"
    echo "id                   ID of base image."
    echo "options:"
    echo "-t, --tag            Tag of dev image."
    echo "-h, --help           Print this help."
    echo
}

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -t|--tag)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        tag="${2}"
        shift 2
      else
        echo "Error: not enough arguments for $1" >&2
        exit 1
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

imageID="${1}"
if [ "${imageID}" == "" ]; then
    echo "Missing image ID." 1>&2
    exit 3
fi

#if ! $(docker image inspect ${imageID} &> /dev/null); then 
#    echo "No such image \"${imageID}\"." 1>&2
#    exit 4
#fi

builddir=$( mktemp -d "/tmp/devenv-XXXXXX" )
pushd ${builddir} &> /dev/null

dfpath=$(readlink -f ~/.local/share/devenv-nvim.dockerfile)
docker build \
    --build-arg="user=${USER}" \
    --build-arg="http_proxy=${http_proxy}" \
    --build-arg="https_proxy=${https_proxy}" \
    --build-arg="no_proxy=${no_proxy}" \
    --build-arg="UID=$( id -u )" \
    --build-arg="GID=$( id -g )" \
    --build-arg="base=${imageID}" \
	. \
    -t ${tag:-devenv-nvim} \
    -f ${dfpath}
popd &> /dev/null

# reqs:
# bash neovim gcompat clang16-extra-tools git gdb ripgrep
#
