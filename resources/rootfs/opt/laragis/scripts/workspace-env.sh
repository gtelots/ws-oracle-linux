#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0
#
# Environment configuration for apache

# The values for all environment variables will be set in the below order of precedence
# 1. Custom environment variables defined below after LaraGIS defaults
# 2. Constants defined in this file (environment variables with no default), i.e. LARAGIS_ROOT_DIR
# 3. Environment variables overridden via external files using *_FILE variables (see below)
# 4. Environment variables set externally (i.e. current Bash context/Dockerfile/userdata)

# Load logging library
# shellcheck disable=SC1090,SC1091
. /opt/laragis/lib/log.sh

export LARAGIS_ROOT_DIR="/opt/laragis"
export LARAGIS_VOLUME_DIR="/laragis"

# Logging configuration
export MODULE="${MODULE:-ws}"
export LARAGIS_DEBUG="${LARAGIS_DEBUG:-false}"

# # By setting an environment variable matching *_FILE to a file path, the prefixed environment
# # variable will be overridden with the value specified in that file
# apache_env_vars=(
#     APACHE_HTTP_PORT_NUMBER
#     APACHE_HTTPS_PORT_NUMBER
#     APACHE_SERVER_TOKENS
#     APACHE_HTTP_PORT
#     APACHE_HTTPS_PORT
# )
# for env_var in "${apache_env_vars[@]}"; do
#     file_env_var="${env_var}_FILE"
#     if [[ -n "${!file_env_var:-}" ]]; then
#         if [[ -r "${!file_env_var:-}" ]]; then
#             export "${env_var}=$(< "${!file_env_var}")"
#             unset "${file_env_var}"
#         else
#             warn "Skipping export of '${env_var}'. '${!file_env_var:-}' is not readable."
#         fi
#     fi
# done
# unset apache_env_vars