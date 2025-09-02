#!/bin/bash

CONFIG_DIR="$HOME/.cloudflared"
DOMAINS_DIR="$CONFIG_DIR/domains"
mkdir -p "$CONFIG_DIR/pids"
mkdir -p "$DOMAINS_DIR"

# Cargar variables desde .env
# if [[ -f .env ]]; then
#   export $(grep -v '^#' .env | xargs)
# fi

# if [[ -z "$CF_DOMAIN" ]]; then
#   echo -e "\033[0;31m[!] Variable CF_DOMAIN no está definida en .env\033[0m"
#   exit 1
# fi

# Colores
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[0;34m"
COLOR_CYAN="\033[0;36m"
COLOR_RESET="\033[0m"

print_line() {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

extract_port() {
  local config_file="$1"
  if [[ -f "$config_file" ]]; then
    grep -oE 'http://[^:]+:([0-9]+)' "$config_file" | grep -oE '[0-9]+$' | head -1
  fi
}

generate_pet_name() {
  adjectives=(
    "morbid" "sarcastic" "chaotic" "deranged" "manic"
    "nihilistic" "twisted" "grotesque" "unhinged" "macabre"
    "sinister" "eerie" "hysterical" "toxic" "bleak"
    "lunatic" "cryptic" "damned" "grim" "volatile"
    "hollow" "rancid" "spiteful" "vile" "decaying"
    "neurotic" "obsessive" "tormented" "malignant" "ashen"
    "dreadful" "morose" "feral" "cursed" "ghastly"
    "seething" "rotting" "gory" "haunted" "infernal"
    "sickly" "chained" "fractured" "stained" "withering"
    "maddened" "coldblooded" "ravaged" "scorched" "crimson"
  )

  nouns=(
    "ghost" "zombie" "vampire" "skeleton" "demon"
    "witch" "phantom" "wraith" "specter" "goblin"
    "banshee" "ghoul" "mutant" "shade" "reaper"
    "fiend" "creep" "entity" "poltergeist" "devil"
    "succubus" "lich" "abomination" "incubus" "jackal"
    "ravager" "howler" "lurker" "serpent" "fallen"
  )

  adj1="${adjectives[$RANDOM % ${#adjectives[@]}]}"
  adj2="${adjectives[$RANDOM % ${#adjectives[@]}]}"
  noun="${nouns[$RANDOM % ${#nouns[@]}]}"

  echo "$adj1-$adj2-$noun"
}

migrate_env_file() {
  local env_file=".env"
  local migrated_env_file=".env.migrated"
  
  if [[ -f "$env_file" ]]; then
    echo -e "${COLOR_CYAN}[*] Found existing .env file. Migrating to new multi-domain format...${COLOR_RESET}"
    
    # Source the .env file safely
    export $(grep -v '^#' "$env_file" | xargs)
    
    if [[ -n "$CF_DOMAIN" && -n "$CF_API_TOKEN" && -n "$CF_ZONE_ID" ]]; then
      local domain_file="$DOMAINS_DIR/$CF_DOMAIN.conf"
      
      cat > "$domain_file" <<EOF
CF_DOMAIN="$CF_DOMAIN"
CF_API_TOKEN="$CF_API_TOKEN"
CF_ZONE_ID="$CF_ZONE_ID"
EOF
      
      mv "$env_file" "$migrated_env_file"
      
      echo -e "${COLOR_GREEN}[+] Successfully migrated '$CF_DOMAIN' to the new configuration system.${COLOR_RESET}"
      echo -e "${COLOR_YELLOW}[i] Your old .env file has been renamed to .env.migrated.${COLOR_RESET}"
      sleep 2
    else
      echo -e "${COLOR_RED}[!] .env file is missing required variables (CF_DOMAIN, CF_API_TOKEN, CF_ZONE_ID). Migration failed.${COLOR_RESET}"
      sleep 2
    fi
  fi
}

add_domain() {
  echo -e "${COLOR_CYAN}=== Add New Domain ===${COLOR_RESET}"
  echo -n "Enter domain name (e.g., example.com): "
  read domain_name
  if [[ -z "$domain_name" ]]; then
    echo -e "${COLOR_RED}[!] Domain name cannot be empty.${COLOR_RESET}"
    return
  fi

  echo -n "Enter Cloudflare API Token: "
  read api_token
  if [[ -z "$api_token" ]]; then
    echo -e "${COLOR_RED}[!] API Token cannot be empty.${COLOR_RESET}"
    return
  fi

  echo -n "Enter Cloudflare Zone ID: "
  read zone_id
  if [[ -z "$zone_id" ]]; then
    echo -e "${COLOR_RED}[!] Zone ID cannot be empty.${COLOR_RESET}"
    return
  fi

  local domain_file="$DOMAINS_DIR/$domain_name.conf"
  cat > "$domain_file" <<EOF
CF_DOMAIN="$domain_name"
CF_API_TOKEN="$api_token"
CF_ZONE_ID="$zone_id"
EOF
  echo -e "${COLOR_GREEN}[+] Domain '$domain_name' added successfully.${COLOR_RESET}"
  sleep 1
}

list_domains() {
  echo -e "${COLOR_CYAN}=== Configured Domains ===${COLOR_RESET}"
  local domain_files=("$DOMAINS_DIR"/*.conf)
  if [[ ${#domain_files[@]} -eq 1 && ! -e "${domain_files[0]}" ]]; then
    echo -e "${COLOR_YELLOW}No domains configured yet.${COLOR_RESET}"
    return
  fi

  for file in "${domain_files[@]}"; do
    echo "- $(basename "$file" .conf)"
  done
}

delete_domain() {
  echo -e "${COLOR_CYAN}=== Delete Domain ===${COLOR_RESET}"
  list_domains
  echo -n "Enter domain name to delete: "
  read domain_name
  if [[ -z "$domain_name" ]]; then
    echo -e "${COLOR_RED}[!] Domain name cannot be empty.${COLOR_RESET}"
    return
  fi

  local domain_file="$DOMAINS_DIR/$domain_name.conf"
  if [[ -f "$domain_file" ]]; then
    rm "$domain_file"
    echo -e "${COLOR_GREEN}[+] Domain '$domain_name' deleted.${COLOR_RESET}"
  else
    echo -e "${COLOR_RED}[!] Domain '$domain_name' not found.${COLOR_RESET}"
  fi
  sleep 1
}

manage_domains() {
  while true; do
    clear
    echo -e "${COLOR_BLUE}Domain Management${COLOR_RESET}"
    list_domains
    print_line
    echo "1. Add new domain"
    echo "2. Delete domain"
    echo "3. Back to main menu"
    print_line
    echo -n "Choose option: "
    read opt

    case $opt in
      1) add_domain ;;
      2) delete_domain ;;
      3) break ;;
      *) echo -e "${COLOR_RED}[!] Invalid option${COLOR_RESET}" ; sleep 1 ;;
    esac
  done
}

select_domain() {
  while true; do
    clear
    echo -e "${COLOR_BLUE}Select a Domain to Manage${COLOR_RESET}"
    local domain_files=("$DOMAINS_DIR"/*.conf)
    if [[ ${#domain_files[@]} -eq 1 && ! -e "${domain_files[0]}" ]]; then
      echo -e "${COLOR_YELLOW}No domains configured. Please add a domain first.${COLOR_RESET}"
      echo -n "Press Enter to go to Domain Management..."
      read
      manage_domains
      continue
    fi

    local i=1
    local domains=()
    for file in "${domain_files[@]}"; do
      domains+=("$(basename "$file" .conf)")
      echo "$i. ${domains[i-1]}"
      i=$((i+1))
    done
    echo "$i. Back to main menu"
    print_line
    echo -n "Choose option: "
    read opt

    if [[ "$opt" -ge 1 && "$opt" -lt "$i" ]]; then
      local selected_domain="${domains[opt-1]}"
      source "$DOMAINS_DIR/$selected_domain.conf"
      export CF_DOMAIN CF_API_TOKEN CF_ZONE_ID
      tunnel_menu
    elif [[ "$opt" -eq "$i" ]]; then
      break
    else
      echo -e "${COLOR_RED}[!] Invalid option${COLOR_RESET}" ; sleep 1
    fi
  done
}

crear_tunel() {
  echo -n "Subdomain (e.g., home) [leave blank for random name or type 'cancel' to exit]: "
  read SUB
  [[ "$SUB" == "exit" || "$SUB" == "cancel" ]] && echo -e "${COLOR_YELLOW}[-] Operación cancelada por el usuario.${COLOR_RESET}" && sleep 1 && return

  if [[ -z "$SUB" ]]; then
    SUB=$(generate_pet_name)
    echo -e "${COLOR_CYAN}[*] Generated random subdomain: $SUB${COLOR_RESET}"
  fi

  echo -n "Local port (e.g., 3000) [or type 'cancel' to abort]: "
  read PORT
  [[ "$PORT" == "exit" || "$PORT" == "cancel" || -z "$PORT" ]] && echo -e "${COLOR_YELLOW}[-] Operación cancelada por el usuario.${COLOR_RESET}" && sleep 1 && return

  echo -e "${COLOR_CYAN}[*] Creating tunnel: $SUB.$CF_DOMAIN → localhost:$PORT ...${COLOR_RESET}"
  
  TUNNEL_OUTPUT=$(cloudflared tunnel create "$SUB-tunnel" 2>&1)
  TUNNEL_ID=$(echo "$TUNNEL_OUTPUT" | grep -oE '[0-9a-f\-]{36}' | head -n 1)

  if [[ -z "$TUNNEL_ID" ]]; then
    echo -e "${COLOR_RED}[!] Could not create tunnel. Review: ${TUNNEL_OUTPUT}${COLOR_RESET}"
    return
  fi

  echo -e "${COLOR_GREEN}[+] Tunnel created with ID: $TUNNEL_ID${COLOR_RESET}"

  CONFIG_PATH="$CONFIG_DIR/$SUB-config.yml"
  CRED_PATH="$CONFIG_DIR/$TUNNEL_ID.json"

  cat > "$CONFIG_PATH" <<EOF
tunnel: "$TUNNEL_ID"
credentials-file: "$CRED_PATH"
ingress:
  - hostname: "$SUB.$CF_DOMAIN"
    icmp: false
    service: "http://0.0.0.0:$PORT"
  - service: http_status:404
EOF

  echo -e "${COLOR_GREEN}[+] Config generated: $CONFIG_PATH${COLOR_RESET}"
  echo -e "${COLOR_YELLOW}[!] Point DNS to: CNAME → $TUNNEL_ID.cfargotunnel.com${COLOR_RESET}"

  echo -n "Create DNS record automatically? (y/n): "
  read create_dns
  if [[ "$create_dns" == "y" ]]; then
    export CF_DNS_SUB="$SUB"
    export CF_DNS_TARGET="$TUNNEL_ID.cfargotunnel.com"
    SCRIPT_DIR="$(dirname "$0")"
    "$SCRIPT_DIR/cfdns.sh" --auto-tunnel
    echo -e "${COLOR_GREEN}[+] DNS record created automatically.${COLOR_RESET}"
    # Iniciar el túnel automáticamente después de crear el registro DNS
    nohup cloudflared tunnel --config "$CONFIG_PATH" run > "$CONFIG_DIR/$SUB-tunnel.log" 2>&1 &
    echo "$!" > "$CONFIG_DIR/pids/$SUB.pid"
    echo -e "${COLOR_GREEN}[+] Tunnel started in background after DNS creation.${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}[i] Logs are being saved to $CONFIG_DIR/$SUB-tunnel.log${COLOR_RESET}"
  else
    echo -n "Do you want to start the tunnel now? (y/n): "
    read start
    if [[ "$start" == "y" ]]; then
      nohup cloudflared tunnel --config "$CONFIG_PATH" run > "$CONFIG_DIR/$SUB-tunnel.log" 2>&1 &
      echo "$!" > "$CONFIG_DIR/pids/$SUB.pid"
      echo -e "${COLOR_GREEN}[+] Tunnel started in background.${COLOR_RESET}"
      echo -e "${COLOR_YELLOW}[i] Logs are being saved to $CONFIG_DIR/$SUB-tunnel.log${COLOR_RESET}"
    fi
  fi

  sleep 1
}

eliminar_tunel() {
  NAME="$1"
  if [[ -z "$NAME" ]]; then
    echo -n "Tunnel name to delete: "
    read NAME
  fi

  echo -n "This will delete the tunnel '$NAME' and its DNS record. Are you sure? (y/n): "
  read confirmation
  if [[ "$confirmation" != "y" ]]; then
    echo -e "${COLOR_YELLOW}[-] Operation cancelled.${COLOR_RESET}"
    return
  fi

  # Delete DNS record first
  SCRIPT_DIR="$(dirname "$0")"
  "$SCRIPT_DIR/cfdns.sh" --delete-sub "$NAME"

  CONFIG_PATH="$CONFIG_DIR/$NAME-config.yml"

  if [[ -f "$CONFIG_PATH" ]]; then
    CRED_FILE=$(grep 'credentials-file:' "$CONFIG_PATH" | awk '{print $2}' | tr -d '"')
    [[ -n "$CRED_FILE" && -f "$CRED_FILE" ]] && rm -f "$CRED_FILE"
  fi

  cloudflared tunnel delete "$NAME-tunnel"
  rm -f "$CONFIG_PATH" "$CONFIG_DIR/pids/$NAME.pid" "$CONFIG_DIR/$NAME-tunnel.log"
  echo -e "${COLOR_RED}[-] Tunnel $NAME and its artifacts deleted.${COLOR_RESET}"
}

start_tunel() {
  NAME="$1"
  CONFIG_PATH="$CONFIG_DIR/$NAME-config.yml"
  PID_PATH="$CONFIG_DIR/pids/$NAME.pid"

  if [[ ! -f "$CONFIG_PATH" ]]; then
    echo -e "${COLOR_RED}[!] Tunnel not found: $NAME${COLOR_RESET}"
    return
  fi

  if [[ -f "$PID_PATH" ]]; then
    PID=$(cat "$PID_PATH")
    kill -0 "$PID" &>/dev/null && kill "$PID" && sleep 1
  fi

  nohup cloudflared tunnel --config "$CONFIG_PATH" run > /dev/null 2>&1 &
  echo "$!" > "$PID_PATH"
  echo -e "${COLOR_GREEN}[+] $NAME started in background.${COLOR_RESET}"
}

stop_tunel() {
  NAME="$1"
  PID_PATH="$CONFIG_DIR/pids/$NAME.pid"

  if [[ ! -f "$PID_PATH" ]]; then
    echo -e "${COLOR_RED}[!] No PID registered for $NAME.${COLOR_RESET}"
    return
  fi

  PID=$(cat "$PID_PATH")
  kill -0 "$PID" &>/dev/null && kill "$PID"
  rm -f "$PID_PATH"
  echo -e "${COLOR_YELLOW}[-] $NAME stopped.${COLOR_RESET}"
}

edit_tunel() {
  NAME="$1"
  [[ -z "$NAME" ]] && read -p "Tunnel name to edit: " NAME

  CONFIG_PATH="$CONFIG_DIR/$NAME-config.yml"
  CRED_FILE=$(grep 'credentials-file:' "$CONFIG_PATH" | awk '{print $2}' | tr -d '"')

  [[ ! -f "$CONFIG_PATH" ]] && echo -e "${COLOR_RED}[!] Tunnel not found: $NAME${COLOR_RESET}" && return

  echo -e "${COLOR_BLUE}[*] Editing YAML config: $CONFIG_PATH${COLOR_RESET}"
  read -p "Press Enter to continue..."
  ${EDITOR:-nano} "$CONFIG_PATH"

  if [[ -f "$CRED_FILE" ]]; then
    echo -e "${COLOR_BLUE}[*] Editing JSON credentials: $CRED_FILE${COLOR_RESET}"
    read -p "Press Enter to continue..."
    ${EDITOR:-nano} "$CRED_FILE"
  else
    echo -e "${COLOR_RED}[!] Credentials file not found: $CRED_FILE${COLOR_RESET}"
  fi
}

exportar_tunel() {
  NAME="$1"
  [[ -z "$NAME" ]] && read -p "Tunnel name to export: " NAME

  CONFIG_PATH="$CONFIG_DIR/$NAME-config.yml"
  CRED_FILE=$(grep 'credentials-file:' "$CONFIG_PATH" | awk '{print $2}' | tr -d '"')

  if [[ ! -f "$CONFIG_PATH" || ! -f "$CRED_FILE" ]]; then
    echo -e "${COLOR_RED}[!] Missing config or credentials for $NAME${COLOR_RESET}"
    return
  fi

  # Save export in a folder relative to the current directory
  EXPORT_DIR="./cloudflared-export/$NAME"
  mkdir -p "$EXPORT_DIR"
  cp "$CONFIG_PATH" "$EXPORT_DIR/"
  cp "$CRED_FILE" "$EXPORT_DIR/"

  echo -e "${COLOR_GREEN}[+] Tunnel exported to $EXPORT_DIR${COLOR_RESET}"
  echo -e "${COLOR_YELLOW}[!] Copy this folder to the new device and edit the credentials-file path if needed.${COLOR_RESET}"
}

view_logs() {
  NAME="$1"
  [[ -z "$NAME" ]] && read -p "Tunnel name to view logs for: " NAME

  LOG_FILE="$CONFIG_DIR/$NAME-tunnel.log"

  if [[ -f "$LOG_FILE" ]]; then
    echo -e "${COLOR_BLUE}[*] Displaying logs for $NAME. Press Ctrl+C to stop.${COLOR_RESET}"
    tail -f "$LOG_FILE"
  else
    echo -e "${COLOR_RED}[!] Log file not found for $NAME: $LOG_FILE${COLOR_RESET}"
  fi
}

status_tuneles() {
  while true; do
    clear
    echo -e "${COLOR_CYAN}==== Cloudflared Tunnel Dashboard ====${COLOR_RESET}"
    print_line
    printf "%-25s %-10s %-10s %-10s %-10s\n" "Tunnel" "Status" "Port" "CPU%" "MEM%"
    print_line

    TUNNELS=($(find "$CONFIG_DIR" -name '*-config.yml'))
    if [[ ${#TUNNELS[@]} -eq 0 ]]; then
      echo -e "${COLOR_RED}No tunnels configured.${COLOR_RESET}"
    else
      for config in "${TUNNELS[@]}"; do
        NAME=$(basename "$config" | sed 's/-config.yml//')
        PID_FILE="$CONFIG_DIR/pids/$NAME.pid"
        PORT=$(extract_port "$config")
        PORT=${PORT:-N/A}
        CPU="N/A"
        MEM="N/A"

        if [[ -f "$PID_FILE" ]]; then
          PID=$(cat "$PID_FILE")
          if kill -0 "$PID" &>/dev/null; then
            STATUS="${COLOR_GREEN}RUNNING${COLOR_RESET}"
            # OS-specific ps command for resource usage
            if [[ "$(uname)" == "Darwin" ]]; then # macOS
              USAGE=$(ps -p "$PID" -o pcpu,pmem | tail -n +2)
            else # Linux/Termux
              USAGE=$(ps -p "$PID" -o %cpu,%mem --no-headers)
            fi
            CPU=$(echo "$USAGE" | awk '{print $1}')
            MEM=$(echo "$USAGE" | awk '{print $2}')
          else
            STATUS="${COLOR_RED}DEAD${COLOR_RESET}"
            rm -f "$PID_FILE"
          fi
        else
          STATUS="${COLOR_YELLOW}STOPPED${COLOR_RESET}"
        fi

    # Trim nombre a 23 chars para no romper tabla
        NAME_TRIMMED=$(echo "$NAME" | cut -c1-23)
        NAME_PADDED=$(printf "%-25s" "$NAME_TRIMMED")
        STATUS_PLAIN=$(echo -e "$STATUS" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')
        STATUS_PADDED=$(printf "%-10s" "$STATUS_PLAIN")
        PORT_PADDED=$(printf "%-10s" "$PORT")
        CPU_PADDED=$(printf "%-10s" "$CPU")
        MEM_PADDED=$(printf "%-10s" "$MEM")

      printf "%s  %b  %s  %s  %s\n" "$NAME_PADDED" "$STATUS" "$PORT_PADDED" "$CPU_PADDED" "$MEM_PADDED"
      done
    fi

    print_line
    echo -e "${COLOR_BLUE}Commands:${COLOR_RESET} start <name> | stop <name> | delete <name> | edit <name> | export <name> | export-all"
    echo -e "          start-all | stop-all | delete-all | refresh | back | logs <name>"
    print_line
    echo -n ">> "
    read action param

    case $action in
      start) start_tunel "$param" ;;
      stop) stop_tunel "$param" ;;
      delete) eliminar_tunel "$param" ;;
      edit) edit_tunel "$param" ;;
      export) exportar_tunel "$param" ;;
      logs) view_logs "$param" ;;
      export-all)
        for conf in "${TUNNELS[@]}"; do
          NAME=$(basename "$conf" | sed 's/-config.yml//')
          exportar_tunel "$NAME"
        done ;;
      start-all)
        for conf in "${TUNNELS[@]}"; do
          NAME=$(basename "$conf" | sed 's/-config.yml//')
          start_tunel "$NAME"
        done ;;
      stop-all)
        for conf in "${TUNNELS[@]}"; do
          NAME=$(basename "$conf" | sed 's/-config.yml//')
          stop_tunel "$NAME"
        done ;;
      delete-all)
        for conf in "${TUNNELS[@]}"; do
          NAME=$(basename "$conf" | sed 's/-config.yml//')
          eliminar_tunel "$NAME"
        done ;;
      refresh) continue ;;
      back) break ;;
      *) echo -e "${COLOR_RED}[!] Invalid command${COLOR_RESET}" ; sleep 1 ;;
    esac
    sleep 1
  done
}

tunnel_menu() {
  while true; do
    clear
    echo -e "${COLOR_BLUE}Cloudflared Tunnel Manager for domain: $CF_DOMAIN${COLOR_RESET}"
    echo "1. Create new tunnel"
    echo "2. View tunnel status"
    echo "3. Back to domain selection"
    print_line
    echo -n "Elige opción: "
    read opt

    case $opt in
      1) crear_tunel ;;
      2) status_tuneles ;;
      3) break ;;
      *) echo -e "${COLOR_RED}[!] Invalid option${COLOR_RESET}" ; sleep 1 ;;
    esac
  done
}

menu() {
  while true; do
    clear
    echo -e "${COLOR_BLUE}Cloudflared Multi-Domain Manager${COLOR_RESET}"
    echo "1. Manage Tunnels"
    echo "2. Manage Domains"
    echo "3. Cloudflare Login"
    echo "4. Exit"
    print_line
    echo -n "Elige opción: "
    read opt

    case $opt in
      1) select_domain ;;
      2) manage_domains ;;
      3) cloudflared tunnel login ;;
      4) exit ;;
      *) echo -e "${COLOR_RED}[!] Invalid option${COLOR_RESET}" ; sleep 1 ;;
    esac
  done
}

# Parse CLI arguments for non-interactive mode
if [[ $# -gt 0 ]]; then
  ACTION="$1"
  shift
  case "$ACTION" in
    create)
      # Usage: create --sub <subdomain> --port <port>
      while [[ $# -gt 0 ]]; do
        case $1 in
          --sub)
            SUB="$2"; shift 2;;
          --port)
            PORT="$2"; shift 2;;
          *) shift;;
        esac
      done
      if [[ -z "$SUB" || -z "$PORT" ]]; then
        echo "Usage: $0 create --sub <subdomain> --port <port>"
        exit 1
      fi
      # Call crear_tunel non-interactively
      crear_tunel_noninteractive() {
        local SUB="$1"
        local PORT="$2"
        # Simulate the logic of crear_tunel but without prompts
        TUNNEL_OUTPUT=$(cloudflared tunnel create "$SUB-tunnel" 2>&1)
        TUNNEL_ID=$(echo "$TUNNEL_OUTPUT" | grep -oE '[0-9a-f\-]{36}' | head -n 1)
        if [[ -z "$TUNNEL_ID" ]]; then
          echo "[!] Could not create tunnel. Review: ${TUNNEL_OUTPUT}"
          exit 1
        fi
        CONFIG_PATH="$CONFIG_DIR/$SUB-config.yml"
        CRED_PATH="$CONFIG_DIR/$TUNNEL_ID.json"
        cat > "$CONFIG_PATH" <<EOF
 tunnel: "$TUNNEL_ID"
 credentials-file: "$CRED_PATH"
 ingress:
   - hostname: "$SUB.$CF_DOMAIN"
     icmp: false
     service: "http://0.0.0.0:$PORT"
   - service: http_status:404
EOF
        echo "[+] Tunnel created: $SUB.$CF_DOMAIN (ID: $TUNNEL_ID)"
        echo "[!] Point DNS to: CNAME → $TUNNEL_ID.cfargotunnel.com"
        # Create DNS record automatically
        export CF_DNS_SUB="$SUB"
        export CF_DNS_TARGET="$TUNNEL_ID.cfargotunnel.com"
        "$SCRIPT_DIR/cfdns.sh" --auto-tunnel
        echo "[+] DNS record created automatically."
        # Start tunnel automatically
        cloudflared tunnel --config "$CONFIG_PATH" run &
        echo "[+] Tunnel started in background."
      }
      SCRIPT_DIR="$(dirname "$0")"
      crear_tunel_noninteractive "$SUB" "$PORT"
      exit 0
      ;;
    start)
      # Usage: start <subdomain>
      NAME="$1"
      if [[ -z "$NAME" ]]; then
        echo "Usage: $0 start <subdomain>"
        exit 1
      fi
      start_tunel "$NAME"
      exit 0
      ;;
    stop)
      # Usage: stop <subdomain>
      NAME="$1"
      if [[ -z "$NAME" ]]; then
        echo "Usage: $0 stop <subdomain>"
        exit 1
      fi
      stop_tunel "$NAME"
      exit 0
      ;;
    export)
      # Usage: export <subdomain>
      NAME="$1"
      if [[ -z "$NAME" ]]; then
        echo "Usage: $0 export <subdomain>"
        exit 1
      fi
      exportar_tunel "$NAME"
      exit 0
      ;;
    export-all)
      # Export all tunnels
      TUNNELS=( $(find "$CONFIG_DIR" -name '*-config.yml') )
      for conf in "${TUNNELS[@]}"; do
        NAME=$(basename "$conf" | sed 's/-config.yml//')
        exportar_tunel "$NAME"
      done
      exit 0
      ;;
    *)
      echo "Unknown command: $ACTION"
      echo "Available commands: create, start, stop, export, export-all"
      exit 1
      ;;
  esac
fi

migrate_env_file
menu
