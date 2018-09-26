for i in ARGS; do
  test -d "$i" && i="$i/"
  rsync -a "$i" DEST
done
