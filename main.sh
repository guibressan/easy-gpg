#!/usr/bin/env bash
####################
set -e
####################
readonly CFG_FILE_PATH=/tmp/easygpgcfg 
readonly REL_DIR="$(dirname ${0})"
readonly DATA_PATH="${REL_DIR}/data"
readonly VERSION="v0.1.1"
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
imp_pubkey(){
  local file_name="${1}"
  if [ -z "${file_name}" ]; then
    printf 'Expected parameter: <pubkey_file_name>\n' 1>&2; return 1
  fi
  local pubkey_path="${DATA_PATH}/${file_name}"
  if ! [ -e "${pubkey_path}" ]; then
    printf "Pubkey file must be at the path: ${pubkey_path}\n" 1>&2; return 1
  fi

  printf "Importing pubkey at ${pubkey_path}\n"
  gpg --import "${pubkey_path}"
}
encrypt_file(){
  local file_name="${1}"
  local identity_email="${2}"
  local recipient_email="${3}"
  if [ -z "${file_name}" ] || [ -z "${identity_email}" ] || [ -z "${recipient_email}" ]; then
    printf 'expected parameters: <file_name> <local_identity_email> <recipient_email>\n' 1>&2; return 1
  fi
  local plaintext_path="${DATA_PATH}/${file_name}"
  if ! [ -e ${plaintext_path} ]; then
    printf "Plaintext file must be at: ${plaintext_path}\n" 1>&2; return 1
  fi

  local ciphertext_target="${DATA_PATH}/${file_name}.encrypted"
  printf "Encrypting file at: ${plaintext_path}\nCiphertext at: ${ciphertext_target}\n"
  gpg -se -u ${identity_email} -r ${recipient_email} --output ${ciphertext_target} ${plaintext_path}
}
decrypt_file(){
  local file_name="${1}"
  if [ -z "${file_name}" ]; then
    printf 'expected parameter: <file_name>\n' 1>&2; return 1
  fi
  local ciphertext_path="${DATA_PATH}/${file_name}"
if ! [ -e "${ciphertext_path}" ]; then
  printf "Ciphertext file must be at: ${ciphertext_path}\n" 1>&2; return 1
fi
  
  local plaintext_target="${DATA_PATH}/${file_name}.plaintext"
  printf "Decrypting file: ${ciphertext_path}\nPlaintext should be stored at ${plaintext_target}\n"
  gpg -d --output "${plaintext_target}" "${ciphertext_path}"
}
print_version(){
  printf "EasyGPG ${VERSION}\n"
}
####################
mkdirs
####################
case ${1} in
  new_identity) gen_key "${2}" "${3}" ;;
  delete_identity) del_sec_key "${2}" ;;
  export_public_key) exp_pubkey "${2}" ;;
  import_public_key) imp_pubkey "${2}" ;;
  encrypt_file) encrypt_file "${2}" "${3}" "${4}" ;;
  decrypt_file) decrypt_file "${2}" ;;
  version | -v | --version) print_version ;;
  *) printf 'Usage: < new_identity | delete_identity | export_public_key | import_public_key | encrypt_file | decrypt_file | help >\n' 1>&2; exit 1 ;;
esac
