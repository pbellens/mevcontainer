#!/bin/bash

Help()
{
    echo "Install mevcontainer."
    echo
    echo "Syntax: $( basename ${0} ) [-h]"
    echo "options:"
    echo "-h, --help           Print this help."
    echo
}

PARAMS=""
while (( "$#" )); do
  case "$1" in
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

chmod u+x devify/.local/bin/devify.sh
chmod u+x devify/.local/bin/dev.sh

if stow --version &> /dev/null; then 
    stow -R -t ${HOME} container --verbose=2 
    stow -R -t ${HOME} devify --verbose=2 
    stow -R -t ${HOME} dev --verbose=2 
else
    # symlink manually
    echo "stow not found." 1>&2
    exit 2
fi
