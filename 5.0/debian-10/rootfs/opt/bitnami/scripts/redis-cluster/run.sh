#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# We need  to enable job control
set -m

# Load Redis environment variables
. /opt/bitnami/scripts/redis-cluster-env.sh

# Load libraries
. /opt/bitnami/scripts/libos.sh
. /opt/bitnami/scripts/librediscluster.sh

IFS=' ' read -ra nodes <<< "$REDIS_NODES"

ARGS=("--port" "$REDIS_PORT_NUMBER")
ARGS+=("--include" "${REDIS_BASE_DIR}/etc/redis.conf")

if ! is_boolean_yes "$ALLOW_EMPTY_PASSWORD"; then
    ARGS+=("--requirepass" "$REDIS_PASSWORD")
    ARGS+=("--masterauth" "$REDIS_PASSWORD")
else
    ARGS+=("--protected-mode" "no")
fi

ARGS+=("$@")

if is_boolean_yes "$REDIS_CLUSTER_CREATOR"; then
    # Start Redis in background
    if am_i_root; then
        gosu "$REDIS_DAEMON_USER" redis-server "${ARGS[@]}" &
    else
        redis-server "${ARGS[@]}" &
    fi
    # Create the cluster
    redis_cluster_create "${nodes[@]}"
    # Bring redis process to foreground
    fg
else
    if am_i_root; then
        exec gosu "$REDIS_DAEMON_USER" redis-server "${ARGS[@]}"
    else
        exec redis-server "${ARGS[@]}"
    fi
fi
