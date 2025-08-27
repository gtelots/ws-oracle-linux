#!/bin/bash

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

/usr/local/bin/supervisord -n -c /opt/laragis/supervisor/conf.d/supervisord.conf