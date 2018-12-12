#!/bin/sh

APPDIR=$(dirname $0)
# Definition of Config-Parameters 
. ${APPDIR}/etc_default_extSimpleHandler
export HANDLER_PORT EXTSIMPLEHANDLERCONFIG
# Start Application
exec ${APPDIR}/extSimpleHandler.pl
