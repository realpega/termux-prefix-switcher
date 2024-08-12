#!/bin/bash
# Termux Prefix Switcher
# Developed by realpega

case "$(getprop ro.build.version.release)" in
	5*|6*)
		echo "Android 5/6 isn't supported! 🤡"
		exit 2
		;;
	*) ;;
esac

unset LD_PRELOAD

BOOTSTRAP_ARM="https://github.com/termux/termux-packages/releases/download/bootstrap-2021.04.13-r1/bootstrap-arm.zip"

BOOTSTRAP_INTEL="https://github.com/termux/termux-packages/releases/download/bootstrap-2021.04.13-r1/bootstrap-i686.zip"

TEMPDIR="$(mktemp -d)"

print-help(){
	cat <<- EOM
	Termux Prefix Switcher

	Options:
	 help - show this info
	 switch - Switches to 32-bit Mode 🗿💀
	 revert - Reverts to 64-bit Mode 🤦🏻‍♀️

	NOTE: You will need to re-install all the previously installed packages manually after you switch to 32-bit Mode 🥺

	Termux Prefix Switcher [github.com/realpega/termux-prefix-switcher]
	EOM
}

switch(){
	# Check if running as 32-bit
	case "$(uname -m)" in
		armv8*|armv7*|i*86)
			cat <<- EOM
			Cannot Switch Environment! ❌ Your device is running in 32-bit! 🤡
			EOM
			exit 2
			;;
		*) ;;
	esac
	# Print some warning message
	cat <<- EOM
	⚠️ WARNING: You're about to destroy all your data 🥰 (within Termux 🤡) 32-bit is good for using Wine 🍷 

	* Inconsistency will occur when running 64-bit on 32-bit environment, in some cases with the preloaded termux-exec library, you can usually unset it

	* When Running Chromium in 32-bit proot'ed linux environment, expect segmentation failures (even with --no-sandbox) option,

	* This Script will not track what packages you've installed, so you will need to reinstall them again if possible

	The Installation will begin in 5 seconds & all your data will be lost! 😂
	EOM
	sleep 5.5

	echo "Downloading 32-bit Termux bootstrap... 🗿💀"
	case "$(uname -m)" in
		aarch64)
			curl --fail --location --output $TEMPDIR/termux-bootstrap.zip.part "$BOOTSTRAP_ARM"
			;;
		x86_64)
			curl --fail --location --output $TEMPDIR/termux-bootstrap.zip.part "$BOOTSTRAP_INTEL"
			;;
		*)
			exit 2
	esac

	# Check if file is downloaded properly
	if [ -e $TEMPDIR/termux-bootstrap.zip.part ]; then
		mv $TEMPDIR/termux-bootstrap.zip.part $TEMPDIR/termux-bootstrap.zip
	else
		echo "An error has occured! Aborting Installation... 🏳️‍🌈"
		exit 2
	fi

	# Unpack and remove existing installation
	echo "Unpacking 32-bit termux bootstrap... 🗿"
	sleep 3
	chmod 755 usr -R ||:
	rm -rf $PREFIX/../usr32-staging
	unzip -d $PREFIX/../usr32-staging $TEMPDIR/termux-bootstrap.zip

	# Process Symlinks
	echo "Processing Symlinks... 🐣"
	cd $PREFIX/../usr32-staging
	while read s; do
		ln -s ${s/←/ }
	done <SYMLINKS.txt
	rm SYMLINKS.txt

	# Create Second Stage Script
	echo "Doing Second Stage Setup... 👉🏻👌🏻"
	cat > $PREFIX/../secondstage-setup.sh <<- EOM
	#!/system/bin/sh
	echo "Creating Backup... 💦"
	mv usr usr64-backup
	echo "Switching... 🗿"
	mv usr32-staging usr
	rm secondstage-setup.sh
	echo "Done ✅ Please Close and Reopen the app!"
	sleep 2
	kill -KILL $PPID
	EOM
	chmod 755 $PREFIX/../secondstage-setup.sh
	cd $PREFIX/..

	# Kill Current Process and Do Second Stage Setup
	exec /system/bin/env -i ./secondstage-setup.sh
}

revert(){
	# Check if running in 64-bit mode
	case "$(uname -m)" in
		aarch64|x86_64)
			echo "This option is used to switch back to 64-bit. But you're already in 64-bit! 🤦🏻‍♀️🤣"
			exit 2
			;;
		*) ;;
	esac

	# Ask for Confirmation
	read -p "Do you want to switch back to 64-bit? 🥵 All data in this environment will be lost 😭 [y/N]" answer

	case "$answer" in
		Y*|y*) ;;
		*) echo "Aborting... 🏳️‍🌈"; exit 2 ;;
	esac

	# Switch back to 64-bit
	cd $PREFIX/..

	# Check if Backup File Exists
	if [ ! -e usr64-backup ]; then
		echo "The Backup Directory doesn't exist! 🤦🏻‍♀️ Continuing anyway! 💀"
	fi

	# Revert Back to 64-bit
	echo "Purging 32-bit environment... 🏳️‍🌈"
	cat > purge-prefix.sh <<- EOM
	#!/system/bin/sh
	chmod 755 usr -R ||:
	rm -rf usr

	# Restore Backup directory if possible"
	if [ -e usr64-backup ]; then
		echo "Restoring 64-bit Prefix... 🗿"
		mv usr64-backup usr
	fi

	rm -rf purge-prefix.sh

	echo "Done ✅ Please Close and Reopen the app!"
	sleep 2
	kill -KILL $PPID
	EOM
	chmod 755 purge-prefix.sh

	# Kill Current Process and Purge 32-bit prefix
	exec /system/bin/env -i ./purge-prefix.sh
}

args="$1"

if [ -z "$args" ]; then
	print-help
	exit 2
fi

case "$args" in
	help)
		print-help
		;;
	switch)
		switch
		;;
	revert)
		revert
		;;
	*)
		cat <<- EOM
		Unknown Argument: $args

		See "termux-prefix-switcher help" for more information
		EOM
		;;
esac

# EOF
