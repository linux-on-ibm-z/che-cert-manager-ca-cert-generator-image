#!/bin/sh
# Copyright (c) 2020 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

# This script assumes its being run on CentOS Linux 7/x86_64

REGISTRY="quay.io"
ORGANIZATION="eclipse"

load_jenkins_vars() {
    set +x
    eval "$(./env-toolkit load -f jenkins-env.json \
                                    QUAY_ECLIPSE_CHE_USERNAME \
                                    QUAY_ECLIPSE_CHE_PASSWORD)"
}

install_deps() {
    set +x
    yum -y update
    yum -y install centos-release-scl-rh git
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce
    service docker start
}

login_on_quay() {
    if [[ -n "${QUAY_ECLIPSE_CHE_USERNAME}" ]] && [[ -n "${QUAY_ECLIPSE_CHE_PASSWORD}" ]]; then
        docker login -u "${QUAY_ECLIPSE_CHE_USERNAME}" -p "${QUAY_ECLIPSE_CHE_PASSWORD}" "${REGISTRY}"
    else
        echo "Could not login, missing credentials for pushing to the '${ORGANIZATION}' organization"
        exit 1
    fi
}

build_and_push_on_quay() {
    TAG=$(git rev-parse --short HEAD)
    docker build -t quay.io/eclipse/che-cert-manager-ca-cert-generator:${TAG} .
    docker push quay.io/eclipse/che-cert-manager-ca-cert-generator:${TAG}
}

load_jenkins_vars
install_deps

login_on_quay
build_and_push_on_quay
