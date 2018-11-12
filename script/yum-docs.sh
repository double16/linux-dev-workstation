#!/bin/bash -eux

# Ensure docs are installed with packages
sed -i '/tsflags=nodocs/d' /etc/yum.conf
