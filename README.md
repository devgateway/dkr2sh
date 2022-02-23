# dkr2sh - convert Dockerfile to shell script

This script naively translates some Dockerfile instructions into corresponding shell commands.

## Usage

The file to use is `dkr2sh.sed`, which is a sed script, note how it starts:
```
#!/bin/sed -f
# Convert Dockerfile to shell script.
```

To use it, normal sed usage implies it takes stdin and outputs stdout. So:
```
./dkr2sh.sed < Dockerfile > mydockerscript.sh
```

## Contributing
The explanation of the tranform rules below matches with .sh files, eg. `copy-from.sh`, `copy.sh` and `add.sh`

In the `dkr2sh.sed` file, the transform rules have been translated to sed patterns. The `sh2sed.sh` is the helper script that can do this as part of manual labour. You can change any of the patterns and run, eg. `./sh2sed.sh < copy-from.sh` and you will get this:
```
for i in ARGS; do\n\ttest -d "$i" \&\& i="$i\/"\n\trsync -a "$i" DEST # FROM\ndone
```

It matches the replacement string in the `dkr2sh.sed` file, here, but with match groups inserted inplace of ARGS, DEST, FROM
```
s/^[[:space:]]*COPY\([[:space:]]\+--from=[^[:space:]]\+\)\(\([[:space:]]\+[^[:space:]]\+\)\+\)\([[:space:]]\+[^[:space:]]\+\)[[:space:]]*/for i in\2; do\n\ttest -d "$i" \&\& i="$i\/"\n\trsync -a "$i"\4 #\1\ndone/i
```

Each match group and result has to be implemented manually.

## Conversion Rules

### Instructions commented out

* FROM
* CMD
* LABEL
* MAINTAINER
* EXPOSE
* ENTRYPOINT
* VOLUME
* ARG
* ONBUILD
* STOPSIGNAL
* HEALTHCHECK

Translate these instructions manually:

* USER - execute the next block(s) with `su` or equivalent
* SHELL - unwrap JSON-formatted arguments, run it for subsequent block(s)

### ENV

Before:

    ENV FOO bar

After:

    export FOO=bar

### RUN

Before:

    RUN /usr/bin/foo \
        && /sbin/bar --quux

After:

    /usr/bin/foo \
        && /sbin/bar --quux

### COPY

`COPY` behaves differently on files and directories, so we use `rsync` to emulate *recursive
content copying* on directories.

If `--from` argument is given, it becomes just a comment, because unlike Docker images (and ogres),
shell scripts don't have layers.

Before:

    COPY --from=composer foo.sh /usr/local/bin/

After:

    for i in foo.sh; do
            test -d "$i" && i="$i/"
            rsync -a "$i" /usr/local/bin/ # --from=composer
    done

### WORKDIR

Before:

    WORKDIR /var/lib/pgsql/10.1

After:

    mkdir -p /var/lib/pgsql/10.1 && cd /var/lib/pgsql/10.1

### ADD

`ADD` has [many rules](https://docs.docker.com/v17.09/engine/reference/builder/#add), and transforms
into a fairly large snippet.

Before:

    ADD https://example.org/foo.bin /opt

After:

    if echo "/opt" | grep -q '/$'; then
            mkdir -p "/opt";
    else
            mkdir -p "$(dirname "/opt")";
    fi

    for i in https://example.org/foo.bin; do
            if echo "$i" | grep -q '^\(https\?\|ftp\)://'; then
                    if echo "/opt" | grep -q '/$'; then
                            (cd "/opt" && wget -q "$i");
                    else
                            wget -q -O "/opt" "$i";
                    fi
            elif test -d "$i"; then
                    rsync -a "$i/" "/opt";
            elif tar -tf "$i" >/dev/null 2>&1; then
                    mkdir -p "/opt" && tar -C "/opt" -xf "$i";
            else
                    rsync -a "$i" "/opt";
            fi
    done

## Copyright

Copyright 2018, Development Gateway

This program is free software: you can redistribute it and/or modify it under the terms of
the GNU General Public License as published by the Free Software Foundation, either version 3 of
the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not,
see <https://www.gnu.org/licenses/>.
