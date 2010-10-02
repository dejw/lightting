#!/bin/bash
#
# Runs lighttpd in current directory, which allows to serve
# PHP scripts, and browsing indices.
#

__VERSION="0.0.1"
__AUTHOR="Dawid Fatyga"

# This section defines default configuration
: <<DEFAULT_CONFIG
server.modules = (
  "mod_access",
  "mod_alias",
  "mod_cgi",
  "mod_accesslog",
)
index-file.names           = ( "index.php", "index.html",
                               "index.htm", "default.htm",
                               "index.lighttpd.html" )
url.access-deny            = ( "~", ".inc" )
static-file.exclude-extensions = ( ".php", ".pl", ".fcgi" )
dir-listing.encoding        = "utf-8"
server.dir-listing          = "enable"

server.username            = "www-data"
server.groupname           = "www-data"

include_shell "/usr/share/lighttpd/create-mime.assign.pl"
DEFAULT_CONFIG

function log(){
  echo $1
}

function fatal(){
  log "! $1"
  exit
}

# Defines boolean command line option
# name variable [true|false]
function boolean(){
  if [ -z "$3" ]; then
    value=true
  else
    value=$3
  fi

  if [ "$1" = "$current" ]; then
    export $2=$value
  fi
}

# Defines command line option that takes 1 parameter
# name variable
function parameter(){
  if [ "$1" = "$current" ]; then
    (( i= $i + 1 ))
    if [ $i = $arguments_length ]; then
      fatal "$1 przyjmuje 1 parametr"
    else
      export $2=${arguments[$i]}
    fi
  fi
}

# defines command line options that calls function
# name callback
function callback(){
  if [ "$1" = "$current" ]; then
    $2
  fi
}

function checkFor(){
  `$1 --version &> /dev/null`
  if [ "$?" != 0 -a "$?" != 255 ]; then
    fatal "Cannot find $1 in your PATH"
  fi
  v=`$1 --version 2> /dev/null | head -n 1`
  log "Using $v"
}

function version(){
  echo "$__VERSION"
  echo "Copyright (c) `date +%Y`, $__AUTHOR"
  exit
}

function usage(){
  echo " usage: $program [options]"
  echo ""
  echo " Runs lighttpd in current directory, which allows to serve PHP scripts,"
  echo " and browsing indices."
  echo ""
  echo " Available options:"
  echo "   -h --help              Shows this help"
  echo "   -v --version           Shows version number"
  echo ""
  exit
}

function showDefaultConfig(){
  checkFor sed
  sed --silent -e '/DEFAULT_CONFIG$/,/^DEFAULT_CONFIG$/p' "$0" | sed -e '/DEFAULT_CONFIG$/d'
  exit
}


OLD_IFS="$IFS";
IFS=" "

arguments_length=$#
arguments=( $@ )
program=$0

IFS=$OLD_IFS

# Process the command line arguments
for (( i=0; i <= $#; i++ )); do
  current=${arguments[$i]}

  boolean "--force-config" force_config
  boolean "-c" force_config

  parameter "-f" config_file
  parameter "--config-file" config_file

  parameter "-p" port
  parameter "--port" port

  parameter "-b" bind
  parameter "--bind" bind

  parameter "-r" document-root
  parameter "--document-root" document-root

  callback "-v", version
  callback "--version" version

  callback "--show-default" showDefaultConfig
  callback "-h" usage
  callback "--help" usage
done

checkFor lighttpd
checkFor sed

__BASE__=`pwd`

port=8080
bind=localhost

config_file=.lightting.conf
force_config=true

document_root=$__BASE__
not_daemon=true

php_path=`which php5-cgi`
chroot=/
access="$__BASE__/access.log"
error="$__BASE__/error.log"
upload="$__BASE__/uploads"
pid_file="$__BASE__/lighttpd.pid"

function config(){
  echo $1 >> $config_file
}

if [ ! -e $config_file -o $force_config ]; then
  sed --silent -e '/DEFAULT_CONFIG$/,/^DEFAULT_CONFIG$/p' "$0" | sed -e '/DEFAULT_CONFIG$/d' > $config_file
  config "# Config generated on `date`"
  config "server.document-root = \"$document_root\""
  config "server.port = $port"
  config "server.bind = \"$bind\""
  config "accesslog.filename = \"$access\""
  config "server.errorlog = \"$error\""
  config "server.upload-dirs = ( \"$upload\" )"
  config "server.pid-file = \"$pid_file\""
  config "cgi.assign = ( \".php\" => \"$php_path\" )"
fi

log "Listening on $bind:$port..."
lighttpd -D -f $config_file
