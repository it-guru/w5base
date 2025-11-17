#!/bin/sh
test -x /etc/profile.local && . /etc/profile.local
env >&2
exec fastapp.pl
