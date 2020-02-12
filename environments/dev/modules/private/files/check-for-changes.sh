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

TIME="$(date '+%l:%M%p')"
echo "tooltip:${TIME} Scanning for changes..." > ${PIPE}
rm "${CHANGED}" 2>/dev/null

find ${ROOT} -xdev -name .git -type d -not -ipath '*/.tmp/*' -not -ipath '*/pkg/*' -prune | while read D; do
  cd "${D}/.." >/dev/null
  git status --porcelain --branch > "${STATUS}"
  if pending "${STATUS}"; then
    echo $(dirname "${D}"): >> "${CHANGED}"
    sed -e 's/^/  - "/' -e 's/$/"/' "${STATUS}" >> "${CHANGED}"
    echo >> "${CHANGED}"
  fi
  cd - >/dev/null
done

find ${ROOT} -xdev -name .svn -type d -not -ipath '*/.tmp/*' -prune | while read D; do
  cd "${D}/.." >/dev/null
  svn status > "${STATUS}"
  if [ -s "${STATUS}" ]; then
    echo $(dirname "${D}"): >> "${CHANGED}"
    sed -e 's/^/  - "/' -e 's/$/"/' "${STATUS}" >> "${CHANGED}"
    echo >> "${CHANGED}"
  fi
  cd - >/dev/null
done

TIME="$(date '+%l:%M%p')"
if [ -s "${CHANGED}" ]; then
  echo 'icon:emblem-important' > ${PIPE}
  echo "tooltip:${TIME} Changes found, not safe to destroy box" > ${PIPE}
else
  echo 'icon:emblem-generic' > ${PIPE}
  echo "tooltip:${TIME} No changes found, safe to destroy box" > ${PIPE}
fi

exit 0
