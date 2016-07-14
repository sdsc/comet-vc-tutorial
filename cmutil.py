#!/usr/bin/env python
import os
import sys
import subprocess
import json
from pprint import pprint

import StringIO
import csv

import ast
from getpass import getpass

def generate_nodesfile(vcname, subnet=None):

    nodescmd = "cm comet cluster {} --format=rest".format(vcname)
    proc = subprocess.Popen(nodescmd.split(" "), stdout=subprocess.PIPE)
    (out, err) = proc.communicate()

    nodesobj = ast.literal_eval(out)
    frontend = nodesobj[0]['frontend']
    fields = ["ip", "mask", "gateway", "dns", "ntp"]
    with open('vcnet_{}.txt'.format(vcname), 'w') as f:
        print >> f, "IP:", frontend["pub_ip"]
        print >> f, "MASK:", frontend["pub_netmask"]
        print >> f, "GATEWAY:", frontend["gateway"]
        print >> f, "DNS:", "{} {}".format(frontend["dns1"], frontend["dns2"])
        print >> f, "NTP:", frontend["ntp"]
    nodes = nodesobj[0]['computes']
    if not subnet:
        subnet = "192.168.1."
    ip_idx = 0
    with open('vcnodes_{}.txt'.format(vcname), 'w') as f:
        for node in nodes:
            ip_idx += 1
            print >> f, "{},{},{}".format(node["name"],
                                            node["interface"][0]["mac"],
                                            "{}{}".format(subnet, ip_idx)
                                            )

def generate_pxefile(nodesfile=None, netfile=None, vc=None):
    if vc:
        if not nodesfile:
            nodesfile = "vcnodes_{}.txt".format(vc)
        if not netfile:
            netfile = "vcnet_{}.txt".format(vc)
    else:
        if not (nodesfile and netfile):
            print ("parameters not specified")
            return
    pxetemp = "/var/lib/tftpboot/pxelinux.cfg/default.temp"
    netconfs = {}
    with open(netfile) as file:
        lines = file.readlines()
        for line in lines:
            row = line.split(": ")
            netconfs[row[0]] = row[1].strip("\n")
    with open(nodesfile) as nodes:
        lines = nodes.readlines()
        for aline in lines:
            row = aline.split(",")
            #print (row)
            name = row[0]
            mac = row[1]
            ip = row[2].strip("\n")
            filename="01-{}".format(mac.replace(":","-"))
            #print (filename)
            replacements = {'$NETIP':ip,
                            '$NODENAME':name,
                            '$NETMASK':netconfs["MASK"],
                            #'$NETGATEWAY':netconfs["GATEWAY"],
                            '$NETGATEWAY':"192.168.1.254",
                            "$DNS":netconfs["DNS"]}
            #print (replacements)
            with open('/var/lib/tftpboot/pxelinux.cfg/{}'.format(filename), 'w') as outfile:
                with open(pxetemp) as infile:
                    for line in infile:
                        for src, target in replacements.iteritems():
                            line = line.replace(src, target)
                            #print (line)
                        outfile.write(line)
                #print ("finished writing one file...")

def setboot(node, nodesfile=None, vc=None, net=True):
    if vc:
        if not nodesfile:
            nodesfile = "vcnodes_{}.txt".format(vc)
    else:
        if not nodesfile:
            print ("parameters not specified")
            return
    filename = None
    with open(nodesfile) as nodes:
        lines = nodes.readlines()
        for aline in lines:
            row = aline.split(",")
            name = row[0]
            mac = row[1]
            if name == node:
                filename="01-{}".format(mac.replace(":","-"))
                break
    if filename:
        lines = []
        with open('/var/lib/tftpboot/pxelinux.cfg/{}'.format(filename)) as infile:
            lines = infile.readlines()
        with open('/var/lib/tftpboot/pxelinux.cfg/{}'.format(filename), 'w') as outfile:
            netbootline = "default netinstall"
            localbootline = "default local"
            for line in lines:
                if net:
                    line = line.replace(localbootline, netbootline)
                else:
                    line = line.replace(netbootline, localbootline)
                outfile.write(line)

