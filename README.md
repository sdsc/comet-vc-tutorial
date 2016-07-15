# comet-vc-tutorial

Configuration and sample applications for an virtual Ubuntu cluster on [Comet](http://www.sdsc.edu/support/user_guides/comet.html).

## Link to Comet docs

* [Tutorial](http://cloudmesh.github.io/client/tutorials/comet_cloudmesh.html)
* [Cloudmesh documentation](http://cloudmesh.github.io/client/commands/command_comet.html)

## Basic Steps

* Install Cloudmesh client and configure it to access a Comet virtual
cluster.
* Install an Ubuntu front end following the tutorial.
* Generate networking information using [cmutil.py](cmutil.py) and
send to front end.

 ```
 wget http://bit.ly/vc-cmutil
 python cmutil.py nodesfile
 scp vcn*.txt <USER>@vct<##>.sdsc.edu:~/
 ```
* Get the [deploy.sh](deploy.sh) script and configure the front end.

 ```bash
 wget -O deploy.sh http://bit.ly/vc-deployment
 chmod +x deploy.sh
 sudo ./deploy.sh
 ```
* Power on the compute nodes to install.

