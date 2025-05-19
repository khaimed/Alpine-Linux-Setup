#!/bin/sh
# ~/.xsession  (or ~/.xinitrc)

# 1) Ensure DISPLAY is set
[ -z "$DISPLAY" ] && export DISPLAY=":0"

# 2) Prepare per-user runtime dir & authority paths
UID=$(id -u)
RUNDIR="/run/user/$UID"
AUTH="$RUNDIR/lyxauth"
LOCK="$AUTH-c"

# 3) Remove only the stale lock
[ -e "$LOCK" ] && rm -f "$LOCK"

# 4) Secure the runtime dir
mkdir -p "$RUNDIR"    && chmod 700 "$RUNDIR"

# 5) Touch & protect the authority file
touch "$AUTH"         && chmod 600 "$AUTH"
export XAUTHORITY="$AUTH"

# 6) Generate or add a cookie if none exists
if ! xauth list | grep -q "$DISPLAY"; then
  if ! xauth generate "$DISPLAY" . trusted 2>/dev/null; then
    # fallback if xauth generate isn’t supported
    COOKIE=$(mcookie)
    xauth add "$DISPLAY" . "$COOKIE"
  fi
fi

# 7) (Optional) print for debug
echo "→ xauth entries for $DISPLAY:"
xauth list

# 8) Finally, launch your WM
exec i3
