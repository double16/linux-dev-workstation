#!/bin/bash

ROOT="${HOME}"
PIPE="/var/local/pending-changes/pipe"
CHANGED="/var/local/pending-changes/changed"
STATUS="/var/local/pending-changes/status"

# Don't run if the pipe doesn't exist
[ -e "${PIPE}" ] || exit 1

function cleanup {
  rm ${STATUS}
}
trap cleanup EXIT

function pending {
  [ -s "$1" ] || return 1
  [ $(wc -l "$1" | cut -d ' ' -f 1) -gt 1 ] && return 0
  grep -qF " [ahead " "$1"
}

echo 'tooltip:Scanning for changes...' > ${PIPE}
rm "${CHANGED}" 2>/dev/null

find ${ROOT} -name .git -type d -not -ipath '*/.tmp/*' -not -ipath '*/pkg/*' -prune | while read D; do
  cd "${D}/.." >/dev/null
  git status --porcelain --branch > "${STATUS}"
  if pending "${STATUS}"; then
    echo $(dirname "${D}"): >> "${CHANGED}"
    sed -e 's/^/  - "/' -e 's/$/"/' "${STATUS}" >> "${CHANGED}"
    echo >> "${CHANGED}"
  fi
  cd - >/dev/null
done

if [ -s "${CHANGED}" ]; then
  echo 'icon:emblem-important' > ${PIPE}
  echo 'tooltip:Changes found, not safe to destroy box' > ${PIPE}
else
  echo 'icon:emblem-generic' > ${PIPE}
  echo 'tooltip:No changes found, safe to destroy box' > ${PIPE}
fi

exit 0
