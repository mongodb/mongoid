#!/usr/bin/env bash
# shellcheck shell=sh

#For future use the feed to get full list of distros : http://downloads.mongodb.org/full.json

set -o errexit  # Exit the script with error if any of the commands fail

get_distro ()
{
   if [ -f /etc/os-release ]; then
      . /etc/os-release
      DISTRO="${ID}-${VERSION_ID}"
   elif [ -f /etc/centos-release ]; then
      version=$(cat /etc/centos-release | tr -dc '0-9.' | cut -d '.' -f1)
      DISTRO="centos-${version}"
   elif command -v lsb_release >/dev/null 2>&1; then
      name=$(lsb_release -s -i)
      if [ "$name" = "RedHatEnterpriseServer" ]; then # RHEL 6.2 at least
         name="rhel"
      fi
      version=$(lsb_release -s -r)
      DISTRO="${name}-${version}"
   elif [ -f /etc/redhat-release ]; then
      release=$(cat /etc/redhat-release)
      case $release in
         *Red\ Hat*)
            name="rhel"
         ;;
         Fedora*)
            name="fedora"
         ;;
      esac
      version=$(echo $release | sed 's/.*\([[:digit:]]\).*/\1/g')
      DISTRO="${name}-${version}"
   elif [ -f /etc/lsb-release ]; then
      . /etc/lsb-release
      DISTRO="${DISTRIB_ID}-${DISTRIB_RELEASE}"
   elif grep -R "Amazon Linux" "/etc/system-release" >/dev/null 2>&1; then
      DISTRO="amzn64"
   fi

   OS_NAME=$(uname -s)
   MARCH=$(uname -m)
   DISTRO=$(echo "$OS_NAME-$DISTRO-$MARCH" | tr '[:upper:]' '[:lower:]')

   echo $DISTRO
}

