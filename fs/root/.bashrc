cat << EOM
Available aliases:

dmls => docker-machine ls
dmc  => docker-machine create
di   => docker info as json
dils => docker image ls
did  => docker images --filter dangling=true
dvls => docker volume ls
dnls => docker network ls
dcls => docker container ls

getenv => get environment variables for
	VSPHERE
	DOCKERCLOUD
	DNS

use <docker-machine name> load environment
reinit_swarm <LEADER> <"WORKER1 WORKER2">
create_swarm [SWARMNAME=swarm] [WORKER_PREFIX=worker] [NUM_WORKER=3]

EOM

alias dmls='docker-machine ls'
alias dmc='docker-machine create --driver vmwarevsphere'

alias di='docker info --format="{{json .}}" | jq "."'
alias dils='docker images --format "{{.ID}}\t{{.Repository}}:{{.Tag}}"'
alias did='docker images --filter dangling=true'
alias dvls='docker volume ls'
alias dnls='docker network ls'
alias dcls='docker ps --format="table{{.ID}}\t{{.Image}}\t{{.RunningFor}}\t{{.Status}}\t{{.Names}}"'
alias dps='docker ps --format="table{{.ID}}\t{{.Image}}\t{{.RunningFor}}\t{{.Status}}\t{{.Names}}"'

alias getenv='printenv | grep "VSPHERE\|DOCKER\|DNS" |grep -v "VERSION\|SHA256\|BUCKET\|URL" | sort'

function use(){
  local name="${1}"
  eval $(docker-machine env "${name}")
}

function reinit_swarm(){
  local LEADER="${1}"
  local WORKER="${2}"

  if [[ $# -ne 2 ]]; then
cat <<EOM
usage:
   reinit_swarm LEADER "WORKER1 WORKER2"
EOM
    return 
  else
    docker-machine regenerate-certs --force ${LEADER}
    use ${LEADER}
    docker node rm -f ${WORKER}
    docker swarm leave -f
    docker swarm init
    TOKEN=$(docker swarm join-token -q worker)
    IP=$(docker-machine url ${LEADER})
    IP=${IP##tcp://}
    IP=${IP%%:2376}

    for name in ${WORKER}; do
      docker-machine regenerate-certs --force ${name}
      use ${name}
      docker swarm leave -f
      docker swarm join --token ${TOKEN} ${IP}:2377
    done
  fi
}

function create_swarm(){
  local LEADER="${1:=swarm}"
  local WORKER="${2:=worker}"
  local CONTER="${3:=3}"

  if [[ $# -gt 3 || "${1}" == "help" ]]; then
cat <<EOM
usage:
   create_swarm SWARMNAME [WORKER_PREFIX=worker] [NUM_WORKER=3]
EOM
    return 
  else
    echo "=> Create Leader"
    docker-machine create --driver vmwarevsphere ${LEADER}
    use ${LEADER}
    docker swarm init
    TOKEN=$(docker swarm join-token -q worker)
    IP=$(docker-machine url ${LEADER})
    IP=${IP##tcp://}
    IP=${IP%%:2376}
    echo "<= Leader created"
    for i in $(seq 1 1 $COUNTER); do
      local name="${SWARMNAME}-${WORKER}-${i}"
      echo "=> Creating ${name}"
      docker-machine create --driver vmwarevsphere ${name}
      use ${name}
      docker swarm join --token ${TOKEN} ${IP}:2377
      echo "<= ${name} created"
    done
    use ${LEADER}
    printf "\nvSphere Swarm Cluster\n===================\n"
    docker node ls
  fi
}
