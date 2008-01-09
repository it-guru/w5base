#!/usr/bin/env bash
mysqldump -d w5base2 | egrep -v -e '^--' -e '^\s*$' | sed -e 's/`//g' -e 's/ TYPE=MyISAM//g'> master.sql
