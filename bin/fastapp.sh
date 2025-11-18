#!/bin/sh
test -x /etc/profile.local && . /etc/profile.local
exec fastapp.pl