# get_mongodb_download_url_for "linux-distro-version-architecture" "latest|44|42|40|36|34|32|30|28|26|24" "true|false"
# Sets EXTRACT to appropriate extract command
# Sets MONGODB_DOWNLOAD_URL to the appropriate download url
# Sets MONGO_CRYPT_SHARED_DOWNLOAD_URL to the corresponding URL to a crypt_shared library archive
get_mongodb_download_url_for ()
{
   _DISTRO=$1
   _VERSION=$2
   _DEBUG=$3

   VERSION_MONGOSH="2.1.1"
   # Set VERSION_RAPID to the latest rapid release each quarter.
   VERSION_RAPID="7.3.4"
   VERSION_80="8.0.1"
   VERSION_70="7.0.15-rc1"
   VERSION_60="6.0.18"
   VERSION_50="5.0.29"

   # This version is used for performance benchmarking. Do not update to a newer version
   VERSION_60_PERF="6.0.6"

   # EOL versions
   VERSION_44="4.4.29"
   VERSION_42="4.2.25"
   VERSION_40="4.0.28"
   VERSION_36="3.6.23"
   VERSION_34="3.4.24"
   VERSION_32="3.2.22"
   VERSION_30="3.0.15"
   VERSION_26="2.6.12"
   VERSION_24="2.4.14"

   EXTRACT="tar zxf"
   EXTRACT_MONGOSH=$EXTRACT

   case "$_DEBUG" in
      true)
         DEBUG="-debugsymbols"
      ;;
      *)
         DEBUG=""
      ;;
   esac

   # getdata matrix on:
   # https://evergreen.mongodb.com/version/5797f0493ff12235e5001f05
   case "$_DISTRO" in
      darwin--arm64)
         EXTRACT_MONGOSH="unzip -q"
         MONGODB_LATEST="http://downloads.10gen.com/osx/mongodb-macos-arm64-enterprise${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-darwin-arm64.zip"
             MONGODB_RAPID="http://downloads.10gen.com/osx/mongodb-macos-arm64-enterprise${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/osx/mongodb-macos-arm64-enterprise${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/osx/mongodb-macos-arm64-enterprise${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/osx/mongodb-macos-arm64-enterprise${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise${DEBUG}-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise${DEBUG}-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise${DEBUG}-${VERSION_32}.tgz"
             MONGODB_30="https://fastdl.mongodb.org/osx/mongodb-osx-x86_64${DEBUG}-${VERSION_30}.tgz"
             MONGODB_26="https://fastdl.mongodb.org/osx/mongodb-osx-x86_64${DEBUG}-${VERSION_26}.tgz"
             MONGODB_24="https://fastdl.mongodb.org/osx/mongodb-osx-x86_64${DEBUG}-${VERSION_24}.tgz"
      ;;
      darwin--x86_64)
         EXTRACT_MONGOSH="unzip -q"
         MONGODB_LATEST="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-darwin-x64.zip"
             MONGODB_RAPID="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise${DEBUG}-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise${DEBUG}-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise${DEBUG}-${VERSION_32}.tgz"
             MONGODB_30="https://fastdl.mongodb.org/osx/mongodb-osx-x86_64${DEBUG}-${VERSION_30}.tgz"
             MONGODB_26="https://fastdl.mongodb.org/osx/mongodb-osx-x86_64${DEBUG}-${VERSION_26}.tgz"
             MONGODB_24="https://fastdl.mongodb.org/osx/mongodb-osx-x86_64${DEBUG}-${VERSION_24}.tgz"
      ;;
      sunos*i86pc)
         MONGODB_LATEST="https://fastdl.mongodb.org/sunos5/mongodb-sunos5-x86_64${DEBUG}-latest.tgz"
             MONGODB_34="https://fastdl.mongodb.org/sunos5/mongodb-sunos5-x86_64${DEBUG}-3.4.5.tgz"
             MONGODB_32="https://fastdl.mongodb.org/sunos5/mongodb-sunos5-x86_64${DEBUG}-3.2.14.tgz"
             MONGODB_30="https://fastdl.mongodb.org/sunos5/mongodb-sunos5-x86_64${DEBUG}-${VERSION_30}.tgz"
             MONGODB_26="https://fastdl.mongodb.org/sunos5/mongodb-sunos5-x86_64${DEBUG}-${VERSION_26}.tgz"
             MONGODB_24="https://fastdl.mongodb.org/sunos5/mongodb-sunos5-x86_64${DEBUG}-${VERSION_24}.tgz"
      ;;
      linux-rhel-9*-aarch64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel93${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-arm64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel90${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel93${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel90${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel90${DEBUG}-${VERSION_60}.tgz"
      ;;
      linux-rhel-9*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel93${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel90${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel93${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel90${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60_PERF="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel90${DEBUG}-${VERSION_60_PERF}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel90${DEBUG}-${VERSION_60}.tgz"
      ;;
      linux-rhel-8*-ppc64le)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-ppc64le.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81${DEBUG}-${VERSION_42}.tgz"
      ;;
      linux-rhel-8*-s390x)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel83${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-s390x.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel83${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel83${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel83${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel83${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel83${DEBUG}-${VERSION_50}.tgz"
             # SERVER-44074 Added support for RHEL 8 (zSeries) in 5.0.8 and 6.0.0-rc0.
      ;;
      linux-rhel-8*-aarch64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel8${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-arm64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel8${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel8${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel8${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel8${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel8${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel82${DEBUG}-${VERSION_44}.tgz"
             # SERVER-48282 Added support for RHEL 8 ARM in 4.4.2.
      ;;
      linux-rhel-8*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel8${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel8${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel8${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel8${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel8${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel8${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel80${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel80${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel80${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel80${DEBUG}-${VERSION_36}.tgz"
      ;;
      linux-rhel-7*-s390x)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-s390x.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72${DEBUG}-${MONGODB_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72${DEBUG}-3.6.4.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72${DEBUG}-3.4.14.tgz"
      ;;
      linux-rhel-7*-ppc64le)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-ppc64le.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71${DEBUG}-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71${DEBUG}-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71${DEBUG}-${VERSION_32}.tgz"
      ;;
      linux-rhel-7.*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70${DEBUG}-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70${DEBUG}-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70${DEBUG}-${VERSION_32}.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70${DEBUG}-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70${DEBUG}-${VERSION_26}.tgz"
      ;;
      linux-rhel-6*-s390x)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel67${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-s390x.tgz"
             # SERVER-53726 removed support for s390x (zSeries) on RHEL6.
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel67${DEBUG}-4.4.6.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel67${DEBUG}-4.2.18.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel67${DEBUG}-4.0.28.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel67${DEBUG}-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel67${DEBUG}-${VERSION_34}.tgz"
      ;;
      linux-rhel-6.2*|linux-centos-6*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62${DEBUG}-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62${DEBUG}-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62${DEBUG}-${VERSION_32}.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62${DEBUG}-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62${DEBUG}-${VERSION_26}.tgz"
             MONGODB_24="http://downloads.10gen.com/linux/mongodb-linux-x86_64-subscription-rhel62${DEBUG}-${VERSION_24}.tgz"
      ;;
      linux-rhel-5.5*)
         MONGODB_LATEST="http://downloads.mongodb.org/linux/mongodb-linux-x86_64-rhel55${DEBUG}-latest.tgz"
             MONGODB_32="http://downloads.mongodb.org/linux/mongodb-linux-x86_64-rhel55${DEBUG}-${VERSION_32}.tgz"
             MONGODB_30="http://downloads.mongodb.org/linux/mongodb-linux-x86_64-rhel55${DEBUG}-${VERSION_30}.tgz"
      ;;
      linux-sles-15.1-x86_64)
          MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse15${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse15${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse15${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse15${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse15${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse15${DEBUG}-${VERSION_50}.tgz"
      ;;
      linux-sles-12*-s390x)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-suse12${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-s390x.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-suse12${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-suse12${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-suse12${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-suse12${DEBUG}-3.6.3.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-suse12${DEBUG}-3.4.13.tgz"
      ;;
      linux-sles-12*-x86_64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12${DEBUG}-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12${DEBUG}-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12${DEBUG}-${VERSION_32}.tgz"
      ;;
      linux-sles-11*-x86_64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse11${DEBUG}-latest.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse11${DEBUG}-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse11${DEBUG}-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse11${DEBUG}-${VERSION_32}.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse11${DEBUG}-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse11${DEBUG}-${VERSION_26}.tgz"
             MONGODB_24="http://downloads.10gen.com/linux/mongodb-linux-x86_64-subscription-suse11${DEBUG}-${VERSION_24}.tgz"
      ;;
      linux-amzn-2023-x86_64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2023${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2023${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2023${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2023${DEBUG}-${VERSION_70}.tgz"
      ;;
      linux-amzn-2023-aarch64)
          MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2023${DEBUG}-latest.tgz"
          MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-arm64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2023${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2023${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2023${DEBUG}-${VERSION_70}.tgz"
      ;;
      linux-amzn-2018*-x86_64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64${DEBUG}-${VERSION_RAPID}.tgz"
             # SERVER-50564 Removed support for Amazon Linux (v1) in 6.0.0-rc1.
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64${DEBUG}-6.0.0-rc0.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64${DEBUG}-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64${DEBUG}-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64${DEBUG}-${VERSION_32}.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64${DEBUG}-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64${DEBUG}-${VERSION_26}.tgz"
             MONGODB_24="http://downloads.10gen.com/linux/mongodb-linux-x86_64-subscription-amzn64${DEBUG}-${VERSION_24}.tgz"
      ;;
      linux-amzn-2-x86_64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2${DEBUG}-${VERSION_40}.tgz"
      ;;
      linux-amzn-2-aarch64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2${DEBUG}-latest.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2${DEBUG}-${VERSION_42}.tgz"
      ;;
      linux-debian-12*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian12${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian12${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian12${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian12${DEBUG}-${VERSION_70}.tgz"
      ;;
      linux-debian-11*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian11${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian11${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian11${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian11${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian11${DEBUG}-${VERSION_50}.tgz"
             # SERVER-62299 Added support for Debian 11 in 5.0.8 and 6.0.0-rc0
      ;;
      linux-debian-10*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian10${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian10${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian10${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian10${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian10${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian10${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian10${DEBUG}-${VERSION_42}.tgz"
      ;;
      linux-debian-9*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian92${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             # SERVER-62308 Removed support for Debian 9 in server version 6.0.0-rc5.
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian92${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian92${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian92${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian92${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian92${DEBUG}-${VERSION_36}.tgz"
      ;;
      linux-debian-8*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian81${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             # SERVER-37767 Removed support for Debian 8
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian81${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian81${DEBUG}-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian81${DEBUG}-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian81${DEBUG}-${VERSION_32}.tgz"
      ;;
      linux-debian-7*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian71${DEBUG}-latest.tgz"
             # SERVER-32999 removed support for Debian 7.
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian71${DEBUG}-3.6.5.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian71${DEBUG}-3.4.15.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian71${DEBUG}-3.2.20.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian71${DEBUG}-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian71${DEBUG}-${VERSION_26}.tgz"
      ;;
      linux-ubuntu-24.04-aarch64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2404${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-arm64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2404${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2404${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2404${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2404${DEBUG}-${VERSION_60}.tgz"
      ;;
      linux-ubuntu-24.04*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2404${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2404${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2404${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2404${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2404${DEBUG}-${VERSION_60}.tgz"
      ;;
      linux-ubuntu-22.04-aarch64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2204${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-arm64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2204${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2204${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2204${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2204${DEBUG}-${VERSION_60}.tgz"
             # SERVER-62301 Added support for Ubuntu 22.04 in 6.0.3
      ;;
      linux-ubuntu-22.04*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2204${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2204${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2204${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2204${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2204${DEBUG}-${VERSION_60}.tgz"
             # SERVER-62300 Added support for Ubuntu 22.04 in 6.0.4
      ;;
      linux-ubuntu-20.04-aarch64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2004${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-arm64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2004${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2004${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2004${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2004${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2004${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2004${DEBUG}-${VERSION_44}.tgz"
      ;;
      linux-ubuntu-20.04*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2004${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2004${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_80="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2004${DEBUG}-${VERSION_80}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2004${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2004${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2004${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2004${DEBUG}-${VERSION_44}.tgz"
      ;;
      linux-ubuntu-18.04-s390x)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1804${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-s390x.tgz"
             # SERVER-32999 removed support for s390x (zSeries) on Ubuntu 18.04.
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1804${DEBUG}-4.4.6.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1804${DEBUG}-4.2.14.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1804${DEBUG}-4.0.25.tgz"
      ;;
      linux-ubuntu-18.04-aarch64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-arm64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804${DEBUG}-${VERSION_42}.tgz"
      ;;
      linux-ubuntu-18.04-ppc64le)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1804${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-ppc64le.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1804${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1804${DEBUG}-${VERSION_42}.tgz"
      ;;
      linux-ubuntu-18.04*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804${DEBUG}-${VERSION_RAPID}.tgz"
             MONGODB_70="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804${DEBUG}-${VERSION_70}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804${DEBUG}-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804${DEBUG}-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804${DEBUG}-${VERSION_36}.tgz"
      ;;
      linux-ubuntu-16.04-s390x)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1604${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-s390x.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1604${DEBUG}-v4.0-latest.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1604${DEBUG}-3.6.4.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1604${DEBUG}-3.4.14.tgz"
      ;;
      linux-ubuntu-16.04-ppc64le)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1604${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-ppc64le.tgz"
             # SERVER-37774 Removed support for Ubuntu 16.04 PPCLE
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1604${DEBUG}-4.0.9.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1604${DEBUG}-3.6.12.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1604${DEBUG}-3.4.20.tgz"
      ;;
      linux-ubuntu-16.04-aarch64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1604${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-arm64.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1604${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1604${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-arm64-enterprise-ubuntu1604${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-arm64-enterprise-ubuntu1604${DEBUG}-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-arm64-enterprise-ubuntu1604${DEBUG}-${VERSION_34}.tgz"
      ;;
      linux-ubuntu-16.04*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604${DEBUG}-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604${DEBUG}-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604${DEBUG}-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604${DEBUG}-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604${DEBUG}-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604${DEBUG}-${VERSION_32}.tgz"
      ;;
      linux-ubuntu-14.04*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             # SERVER-37765 Removed support for Ubuntu 14.04
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404${DEBUG}-4.0.9.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404${DEBUG}-3.6.12.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404${DEBUG}-3.4.20.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404${DEBUG}-${VERSION_32}.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404${DEBUG}-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404${DEBUG}-${VERSION_26}.tgz"
      ;;
      linux-ubuntu-12.04*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1204${DEBUG}-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             # SERVER-31535 removed support for Ubuntu 12.
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1204${DEBUG}-3.6.3.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1204${DEBUG}-3.4.14.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1204${DEBUG}-3.2.19.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1204${DEBUG}-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1204${DEBUG}-${VERSION_26}.tgz"
             MONGODB_24="http://downloads.10gen.com/linux/mongodb-linux-x86_64-subscription-ubuntu1204${DEBUG}-${VERSION_24}.tgz"
      ;;
      windows32*)
         EXTRACT="/cygdrive/c/Progra~1/7-Zip/7z.exe x"
         EXTRACT_MONGOSH="/cygdrive/c/Progra~1/7-Zip/7z.exe x"
         set_url_win32
       ;;
      cygwin*-i686)
         EXTRACT="/cygdrive/c/Progra~1/7-Zip/7z.exe x"
         EXTRACT_MONGOSH="/cygdrive/c/Progra~1/7-Zip/7z.exe x"
         set_url_win32
      ;;
      windows64*)
         EXTRACT="/cygdrive/c/Progra~2/7-Zip/7z.exe x"
         EXTRACT_MONGOSH="/cygdrive/c/Progra~2/7-Zip/7z.exe x"
         set_url_win64
      ;;
      cygwin*-x86_64)
         EXTRACT="/cygdrive/c/Progra~2/7-Zip/7z.exe x"
         EXTRACT_MONGOSH="/cygdrive/c/Progra~2/7-Zip/7z.exe x"
         set_url_win64
      ;;
      # Windows on GitHub Actions
      mingw64_nt-*-x86_64)
         EXTRACT="7z.exe x"
         EXTRACT_MONGOSH="7z.exe x"
         set_url_win64
      ;;
   esac

   # Fallback to generic Linux x86_64 builds (without SSL) when no platform specific link is available.
   case "$_DISTRO" in
      *linux*x86_64)
         MONGODB_LATEST=${MONGODB_LATEST:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64${DEBUG}-latest.tgz"}
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
                 # SERVER-37316 Removed support for generic linux builds.
                 MONGODB_42=${MONGODB_42:-""}
                 MONGODB_40=${MONGODB_40:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64${DEBUG}-${VERSION_40}.tgz"}
                 MONGODB_36=${MONGODB_36:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64${DEBUG}-${VERSION_36}.tgz"}
                 MONGODB_34=${MONGODB_34:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64${DEBUG}-${VERSION_34}.tgz"}
                 MONGODB_32=${MONGODB_32:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64${DEBUG}-${VERSION_32}.tgz"}
                 MONGODB_30=${MONGODB_30:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64${DEBUG}-${VERSION_30}.tgz"}
                 MONGODB_26=${MONGODB_26:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64${DEBUG}-${VERSION_26}.tgz"}
                 MONGODB_24=${MONGODB_24:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64${DEBUG}-${VERSION_24}.tgz"}
      ;;
   esac

   # PYTHON-2238 On Archlinux MongoDB <= 3.2 requires LC_ALL=C.
   case "$_DISTRO" in
      linux-arch-*)
        case "$_VERSION" in
           3.2) export LC_ALL=C ;;
           3.0) export LC_ALL=C ;;
           2.6) export LC_ALL=C ;;
           2.4) export LC_ALL=C ;;
        esac
      ;;
   esac

   MONGOSH_DOWNLOAD_URL=$MONGOSH
   case "$_VERSION" in
      latest) MONGODB_DOWNLOAD_URL=$MONGODB_LATEST ;;
      rapid) MONGODB_DOWNLOAD_URL=$MONGODB_RAPID ;;
      8.0) MONGODB_DOWNLOAD_URL=$MONGODB_80 ;;
      7.0) MONGODB_DOWNLOAD_URL=$MONGODB_70 ;;
      v6.0-latest) MONGODB_DOWNLOAD_URL=$MONGODB_60_LATEST ;;
      v6.0-perf) MONGODB_DOWNLOAD_URL=$MONGODB_60_PERF ;;
      6.0) MONGODB_DOWNLOAD_URL=$MONGODB_60 ;;
      5.0) MONGODB_DOWNLOAD_URL=$MONGODB_50 ;;
      4.4) MONGODB_DOWNLOAD_URL=$MONGODB_44 ;;
      4.2) MONGODB_DOWNLOAD_URL=$MONGODB_42 ;;
      4.0) MONGODB_DOWNLOAD_URL=$MONGODB_40 ;;
      3.6) MONGODB_DOWNLOAD_URL=$MONGODB_36 ;;
      3.4) MONGODB_DOWNLOAD_URL=$MONGODB_34 ;;
      3.2) MONGODB_DOWNLOAD_URL=$MONGODB_32 ;;
      3.0) MONGODB_DOWNLOAD_URL=$MONGODB_30 ;;
      2.6) MONGODB_DOWNLOAD_URL=$MONGODB_26 ;;
      2.4) MONGODB_DOWNLOAD_URL=$MONGODB_24 ;;
   esac

   if [ -z "$MONGODB_DOWNLOAD_URL" ]; then
     echo "Unknown version: $_VERSION for $_DISTRO"
     exit 1
   fi

   # Get the download URL for crypt_shared.
   # The crypt_shared package is available on server 6.0 and newer.
   # Try to download a version of crypt_shared matching the server version.
   # If no matching version is available, try to download the latest Major release of crypt_shared.
   case "$_VERSION" in
      latest)
         # If latest is not at least 6.0 on this OS, the crypt_shared package will not be available.
         if [ -n "$MONGODB_60" ] || [ -n "$MONGODB_70" ] || [ -n "$MONGODB_80" ]; then
           MONGO_CRYPT_SHARED_DOWNLOAD_URL=$MONGODB_LATEST
         fi ;;
      rapid) MONGO_CRYPT_SHARED_DOWNLOAD_URL=$MONGODB_RAPID ;;
      8.0) MONGO_CRYPT_SHARED_DOWNLOAD_URL=$MONGODB_80 ;;
      7.0) MONGO_CRYPT_SHARED_DOWNLOAD_URL=$MONGODB_70 ;;
      v6.0-latest) MONGO_CRYPT_SHARED_DOWNLOAD_URL=$MONGODB_60_LATEST ;;
      v6.0-perf) MONGO_CRYPT_SHARED_DOWNLOAD_URL=$MONGODB_60_PERF ;;
      6.0) MONGO_CRYPT_SHARED_DOWNLOAD_URL=$MONGODB_60 ;;
      5.0 | 4.4 | 4.2 | 4.0 | 3.6 | 3.4 | 3.2 | 3.0 | 2.6 | 2.4)
         # Default to using the latest Major release. Major releases are expected yearly.
         # MONGODB_60 may be empty if there is no 6.0 download available for this platform.
         MONGO_CRYPT_SHARED_DOWNLOAD_URL="$MONGODB_60"
         ;;
      *) echo "Unknown version '$_VERSION'";
         exit 1;
         ;;
   esac

   if [ -n "$MONGO_CRYPT_SHARED_DOWNLOAD_URL" ]; then
      # The crypt_shared package is simply the same file URL with the "mongodb-"
      # prefix replaced with "mongo_crypt_shared_v1-"
      MONGO_CRYPT_SHARED_DOWNLOAD_URL="$(printf '%s' "$MONGO_CRYPT_SHARED_DOWNLOAD_URL" | sed 's|/mongodb-|/mongo_crypt_shared_v1-|')"
   fi

   echo $MONGODB_DOWNLOAD_URL
}

set_url_win64 ()
{
  MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-win32-x64.zip"
  MONGODB_LATEST="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise${DEBUG}-latest.zip"
  MONGODB_RAPID="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise${DEBUG}-${VERSION_RAPID}.zip"
  MONGODB_80="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise${DEBUG}-${VERSION_80}.zip"
  MONGODB_70="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise${DEBUG}-${VERSION_70}.zip"
  MONGODB_60="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise${DEBUG}-${VERSION_60}.zip"
  MONGODB_50="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise${DEBUG}-${VERSION_50}.zip"
  MONGODB_44="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise${DEBUG}-${VERSION_44}.zip"
  MONGODB_42="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64${DEBUG}-${VERSION_42}.zip"
  MONGODB_40="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64${DEBUG}-${VERSION_40}.zip"
  MONGODB_36="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64${DEBUG}-${VERSION_36}.zip"
  MONGODB_34="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64${DEBUG}-${VERSION_34}.zip"
  MONGODB_32="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64${DEBUG}-${VERSION_32}.zip"
  MONGODB_30="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64${DEBUG}-${VERSION_30}.zip"
  MONGODB_26="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64${DEBUG}-${VERSION_26}.zip"
  MONGODB_24="https://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2008plus${DEBUG}-${VERSION_24}.zip"
}

set_url_win32 ()
{
  MONGODB_32="https://fastdl.mongodb.org/win32/mongodb-win32-i386${DEBUG}-${VERSION_32}.zip"
  MONGODB_30="https://fastdl.mongodb.org/win32/mongodb-win32-i386${DEBUG}-${VERSION_30}.zip"
  MONGODB_26="https://fastdl.mongodb.org/win32/mongodb-win32-i386${DEBUG}-${VERSION_26}.zip"
  MONGODB_24="https://fastdl.mongodb.org/win32/mongodb-win32-i386${DEBUG}-${VERSION_24}.zip"
}

# curl_retry emulates running curl with `--retry 5` and `--retry-all-errors`.
curl_retry ()
{
  for i in 1 2 4 8 16; do
    { curl --fail -sS --max-time 300 "$@" && return 0; } || sleep $i
  done
  return 1
}

# download_and_extract_package downloads a MongoDB server package.
download_and_extract_package ()
{
   MONGODB_DOWNLOAD_URL=$1
   EXTRACT=$2

   if [ -n "${MONGODB_BINARIES:-}" ]; then
      cd "$(dirname "$(dirname "${MONGODB_BINARIES:?}")")"
   else
      cd $DRIVERS_TOOLS
   fi

   echo "Installing server binaries..."
   curl_retry $MONGODB_DOWNLOAD_URL --output mongodb-binaries.tgz

   $EXTRACT mongodb-binaries.tgz
   echo "Installing server binaries... done."

   set -x
   rm -f mongodb-binaries.tgz
   mv mongodb* mongodb
   chmod -R +x mongodb
   # Clear the environment to avoid "find: The environment is too large for exec()"
   # error on Windows.
   env -i PATH="$PATH" find . -name vcredist_x64.exe -exec {} /install /quiet \;
   echo "MongoDB server version: $(./mongodb/bin/mongod --version)"
   cd -
}

download_and_extract_mongosh ()
{
   MONGOSH_DOWNLOAD_URL=$1
   EXTRACT_MONGOSH=${2:-"tar zxf"}

   if [ -z "$MONGOSH_DOWNLOAD_URL" ]; then
      get_mongodb_download_url_for "$(get_distro)" latest false
   fi

   if [ -n "${MONGODB_BINARIES:-}" ]; then
      cd "$(dirname "$(dirname "${MONGODB_BINARIES:?}")")"
   else
      cd $DRIVERS_TOOLS
   fi

   echo "Installing MongoDB shell..."
   curl_retry $MONGOSH_DOWNLOAD_URL --output mongosh.tgz
   $EXTRACT_MONGOSH mongosh.tgz

   rm -f mongosh.tgz
   mv mongosh-* mongosh
   mkdir -p mongodb/bin
   mv mongosh/bin/* mongodb/bin
   rm -rf mongosh
   chmod -R +x mongodb/bin
   echo "Installing MongoDB shell... done."
   echo "MongoDB shell version: $(./mongodb/bin/mongosh --version)"
   cd -
}

# download_and_extract downloads a requested MongoDB server package.
# If the legacy shell is not included in the download, the legacy shell is also downloaded from the 5.0 package.
download_and_extract ()
{
   MONGODB_DOWNLOAD_URL=$1
   EXTRACT=$2
   MONGOSH_DOWNLOAD_URL=$3
   EXTRACT_MONGOSH=$4

   download_and_extract_package "$MONGODB_DOWNLOAD_URL" "$EXTRACT"

   if [ "$MONGOSH_DOWNLOAD_URL" ]; then
      download_and_extract_mongosh "$MONGOSH_DOWNLOAD_URL" "$EXTRACT_MONGOSH"
   fi

   if [ ! -z "${INSTALL_LEGACY_SHELL:-}" ] && [ ! -e $DRIVERS_TOOLS/mongodb/bin/mongo ] && [ ! -e $DRIVERS_TOOLS/mongodb/bin/mongo.exe ]; then
      # The legacy mongo shell is not included in server downloads of 6.0.0-rc6 or later. Refer: SERVER-64352.
      # Some test scripts use the mongo shell for setup.
      # Download 5.0 package to get the legacy mongo shell as a workaround until DRIVERS-2328 is addressed.
      echo "Legacy 'mongo' shell not detected."
      echo "Download legacy shell from 5.0 ... begin"
      # Use a subshell to avoid overwriting MONGODB_DOWNLOAD_URL and MONGO_CRYPT_SHARED_DOWNLOAD_URL.
      MONGODB50_DOWNLOAD_URL=$(
         get_mongodb_download_url_for "$DISTRO" "5.0" > /dev/null
         echo $MONGODB_DOWNLOAD_URL
      )

      SAVED_DRIVERS_TOOLS=$DRIVERS_TOOLS
      mkdir $DRIVERS_TOOLS/legacy-shell-download
      DRIVERS_TOOLS=$DRIVERS_TOOLS/legacy-shell-download
      download_and_extract_package "$MONGODB50_DOWNLOAD_URL" "$EXTRACT"
      if [ -e $DRIVERS_TOOLS/mongodb/bin/mongo ]; then
         cp $DRIVERS_TOOLS/mongodb/bin/mongo $SAVED_DRIVERS_TOOLS/mongodb/bin
      elif [ -e $DRIVERS_TOOLS/mongodb/bin/mongo.exe ]; then
         cp $DRIVERS_TOOLS/mongodb/bin/mongo.exe $SAVED_DRIVERS_TOOLS/mongodb/bin
      fi
      DRIVERS_TOOLS=$SAVED_DRIVERS_TOOLS
      rm -rf $DRIVERS_TOOLS/legacy-shell-download
      echo "Download legacy shell from 5.0 ... end"
   fi

   # Define SKIP_CRYPT_SHARED=1 to skip downloading crypt_shared. This is useful for platforms that have a
   # server release but don't ship a corresponding crypt_shared release, like Amazon 2018.
   if [ -z "${SKIP_CRYPT_SHARED:-}" ]; then
      if [ -z "$MONGO_CRYPT_SHARED_DOWNLOAD_URL" ]; then
         echo "There is no crypt_shared library for distro='$DISTRO' and version='$MONGODB_VERSION'".
      else
         echo "Downloading crypt_shared package from $MONGO_CRYPT_SHARED_DOWNLOAD_URL"
         download_and_extract_crypt_shared "$MONGO_CRYPT_SHARED_DOWNLOAD_URL" "$EXTRACT" CRYPT_SHARED_LIB_PATH
         echo "CRYPT_SHARED_LIB_PATH:" $CRYPT_SHARED_LIB_PATH
         if [ -z $CRYPT_SHARED_LIB_PATH ]; then
            echo "CRYPT_SHARED_LIB_PATH must be assigned, but wasn't" 1>&2 # write to stderr"
            exit 1
         fi
      fi
   fi
}

# download_and_extract_crypt_shared downloads and extracts a crypt_shared package into the current directory.
# Use get_mongodb_download_url_for to get a MONGO_CRYPT_SHARED_DOWNLOAD_URL.
download_and_extract_crypt_shared ()
{
   MONGO_CRYPT_SHARED_DOWNLOAD_URL=$1
   EXTRACT=$2
   __CRYPT_SHARED_LIB_PATH=${3:-CRYPT_SHARED_LIB_PATH}
   rm -rf crypt_shared_download
   mkdir crypt_shared_download
   cd crypt_shared_download

   curl_retry $MONGO_CRYPT_SHARED_DOWNLOAD_URL --output crypt_shared-binaries.tgz
   $EXTRACT crypt_shared-binaries.tgz

   LIBRARY_NAME="mongo_crypt_v1"
   # Windows package includes .dll in 'bin' directory.
   if [ -d ./bin ]; then
      cp bin/$LIBRARY_NAME.* ..
   else
      cp lib/$LIBRARY_NAME.* ..
   fi
   cd ..
   rm -rf crypt_shared_download

   RELATIVE_CRYPT_SHARED_LIB_PATH="$(find . -maxdepth 1 -type f \( -name "$LIBRARY_NAME.dll" -o -name "$LIBRARY_NAME.so" -o -name "$LIBRARY_NAME.dylib" \))"
   ABSOLUTE_CRYPT_SHARED_LIB_PATH=$(pwd)/$(basename $RELATIVE_CRYPT_SHARED_LIB_PATH)
   if [ "Windows_NT" = "$OS" ]; then
      # If we're on Windows, convert the "cygdrive" path to Windows-style paths.
      ABSOLUTE_CRYPT_SHARED_LIB_PATH=$(cygpath -m $ABSOLUTE_CRYPT_SHARED_LIB_PATH)
   fi
   eval $__CRYPT_SHARED_LIB_PATH=$ABSOLUTE_CRYPT_SHARED_LIB_PATH
}
