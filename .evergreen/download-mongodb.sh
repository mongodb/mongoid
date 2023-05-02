#!/bin/sh

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

      if [[ "$release" =~ "Red Hat" ]]; then
         name="rhel"
      elif [[ "$release" =~ "Fedora" ]]; then
         name="fedora"
      fi
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

# get_mongodb_download_url_for "linux-distro-version-architecture" "latest|44|42|40|36|34|32|30|28|26|24"
# Sets EXTRACT to appropriate extract command
# Sets MONGODB_DOWNLOAD_URL to the appropriate download url
# Sets MONGO_CRYPT_SHARED_DOWNLOAD_URL to the corresponding URL to a crypt_shared library archive
get_mongodb_download_url_for ()
{
   _DISTRO=$1
   _VERSION=$2

   # Set VERSION_RAPID to the latest rapid release each quarter.
   VERSION_RAPID="6.2.1"
   VERSION_MONGOSH="1.6.2"
   VERSION_60_LATEST="v6.0-latest"
   VERSION_60="6.0.5"
   VERSION_50="5.0.15"
   VERSION_44="4.4.20"
   VERSION_42="4.2.24"
   VERSION_40="4.0.28"
   VERSION_36="3.6.23"
   VERSION_34="3.4.24"
   VERSION_32="3.2.22"
   VERSION_30="3.0.15"
   VERSION_26="2.6.12"
   VERSION_24="2.4.14"

   EXTRACT="tar zxf"
   EXTRACT_MONGOSH=$EXTRACT
   # getdata matrix on:
   # https://evergreen.mongodb.com/version/5797f0493ff12235e5001f05
   case "$_DISTRO" in
      darwin--arm64)
         EXTRACT_MONGOSH="unzip -q"
         MONGODB_LATEST="http://downloads.10gen.com/osx/mongodb-macos-arm64-enterprise-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-darwin-arm64.zip"
             MONGODB_RAPID="http://downloads.10gen.com/osx/mongodb-macos-arm64-enterprise-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/osx/mongodb-macos-arm64-enterprise-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/osx/mongodb-macos-arm64-enterprise-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise-${VERSION_32}.tgz"
             MONGODB_30="https://fastdl.mongodb.org/osx/mongodb-osx-x86_64-${VERSION_30}.tgz"
             MONGODB_26="https://fastdl.mongodb.org/osx/mongodb-osx-x86_64-${VERSION_26}.tgz"
             MONGODB_24="https://fastdl.mongodb.org/osx/mongodb-osx-x86_64-${VERSION_24}.tgz"
      ;;
      darwin--x86_64)
         EXTRACT_MONGOSH="unzip -q"
         MONGODB_LATEST="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-darwin-x64.zip"
             MONGODB_RAPID="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/osx/mongodb-macos-x86_64-enterprise-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/osx/mongodb-osx-x86_64-enterprise-${VERSION_32}.tgz"
             MONGODB_30="https://fastdl.mongodb.org/osx/mongodb-osx-x86_64-${VERSION_30}.tgz"
             MONGODB_26="https://fastdl.mongodb.org/osx/mongodb-osx-x86_64-${VERSION_26}.tgz"
             MONGODB_24="https://fastdl.mongodb.org/osx/mongodb-osx-x86_64-${VERSION_24}.tgz"
      ;;
      sunos*i86pc)
         MONGODB_LATEST="https://fastdl.mongodb.org/sunos5/mongodb-sunos5-x86_64-latest.tgz"
             MONGODB_34="https://fastdl.mongodb.org/sunos5/mongodb-sunos5-x86_64-3.4.5.tgz"
             MONGODB_32="https://fastdl.mongodb.org/sunos5/mongodb-sunos5-x86_64-3.2.14.tgz"
             MONGODB_30="https://fastdl.mongodb.org/sunos5/mongodb-sunos5-x86_64-${VERSION_30}.tgz"
             MONGODB_26="https://fastdl.mongodb.org/sunos5/mongodb-sunos5-x86_64-${VERSION_26}.tgz"
             MONGODB_24="https://fastdl.mongodb.org/sunos5/mongodb-sunos5-x86_64-${VERSION_24}.tgz"
      ;;
      linux-rhel-8.1-ppc64le)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-ppc64le.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel81-${VERSION_42}.tgz"
      ;;
      linux-rhel-8*-s390x)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel83-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-s390x.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel83-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel83-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel83-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel83-${VERSION_50}.tgz"
             # SERVER-44074 Added support for RHEL 8 (zSeries) in 5.0.8 and 6.0.0-rc0.
      ;;
      linux-rhel-8.2-aarch64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel82-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-arm64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel82-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel82-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel82-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel82-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-rhel82-${VERSION_44}.tgz"
             # SERVER-48282 Added support for RHEL 8 ARM in 4.4.2.
      ;;
      linux-rhel-8*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel80-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel80-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel80-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel80-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel80-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel80-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel80-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel80-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel80-${VERSION_36}.tgz"
      ;;
      linux-rhel-7*-s390x)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-s390x.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72-3.6.4.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel72-3.4.14.tgz"
      ;;
      linux-rhel-7.1-ppc64le)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-ppc64le.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-rhel71-${VERSION_32}.tgz"
      ;;
      linux-rhel-7.*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70-${VERSION_32}.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel70-${VERSION_26}.tgz"
      ;;
      linux-rhel-6*-s390x)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel67-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-s390x.tgz"
             # SERVER-53726 removed support for s390x (zSeries) on RHEL6.
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel67-4.4.6.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel67-4.2.18.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel67-4.0.28.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel67-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-rhel67-${VERSION_34}.tgz"
      ;;
      linux-rhel-6.2*|linux-centos-6*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62-${VERSION_32}.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-rhel62-${VERSION_26}.tgz"
             MONGODB_24="http://downloads.10gen.com/linux/mongodb-linux-x86_64-subscription-rhel62-${VERSION_24}.tgz"
      ;;
      linux-rhel-5.5*)
         MONGODB_LATEST="http://downloads.mongodb.org/linux/mongodb-linux-x86_64-rhel55-latest.tgz"
             MONGODB_32="http://downloads.mongodb.org/linux/mongodb-linux-x86_64-rhel55-${VERSION_32}.tgz"
             MONGODB_30="http://downloads.mongodb.org/linux/mongodb-linux-x86_64-rhel55-${VERSION_30}.tgz"
      ;;
      linux-sles-11*-x86_64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse11-latest.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse11-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse11-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse11-${VERSION_32}.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse11-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse11-${VERSION_26}.tgz"
             MONGODB_24="http://downloads.10gen.com/linux/mongodb-linux-x86_64-subscription-suse11-${VERSION_24}.tgz"
      ;;
      linux-sles-12*-s390x)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-suse12-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-s390x.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-suse12-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-suse12-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-suse12-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-suse12-3.6.3.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-suse12-3.4.13.tgz"
      ;;
      linux-sles-12*-x86_64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-suse12-${VERSION_32}.tgz"
      ;;
      linux-amzn-2018*-x86_64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64-${VERSION_60_LATEST}.tgz"
             # SERVER-50564 Removed support for Amazon Linux (v1) in 6.0.0-rc1.
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64-6.0.0-rc0.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64-${VERSION_32}.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amzn64-${VERSION_26}.tgz"
             MONGODB_24="http://downloads.10gen.com/linux/mongodb-linux-x86_64-subscription-amzn64-${VERSION_24}.tgz"
      ;;
      linux-amzn-2-x86_64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-amazon2-${VERSION_40}.tgz"
      ;;
      linux-amzn-2-aarch64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2-latest.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-amazon2-${VERSION_42}.tgz"
      ;;
      linux-debian-7*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian71-latest.tgz"
             # SERVER-32999 removed support for Debian 7.
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian71-3.6.5.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian71-3.4.15.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian71-3.2.20.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian71-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian71-${VERSION_26}.tgz"
      ;;
      linux-debian-8*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian81-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             # SERVER-37767 Removed support for Debian 8
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian81-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian81-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian81-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian81-${VERSION_32}.tgz"
      ;;
      linux-debian-9*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian92-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             # SERVER-62308 Removed support for Debian 9 in server version 6.0.0-rc5.
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian92-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian92-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian92-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian92-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian92-${VERSION_36}.tgz"
      ;;
      linux-debian-10*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian10-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian10-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian10-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian10-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian10-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian10-${VERSION_44}.tgz"
      ;;
      linux-debian-11*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian11-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian11-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian11-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian11-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-debian11-${VERSION_50}.tgz"
             # SERVER-62299 Added support for Debian 11 in 5.0.8 and 6.0.0-rc0
      ;;
      linux-ubuntu-20.04-aarch64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2004-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-arm64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2004-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2004-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2004-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2004-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu2004-${VERSION_44}.tgz"
      ;;
      linux-ubuntu-20.04*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2004-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2004-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2004-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2004-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2004-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu2004-${VERSION_44}.tgz"
      ;;
      linux-ubuntu-18.04-s390x)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1804-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-s390x.tgz"
             # SERVER-32999 removed support for s390x (zSeries) on Ubuntu 18.04.
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1804-4.4.6.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1804-4.2.14.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1804-4.0.25.tgz"
      ;;
      linux-ubuntu-18.04-aarch64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-arm64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1804-${VERSION_42}.tgz"
      ;;
      linux-ubuntu-18.04-ppc64le)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1804-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-ppc64le.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1804-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1804-${VERSION_42}.tgz"
      ;;
      linux-ubuntu-18.04*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_RAPID="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804-${VERSION_RAPID}.tgz"
             MONGODB_60_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804-${VERSION_60_LATEST}.tgz"
             MONGODB_60="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804-${VERSION_60}.tgz"
             MONGODB_50="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804-${VERSION_50}.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1804-${VERSION_36}.tgz"
      ;;
      linux-ubuntu-16.04-s390x)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1604-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-s390x.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1604-v4.0-latest.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1604-3.6.4.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-s390x-enterprise-ubuntu1604-3.4.14.tgz"
      ;;
      linux-ubuntu-16.04-ppc64le)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1604-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-ppc64le.tgz"
             # SERVER-37774 Removed support for Ubuntu 16.04 PPCLE
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1604-4.0.9.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1604-3.6.12.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-ppc64le-enterprise-ubuntu1604-3.4.20.tgz"
      ;;
      linux-ubuntu-16.04-aarch64)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1604-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-arm64.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1604-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-aarch64-enterprise-ubuntu1604-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-arm64-enterprise-ubuntu1604-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-arm64-enterprise-ubuntu1604-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-arm64-enterprise-ubuntu1604-${VERSION_34}.tgz"
      ;;
      linux-ubuntu-16.04*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             MONGODB_44="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604-${VERSION_44}.tgz"
             MONGODB_42="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604-${VERSION_42}.tgz"
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604-${VERSION_40}.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604-${VERSION_36}.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604-${VERSION_34}.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1604-${VERSION_32}.tgz"
      ;;
      linux-ubuntu-14.04*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             # SERVER-37765 Removed support for Ubuntu 14.04
             MONGODB_40="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404-4.0.9.tgz"
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404-3.6.12.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404-3.4.20.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404-${VERSION_32}.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1404-${VERSION_26}.tgz"
      ;;
      linux-ubuntu-12.04*)
         MONGODB_LATEST="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1204-latest.tgz"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
             # SERVER-31535 removed support for Ubuntu 12.
             MONGODB_36="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1204-3.6.3.tgz"
             MONGODB_34="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1204-3.4.14.tgz"
             MONGODB_32="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1204-3.2.19.tgz"
             MONGODB_30="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1204-${VERSION_30}.tgz"
             MONGODB_26="http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-ubuntu1204-${VERSION_26}.tgz"
             MONGODB_24="http://downloads.10gen.com/linux/mongodb-linux-x86_64-subscription-ubuntu1204-${VERSION_24}.tgz"
      ;;
      windows32*)
         EXTRACT="/cygdrive/c/Progra~2/7-Zip/7z.exe x"
         EXTRACT_MONGOSH="/cygdrive/c/Progra~2/7-Zip/7z.exe x"
             MONGODB_32="https://fastdl.mongodb.org/win32/mongodb-win32-i386-${VERSION_32}.zip"
             MONGODB_30="https://fastdl.mongodb.org/win32/mongodb-win32-i386-${VERSION_30}.zip"
             MONGODB_26="https://fastdl.mongodb.org/win32/mongodb-win32-i386-${VERSION_26}.zip"
             MONGODB_24="https://fastdl.mongodb.org/win32/mongodb-win32-i386-${VERSION_24}.zip"
      ;;
      windows64*)
         # same as cygwin*-86-64
         EXTRACT="/cygdrive/c/Progra~2/7-Zip/7z.exe x"
         EXTRACT_MONGOSH="/cygdrive/c/Progra~2/7-Zip/7z.exe x"
         MONGODB_LATEST="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise-latest.zip"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-win32-x64.zip"
             MONGODB_RAPID="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise-${VERSION_RAPID}.zip"
             MONGODB_60_LATEST="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise-${VERSION_60_LATEST}.zip"
             MONGODB_60="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise-${VERSION_60}.zip"
             MONGODB_50="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise-${VERSION_50}.zip"
             MONGODB_44="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise-${VERSION_44}.zip"
             MONGODB_42="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_42}.zip"
             MONGODB_40="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_40}.zip"
             MONGODB_36="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_36}.zip"
             MONGODB_34="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_34}.zip"
             MONGODB_32="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_32}.zip"
             MONGODB_30="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_30}.zip"
             MONGODB_26="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_26}.zip"
             MONGODB_24="https://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2008plus-${VERSION_24}.zip"
      ;;
      cygwin*-x86_64)
         EXTRACT="/cygdrive/c/Progra~2/7-Zip/7z.exe x"
         EXTRACT_MONGOSH="/cygdrive/c/Progra~2/7-Zip/7z.exe x"
         MONGODB_LATEST="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise-latest.zip"
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-win32-x64.zip"
             MONGODB_RAPID="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise-${VERSION_RAPID}.zip"
             MONGODB_60_LATEST="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise-${VERSION_60_LATEST}.zip"
             MONGODB_60="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise-${VERSION_60}.zip"
             MONGODB_50="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise-${VERSION_50}.zip"
             MONGODB_44="http://downloads.10gen.com/windows/mongodb-windows-x86_64-enterprise-${VERSION_44}.zip"
             MONGODB_42="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_42}.zip"
             MONGODB_40="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_40}.zip"
             MONGODB_36="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_36}.zip"
             MONGODB_34="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_34}.zip"
             MONGODB_32="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_32}.zip"
             MONGODB_30="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_30}.zip"
             MONGODB_26="http://downloads.10gen.com/win32/mongodb-win32-x86_64-enterprise-windows-64-${VERSION_26}.zip"
             MONGODB_24="https://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2008plus-${VERSION_24}.zip"
      ;;
      cygwin*-i686)
         EXTRACT="/cygdrive/c/Progra~1/7-Zip/7z.exe x"
         EXTRACT_MONGOSH="/cygdrive/c/Progra~1/7-Zip/7z.exe x"
             MONGODB_32="https://fastdl.mongodb.org/win32/mongodb-win32-i386-${VERSION_32}.zip"
             MONGODB_30="https://fastdl.mongodb.org/win32/mongodb-win32-i386-${VERSION_30}.zip"
             MONGODB_26="https://fastdl.mongodb.org/win32/mongodb-win32-i386-${VERSION_26}.zip"
             MONGODB_24="https://fastdl.mongodb.org/win32/mongodb-win32-i386-${VERSION_24}.zip"
      ;;
   esac

   # Fallback to generic Linux x86_64 builds (without SSL) when no platform specific link is available.
   case "$_DISTRO" in
      *linux*x86_64)
         MONGODB_LATEST=${MONGODB_LATEST:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64-latest.tgz"}
         MONGOSH="https://downloads.mongodb.com/compass/mongosh-${VERSION_MONGOSH}-linux-x64.tgz"
                 # SERVER-37316 Removed support for generic linux builds.
                 MONGODB_42=${MONGODB_42:-""}
                 MONGODB_40=${MONGODB_40:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64-${VERSION_40}.tgz"}
                 MONGODB_36=${MONGODB_36:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64-${VERSION_36}.tgz"}
                 MONGODB_34=${MONGODB_34:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64-${VERSION_34}.tgz"}
                 MONGODB_32=${MONGODB_32:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64-${VERSION_32}.tgz"}
                 MONGODB_30=${MONGODB_30:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64-${VERSION_30}.tgz"}
                 MONGODB_26=${MONGODB_26:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64-${VERSION_26}.tgz"}
                 MONGODB_24=${MONGODB_24:-"http://downloads.mongodb.org/linux/mongodb-linux-x86_64-${VERSION_24}.tgz"}
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
      v6.0-latest) MONGODB_DOWNLOAD_URL=$MONGODB_60_LATEST ;;
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
         if [ -n "$MONGODB_60" ]; then
           MONGO_CRYPT_SHARED_DOWNLOAD_URL=$MONGODB_LATEST
         fi ;;
      rapid) MONGO_CRYPT_SHARED_DOWNLOAD_URL=$MONGODB_RAPID ;;
      v6.0-latest) MONGO_CRYPT_SHARED_DOWNLOAD_URL=$MONGODB_60_LATEST ;;
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

# download_and_extract_package downloads a MongoDB server package.
download_and_extract_package ()
{
   MONGODB_DOWNLOAD_URL=$1
   EXTRACT=$2

   cd $DRIVERS_TOOLS
   curl --retry 8 -sS $MONGODB_DOWNLOAD_URL --max-time 300 --output mongodb-binaries.tgz
   $EXTRACT mongodb-binaries.tgz

   rm -f mongodb-binaries.tgz
   mv mongodb* mongodb
   chmod -R +x mongodb
   find . -name vcredist_x64.exe -exec {} /install /quiet \;
   ./mongodb/bin/mongod --version
   cd -
}

download_and_extract_mongosh ()
{
   MONGOSH_DOWNLOAD_URL=$1
   EXTRACT_MONGOSH=$2

   cd $DRIVERS_TOOLS
   curl --retry 8 -sS $MONGOSH_DOWNLOAD_URL --max-time 300 --output mongosh.tgz
   $EXTRACT_MONGOSH mongosh.tgz

   rm -f mongosh.tgz
   mv mongosh-* mongosh
   mv mongosh/bin/* mongodb/bin
   chmod -R +x mongodb/bin
   echo "MongoDB shell installed. Version:"
   ./mongodb/bin/mongosh --version
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

   # Deprecated: this will be removed once drivers have updated to mongosh
   if [ ! -e $DRIVERS_TOOLS/mongodb/bin/mongo -a ! -e $DRIVERS_TOOLS/mongodb/bin/mongo.exe ]; then
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
}

# download_and_extract_crypt_shared downloads and extracts a crypt_shared package into the current directory.
# Use get_mongodb_download_url_for to get a MONGO_CRYPT_SHARED_DOWNLOAD_URL.
download_and_extract_crypt_shared ()
{
   MONGO_CRYPT_SHARED_DOWNLOAD_URL=$1
   EXTRACT=$2
   __CRYPT_SHARED_LIB_PATH=${3:-CRYPT_SHARED_LIB_PATH}
   mkdir crypt_shared_download
   cd crypt_shared_download
   curl --retry 8 -sS $MONGO_CRYPT_SHARED_DOWNLOAD_URL --max-time 300 --output crypt_shared-binaries.tgz
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