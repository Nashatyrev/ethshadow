#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e

if ! test $(uname -s) = "Linux"; then
    echo "Only Linux is supported"
fi

check_cmd() {
    if ! command -v $1 >/dev/null; then
        echo -e "\nCommand '$1' not found, please install it first.\n\n$2\n"
        exit 1
    fi
}

if test -e $ROOT; then
    echo "The file $ROOT already exists, please delete or move it first."
    exit 1
fi

check_cmd shadow "See https://shadow.github.io/docs/guide/install_shadow.html for installation, but use the \"ethereum\" branch from https://github.com/ppopth/shadow instead."
check_cmd geth "See https://geth.ethereum.org/docs/getting-started/installing-geth for more detail."
check_cmd yq "See https://github.com/mikefarah/yq for more detail."

mkdir -p $ROOT

# Generate a dummy password for accounts
echo "itsjustnothing" > $ROOT/password

cp $SHADOW_CONFIG_TEMPLATE_FILE $SHADOW_CONFIG_FILE

for (( node=1; node<=$NODE_COUNT; node++ )); do
    node_ip $node
    yq -i ".hosts.node$node = { \
        \"network_node_id\": 0, \
        \"ip_addr\": \"$ip\", \
        \"processes\": [] \
    }" $SHADOW_CONFIG_FILE
done

if ! ./scripts/prepare-el.sh; then
    echo -e "\n*Failed!* in the execution layer preparation step\n"
    exit 1
fi

shadow -d $SHADOW_DIR $SHADOW_CONFIG_FILE --progress true > $ROOT/shadow.log
