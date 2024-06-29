#!/bin/sh

# Update package repositories and upgrade existing packages
sudo apt-get update && sudo apt-get upgrade -y
clear

# Set script to exit immediately if any command fails
set -e

# Define URLs for Sonaric installation
APT_KEY_URL="https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg"
APT_DOWNLOAD_URL="https://us-central1-apt.pkg.dev/projects/sonaric-platform"
RPM_DOWNLOAD_URL="https://us-central1-yum.pkg.dev/projects/sonaric-platform/sonaric-releases-rpm"
DOWNLOAD_URL="https://storage.googleapis.com/sonaric-releases/stable/linux/sonaric-amd64-latest.tar.gz"

# Function to check if a command exists
command_exists() {
	command -v "$@" > /dev/null 2>&1
}

# Function to get Linux distribution name
get_distribution() {
	lsb_dist=""
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi
	echo "$lsb_dist"
}

# Function to check if the Linux distribution is forked
check_forked() {
	if command_exists lsb_release; then
		set +e
		lsb_release -a -u > /dev/null 2>&1
		lsb_release_exit_code=$?
		set -e

		if [ "$lsb_release_exit_code" = "0" ]; then
			cat <<-EOF
			You're using '$lsb_dist' version '$dist_version'.
			EOF

			lsb_dist=$(lsb_release -a -u 2>&1 | tr '[:upper:]' '[:lower:]' | grep -E 'id' | cut -d ':' -f 2 | tr -d '[:space:]')
			dist_version=$(lsb_release -a -u 2>&1 | tr '[:upper:]' '[:lower:]' | grep -E 'codename' | cut -d ':' -f 2 | tr -d '[:space:]')

			cat <<-EOF
			Upstream release is '$lsb_dist' version '$dist_version'.
			EOF
		else
			if [ -r /etc/debian_version ] && [ "$lsb_dist" != "ubuntu" ] && [ "$lsb_dist" != "raspbian" ]; then
				if [ "$lsb_dist" = "osmc" ]; then
					lsb_dist=raspbian
				else
					lsb_dist=debian
				fi
				dist_version="$(sed 's/\/.*//' /etc/debian_version | sed 's/\..*//')"
				case "$dist_version" in
					12) dist_version="bookworm" ;;
					11) dist_version="bullseye" ;;
					10) dist_version="buster" ;;
					9) dist_version="stretch" ;;
					8) dist_version="jessie" ;;
				esac
			fi
		fi
	fi
}

# Function to perform Sonaric installation
do_install() {
	echo "# Executing Sonaric install script"

	user="$(id -un 2>/dev/null || true)"

	sh_c='sh -c'
	if [ "$user" != 'root' ]; then
		if command_exists sudo; then
			sh_c='sudo -E sh -c'
		elif command_exists su; then
			sh_c='su -c'
		else
			cat >&2 <<-'EOF'
			Error: this installer needs the ability to run commands as root.
			We are unable to find either "sudo" or "su" available to make this happen.
			EOF
			exit 1
		fi
	fi

	# Check if systemctl unit is present and active for Sonaric service
	if command_exists systemctl && systemctl list-units --full --all sonaricd.service | grep -Fq 'sonaricd.service'; then
		$sh_c 'systemctl start sonaricd' || echo "Failed to start sonaricd"
	fi

	# Detect Linux distribution and proceed with setup
	lsb_dist=$(get_distribution)
	lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

	case "$lsb_dist" in
		ubuntu|debian|raspbian)
			if command_exists lsb_release; then
				dist_version="$(lsb_release --codename | cut -f2)"
			fi
			if [ -z "$dist_version" ] && [ -r /etc/lsb-release ]; then
				dist_version="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
			fi

			# Check if Sonaric daemon is already installed
			if command_exists sonaricd; then
				echo "Sonaric is already installed"
				$sh_c 'apt-get install sonaricd sonaric'
				for try in {1..30}; do
					$sh_c "sonaric version" > /dev/null 2>&1 && break || sleep 2
				done
				$sh_c "sonaric update --nocolor --nofancy --all"
				exit 0
			fi

			# Check if apt satisfies the version requirement
			$sh_c "apt satisfy --dry-run 'podman (>=3.4.0)'" || (
				echo "ERROR: Available podman version is too old, please upgrade to a supported distro"
				exit 1
			)

			# Prepare prerequisites for Sonaric installation on Debian-based systems
			pre_reqs="apt-transport-https ca-certificates curl"
			if ! command -v gpg > /dev/null; then
				pre_reqs="$pre_reqs gnupg"
			fi
			apt_repo="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/sonaric.gpg] $APT_DOWNLOAD_URL sonaric-releases-apt main"

			(
				$sh_c 'apt-get update -qq >/dev/null'
				$sh_c "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $pre_reqs >/dev/null"
				$sh_c 'install -m 0755 -d /etc/apt/keyrings'
				$sh_c "curl -fsSL \"$APT_KEY_URL\" | gpg --dearmor --yes -o /etc/apt/keyrings/sonaric.gpg"
				$sh_c "chmod a+r /etc/apt/keyrings/sonaric.gpg"
				$sh_c "echo \"$apt_repo\" > /etc/apt/sources.list.d/sonaric.list"
				$sh_c 'apt-get update -qq >/dev/null'
			)
			$sh_c "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq sonaric >/dev/null"
			exit 0
			;;

		centos|fedora|rhel|rocky)
			if [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "rocky" ]; then
				pkg_manager="dnf"
				pre_reqs="dnf-plugins-core"
			elif [ "$lsb_dist" = "centos" ]; then
				pkg_manager="yum"
				pre_reqs="yum-utils"
			fi

			# Check if Sonaric daemon is already installed
			if command_exists sonaricd; then
				echo "Sonaric is already installed"
				$sh_c "$pkg_manager update --refresh -y -q sonaricd sonaric"
				$sh_c 'systemctl start sonaricd' || echo "Failed to start sonaricd"
				for try in {1..30}; do
					$sh_c "sonaric version" > /dev/null 2>&1 && break || sleep 2
				done
				$sh_c "sonaric update --nocolor --nofancy --all"
				exit 0
			fi

			(
				$sh_c "$pkg_manager install -y -q $pre_reqs"
				$sh_c "tee -a /etc/yum.repos.d/artifact-registry.repo << EOF
[sonaric-releases-rpm]
name=sonaric-releases-rpm
baseurl=$RPM_DOWNLOAD_URL
enabled=1
repo_gpgcheck=0
gpgcheck=0
EOF"

				$sh_c "$pkg_manager makecache"
			)
			(
				pkgs="sonaricd sonaric"
				$sh_c "$pkg_manager install -y -q $pkgs"
			)
			exit 0
			;;

		*)
			echo
			echo "ERROR: Unsupported distribution '$lsb_dist'"
			echo
			exit 1
			;;
	esac
	exit 1
}

# Call the installation function
do_install
