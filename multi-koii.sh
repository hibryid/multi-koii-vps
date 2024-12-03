#!/bin/bash

source .env
COMMAND=$1
SC_NUMBER=$NODES_RANGE

echo "=== The command $COMMAND is selected, processing.. ==="

nodes_configs_folder="configs/nodes"
task_ids_file="$nodes_configs_folder/task-ids"
node_vars_file="$nodes_configs_folder/node-vars"
old_task_ids_file="$nodes_configs_folder/old-task-ids"
stakes_file="$nodes_configs_folder/stakes"
proxies_file="$nodes_configs_folder/proxies"


task_ids_aka_array=$(echo -e "$(cat $task_ids_file 2>/dev/null)\n$DEFAULT_TASK_IDS" | \
                      grep -oP '\K[A-Za-z0-9]+' | sort | uniq | tr '\n' ' ')
old_task_ids_aka_array=$(echo -e "$(cat $old_task_ids_file 2>/dev/null)\n$DEFAULT_OLD_TASK_IDS" | \
                          grep -oP '\K[A-Za-z0-9]+' | sort | uniq | tr '\n' ' ')


ask_user() {
  question=$1
  default_choice="y"  # Set default choice to 'y' (for yes) or 'n' (for no)
  while true; do
    read -p "$question (Y/n): " response
    response=${response:-$default_choice}  # Use default choice if response is empty
    case "$response" in
      [yY][eE][sS]|[yY])
        echo "Continuing..."
        return 0
        ;;
      [nN][oO]|[nN])
        echo "Stopping..."
        return 1
        ;;
      *)
        echo "Invalid input. Please enter 'y' for yes or 'n' for no."
        ;;
    esac
  done
}

update_images() {
  if ask_user "download koii image?"; then
    folder="images"
    if [ ! -d "$folder" ]; then
      mkdir -p "$folder"
      echo "Folder created: $folder"
    fi
    docker pull public.ecr.aws/koii-network/task_node"$KOII_IMAGE_VERSION"
    docker save public.ecr.aws/koii-network/task_node"$KOII_IMAGE_VERSION" > images/task-node.tar
  fi


  if ask_user "rebuild images?"; then
    cd configs/docker/koii && docker build --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" -t local/koii . && cd - || return
#		cd configs/docker/koii-checker && docker build --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" -t local/koii-checker . && cd - || return
#		cd configs/docker/koii-dind && docker build --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" -t local/koii-dind . && cd - || return
    # cd configs/docker/koii-alt && docker build --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" -t local/koii-alt . && cd - || return
  fi

}


unstake() {
  echo 0
}

claim() {
  exho 0
}

get_submissions() {
  number=$1
  task_info=$2
  total_submissions=$(echo "$task_info" | jq '.submissions | to_entries | .[-5:] | from_entries')
  if [[ "$task_type" == "Koii" ]]; then
    wallet_name="staking_wallet"
  else
    wallet_name="staking_wallet_kpl"
  fi
  staking_address="$(koii address -k koii-keys/koii-${number}/namespace/${wallet_name}.json 2>/dev/null || echo '')"
  count_node_submissions=$(echo "$total_submissions" |
                          jq --arg ADDRESS "$staking_address" '[ .[] | keys[] | select(. == $ADDRESS) ] | length')
  echo "$count_node_submissions"
}

get_addresses() {
  number=$1
  system_key="$(koii address -k koii-keys/koii-${number}/wallet/id.json)"
  staking_address="$(koii address -k koii-keys/koii-${number}/namespace/staking_wallet.json 2>/dev/null || echo 'None')"
  staking_address_kpl="$(koii address -k koii-keys/koii-${number}/namespace/staking_wallet_kpl.json 2>/dev/null || echo 'None')"

  echo -e "koii-$number:"
  echo -e "system key: \t$system_key \nstaking: \t$staking_address \nstaking kpl: \t$staking_address_kpl"
}

