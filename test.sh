#!/bin/sh

# If DISPLAY isn’t set, assume :0
[ -z "$DISPLAY" ] && export DISPLAY=":0"

# Paths
UID=$(id -u)
RUNDIR="/run/user/$UID"
LOCK="$RUNDIR/lyxauth-c"
AUTH="$RUNDIR/lyxauth"

# 1. Remove stale lock only
[ -e "$LOCK" ] && rm -f "$LOCK"

# 2. Ensure runtime dir exists and is secure
mkdir -p "$RUNDIR"
chmod 700 "$RUNDIR"

# 3. Prepare authority file
touch "$AUTH"
chmod 600 "$AUTH"
export XAUTHORITY="$AUTH"

# 4. (Re)generate MIT-MAGIC-COOKIE for your display
xauth generate "$DISPLAY" . trusted

# 5. Verify
echo "Current xauth entries:"
xauth list
