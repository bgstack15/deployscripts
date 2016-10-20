#!/bin/sh
# File: /mnt/scripts/template/pack_ds.sh
# Package: deployscripts
# Author: bgstack15
# Startdate: 2016
# Title: Script that Packages deployscripts
# Purpose: Provides an easy way to pack the deployscripts together
# History: Started probably in early 2016
#    2016-10-20 given headers
# Usage: Run ./pack_ds.sh and it will make the new tgz
# Reference:
# Improve:
( cd /mnt/scripts/template && rm -rf deployscripts.tgz && tar -zcf deployscripts.tgz .makecert.exp updateval.sh s*sh; )
