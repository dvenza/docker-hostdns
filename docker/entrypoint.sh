#!/bin/sh

#
# author: Arkadiusz Dzięgiel <arkadiusz.dziegiel@glorpen.pl>
#

if [ -f "${DNS_KEY_SECRET_FILE}" ];
then
	cat "${DNS_KEY_SECRET_FILE}"
else
	echo "${DNS_KEY_SECRET}"
fi \
| exec python -m docker_hostdns "$@"
