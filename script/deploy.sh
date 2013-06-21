#!/usr/bin/env bash

if test $# -eq 0
then
  printf "Usage for setup remote host: %s -s [-p] \n" $(basename $0) >&2
  printf " -p option for production remote host\n"
  printf "Usage for deploy to remote host: %s [-p] [-b branch]\n" $(basename $0) >&2
  exit 2
fi

application='ivr'

# staging host
host=50.19.63.102
user=ubuntu
keyfile=~/.ec2/BBGInstance.pem
app_user=www-data
echo "deploy to $host"

# ssh -i ~/.ec2/BBGInstance.pem -t 50.19.63.102 -l ubuntu "sudo su; ls"

root=/data/$application
shared=$root/shared
name=`date '+%Y%m%d%H%M%S'`
dest=$root/shared/releases/$name
tarfile=${application}.tar
tar cvf $tarfile --exclude '*.tar' --exclude 'tmp' --exclude '*.git' *
scp -i ${keyfile} $tarfile ${user}@${host}:/tmp/.
ssh -i ${keyfile} -t ${host} -l ${user} \
   "sudo chown -R ${user}:${user} /data; \
   mkdir -p $dest; \
   mkdir -p $shared/config; \
   mkdir -p $shared/tmp;  \
   mv /tmp/$tarfile $dest; \
   cd $dest; \
   tar xvf $tarfile ; \
   rm -f $tarfile ; \
   cd $root; \
   rm -f current ; \
   ln -s $dest current; \
   mkdir -p $shared/log; \
   rm -f current/config/database.yml; \
   ln -s $shared/config/database.yml current/config/database.yml; \
   ln -s $shared/log current/log; \
   ln -s $shared/tmp current/tmp; \
   ln -s $shared/prompt current/public/prompt; \
   cd current; \
   touch tmp/restart.txt;\
   sudo chown -R ${app_user}:${app_user} /data/ivr; "


