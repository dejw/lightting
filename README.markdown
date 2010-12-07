# lightting

`lightting` is a simple shell script that allows you to run `lighttpd` from any
directory and serve PHP scripts (and browsing indices).

It was written for local PHP development, and it is not intended to use on a
production.

## requirements

`sed` and obiously `lighttpd`

## installation

    wget --no-check-certificate http://github.com/dejw/lightting/raw/master//lightting.sh && chmod +x lightting.sh

See `lightting.sh --help` for available options.