get_balances() {
  number=$1
  system_key="$(koii balance -k koii-keys/koii-${number}/wallet/id.json)"
  staking_balance="$(koii balance -k koii-keys/koii-${number}/namespace/staking_wallet.json 2>/dev/null || echo 'None')"
  staking_balance_kpl="$(koii balance -k koii-keys/koii-${number}/namespace/staking_wallet_kpl.json 2>/dev/null || echo 'None')"

  echo -e "koii-$number:"
  echo -e "system key: \t$system_key \nstaking: \t$staking_balance \nstaking kpl: \t$staking_balance_kpl"
}


get_rewards() {
  number=$1
  task_info=$2
  task_type=$(echo "$task_info" | jq --raw-output '.task_type')
  if [[ "$task_type" == "Koii" ]]; then
    wallet_name="staking_wallet"
  else
    wallet_name="staking_wallet_kpl"
  fi
  staking_address="$(koii-keygen pubkey koii-keys/koii-${number}/namespace/${wallet_name}.json 2>/dev/null || echo 'None')"
  raw_balance=$(echo "$task_info" | jq --arg ADDRESS "$staking_address" '.available_balances[$ADDRESS]')
  balance=$(echo "scale=2; $raw_balance / 1000000000" | bc -l 2>/dev/null || echo "0.00")
  echo "$balance"

}

show_stake() {
  number=$1
  task_info=$2
  task_type=$(echo "$task_info" | jq --raw-output '.task_type')
  if [[ "$task_type" == "Koii" ]]; then
    wallet_name="staking_wallet"
  else
    wallet_name="staking_wallet_kpl"
  fi
  staking_address="$(koii-keygen pubkey koii-keys/koii-${number}/namespace/${wallet_name}.json 2>/dev/null || echo 'None')"

  raw_stake=$(echo "$task_info" | jq --arg ADDRESS "$staking_address" '.stake_list[$ADDRESS]')
  stake=$( printf '%.2f\n' $(echo "scale=2; $raw_stake / 1000000000" | bc -l 2>/dev/null ) || echo "Error")
  echo "$stake"
}


set_range() {
  sed -i "s/^NODES_RANGE=.*/NODES_RANGE=$1/g" .env
  echo "Done"
}

