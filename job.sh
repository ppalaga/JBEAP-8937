#!/bin/bash
set -e

usage() {
  echo "$(basename ${0}) <path-to-eap-src-archive> <path-to-eap-testsuite-archive> <eap-version> [workspace locatuon]"
  echo ''
  echo 'Workspace location defaults to current dir, if not specified.'
  echo ''
  exit ${1}
}

if [ -n "${HUDSON_STATIC_ENV}" ]; then
  readonly JBOSS_EAP_ARCHIVE_LOCATION="${HUDSON_STATIC_ENV}/eap/${EAP_VERSION}/jboss-eap-${EAP_VERSION}-src.zip"
  readonly JBOSS_EAP_TESTSUITE_ARCHIVE="${HUDSON_STATIC_ENV}/eap/${EAP_VERSION}/jboss-eap-${EAP_VERSION}-testsuite-local-repository.zip"
  if [ -z "${WORKSPACE}" ]; then
      readonly WORKSPACE=$(pwd)
      echo "WORKSPACE variable is not defined - defining to current dir: ${WORKSPACE}"
  fi
else
  # if not running inside a job, some parameters are required
  readonly JBOSS_EAP_ARCHIVE_LOCATION=${1}
  readonly JBOSS_EAP_TESTSUITE_ARCHIVE=${2}
  readonly EAP_VERSION=${3}
  readonly WORKSPACE=${4:-"$(pwd)"}

  if [ ! -e "${JBOSS_EAP_ARCHIVE_LOCATION}" ]; then
    echo "JBoss EAP Archive does not exist: ${JBOSS_EAP_ARCHIVE_LOCATION}"
    usage 1
  fi

  if [ -z "${EAP_VERSION}" ]; then
    echo "No JBoss EAP version specified."
    usage 2
  fi

  if [ ! -e "${JBOSS_EAP_TESTSUITE_ARCHIVE}" ]; then
    echo "JBoss EAP Testsuite Archive does not exist: ${JBOSS_EAP_TESTSUITE_ARCHIVE}"
    usage 1
  fi
fi

unzip -q "${JBOSS_EAP_ARCHIVE_LOCATION}"
cd "jboss-eap-${EAP_VERSION:0:3}-src"
unzip -q ${JBOSS_EAP_TESTSUITE_ARCHIVE}
export MAVEN_REPO_LOCAL="${WORKSPACE}/eap-local-maven-repository"

# JBEAP-8937 - try to fix issue with substitution on Solaris
readonly FILE_TO_PATCH='./mvnw'
cp "../${FILE_TO_PATCH}" "${FILE_TO_PATCH}"
chmod +x "${FILE_TO_PATCH}"

export MAVEN_PROJECTBASEDIR=$(pwd)
# End of fix

# build EAP and testsuite using OOB build scripts
bash -x  ./build.sh -B -llr -Dmaven.repo.local=${MAVEN_REPO_LOCAL} -fae -DskipTests
bash -x  ./integration-tests.sh -B -llr -Dmaven.repo.local=${MAVEN_REPO_LOCAL} -fae -DskipTests
