#!/bin/bash -xl

LOG="$(mktemp)"

xvfb-run -a /opt/netbeans/bin/netbeans --modules --refresh --update-all --nosplash >"${LOG}" 2>&1 &
NETBEANS_PID=$!

while [ -d /proc/${NETBEANS_PID} ] && ! grep -q updates=0 "${LOG}"; do
  sleep 5s
done
cat "${LOG}"
rm "${LOG}"

[ -d /proc/${NETBEANS_PID} ] && kill ${NETBEANS_PID}

exit 0
