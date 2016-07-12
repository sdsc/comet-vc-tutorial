#!/bin/bash

# Clean everything
echo "Cleaning up previous cloudmesh setup..."
rm -rf ~/cloudmesh ~/.cloudmesh ~/.cache/pip

# Python 2.7 is required
echo "Setting up Python 2.7 virtualenv..."
module load python

# Install/upgrade virtualenv in user home
pip install --upgrade virtualenv --user &> /dev/null

# Create/source virtualenv
virtualenv ~/cloudmesh &> /dev/null
source ~/cloudmesh/bin/activate &> /dev/null

# Install cloudmesh_client in virtualenv
echo "Installing cloudmesh_client..."
pip install cloudmesh_client &> /dev/null

# Report version
cm version &> /dev/null

if [[ $? -eq 0 ]]; then

cat << EOT
To run cloudmesh...

$ module load python
$ source ~/cloudmesh/bin/activate
$ cm

EOT

else
	echo "cloudmesh_client could not be installed"
fi

exit 0
