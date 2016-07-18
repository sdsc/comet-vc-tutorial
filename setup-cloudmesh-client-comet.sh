#!/bin/bash

# Script to install cloudmesh client using pip in a virtualenv on a Comet Login
# node in support of XSEDE'16 Comet VC Tutorial.

# Make Python 2.7 the 'active' Python
module load python

if [[ ! -x $(which python) ]]; then
    echo "You need Python 2.7.10 or higher version of Python 2.7 to run cloudmesh"
    exit 1
fi

# To have a 'supported' installation we need Python >= 2.7.10
python --version 2>&1 | egrep -q 'Python 2.7.1[0-9]'
if [[ $? -ne 0 ]]; then
    echo "You need Python 2.7.10 or higher version of Python 2.7 to run cloudmesh"
    exit 1
fi

# Default linux location for --user Python installs
if [[ ! -d $HOME/.local ]]; then
    mkdir -p $HOME/.local/bin
fi

if [[ -d $HOME/.local ]]; then
    PATH="$HOME/.local/bin:$PATH"
    export PATH
fi

# Install setuptools into --user area...
if [[ ! -x $(which easy_install) ]]; then
    curl -O https://bootstrap.pypa.io/ez_setup.py
    python ez_setup.py --user
fi

# Install pip into --user area...
if [[ ! -x $(which pip) ]]; then
    curl -O https://bootstrap.pypa.io/get-pip.py
    python get-pip.py --user
fi

# Install virtualenv into --user area...
if [[ ! -x $(which virtualenv) ]]; then
    pip install virtualenv --user
fi

# Make this installation 'very' clean...
if [[ -d $HOME/cloudmesh ]]; then
    echo "Removing old cloudmesh virtualenv..."
    rm -rf $HOME/cloudmesh
fi

if [[ -d $HOME/.cloudmesh ]]; then
    echo "Removing old cloudmesh configuration..."
    rm -rf $HOME/.cloudmesh
fi

# Create a virtualenv for cloudmesh
echo "Creating/activating virtualenv for cloudmesh..."
virtualenv ~/cloudmesh
source ~/cloudmesh/bin/activate

# Install cloudmesh in the virtual env
echo "Installing cloudmesh into virtualenv..."
pip install cloudmesh_client
cm version

exit 0
