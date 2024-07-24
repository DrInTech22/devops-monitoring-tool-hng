#!/bin/bash

# Check if the script is run as root
if [[ $UID != 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi


# Function to display help message
function help_feature() {
    cat << 'HELP_EOF'
Usage: sudo ./devopsfetch.sh [OPTIONS] 

Options:
   -p, --port [PORT_NUMBER]         -p                Display all active ports and services.                       
                                    -p <port_number>  Provide detailed information about a specific port.

   -d, --docker [CONTAINER_NAME]    -d                List all Docker images and containers.                                 
                                    -d <container_name> Provide detailed information about a specific container.

   -n, --nginx [DOMAIN]             -n                Display all Nginx domains and their ports.
                                    -n <domain>       Provide detailed configuration information for a specific domain.

   -u, --users [USERNAME]           -u                List all users and their last login times.                    
                                    -u <username>     Provide detailed information about a specific user.

   -t, --time [TIME_RANGE]          -t <date>         Display activities for a specific date (e.g., 2024-07-23).
                                    -t <start_date> <end_date> Display activities within the specified date range 
                                                            (e.g., 2024-07-18 2024-07-24).

   -h, --help                        Display this help message and exit.

Examples:
  sudo ./devopsfetch.sh -p                 Display all active ports and services.
  sudo ./devopsfetch.sh -p 80              Display detailed information about port 80.
  sudo ./devopsfetch.sh -d                 List all Docker images and containers.
  sudo ./devopsfetch.sh -d my_container    Provide detailed information about 'my_container'.
  sudo ./devopsfetch.sh -n                 Display all Nginx domains and their ports.
  sudo ./devopsfetch.sh -n example.com     Provide detailed configuration information for 'example.com'.
  sudo ./devopsfetch.sh -u                 List all users and their last login times.
  sudo ./devopsfetch.sh -u johndoe         Provide detailed information about user 'johndoe'.
  sudo ./devopsfetch.sh -t 2024-07-23      Display activities for July 23rd, 2024.
  sudo ./devopsfetch.sh -t 2024-07-18 2024-07-24 Display activities from July 18th, 2024 to July 24th, 2024.
  sudo ./devopsfetch.sh -h                 Display this help message and exit.

HELP_EOF
}

# Function to display active ports and services
function port_feature() {
    local COLUMN1_WIDTH=25
    local COLUMN2_WIDTH=15
    local COLUMN3_WIDTH=25

    # Define the horizontal line pattern
    local HORIZONTAL_LINE="+-$(printf "%-${COLUMN1_WIDTH}s" | tr ' ' '-')-+-$(printf "%-${COLUMN2_WIDTH}s" | tr ' ' '-')-+-$(printf "%-${COLUMN3_WIDTH}s" | tr ' ' '-')-+"

    if [ -z "$1" ]; then
        # Print the header
        echo "$HORIZONTAL_LINE"
        printf "| %-*s | %-*s | %-*s |\n" $COLUMN1_WIDTH "USER" $COLUMN2_WIDTH "PORT" $COLUMN3_WIDTH "SERVICE"
        echo "$HORIZONTAL_LINE"

        # Print the table content
        netstat -tulnp | awk -v col1=$COLUMN1_WIDTH -v col2=$COLUMN2_WIDTH -v col3=$COLUMN3_WIDTH '
        /^tcp/ || /^udp/ {
            split($4, addr, ":")
            split($7, pid, "/")
            if (length(addr[2]) > 0 && length(pid[2]) > 0) {
                user = substr(pid[2], 1, col1)
                port = substr(addr[2], 1, col2)
                service = substr(pid[2], 1, col3)
                printf "| %-*s | %-*s | %-*s |\n", col1, user, col2, port, col3, service
            }
        }'

        # Print the footer
        echo "$HORIZONTAL_LINE"
    else
        local port="$1"
        result=$(netstat -tulnp | awk -v port="$port" -v col1=$COLUMN1_WIDTH -v col2=$COLUMN2_WIDTH -v col3=$COLUMN3_WIDTH '
        /^tcp/ || /^udp/ {
            split($4, addr, ":")
            split($7, pid, "/")
            if (addr[2] == port && length(pid[2]) > 0) {
                user = substr(pid[2], 1, col1)
                port = substr(addr[2], 1, col2)
                service = substr(pid[2], 1, col3)
                printf "| %-*s | %-*s | %-*s |\n", col1, user, col2, port, col3, service
            }
        }')

        if [ -z "$result" ]; then
            echo "No services found on port $port"
        else
            echo "$HORIZONTAL_LINE"
            printf "| %-*s | %-*s | %-*s |\n" $COLUMN1_WIDTH "USER" $COLUMN2_WIDTH "PORT" $COLUMN3_WIDTH "SERVICE"
            echo "$HORIZONTAL_LINE"
            echo "$result"
            echo "$HORIZONTAL_LINE"
        fi
    fi
}

# Function to list Docker images and containers
function docker_feature() {
    if [ -z "$1" ]; then
        # Display Docker Images with formatted table
        echo "Docker Images:"
        docker images --format "{{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}" | awk '
        BEGIN {
            printf "+-------------------------+-------------------------+----------------------------------+-----------+\n"
            printf "| REPOSITORY              | TAG                     | IMAGE ID                         | SIZE      |\n"
            printf "+-------------------------+-------------------------+----------------------------------+-----------+\n"
        }
        {
            # Truncate values if they exceed column width and add "..."
            repository = substr($1, 1, 20)
            if (length($1) > 20) repository = repository "..."
            tag = substr($2, 1, 20)
            if (length($2) > 20) tag = tag "..."
            image_id = substr($3, 1, 29)
            if (length($3) > 29) image_id = image_id "..."
            size = substr($4, 1, 6)
            if (length($4) > 6) size = size "..."
            printf "| %-23s | %-23s | %-32s | %-9s |\n", repository, tag, image_id, size
        }
        END {
            print "+-------------------------+-------------------------+----------------------------------+-----------+"
        }'

        echo ""

        # Display Docker Containers with formatted table
        echo "Docker Containers:"
        docker ps -a --format "{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | awk '
        BEGIN {
            printf "+-------------------------+-------------------------+----------------------+-------------------------+\n"
            printf "| NAMES                   | IMAGE                   | STATUS               | PORTS                   |\n"
            printf "+-------------------------+-------------------------+----------------------+-------------------------+\n"
        }
        {
            # Extract the fields
            names = substr($1, 1, 20)
            if (length($1) > 20) names = names "..."
            
            image = substr($2, 1, 20)
            if (length($2) > 20) image = image "..."
            
            # Handle status field with multiple parts
            status = ""
            for (i = 3; i <= NF-1; i++) {
                status = status " " $i
            }
            status = substr(status, 2)  # Remove leading space

            # Check for "Exited" status and set ports to "dead"
            if (index(status, "Exited") > 0) {
                status = "Exited"  # Set status to "Exited" for consistency
                ports = "inactive"
            } else {
                if (length(status) > 19) status = substr(status, 1, 19) "..."
                ports = substr($NF, 1, 20)
                if (length($NF) > 20) ports = substr($NF, 1, 20) "..."
            }
            
            # Print the formatted row
            printf "| %-23s | %-23s | %-20s | %-23s |\n", names, image, status, ports
        }
        END {
            print "+-------------------------+-------------------------+----------------------+-------------------------+"
        }'
    else
        # Fetch container details using docker inspect and parse with jq
        container_info=$(docker inspect "$1")

        # Check if jq is available
        if ! command -v jq &> /dev/null; then
            echo "jq is not installed. Please install jq to use this feature."
            return 1
        fi

        # Extracting details with jq
        container_id=$(echo "$container_info" | jq -r '.[0].Id' | cut -d '/' -f 3)
        name=$(echo "$container_info" | jq -r '.[0].Name' | sed 's/\///')
        image=$(echo "$container_info" | jq -r '.[0].Config.Image')
        status=$(echo "$container_info" | jq -r '.[0].State.Status')
        ports=$(echo "$container_info" | jq -r '.[0].NetworkSettings.Ports | to_entries | map("\(.key): \(.value | .[] | .HostPort)") | join(", ")')
        env_vars=$(echo "$container_info" | jq -r '.[0].Config.Env[]' | tr '\n' '\n' | sed 's/^/    /')

        # Print formatted output
        echo "Container Information:"
        echo "----------------------"
        echo "Container ID:        $container_id"
        echo "Name:                $name"
        echo "Image:               $image"
        echo "Status:              $status"
        echo "Ports:               $ports"
        echo "Environment Variables:"
        echo "$env_vars"
        echo "----------------------"
    fi
}
# Function to display Nginx domains and ports
function nginx_feature() {
    if [ -z "$1" ]; then
        # Define column widths
        local COL1_WIDTH=54
        local COL2_WIDTH=40
        local COL3_WIDTH=54

        # Print the header
        echo "+$(printf '%0.s-' $(seq 1 $((COL1_WIDTH + 2))) )+$(printf '%0.s-' $(seq 1 $((COL2_WIDTH + 2))) )+$(printf '%0.s-' $(seq 1 $((COL3_WIDTH + 2))) )+"
        echo "| $(printf "%-${COL1_WIDTH}s" "DOMAIN") | $(printf "%-${COL2_WIDTH}s" "PROXY") | $(printf "%-${COL3_WIDTH}s" "CONFIGURATION FILE") |"
        echo "+$(printf '%0.s-' $(seq 1 $((COL1_WIDTH + 2))) )+$(printf '%0.s-' $(seq 1 $((COL2_WIDTH + 2))) )+$(printf '%0.s-' $(seq 1 $((COL3_WIDTH + 2))) )+"

        # Loop through configuration files and print details
        for file in /etc/nginx/sites-enabled/*; do
            # Extract and clean server_name
            server_name=$(grep -E '^\s*server_name\s+' "$file" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/;\s*$//; s/\s*$//')

            # Extract and clean proxy_pass
            proxy_pass=$(grep -E '^\s*proxy_pass\s+' "$file" | awk '{print $2}' | sed 's/;\s*$//')

            # Handle empty values
            [ -z "$server_name" ] && server_name="<No Server Name>"
            [ -z "$proxy_pass" ] && proxy_pass="<No Proxy>"

            # Truncate values if they exceed the column width
            server_name=$(echo "$server_name" | cut -c 1-$COL1_WIDTH)
            proxy_pass=$(echo "$proxy_pass" | cut -c 1-$COL2_WIDTH)
            file=$(echo "$file" | cut -c 1-$COL3_WIDTH)

            # Print results with formatting
            printf "| %-${COL1_WIDTH}s | %-${COL2_WIDTH}s | %-${COL3_WIDTH}s |\n" "$server_name" "$proxy_pass" "$file"
        done

        # Print the footer
        echo "+$(printf '%0.s-' $(seq 1 $((COL1_WIDTH + 2))) )+$(printf '%0.s-' $(seq 1 $((COL2_WIDTH + 2))) )+$(printf '%0.s-' $(seq 1 $((COL3_WIDTH + 2))) )+"
    
    else
        echo "Detailed Configuration for Domain $1:"
        awk -v domain="$1" '
        BEGIN {in_block=0}
        /server {/ {in_block=1; block=""}
        in_block {block=block"\n"$0}
        /}/ {
            if (in_block) {
                in_block=0
                if (block ~ "server_name[ \t]*"domain"[ \t]*;") {
                    print block
                }
                block=""
            }
        }
        ' /etc/nginx/sites-enabled/* | sed -e '/^[[:space:]]*$/d'
    fi
}

# Function to list users and their last login times or detailed information about a specific user
function users_feature() {
    # Define column widths
    local USER_COLUMN_WIDTH=18
    local LOGIN_COLUMN_WIDTH=35
    local FIELD_COLUMN_WIDTH=23
    local VALUE_COLUMN_WIDTH=31

    if [ -z "$1" ]; then
        # No arguments provided, list all users with their last login times
        echo "Users and their last login times:"
        printf "+--------------------+-------------------------------------+\n"
        printf "| %-*s | %-*s |\n" $USER_COLUMN_WIDTH "Username" $LOGIN_COLUMN_WIDTH "Last Login"
        printf "+--------------------+-------------------------------------+\n"

        # List all users and their last login times
        awk -F: '$3 >= 1000 {print $1}' /etc/passwd | while read -r username; do
            lastlog | awk -v user="$username" -v ucol=$USER_COLUMN_WIDTH -v lcol=$LOGIN_COLUMN_WIDTH '
            NR>1 && $1 == user {
                # Capture all fields after the username as the last login info
                if ($0 ~ "**Never logged in**") {
                    latest_login = "**Never logged in**"
                } else {
                    latest_login = substr($0, index($0, $4))
                }
                if (length(user) > ucol) user = substr(user, 1, ucol)
                if (length(latest_login) > lcol) latest_login = substr(latest_login, 1, lcol)
                printf "| %-*s | %-*s |\n", ucol, user, lcol, latest_login
            }'
        done
        printf "+--------------------+-------------------------------------+\n"
    else
        local username="$1"
        user_info=$(getent passwd "$username")
        if [[ -z "$user_info" ]]; then
            echo "User $username does not exist."
            return
        fi
        IFS=':' read -r uname pwd uid gid desc home shell <<< "$user_info"

        # Fetch last login using lastlog
        last_login=$(lastlog | awk -v user="$username" '
        $1 == user {
            if ($0 ~ "**Never logged in**") {
                print "**Never logged in**"
            } else {
                print substr($0, index($0, $4))
            }
        }')

        if [ -z "$last_login" ]; then
            last_login="Never logged in"
        fi

        # Truncate values if necessary
        uname=$(echo "$uname" | cut -c 1-$VALUE_COLUMN_WIDTH)
        uid=$(echo "$uid" | cut -c 1-$VALUE_COLUMN_WIDTH)
        gid=$(echo "$gid" | cut -c 1-$VALUE_COLUMN_WIDTH)
        home=$(echo "$home" | cut -c 1-$VALUE_COLUMN_WIDTH)
        shell=$(echo "$shell" | cut -c 1-$VALUE_COLUMN_WIDTH)
        last_login=$(echo "$last_login" | cut -c 1-$VALUE_COLUMN_WIDTH)

        echo "User details for $username:"
        printf "+-------------------------+---------------------------------+\n"
        printf "| %-*s | %-*s |\n" $FIELD_COLUMN_WIDTH "Field" $VALUE_COLUMN_WIDTH "Value"
        printf "+-------------------------+---------------------------------+\n"
        printf "| %-*s | %-*s |\n" $FIELD_COLUMN_WIDTH "Username" $VALUE_COLUMN_WIDTH "$uname"
        printf "+-------------------------+---------------------------------+\n"
        printf "| %-*s | %-*s |\n" $FIELD_COLUMN_WIDTH "UID" $VALUE_COLUMN_WIDTH "$uid"
        printf "+-------------------------+---------------------------------+\n"
        printf "| %-*s | %-*s |\n" $FIELD_COLUMN_WIDTH "GID" $VALUE_COLUMN_WIDTH "$gid"
        printf "+-------------------------+---------------------------------+\n"
        printf "| %-*s | %-*s |\n" $FIELD_COLUMN_WIDTH "Home directory" $VALUE_COLUMN_WIDTH "$home"
        printf "+-------------------------+---------------------------------+\n"
        printf "| %-*s | %-*s |\n" $FIELD_COLUMN_WIDTH "Shell" $VALUE_COLUMN_WIDTH "$shell"
        printf "+-------------------------+---------------------------------+\n"
        printf "| %-*s | %-*s |\n" $FIELD_COLUMN_WIDTH "Last login" $VALUE_COLUMN_WIDTH "$last_login"
        printf "+-------------------------+---------------------------------+\n"
    fi
}
# Function to display activities within a specified time range
function time_feature() {
    if [ -z "$1" ]; then
        echo "Please provide valid arguments in this format for date (YYYY-MM-DD) or (YYYY-MM-DD YYYY-MM-DD) for date range. Use -h for help"
        return
    elif [ -n "$1" ] && [ -z "$2" ]; then
        start_date="$1"
        journalctl --since "$start_date 00:00:00" --until "$start_date 23:59:59" # --no-pager
    elif [ -n "$1" ] && [ -n "$2" ]; then
        start_date="$1"
        end_date="$2"
        journalctl --since "$start_date 00:00:00" --until "$end_date 23:59:59" # --no-pager
    else
        echo "Invalid arguments. Please provide valid arguments in this format for date (YYYY-MM-DD) or date range (YYYY-MM-DD YYYY-MM-DD)"
    fi
}

if [[ "$#" -eq 0 ]]; then
    help_feature
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p|--port)
            PORT="$2"
            port_feature "$PORT"
            shift 2
            break
            ;;
        -d|--docker)
            CONTAINER="$2"
            docker_feature "$CONTAINER"
            shift 2
            break
            ;;
        -n|--nginx)
            DOMAIN="$2"
            nginx_feature "$DOMAIN"
            shift 2
            break
            ;;
        -u|--users)
            if [[ -n "$2" && "$2" != -* ]]; then
                USER="$2"
                users_feature "$USER"
                shift 2
            else
                users_feature
                shift
            fi
            break
            ;;
        -t|--time)
            if [[ -n "$2" && "$2" != -* ]]; then
                start_date="$2"
                if [[ -n "$3" && "$3" != -* ]]; then
                    end_date="$3"
                    time_feature "$start_date" "$end_date"
                    shift 3
                else
                    time_feature "$start_date"
                    shift 2
                fi
            else
                echo "Please provide valid arguments in this format for date (YYYY-MM-DD) or (YYYY-MM-DD YYYY-MM-DD) for date range. Use -h for help"
                shift
            fi
            ;;
        -h|--help)
            help_feature
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            help_feature
            exit 1
            ;;
    esac
done
