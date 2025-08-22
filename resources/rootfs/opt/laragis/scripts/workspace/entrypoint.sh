#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
#set -o xtrace

# Load libraries
. /opt/laragis/scripts/liblog.sh

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
  info "** Starting Workspace setup **"
  /opt/laragis/scripts/workspace/setup.sh
  /opt/laragis/scripts/supervisor/setup.sh
  /post-init.sh
  info "** Workspace setup finished! **"
fi

[ "$#" -eq 0 ] || exec "$@"