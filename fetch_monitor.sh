#!/bin/bash

# Redirect all output to the log file
exec >> /var/log/fetch_monitor.log 2>&1

while true; do
    echo "=====================================================" 
    echo "             Performing system checks...             " 
    echo "             START TIME: $(date)                     " 
    echo "=====================================================" 
    echo ""
    echo ""

    # USER MONITORING
    USER_COLUMN_WIDTH=18
    LOGIN_COLUMN_WIDTH=35
    echo "**************************    USER LOGIN   **************************"
    echo ""
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
    echo ""
    echo ""

    # PORT STATUS
    COLUMN1_WIDTH=25
    COLUMN2_WIDTH=15
    COLUMN3_WIDTH=25
    HORIZONTAL_LINE="+-$(printf "%-${COLUMN1_WIDTH}s" | tr ' ' '-')-+-$(printf "%-${COLUMN2_WIDTH}s" | tr ' ' '-')-+-$(printf "%-${COLUMN3_WIDTH}s" | tr ' ' '-')-+"
    echo "*************************   ACTIVE PORTS   ************************* "
    echo ""
    COLUMN1_WIDTH=25 COLUMN2_WIDTH=15 COLUMN3_WIDTH=25
    HORIZONTAL_LINE="+-$(printf "%-${COLUMN1_WIDTH}s" | tr ' ' '-')-+-$(printf "%-${COLUMN2_WIDTH}s" | tr ' ' '-')-+-$(printf "%-${COLUMN3_WIDTH}s" | tr ' ' '-')-+"
    echo "$HORIZONTAL_LINE"
    printf "| %-*s | %-*s | %-*s |\n" $COLUMN1_WIDTH "USER" $COLUMN2_WIDTH "PORT" $COLUMN3_WIDTH "SERVICE"
    echo "$HORIZONTAL_LINE"
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
    echo "$HORIZONTAL_LINE"
    echo ""
    echo ""

    # DOCKER IMAGES AND CONTAINER STATUS

    # Display Docker Images with formatted table
    echo "********************************   DOCKER STATUS   ********************************"
    echo ""
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
    echo ""
    echo ""

    # NGINX DOMAIN STATUS
    echo "**************************    NGINX DOMAIN VALIDATION   **************************"
    echo ""
    COL1_WIDTH=54
    COL2_WIDTH=40
    COL3_WIDTH=54
    # Print the header
    echo "+$(printf '%0.s-' $(seq 1 $((COL1_WIDTH + 2))) )+$(printf '%0.s-' $(seq 1 $((COL2_WIDTH + 2))) )+$(printf '%0.s-' $(seq 1 $((COL3_WIDTH + 2))) )+"
    echo "| $(printf "%-${COL1_WIDTH}s" "DOMAIN") | $(printf "%-${COL2_WIDTH}s" "PROXY") | $(printf "%-${COL3_WIDTH}s" "CONFIGURATION FILE") |"
    echo "+$(printf '%0.s-' $(seq 1 $((COL1_WIDTH + 2))) )+$(printf '%0.s-' $(seq 1 $((COL2_WIDTH + 2))) )+$(printf '%0.s-' $(seq 1 $((COL3_WIDTH + 2))) )+"
    # Loop through configuration files and print details
    for file in /etc/nginx/sites-enabled/*; do
        server_name=$(grep -E '^\s*server_name\s+' "$file" | awk '{for(i=2;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/;\s*$//; s/\s*$//')
        proxy_pass=$(grep -E '^\s*proxy_pass\s+' "$file" | awk '{print $2}' | sed 's/;\s*$//')
        [ -z "$server_name" ] && server_name="<No Server Name>"
        [ -z "$proxy_pass" ] && proxy_pass="<No Proxy>"
        server_name=$(echo "$server_name" | cut -c 1-$COL1_WIDTH)
        proxy_pass=$(echo "$proxy_pass" | cut -c 1-$COL2_WIDTH)
        file=$(echo "$file" | cut -c 1-$COL3_WIDTH)
        printf "| %-${COL1_WIDTH}s | %-${COL2_WIDTH}s | %-${COL3_WIDTH}s |\n" "$server_name" "$proxy_pass" "$file"
    done
    echo "+$(printf '%0.s-' $(seq 1 $((COL1_WIDTH + 2))) )+$(printf '%0.s-' $(seq 1 $((COL2_WIDTH + 2))) )+$(printf '%0.s-' $(seq 1 $((COL3_WIDTH + 2))) )+"
    echo ""
    echo ""
    echo "=====================================================" 
    echo "          Checks completed.     " 
    echo "          END TIME: $(date)     " 
    echo "=====================================================" 
    echo ""
    echo ""

    # Sleep for an hour before next check
    sleep 3600
done


