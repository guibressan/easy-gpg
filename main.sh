#!/usr/bin/env bash
####################
set -e
####################
readonly CFG_FILE_PATH=/tmp/easygpgcfg
####################
gen_key(){
  local id="${1}"
  if [ -z "${id}" ]; then
    printf 'Expected <id>. Example: name@example.com\n' 1>&2; return 1
  fi
  cat << EOF > ${CFG_FILE_PATH}
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Your Name
Name-Email: test@example.com
Expire-Date: 0
Passphrase: YourPassphrase
%commit
EOF
gpg --batch --full-gen-key ${CFG_FILE_PATH}
}
case ${1} in
  new_id) gen_key ${2} ;;
  *) printf 'Usage: < new_id | help >\n' 1>&2; exit 1 ;;
esac
