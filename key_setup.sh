#!/bin/bash

# after nodes setup and running
python cmutil.py addhosts $HOSTNAME
python cmutil.py setknownhosts $HOSTNAME