def addhosts(nodesfile=None, vc=None):
    if vc:
        if not nodesfile:
            nodesfile = "vcnodes_{}.txt".format(vc)
    else:
        if not nodesfile:
            print ("parameters not specified")
            return
    with open(nodesfile) as nodes, open("/etc/hosts", "a") as hostfile:
        lines = nodes.readlines()
        print >> hostfile
        for aline in lines:
            row = aline.split(",")
            name = row[0]
            mac = row[1]
            ip = row[2].strip("\n")
            print >> hostfile, "{}\t{}".format(ip, name)

def setpassword():
    print ("Type the root password for the computenodes:")
    password = getpass()
    ksfile = "/var/www/html/ks.cfg"
    with open(ksfile) as infile:
        lines = infile.readlines()
    with open(ksfile, 'w') as outfile:
        for line in lines:
            line = line.replace("$ROOT_PASSWORD", password)
            outfile.write(line)

# before installing the compute nodes
def setkey():
    os.system("ssh-keygen")
    keyfile = os.path.expanduser("~/.ssh/id_rsa.pub")
    key = ''
    with open(keyfile) as f:
        key = f.readline().strip("\n")
    scriptfile = "/var/www/html/postscript.sh"
    with open(scriptfile) as infile:
        lines = infile.readlines()
    with open(scriptfile, 'w') as outfile:
        for line in lines:
            line = line.replace("$PUBLICKEY", key)
            outfile.write(line)

# call after compute nodes up and running
def setknownhosts(nodesfile=None, vc=None):
    if vc:
        if not nodesfile:
            nodesfile = "vcnodes_{}.txt".format(vc)
    else:
        if not nodesfile:
            print ("parameters not specified")
            return
    ips = []
    iphosts = '\n'
    with open(nodesfile) as nodes:
        lines = nodes.readlines()
        for aline in lines:
            row = aline.split(",")
            name = row[0]
            mac = row[1]
            ip = row[2].strip("\n")
            ips.append(ip)
            iphosts += "{}\t{}\n".format(ip, name)
            os.system("ssh-keyscan -H {} >> {}".format(ip, os.path.expanduser("~/.ssh/known_hosts")))
            os.system("ssh-keyscan -H {} >> {}".format(name, os.path.expanduser("~/.ssh/known_hosts")))
    for ip in ips:
        os.system("scp {} root@{}:/root/.ssh/".format(os.path.expanduser("~/.ssh/known_hosts"), ip))
        os.system("scp {} root@{}:/root/.ssh/".format(os.path.expanduser("~/.ssh/id_rsa"), ip))
        os.system("echo '{}' | ssh root@{} 'cat >> /etc/hosts'".format(iphosts, ip))

def usage():
    usagestr = "Usage:\n"\
               "./cmutil.py nodesfile\n"\
               "./cmutil.py pxefile vc2\n"\
               "./cmutil.py setkey\n"\
               "./cmutil.py setpassword\n"\
               "./cmutil.py setboot vc2 node1 net=false\n"\
               "./cmutil.py setboot vc2 node1 net=true\n"\
               "./cmutil.py addhosts vc2\n"\
               "./cmutil.py setknownhosts vc2\n"
    print (usagestr)

if __name__ == "__main__":
    argv = sys.argv[1:]
    commands = ['nodesfile', 'pxefile', 'setkey', 'setpassword', 'setboot', 'addhosts', 'setknownhosts']
    if len(argv) >= 1:
        cmd = argv[0]
        if len(argv) > 1:
            cluster = argv[1]
        if cmd in commands:
            if cmd == 'nodesfile':
                generate_nodesfile(cluster)
            elif cmd == 'pxefile':
                generate_pxefile(vc=cluster)
            elif cmd == 'setkey':
                setkey()
            elif cmd == 'setpassword':
                setpassword()
            elif cmd == 'setboot':
                node = argv[2]
                bootparam = argv[3]
                params = bootparam.split("=")
                if params[0].lower() == 'net':
                    if params[1].lower() == 'true':
                        netboot = True
                    elif params[1].lower() == 'false':
                        netboot = False
                    else:
                        netboot = False
                    setboot(node, vc=cluster, net=netboot)
            elif cmd == 'addhosts':
                addhosts(vc='vc2')
            elif cmd == 'setknownhosts':
                setknownhosts(vc="vc2")
            else:
                usage()
        else:
            usage()
    else:
        usage()