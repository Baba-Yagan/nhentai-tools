#!/bin/bash


file="$1"

case "$file" in
  *.cbz)
    /home/user/.config/lf/preview.sh "$file"
    ;;
  *)
/home/user/.config/lf/pistol-static-linux-xxxxx "$file"
    ;;
esac

exit 0
