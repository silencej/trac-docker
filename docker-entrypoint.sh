#!/bin/bash

set -e

if [ "$1" = "tracd" ]; then
    if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
        echo >&2 "$0: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"

        echo >&2 "$0: Looking for shell scripts in /docker-entrypoint.d/"
        find "/docker-entrypoint.d/" -follow -type f -print | sort -V | while read -r f; do
            case "$f" in
                *.sh)
                    if [ -x "$f" ]; then
                        echo >&2 "$0: Launching $f";
                        "$f"
                    else
                        # warn on shell scripts without exec bit
                        echo >&2 "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *) echo >&2 "$0: Ignoring $f";;
            esac
        done

        echo >&2 "$0: Configuration complete; ready for start up"
    else
        echo >&2 "$0: No files found in /docker-entrypoint.d/, skipping configuration"
    fi
fi

#----------

if [[ -f "$TRAC_DIR/conf/trac.ini" ]]; then
  echo "$TRAC_DIR already initialized, ignore initenv"
else
  mkdir -p $TRAC_DIR
  trac-admin $TRAC_DIR initenv $TRAC_PROJECT_NAME $DB_LINK
  # trac-admin $TRAC_DIR deploy /tmp/deploy
  # mv /tmp/deploy/* $TRAC_DIR
fi

# htpasswd -b -c $TRAC_DIR/.htpasswd $TRAC_ADMIN_NAME $TRAC_ADMIN_PASSWD
trac-admin $TRAC_DIR permission add $TRAC_ADMIN_NAME TRAC_ADMIN || echo "Ignore"
# chown -R www-data: $TRAC_DIR
# chmod -R 775 $TRAC_DIR

# echo "Listen 8123" >> /etc/apache2/ports.conf
# trac.conf /etc/apache2/sites-available/trac.conf
# sed -i 's|$AUTH_NAME|'"$TRAC_PROJECT_NAME"'|g' /etc/apache2/sites-available/trac.conf
# sed -i 's|$TRAC_DIR|'"$TRAC_DIR"'|g' /etc/apache2/sites-available/trac.conf
# a2dissite 000-default && a2ensite trac.conf
# service apache2 stop && apache2ctl -D FOREGROUND

if [[ -f "$TRAC_DIR/users.htdigest" ]]; then
  echo "$TRAC_DIR/users.htdigest exists, ignore generating it"
else
  digest="$( printf "%s:%s:%s" "$TRAC_ADMIN_NAME" "$TRAC_PROJECT_NAME" "$TRAC_ADMIN_PASSWD" | 
           md5sum | awk '{print $1}' )"
  printf "%s:%s:%s\n" "$TRAC_ADMIN_NAME" "$TRAC_PROJECT_NAME" "$digest" > "$TRAC_DIR/users.htdigest"
fi

# exec "$@"
if [[ "$TRAC_AUTH" != "ACCTMNGR" ]]; then
  tracd --port 8123 -r --auth="*,$TRAC_DIR/users.htdigest,$TRAC_PROJECT_NAME" $TRAC_DIR
else
  tracd --port 8123 -r $TRAC_DIR
fi
