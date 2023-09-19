#!/usr/bin/env bash
####################
set -e
####################
readonly CFG_FILE_PATH=/tmp/easygpgcfg
readonly REL_DIR="$(dirname ${0})"
readonly DATA_PATH="${REL_DIR}/data"
####################
mkdirs() {
  if ! [ -e "${DATA_PATH}" ]; then 
    mkdir -p "${DATA_PATH}"
  fi
}
gen_key(){
  local name="${1}"
  local email="${2}"
  if [ -z "${name}" ] || [ -z "${email}" ]; then
    printf 'Expected parameters: <name> <email>\n' 1>&2; return 1
  fi
  printf "Insert the password for the new key: "
  read password
  cat << EOF > ${CFG_FILE_PATH}
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: ${name}
Name-Email: ${email}
Expire-Date: 0
Passphrase: ${password}
%commit
EOF
  gpg  --batch --gen-key ${CFG_FILE_PATH}
  rm -rf ${CFG_FILE_PATH}
}
del_sec_key(){
  local email="${1}"
  if [ -z "${email}" ]; then
    printf 'Expected parameter: <email>\n' 1>&2; return 1
  fi

  gpg --delete-secret-keys ${email}
  gpg --delete-keys ${email}
}
exp_pubkey() {
  local email="${1}"
  if [ -z "${email}" ]; then
    printf 'Expected parameter: <email>\n' 1>&2; return 1
  fi

  gpg --export --armor --output ${DATA_PATH}/"${email}".asc ${email}
  printf "Key exported to: ${DATA_PATH}/"${email}".asc\n"
}
####################
mkdirs
####################
case ${1} in
  new_identity) gen_key "${2}" "${3}" ;;
  delete_identity) del_sec_key "${2}" ;;
  export_public_key) exp_pubkey "${2}" ;;
  *) printf 'Usage: < new_identity | delete_identity | export_public_key | help >\n' 1>&2; exit 1 ;;
esac

# Generate key
# Export public key
# Import public key
# Sign public key
# 
