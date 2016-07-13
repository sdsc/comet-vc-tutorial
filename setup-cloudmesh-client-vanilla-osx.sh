#!/bin/bash
# Script to install cloudmesh client using pip in a virtualenv on a vanilla
# MacOS X system with developer tools installed.
#
# Vanilla means without homebrew or other MacOS packaging env or Python
# framework (ie. Canopy, Anaconda, etc) installed.
#

if [[ ! -x $(which python) ]]; then
    echo "You need Python 2.7.10 or higher version of Python 2.7 to run cloudmesh"
    exit 1
fi

python --version 2>&1 | egrep -q 'Python 2.7.1[0-9]'
if [[ $? -ne 0 ]]; then
    echo "You need Python 2.7.10 or higher version of Python 2.7 to run cloudmesh"
    exit 1
fi

if [[ -d $HOME/Library/Python/2.7/bin/ ]]; then
    PATH="$HOME/Library/Python/2.7/bin:$PATH"
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
    python get-pip.py -–user
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
