#!/bin/bash

# Load libraries
. /opt/laragis/lib/bootstrap.sh
. /opt/laragis/lib/log.sh

# Load Workspace environment
. /opt/laragis/scripts/workspace-env.sh

# print_welcome_page

# # Install custom python package if requirements.txt is present
# if [[ -f "/bitnami/python/requirements.txt" ]]; then
#     . /opt/bitnami/airflow/venv/bin/activate
#     pip install -r /bitnami/python/requirements.txt
#     deactivate
# fi

if [[ "$1" = "/opt/laragis/scripts/workspace/run.sh" ]]; then
  log_info "** Starting Workspace setup **"
  /opt/laragis/scripts/workspace/setup.sh
  /opt/laragis/scripts/supervisor/setup.sh
  /post-init.sh
  log_info "** Workspace setup finished! **"
fi

[ "$#" -eq 0 ] || exec "$@"