#!/bin/bash

#Global arguments
# System architecture
arch=$(uname -m)
# MCSM install dir
mcsmanager_install_path="/opt/mcsmanager"
# MCSM backup dir
mcsm_backup_dir="/opt/"
# Created backup absolute path
backup_path=""
# Download URL
mcsmanager_donwload_addr="http://oss.duzuii.com/d/MCSManager/MCSManager/MCSManager-v10-linux.tar.gz"
# File name
package_name="MCSManager-v10-linux.tar.gz"
# Node.js version to install
node="v20.12.2"
# Node.js install dir
node_install_path="/opt/node-$node-linux-$arch"



# Default systemd user is 'mcsm'
USER="mcsm"
COMMAND="all"

# Helper Functions
usage() {
    echo "Usage: $0 [-u user] [-c command]"
    echo "  -u  Specify the user (mcsm or root), default is 'mcsm'"
    echo "  -c  Specify the command (web, daemon, or all), default is 'all'"
    exit 1
}
Red_Error() {
    echo '================================================='
    printf '\033[1;31;40m%b\033[0m\n' "$@"
    echo '================================================='
    exit 1
}
echo_cyan() {
    printf '\033[1;36m%b\033[0m\n' "$@"
}
echo_red() {
    printf '\033[1;31m%b\033[0m\n' "$@"
}

echo_green() {
    printf '\033[1;32m%b\033[0m\n' "$@"
}

echo_cyan_n() {
    printf '\033[1;36m%b\033[0m' "$@"
}

echo_yellow() {
    printf '\033[1;33m%b\033[0m\n' "$@"
}

# Check root permission
check_sudo() {
	if [ "$EUID" -ne 0 ]; then
		echo "This script must be run as root. Please use \"sudo or root user\" instead."
		exit 1
	fi
}

Install_dependencies() {
	# Install related software
	echo_cyan_n "[+] Installing dependent software (git, tar, wget)... "
	if [[ -x "$(command -v yum)" ]]; then
		yum install -y git tar wget
	elif [[ -x "$(command -v apt-get)" ]]; then
		apt-get install -y git tar wget
	elif [[ -x "$(command -v pacman)" ]]; then
		pacman -S --noconfirm git tar wget
	elif [[ -x "$(command -v zypper)" ]]; then
		zypper --non-interactive install git tar wget
	else
		echo_red "[!] Cannot find your package manager! You may need to install git, tar and wget manually!"
	fi
}

Install_node() {
    echo_cyan_n "[+] Install Node.js environment...\n"

    rm -irf "$node_install_path"

    cd /opt || Red_Error "[x] Failed to enter /opt"

    rm -rf "node-$node-linux-$arch.tar.gz"

    wget "https://nodejs.org/dist/$node/node-$node-linux-$arch.tar.gz" || Red_Error "[x] Failed to download node release"

    tar -zxf "node-$node-linux-$arch.tar.gz" || Red_Error "[x] Failed to untar node"

    rm -rf "node-$node-linux-$arch.tar.gz"

    if [[ -f "$node_install_path"/bin/node ]] && [[ "$("$node_install_path"/bin/node -v)" == "$node" ]]; then
        echo_green "Success"
    else
        Red_Error "[x] Node installation failed!"
    fi

    echo
    echo_yellow "=============== Node.JS Version ==============="
    echo_yellow " node: $("$node_install_path"/bin/node -v)"
    echo_yellow " npm: v$(env "$node_install_path"/bin/node "$node_install_path"/bin/npm -v)"
    echo_yellow "=============== Node.JS Version ==============="
    echo

    sleep 3
}

Backup_MCSM() {
    # Ensure both directories are provided
    if [ -z "$mcsmanager_install_path" ] || [ -z "$mcsm_backup_dir" ]; then
        echo "Error: Backup or source path not set."
        return 1  # Return with error
    fi

    # Check if the source directory exists
    if [ ! -d "$mcsmanager_install_path" ]; then
        echo "Error: Source directory does not exist."
        return 1  # Return with error
    fi

    # Create backup directory (/opt) if it doesn't exist
    if [ ! -d "$mcsm_backup_dir" ]; then
        echo "Creating backup directory."
        mkdir -p "$mcsm_backup_dir"
    fi

    # Format the date for the backup filename
    local current_date=$(date +%Y_%m_%d)

    # Define the backup path
    backup_path="${mcsm_backup_dir}/mcsm_backup_${current_date}.tar.gz"

    # Create the backup
	echo "Creating backup..."
    tar -czf "$backup_path" -C "$mcsmanager_install_path" .

    # Check if the backup was successful
    if [ $? -eq 0 ]; then
        echo "Backup created successfully at $backup_path"
    else
        echo "Error creating backup."
        return 1  # Return with error
    fi
}
########### Main Logic ################
check_sudo
# Install Dependencies
Install_dependencies

# Parse provided arguments
while getopts "u:c:" opt; do
    case ${opt} in
        u )
            if [[ "${OPTARG}" == "mcsm" || "${OPTARG}" == "root" ]]; then
                user="${OPTARG}"
            else
                echo "Invalid user specified."
                usage
            fi
            ;;
        c )
            if [[ "${OPTARG}" == "web" || "${OPTARG}" == "daemon" || "${OPTARG}" == "all" ]]; then
                command="${OPTARG}"
            else
                echo "Invalid command specified."
                usage
            fi
            ;;
        \? )
            usage
            ;;
        : )
            echo "Option -$OPTARG requires an argument."
            usage
            ;;
    esac
done

# Logic for different users
case ${USER} in
  root)
    ;;
  mcsm)
    ;;
  *)
    echo "Unknown user: ${USER}. Using default user mcsm..."
    ;;
esac


# Check if the mcsmanager_install_path exists
if [ -d "$mcsmanager_install_path" ]; then
    # Backup first
	Backup_MCSM
	# Install Node.js, this is to ensure the version is up to date.
	
else
    echo "The directory '$mcsmanager_install_path' does not exist."
    # Logic branch when the directory does not exist
    # For example, create the directory
    echo "Creating $mcsmanager_install_path..."
fi