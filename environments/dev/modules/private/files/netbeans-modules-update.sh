#!/bin/bash -xl

LOG="$(mktemp)"

# When installing modules using --install, if the module is already installed it is reported as it can't be found, but the install continues
# with other uninstalled plugins. The error message can be ignored.

# --update-all MUST be last because the script uses it's output to determine when to kill NetBeans

xvfb-run -a /opt/netbeans/bin/netbeans --nosplash --modules --refresh --install $(grep -v '^#' /opt/netbeans-plugins.txt) --update-all >"${LOG}" 2>&1 &
NETBEANS_PID=$!

while [ -d /proc/${NETBEANS_PID} ] && ! grep -q updates=0 "${LOG}"; do
  sleep 5s
done
cat "${LOG}"
rm "${LOG}"

#[ -d /proc/${NETBEANS_PID} ] && pkill ${NETBEANS_PID}
killall Xvfb

exit 0
