#!/bin/sh
# fix-xauth.sh: repair X authority locking errors

# 1. Ensure DISPLAY is set
if [ -z "$DISPLAY" ]; then
  export DISPLAY=":0"
fi

# 2. Define paths
UID=$(id -u)
RUNDIR="/run/user/$UID"
LOCK="$RUNDIR/lyxauth-c"
AUTH="$RUNDIR/lyxauth"

# 3. Remove only the stale lock file
rm -f "$LOCK"

# 4. Ensure runtime dir exists and is secure
mkdir -p "$RUNDIR"
chmod 700 "$RUNDIR"

# 5. Prepare the authority file in /run/user
touch "$AUTH"
chmod 600 "$AUTH"
export XAUTHORITY="$AUTH"

# 6. Try to generate a fresh cookie
if ! xauth generate "$DISPLAY" . trusted; then
  # fallback to mcookie if available
  if command -v mcookie >/dev/null 2>&1; then
    COOKIE=$(mcookie)
    xauth add "$DISPLAY" . "$COOKIE"
  else
    echo "Error: xauth generate failed and mcookie not found" >&2
    exit 1
  fi
fi

# 7. If still empty, switch to ~/.Xauthority
if [ -z "$(xauth list)" ]; then
  export XAUTHORITY="$HOME/.Xauthority"
  touch "$XAUTHORITY"
  chmod 600 "$XAUTHORITY"
  if ! xauth generate "$DISPLAY" . trusted && command -v mcookie >/dev/null 2>&1; then
    COOKIE=$(mcookie)
    xauth add "$DISPLAY" . "$COOKIE"
  fi
fi

# 8. Show the resulting entries
echo "Final xauth entries in $XAUTHORITY:"
xauth list
