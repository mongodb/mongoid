set_fcv() {
  if test -n "$FCV"; then
    mongo --eval 'assert.commandWorked(db.adminCommand( { setFeatureCompatibilityVersion: "'"$FCV"'" } ));' "$MONGODB_URI"
    mongo --quiet --eval 'db.adminCommand( { getParameter: 1, featureCompatibilityVersion: 1 } )' |grep  "version.*$FCV"
  fi
}

set_env_vars() {
  AUTH=${AUTH:-noauth}
  SSL=${SSL:-nossl}
  MONGODB_URI=${MONGODB_URI:-}
  TOPOLOGY=${TOPOLOGY:-server}
  DRIVERS_TOOLS=${DRIVERS_TOOLS:-}

  if [ "$AUTH" != "noauth" ]; then
    export ROOT_USER_NAME="bob"
    export ROOT_USER_PWD="pwd123"
  fi
  if [ "$COMPRESSOR" == "zlib" ]; then
    export COMPRESSOR="zlib"
  fi
  export CI=evergreen
  # JRUBY_OPTS were initially set for Mongoid
  export JRUBY_OPTS="--server -J-Xms512m -J-Xmx1G"

  if test -n "$SINGLE_MONGOS"; then
    # Tests which perform query count assertions are incompatible with 
    # multi-shard deployments, because of how any_instance_of assertions work
    # (they must all be invoked on the same connection object, and in
    # multi-shard deployments server selection rotates through available
    # mongos nodes).
    echo Restricting to a single mongos
    export MONGODB_URI=`echo "$MONGODB_URI" |sed -e 's/,.*//'`
  fi
}

install_deps() {
  echo "Installing all gem dependencies"
  which bundle
  bundle --version
  bundle install
  bundle exec rake clean
}

kill_jruby() {
  jruby_running=`ps -ef | grep 'jruby' | grep -v grep | awk '{print $2}'`
  if [ -n "$jruby_running" ];then
    echo "terminating remaining jruby processes"
    for pid in $(ps -ef | grep "jruby" | grep -v grep | awk '{print $2}'); do kill -9 $pid; done
  fi
}

prepare_server() {
  arch=$1
  version=$2
  
  url=http://downloads.10gen.com/linux/mongodb-linux-x86_64-enterprise-$arch-$version.tgz
  mongodb_dir="$MONGO_ORCHESTRATION_HOME"/mdb
  mkdir -p "$mongodb_dir"
  curl $url |tar xz -C "$mongodb_dir" -f -
  BINDIR="$mongodb_dir"/`basename $url |sed -e s/.tgz//`/bin
  export PATH="$BINDIR":$PATH
}

install_mlaunch() {
  pythonpath="$MONGO_ORCHESTRATION_HOME"/python
  pip install -t "$pythonpath" 'mtools[mlaunch]'
  export PATH="$pythonpath/bin":$PATH
  export PYTHONPATH="$pythonpath"
}
