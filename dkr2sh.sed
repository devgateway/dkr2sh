#!/bin/sed -f
# Convert Dockerfile to shell script.
# Copyright 2018, Development Gateway, GPLv3+

# comment out other instructions
/^[[:space:]]*\<\(FROM\|CMD\|LABEL\|MAINTAINER\|EXPOSE\|ENTRYPOINT\|VOLUME\|USER\|ARG\|ONBUILD\|STOPSIGNAL\|HEALTHCHECK\|SHELL\)\>/I s/^[[:space:]]*/# /;

# ENV instructions become export commands
s/^[[:space:]]*ENV[[:space:]]\+\([^[:space:]]\+\)[[:space:]]\+\(.\+\)/export \1='\2'/i;

# RUN get executed literally, including line wraps
s/^[[:space:]]*RUN[[:space:]]\+//i;

# COPY behaves differently on files and directories
# with a "--from" argument
s/^[[:space:]]*COPY\([[:space:]]\+--from=[^[:space:]]\+\)\(\([[:space:]]\+[^[:space:]]\+\)\+\)\([[:space:]]\+[^[:space:]]\+\)[[:space:]]*/for i in\2; do\n\ttest -d "$i" \&\& i="$i\/"\n\trsync -a "$i"\4 #\1\ndone/i
# without "--from" argument
s/^[[:space:]]*COPY\(\([[:space:]]\+[^[:space:]]\+\)\+\)\([[:space:]]\+[^[:space:]]\+\)[[:space:]]*/for i in\1; do\n\ttest -d "$i" \&\& i="$i\/"\n\trsync -a "$i"\3\ndone/i

# ADD
s/^[[:space:]]*ADD\(\([[:space:]]\+[^[:space:]]\+\)\+\)[[:space:]]\+\([^[:space:]]\+\)[[:space:]]*/if echo "\3" | grep -q '\/$'; then\n\tmkdir -p "\3";\nelse\n\tmkdir -p "$(dirname "\3")";\nfi\n\nfor i in\1; do\n\tif echo "$i" | grep -q '^\\(https\\?\\|ftp\\):\/\/'; then\n\t\tif echo "\3" | grep -q '\/$'; then\n\t\t\t(cd "\3" \&\& wget -q "$i");\n\t\telse\n\t\t\twget -q -O "\3" "$i";\n\t\tfi\n\telif test -d "$i"; then\n\t\trsync -a "$i\/" "\3";\n\telif tar -tf "$i" >\/dev\/null 2>\&1; then\n\t\tmkdir -p "\3" \&\& tar -C "\3" -xf "$i";\n\telse\n\t\trsync -a "$i" "\3";\n\tfi\ndone/i

# imitate WORKDIR behavior
s/^[[:space:]]*WORKDIR[[:space:]]\+\(.\+\)/mkdir -p \1 \&\& cd \1/i
