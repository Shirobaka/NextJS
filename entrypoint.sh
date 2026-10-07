#!/bin/bash
# Pelican Panel entrypoint: runs the egg's startup command in /home/container.
cd /home/container || exit 1
 
# Make the container's internal IP available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP
 
# Next.js reads PORT. Default it to the port Pelican allocated to the server,
# so `next start` / `node server.js` listen on the right one without flags.
export PORT="${PORT:-${SERVER_PORT}}"
 
# Show the runtime versions in the console.
printf 'Node.js %s, npm %s\n' "$(node -v)" "$(npm -v)"
 
# The panel sends the startup command with {{VARIABLE}} placeholders.
# Convert them to ${VARIABLE} so the shell expands them.
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"
 
# Run the server.
eval "${MODIFIED_STARTUP}"