if echo "DEST" | grep -q '/$'; then
  mkdir -p "DEST";
else
  mkdir -p "$(dirname "DEST")";
fi

for i in ARGS; do
  if echo "$i" | grep -q '^\(https\?\|ftp\)://'; then
    if echo "DEST" | grep -q '/$'; then
      (cd "DEST" && wget -q "$i");
    else
      wget -q -O "DEST" "$i";
    fi
  elif test -d "$i"; then
    rsync -a "$i/" "DEST";
  elif tar -tf "$i" >/dev/null 2>&1; then
    mkdir -p "DEST" && tar -C "DEST" -xf "$i";
  else
    rsync -a "$i" "DEST";
  fi
done
