#!/bin/sed -f
# Convert Dockerfile to shell script.
# Copyright 2018, Development Gateway, GPLv3+

# comment out other instructions
/^[[:space:]]*\<\(FROM\|CMD\|LABEL\|MAINTAINER\|EXPOSE\|ADD\|ENTRYPOINT\|VOLUME\|USER\|ARG\|ONBUILD\|STOPSIGNAL\|HEALTHCHECK\|SHELL\)\>/I s/^[[:space:]]*/# /;

# ENV instructions become export commands
s/^[[:space:]]*ENV[[:space:]]\+\([^[:space:]]\+\)[[:space:]]\+\(.\+\)/export \1='\2'/i;

# RUN get executed literally, including line wraps
s/^[[:space:]]*RUN[[:space:]]\+//i;

# COPY behaves differently on files and directories
s/^[[:space:]]*COPY\([[:space:]]\+--from=[^[:space:]]\+\)*\(\([[:space:]]\+[^[:space:]]\+\)\+\)\([[:space:]]\+[^[:space:]]\+\)[[:space:]]*/for i in\2; do\n\ttest -d "$i" \&\& i="$i\/"\n\trsync -a "$i" \4\ndone/i

# imitate WORKDIR behavior
s/^[[:space:]]*WORKDIR[[:space:]]\+\(.\+\)/mkdir \1 \&\& cd \1/i