get_padding_width() {
    local padding=$(echo $1 | cut -d'-' -f1)
    echo ${#padding}
}

# Function to extract range numbers
    get_range() {
        local input=$1
        local start=$(echo $input | cut -d'-' -f1)
        local end=$(echo $input | cut -d'-' -f2)

        # Remove leading zeros for numeric comparison
        start=$(echo $start | sed 's/^0*//')
        end=$(echo $end | sed 's/^0*//')

        echo "$start $end"
    }

# Function to generate sequence
generate_sequence() {
    local start=$1
    local end=$2
    local padding=$3

    local result=""
    for ((i=start; i<=end; i++)); do
        # Format number with proper padding
        printf -v padded_num "%0${padding}d" $i
        result+="$padded_num "
    done

    # Remove trailing space
    echo "${result% }"
}

function get_task_info() {
  i=$1
  task_info=$(npx tsx rpc.ts task-info "$i" 2>/dev/null)
  task_type=$(echo "$task_info" | head -n1 | grep -io "Koii\|KPL")
  echo "$task_info" |\
    sed '/^On KPL Task Operations/d;/On Koii Task Operations/d' |\
    jq --arg ID "$i" --arg TYPE "$task_type" '. + {"task_id": $ID, "task_type": $TYPE}'
}

tasks_responses=()
if [[ "$COMMAND" == "show-rewards" || "$COMMAND" == "claim" ||
      "$COMMAND" == "claim-to-nodes" || "$COMMAND" == "unstake" ||
      "$COMMAND" == "show-stakes" || "$COMMAND" == "show-submissions" ]];then

  for i in $task_ids_aka_array; do
    available_info=$(get_task_info "$i")
    if [ -z "$available_info" ];then
      echo "ERROR: something went wrong in receiving response from RPC"
      exit
    fi
    tasks_responses+=("$available_info")
  done

elif [[ "$COMMAND" == "withdraw-unstaked" || "$COMMAND" == "claim-from-old-tasks" ]]; then

  for i in $old_task_ids_aka_array; do
    available_info=$(get_task_info "$i")
    tasks_responses+=("$available_info")
  done
fi


if [[ "$COMMAND" == "unstake" || "$COMMAND" == "claim" || "$COMMAND" == "claim-to-nodes" || "$COMMAND" == "claim-from-old-tasks" || "$COMMAND" == "withdraw-unstaked" ]];then
  echo "will be added soon"
  exit
fi

if [[ "$COMMAND" == "update-images" || "$COMMAND" == "download-images" ]];then
  update_images
  exit 0
fi

if [[ "$COMMAND" == "set-range" ]];then
  set_range "$2"
  exit 0
fi

if [ -z "$2" ];then
  SC_NUMBER=$NODES_RANGE
else
  SC_NUMBER=$2
fi

if [ -z "$SC_NUMBER" ]; then
  echo "No nodes range provided"
  exit 1
fi

if [[ "$COMMAND" == "up-webtop" ]];then
  if [ -z "$WEBTOP_PASSWORD" ]; then
    echo "Error: no password for webtop was provided"
    exit 1
  fi
fi

if [[ $SC_NUMBER == *-* ]]; then
  RANGE_NUMBER=$(echo "$SC_NUMBER" | sed 's/-/ /g')
#  range=$(seq -w $RANGE_NUMBER)
  total_nodes=$(echo "$RANGE_NUMBER" | awk '{print $2}')
  padding=$(get_padding_width "$SC_NUMBER")
  read -r start end <<< "$(get_range "$SC_NUMBER")"
  range=$(generate_sequence "$start" "$end" "$padding")
else
  padding=$(get_padding_width "$SC_NUMBER")
  read -r start end <<< "$(get_range "$SC_NUMBER")"
  range=$(generate_sequence "$start" "$end" "$padding")
  total_nodes=$SC_NUMBER
fi

# check if network is created
max_net_number=$(awk 'BEGIN { rounded = int('"$((10#${total_nodes}))/250"'+0.999999); print rounded }')
for i in $(seq $max_net_number); do
  docker network create koii-net-$i 1>/dev/null 2>/dev/null
done


announce_settings() {
  i=$1
  proxy=$2
  tasks=$3

  echo "koii-$1 summary:"
  if [[ -n "$proxy" ]]; then
      echo "Proxy: yes"
  else
      echo "Proxy: no"
  fi

  if [[ "$tasks" != "$DEFAULT_TASK_IDS" ]]; then
      echo "Tasks: custom"
  else
      echo "Tasks: default or same"
  fi
}

main() {
  for i in $range; do
    current_proxy=$(cat $proxies_file 2>/dev/null | sed "${i}q;d" | sed 's/socks5:\/\///g')
    current_task_ids=$(cat $task_ids_file 2>/dev/null | sed "${i}q;d" | grep -oP '\K[A-Za-z0-9]+' | paste -sd',' - | sed "s/^$/$DEFAULT_TASK_IDS/" || echo "$DEFAULT_TASK_IDS")
    current_task_stakes=$(cat $stakes_file 2>/dev/null | sed "${i}q;d" | grep -oP '\K[A-Za-z0-9]+' | paste -sd',' - | sed "s/^$/$DEFAULT_TASK_STAKES/" || echo "$DEFAULT_TASK_STAKES")
    current_node_vars=$(cat $node_vars_file 2>/dev/null | sed "${i}q;d" | tr ' ,;' '\n' | grep .)

    # round even 1.00001 to 2, zeros before numbers like 0020 expected
    net_number=$(awk 'BEGIN { rounded = int('"$((10#${i}))/250"'+0.999999); print rounded }')

    up_commands='{
      "up": "docker-compose.yml", "up-alt": "docker-compose-alt.yml",
      "up-old": "docker-compose.yml","up-sdind": "docker-compose-sdind.yml",
      "up-checker": "docker-compose-checker.yml"
    }'

    if echo "$up_commands" | jq -e --arg key "$COMMAND" '. | has($key)' > /dev/null; then
      announce_settings "$i" "$current_proxy" "$current_task_ids"
      compose_file=$(echo "$up_commands" | jq -r --arg key "$COMMAND" '.[$key]')
      NUMBER=$i TASK_IDS=$current_task_ids TASK_STAKES=$current_task_stakes PROXY=$current_proxy \
              NODE_VARS=$current_node_vars NETNUMBER=$net_number HOST_UID=$(id -u) HOST_GID=$(id -g) \
                docker compose -p "$i" -f "$compose_file" up -d

    elif [[ "$COMMAND" == "up-webtop" ]];then
      echo "starting koii-$i with webtop port: $WEBTOP_IP:$((30000+i))"
      NUMBER=$i NETNUMBER=$net_number CUSTOM_USER=$WEBTOP_CUSTOM_USER PASSWORD=$WEBTOP_PASSWORD \
            IP=$WEBTOP_IP PORT=$((30000+i)) HOST_UID=$(id -u) HOST_GID=$(id -g) \
                docker compose -p "$i" -f "docker-compose-webtop.yml" up -d

    elif [[ "$COMMAND" == "restart" ]];then
      echo "Restarting koii-$i.."
      docker compose -p "$i" restart

    elif [[ "$COMMAND" == "down" ]];then
      docker compose -p "$i" down -v

    elif [[ "$COMMAND" == "kill" ]];then
      docker compose -p "$i" kill
      docker compose -p "$i" down -v

    elif [[ "$COMMAND" == "show-addresses" ]];then
      get_addresses "$i"

    elif [[ "$COMMAND" == "show-balances" ]];then
      get_balances "$i"

    elif [[ "$COMMAND" == "show-rewards" || "$COMMAND" == "get-rewards" ]];then
      echo "koii-$i rewards:"

      for task in "${tasks_responses[@]}"; do
        task_id=$(echo "$task" | jq --raw-output ".task_id")
        if echo "$current_task_ids" | grep -q "$task_id"; then
          task_name=$(echo "$task" | jq ".task_name")
          task_type=$(echo "$task" | jq --raw-output ".task_type")
          rewards_amount=$(get_rewards "$i" "$task")
          echo "$task_id ($task_name) $task_type: $rewards_amount"
        fi
      done

    elif [[ "$COMMAND" == "show-stakes" ]];then
      echo "koii-$i stakes:"


      for task in "${tasks_responses[@]}"; do
        task_id=$(echo "$task" | jq --raw-output ".task_id")

        if echo "$current_task_ids" | grep -q "$task_id"; then
          task_name=$(echo "$task" | jq ".task_name")
          task_type=$(echo "$task" | jq --raw-output ".task_type")
          stake_amount=$(show_stake "$i" "$task")
          echo "$task_id ($task_name) $task_type: $stake_amount"
        fi

      done

    elif [[ "$COMMAND" == "show-submissions" ]];then
      echo "koii-$i submissions:"

      for task in "${tasks_responses[@]}"; do
        task_id=$(echo "$task" | jq --raw-output ".task_id")
        if echo "$current_task_ids" | grep -q "$task_id"; then
          task_name=$(echo "$task" | jq ".task_name")
          task_type=$(echo "$task" | jq --raw-output ".task_type")
          count=$(get_submissions "$i" "$task")
          echo "$task_id ($task_name): $count / 5 rounds"
        fi
      done

    elif [[ "$COMMAND" == "claim" || "$COMMAND" == "claim-to-nodes" || "$COMMAND" == "claim-from-old-tasks" || "$COMMAND" == "withdraw-unstaked" ]];then
      balance=$(get_rewards "$i" "$task")
      echo "koii-$i: $balance KOII"
      if (( $(echo "$balance > 0" | bc -l) )); then
        claim "$i"
      else
        echo "koii-$i: NO balance"
      fi

    elif [[ "$COMMAND" == "unstake" ]];then
      unstake "$i"

    elif [[ "$COMMAND" == "logs" ]];then
      docker logs -n1000 -f koii-$i
      exit 0

    else
      echo "UNKNOWN COMMAND"
      echo "
      commands are:
      up
      up-webtop
      down
      show-balances
      show-rewards
      show-stakes
      claim
      claim-from-old-tasks
      claim-to-nodes
      set-range
      COMMAND <NODE_NUMBER>
      "

      exit 1
    fi
  done
}

main