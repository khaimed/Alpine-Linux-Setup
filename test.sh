#!/bin/sh

# Determine UID and paths
UID=$(id -u)
RUNDIR="/run/user/$UID"
LOCK="$RUNDIR/lyxauth-c"
AUTH="$RUNDIR/lyxauth"

# 1. Remove only the stale lock file (if it exists)
[ -e "$LOCK" ] && rm -f "$LOCK"

# 2. Make sure the runtime dir exists and is secure
mkdir -p "$RUNDIR"
chmod 700 "$RUNDIR"

# 3. Prepare the authority file itself
touch "$AUTH"
chmod 600 "$AUTH"
export XAUTHORITY="$AUTH"

# 4. (Re)generate a fresh MIT-MAGIC-COOKIE for your display
xauth generate "$DISPLAY" . trusted

# 5. Verify the entry
echo "Current xauth entries:"
xauth list
