#!/usr/bin/env sh
rake spec
export TZ=America/Santiago
rake spec
export TZ=US/Central
rake spec
export TZ=Europe/Stockholm
rake spec
export TZ=US/Pacific
rake spec

