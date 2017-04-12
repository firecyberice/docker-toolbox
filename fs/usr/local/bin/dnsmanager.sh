#!/bin/bash
set -e +x

function dnsupdater (){
  local query="${1}"
  if [[ $# -eq 2 ]]; then
    local key="${2}"
    if [[ -f "$key" ]]; then
      local AUTH="-k $key"
    else
      local AUTH="-y $key"
    fi
  fi
  echo "create command"
  local nsupcmd="printf \"server %s %s\nzone %s\n%bsend\nquit\" \"${DNS_SERVER}\" \"${DNS_PORT}\" \"${DNS_ZONE}\" \"${query}\"| nsupdate -v -d ${AUTH}"
#  local nsupcmd="printf \"%s\" \"${query}\" | nsupdate -v -d ${AUTH}"
  echo "${nsupcmd}"
  echo "exec command"
  local nsupdres="$(eval ${nsupcmd})"
  echo "${nsupdres}"
}

function querybuilder (){
  local domain="${1}"
  local ip="${2}"
  local mode="${3:=update}"

  case "${mode}" in
    "delete")
        local query="update delete ${domain}.${DNS_ZONE}\nupdate delete *.${domain}.${DNS_ZONE}\n"
      ;;
    "add")
        local query="update add ${domain}.${DNS_ZONE}. 60 A ${ip}\n"
      ;;
    "addcname")
        local query="update add *.${domain}.${DNS_ZONE}. 60 CNAME ${domain}.${DNS_ZONE}.\n"
      ;;
    "update")
        local query="update delete ${domain}.${DNS_ZONE}\nupdate add ${domain}.${DNS_ZONE}. 60 A ${ip}\n"
      ;;
    *)
        exit 1
      ;;
  esac
  echo "${query}"
#  printf "server %s %s\nzone %s\n%bsend\nquit" "${DNS_SERVER}" "${DNS_PORT}" "${DNS_ZONE}" "${query}"
}

function main_dns(){
  local IP=""
  if [[ ! -z "${ID}" ]]; then
    IP=$(docker-machine ip ${ID})
  fi
  if [[ -z "${IP}" && "${1}" == "update" ]]; then
    read -rp "Please enter IPv4 address: " IP
  fi
  local query="$(querybuilder "${NAME}" "${IP}" "${1}")"
  echo -e "\n\ncreated query\n${query}\n"
  dnsupdater "${query}" "${DNSSEC_KEY}"
}

function main_checkdns(){
  [ "${DNS_PORT:-}" ] && DNS_PORT="-p $DNS_PORT"
  echo "check ${NAME}.${DNS_ZONE} against ${DNS_SERVER}"
  dig +short ${DNS_PORT} @"${DNS_SERVER}" "${NAME}.${DNS_ZONE}"
}

function usage(){
cat <<EOM
Options:
    -i ID, -id=ID                 Name of docker-machine.
    -n NAME, --name=NAME          Hostname
    --help                        Shows this help.

  All NAME values get ${DNS_ZONE} as suffix.
Commands:
    check            --name=NAME    Check if the hostname is set.
    add     --id=ID  --name=NAME    Add the NAME as NAME.${DNS_ZONE} for docker-machine with the id <ID>.
    addcname         --name=NAME    Add a wildcard CNAME record for NAME.
    delete           --name=NAME    Delete all subdomains of that name and the name.
    update [--id=ID] --name=NAME    Update this NAME with the ip of docker-machine <ID>

EOM
}

#--------------#
# MAIN PROGRAM #
#--------------#

: "${DNS_SERVER:=localhost}"
# : "${DNS_PORT}"
# : "${DNS_ZONE}"
# : "${DNSSEC_KEY}"

while [[ $# -gt 0 ]]
  do
    case "${1}" in
      add|addcname|delete|update|check)
        CMD="${1}"
        shift 1
      ;;
      -i)
        ID="${2}"
#       if [[ "${ID}" == "" ]]; then break; fi
        [ "${ID:-}" ] || break
        shift 2

      ;;
      --id=*)
        ID="${1#*=}"
        shift 1
      ;;
      -n)
        NAME="${2}"
#        if [[ "${NAME}" == "" ]]; then break; fi
        [ "${NAME:-}" ] || break
        shift 2
      ;;
      --name=*)
        NAME="${1#*=}"
        shift 1
      ;;
      --help)
        usage
        exit 1
      ;;
      *)
        echo "Unknown argument: $1"
        usage
        exit 1
      ;;
  esac
done

if [[ ! -z "${SERVERID}" ]]; then
  ID="${SERVERID}"
fi

if [[ ! -z "${SERVERNAME}" ]]; then
  NAME="${SERVERNAME}"
fi

  case "${CMD}" in
    check)
        if [[ "${NAME}" == "" ]]; then
          echo "NAME is needed here."
        else
          main_checkdns
        fi
      ;;
    addcname|delete|update)
        if [[ "${NAME}" == "" ]]; then
          echo "NAME is needed here."
        else
          main_dns "${CMD}"
        fi
      ;;
    add)
        if [[ "${ID}" == "" || "${NAME}" == "" ]]; then
          echo "ID and NAME are needed here."
        else
          main_dns add
        fi
      ;;
    *)
      usage
      exit 1
      ;;
  esac

exit 0

# curl dyndns *.${DNSNAME}.${DOMAIN} => ${IP}
# nsupdate.sh ip.homenet2go.de home 127.0.0.1 DYN_IP:vBhBG0egEtzVcP+...iic6Wg==
#  query="$(querybuilder <domain> <zone> <ip> [add|delete|update] [server])"
