#!/bin/sh

SSHDIR=${SSHDIR:-~/.ssh}
CONFDIR=${CONFDIR:-$SSHDIR/config.d}
CONFFILE=${CONFFILE:-$SSHDIR/config}

FAILEDFILE=$CONFFILE.failed
TMPFILE=`mktemp $CONFFILE.XXXXXX` || exit 1
ERRFILE=`mktemp $CONFFILE.err.XXXXXX` || exit 1
trap "{ rm -f \"$TMPFILE\" \"$ERRFILE\"; }" EXIT
NOW=`date '+%Y-%m-%d_%H%M%S'`

# First run?
FIRST_RUN_CHECK=$SSHDIR/.build-config-first-run
if ! [ -f "$FIRST_RUN_CHECK" ]; then
  # Take a backup of the existing config file
  cp "$CONFFILE" "$CONFFILE-$NOW"

  # Make sure confdir exists. If it doesn't, create it
  if ! [ -d "$CONFDIR" ]; then
    mkdir -p "$CONFDIR"
    # Add a README file
    cat << EOF > "$CONFDIR/README"
Put your ssh config files in this directory, or in subdirectories
within this directory. The filenames should have the .conf extension.
EOF
  fi
  if [ -z "$(find -s $CONFDIR -type f -name \*.conf)" ]; then
    # There are no files in CONFDIR.
    # Copy the user's current config file there.
    cp "$CONFFILE" "$CONFDIR/00-general.conf"
  fi
  echo $NOW > "$FIRST_RUN_CHECK"
fi

# Delete any failure from the previous run
rm -f "$FAILEDFILE"

printf "# Generated $NOW\n\n" > "$TMPFILE"

# cat all files, with a header & footer for each
find -s $CONFDIR -type f -name \*.conf -print0 | \
  xargs -0 awk -v confdir="$CONFDIR" 'BEGIN {last_filename = "";} \
      FNR == 1 {if (last_filename==""){last_filename=substr(FILENAME, length(confdir)+2);} \
      else {print "# end "last_filename"\n"; last_filename=substr(FILENAME, length(confdir)+2);}} \
      FNR == 1 { print "# "substr(FILENAME, length(confdir)+2)}; \
      END{print "# end "last_filename;} \
      {print}' > $TMPFILE 2> $ERRFILE

# Check that the command competed, and produced some output
# (this means that the existing config file won't be overwritten
# if no .conf files were found)
if [ $? -eq 0 ] && [ -s "$TMPFILE" ]; then
  mv "$TMPFILE" "$CONFFILE"
else
  if ! [ -s "$TMPFILE" ]; then
    echo No .conf files were found in $CONFDIR >> "$ERRFILE"
  fi
  mv "$TMPFILE" "$FAILEDFILE"
  cat "$ERRFILE" >> "$FAILEDFILE"
  exit 1
fi
