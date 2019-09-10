# Colors
GREEN='\033[1;32m' # Green
BLUE='\033[1;34m' # Blue
RED='\033[1;31m' # Red
RESET='\033[0m' # No Color




# Get current directory
BASEDIR="$(pwd)"
#echo -e "BASEDIR: $BASEDIR"




function sedreplace () {

	if [[ $OS == "MacOS" ]]; then

		sed -i "" "$1" "$2";

	else

		sed -i "$1" "$2";

	fi

}

function get_env_data {


	# Get data from sample.env file
	source "$BUILDERDIR/sample.env"


	# Get local.env in project folder, if exists
	if [[ -f "$PROJECTDIR/local.env" ]]; then

		source "$PROJECTDIR/local.env"

	fi


	# Get .env in project folder, if exists
	if [[ -f "$PROJECTDIR/.env" ]]; then

		source "$PROJECTDIR/.env"
		SLUG=$PROJECTNAME

	fi


}

function update_environment {


	echo "Start updating environment files..."

	if [[ -z $WP_VERSION ]]; then

		echo -e "${RED}Environment variables couldn't be updated.${RESET}"
		return

	fi

	SAMPLE_ENV="$BUILDERDIR/sample.env"
	PROJECT_ENV="$PROJECTDIR/.env"
	LOCAL_ENV="$PROJECTDIR/local.env"

	# Create the .env file from the template (local.env)
	rm -f "$LOCAL_ENV"
	cp "$SAMPLE_ENV" "$LOCAL_ENV"
	echo -e "local.env file created ... ${GREEN}done${RESET}"


	# Update the .env file
	sedreplace "s/DOMAIN=dev.sitename.com/DOMAIN=$DOMAIN/g" "$LOCAL_ENV";
	sedreplace "s/WP_VERSION=latest/WP_VERSION=$WP_VERSION/g" "$LOCAL_ENV";

	sedreplace "s/SLUG=site-name/SLUG=$SLUG/g" "$LOCAL_ENV";
	sedreplace "s/ACTIVE_THEME=site-name/ACTIVE_THEME=$SLUG/g" "$LOCAL_ENV";
	sedreplace "s/DB_PREFIX=wp_/DB_PREFIX=$DB_PREFIX/g" "$LOCAL_ENV";

	sedreplace "s/NAME=\"Site Name\"/NAME=\"$NAME\"/g" "$LOCAL_ENV";
	sedreplace "s/DESC=\"Site tagline\"/DESC=\"$DESC\"/g" "$LOCAL_ENV";
	sedreplace "s/PREFIX=sitename/PREFIX=$PREFIX/g" "$LOCAL_ENV";
	sedreplace "s/$DEFAULT_PLUGINS/$PLUGINS/g" "$LOCAL_ENV";
	sedreplace "s/DEFAULT_PLUGINS/PLUGINS/g" "$LOCAL_ENV";

	sedreplace "s/DEVELOPER_USERNAME=Username/DEVELOPER_USERNAME=$DEVELOPER_USERNAME/g" "$LOCAL_ENV";
	sedreplace "s/DEVELOPER_NAME=Name/DEVELOPER_NAME=$DEVELOPER_NAME/g" "$LOCAL_ENV";
	sedreplace "s/DEVELOPER_LAST_NAME=Lastname/DEVELOPER_LAST_NAME=$DEVELOPER_LAST_NAME/g" "$LOCAL_ENV";
	sedreplace "s#DEVELOPER_EMAIL=name@company.com#DEVELOPER_EMAIL=$DEVELOPER_EMAIL#g" "$LOCAL_ENV";
	sedreplace "s#DEVELOPER_URL=www.company.com#DEVELOPER_URL=$DEVELOPER_URL#g" "$LOCAL_ENV";

	echo -e "local.env file updated with the new info ... ${GREEN}done${RESET}"


	# Make the local.env live
	rm -f "$PROJECT_ENV"
	cp "$LOCAL_ENV" "$PROJECT_ENV"
	echo -e "local.env copied as .env ... ${GREEN}done${RESET}"


	# Add slashes to the directories
	PROJECT_DIR=$(echo "$PROJECTDIR" | sed 's/ /\\ /g')
	BUILDER_DIR=$(echo "$BUILDERDIR" | sed 's/ /\\ /g')


	# Add the PROJECT_DIR and BUILDER_DIR to .env file
	echo "PROJECT_DIR=$PROJECT_DIR" >> "$PROJECT_ENV"
	echo "BUILDER_DIR=$BUILDER_DIR" >> "$PROJECT_ENV"
	echo -e "Add project and builder directories to the .env file ... ${GREEN}done${RESET}"


	echo -e "Updating environment files ... ${GREEN}done${RESET}"


}

function self_update () {

	(
		cd "$BUILDERDIR"

		# Builder updates
		echo "Updating the builder..."
		git pull
		git reset --hard
		git pull
		echo -e "Builder update complete ... ${GREEN}done${RESET}"

	)

}

function docker_compose {

	if [[ -f "$PROJECTDIR/.env" ]]; then

		(
			cd "$PROJECTDIR"
			command docker-compose -f "$BUILDERDIR/docker-compose.yml" -p "$SLUG" "$@"
		)
	
	else

		echo -e "${RED}Cannot do any docker-compose command because project is not installed.${RESET}"

	fi

}

function run_server_if_not_running {


	# Check if services are running
	if [[ $CONTAINEREXISTS == "yes" ]] && [[ $CONTAINERRUNNING == "no" ]]; then


		echo "Services not running. Starting..."
		docker_compose up -d --no-recreate

		if [[ ! -z `docker ps -q --no-trunc | grep $(docker_compose ps -q wpcli)` ]] && [[ ! -z `docker ps -q --no-trunc | grep $(docker_compose ps -q db)` ]]; then

			CONTAINERRUNNING="yes"
			echo -e "Services restarted ... ${GREEN}done${RESET}"

		else

			echo -e "${RED}Services could not be started.${RESET}"

		fi


	fi # If not running


}

function server_permission_update () {


	echo "Fixing the server file permissions in ($1)..."
	docker_compose exec wpcli chown -R www-data:www-data "$1"
	# docker_compose exec wpcli chmod -R a=rwx $1
	docker_compose exec wpcli find "$1" -type d ! \( -path '*/node_modules/*' -or -path '*/.git/*' -or -name 'node_modules' -or -name '.git' \) -exec chmod 755 {} \;
	docker_compose exec wpcli find "$1" -type f ! \( -path '*/node_modules/*' -or -path '*/.git/*' -or -name 'node_modules' -or -name '.git' \) -exec chmod 644 {} \;
	echo -e "Server file permissions fixed ... ${GREEN}done${RESET}"


}

function permission_update () {

	echo "Fixing the file permissions in ($1)..."
	#sudo chown -R $(logname):staff $1
	find "$1" ! \( -path '*/node_modules/*' -or -path '*/.git/*' -or -name 'node_modules' -or -name '.git' \) -exec chown $(logname):staff {} \;
	# sudo chmod -R a=rwx $1
	find "$1" -type d ! \( -path '*/node_modules/*' -or -path '*/.git/*' -or -name 'node_modules' -or -name '.git' \) -exec chmod 755 {} \;
	find "$1" -type f ! \( -path '*/node_modules/*' -or -path '*/.git/*' -or -name 'node_modules' -or -name '.git' \) -exec chmod 644 {} \;
	echo -e "File permissions fixed ... ${GREEN}done${RESET}"

}

function git_permission_update () {

	echo "Fixing the git permissions in ($1)..."
	# cd /path/to/repo.git
	sudo chmod -R g+rwX "$1"
	find "$1" -type d -exec chmod g+s '{}' +
	echo -e "Git permissions fixed ... ${GREEN}done${RESET}"

}

function wp {

	docker_compose exec wpcli wp --allow-root "$@"

}

function db_backup () {


	if [[ $INSTALLED == "yes" ]] && [[ $CONTAINEREXISTS == "yes" ]]; then


		# Run server if not running
		run_server_if_not_running


		# Register the IP before overwrite
		REAL_IP=$IP


		# Get data
		source "$BUILDERDIR/sample.env"
		source "$PROJECTDIR/.env"


		# Re-assign the real IP
		IP=$REAL_IP


		# Checking the WP version
		echo "Checking the WP version..."
		WP_VERSION="$(wp core version)"
		WP_VERSION=${WP_VERSION%?}
		echo -e "WP version found: ${GREEN}${WP_VERSION}${RESET}"


		# Update environment files
		update_environment


		# Update the current local IP on builder
		sedreplace "s/IP=127.0.0.1/IP=${REAL_IP}/g" "$PROJECTDIR/.env";


		# Save the DB backup
		echo "Backing up the DB..."
		DB_FILE_NAME=wordpress_data.sql
		wp db export $DB_FILE_NAME
		mv "$PROJECTDIR/wp/${DB_FILE_NAME}" "$PROJECTDIR/database/dump/${DB_FILE_NAME}"
		#echo -e "DB Backup saved in '$PROJECTDIR/database/dump/${DB_FILE_NAME}' ... ${GREEN}done${RESET}"


	else

		echo -e "${BLUE}Cannot get DB backup because project is not installed.${RESET}"

	fi

}

function db_import {


	# Move to the WP area
	cp -rf "$1" "$PROJECTDIR/wp/wordpress_data.sql"


	# Delete all the tables
	echo "Resetting DB..."
	wp db reset --yes


	# Import the DB
	echo "Importing DB..."
	wp db import "wordpress_data.sql"


	# Delete the file from WP area
	rm -rf "$PROJECTDIR/wp/wordpress_data.sql"


}

function search_replace {


	FIND_DOMAIN=$1
	REPLACE_DOMAIN=$2

	# Remove the protocol
	find1="https://"
	find2="http://"
	replace=""
	FIND_DOMAIN="${FIND_DOMAIN/$find1/$replace}"
	FIND_DOMAIN="${FIND_DOMAIN/$find2/$replace}"

	REPLACE_DOMAIN="${REPLACE_DOMAIN/$find1/$replace}"
	REPLACE_DOMAIN="${REPLACE_DOMAIN/$find2/$replace}"


	echo "DB replacements starting (${FIND_DOMAIN} -> ${REPLACE_DOMAIN})..."


	# Force HTTP
	echo -e "Http forcing..."
	wp search-replace "https://${FIND_DOMAIN}" "http://${FIND_DOMAIN}" --recurse-objects --report-changed-only --all-tables
	echo -e "Http force ... ${GREEN}done${RESET}"


	# Check the same values
	if [[ $FIND_DOMAIN != $REPLACE_DOMAIN ]]; then


		# Domain change
		echo -e "Domain changing..."
		wp search-replace "${FIND_DOMAIN}" "${REPLACE_DOMAIN}" --recurse-objects --report-changed-only --all-tables
		echo -e "Domain change ... ${GREEN}done${RESET}"

		# Email corrections !!! TO-DO
		#wp search-replace "@${REPLACE_DOMAIN}" "@${FIND_DOMAIN}" --recurse-objects --report-changed-only

		echo -e "DB replacements from '${FIND_DOMAIN}' to '${REPLACE_DOMAIN}' ... ${GREEN}done${RESET}"


	else


		echo -e "${GREEN}Values are the same. ${RESET}"


	fi



	# Rewrite Flush
	echo -e "Flushing the rewrite rules..."
	wp rewrite flush --hard
	echo -e "Flushing the rewrite rules ... ${GREEN}done${RESET}"


	# Save the DB backup
	db_backup

}

function db_url_update () {


	echo -e "Checking registered domain name..."
	OLD_DOMAIN="$(wp option get siteurl)"
	OLD_DOMAIN=${OLD_DOMAIN%?}
	echo -e "Registered domain name: ${GREEN}${OLD_DOMAIN}${RESET}"


	# URL replacements
	if [[ $OLD_DOMAIN != "http://${DOMAIN}" ]]; then

		# Do the replacements
		search_replace "${OLD_DOMAIN}" "${DOMAIN}"

	else

		echo "No need to do DB replacements."

	fi


}

function wait_for_mysql () {


	# Check MySQL to be ready
	while ! docker_compose exec db mysqladmin --user=root --password=password --host "$IP" ping --silent &> /dev/null ; do
		echo "Waiting for database connection ..."
		sleep 3
	done
	echo -e "MySQL is ready! ... ${GREEN}done${RESET}"


}

function move_import_files () {


	# If no "import/" folder added yet
	if [[ ! -d "$PROJECTDIR/import/" ]]; then

		echo -e "${BLUE}Please move your 'import/' folder to the '$PROJECTDIR/' folder and hit enter${RESET}"
		read IMPORT
		while [[ ! -d "$PROJECTDIR/import" ]]; do

			echo -e "${BLUE}Please move your 'import/' folder to the '$PROJECTDIR/' folder and hit enter${RESET}"
			read IMPORT

		done

	fi
	echo -e "'import' folder detected ... ${GREEN}done${RESET}"

	# IMPORT FOLDER NOW EXISTS


	# Prepare the backup folder
	if [[ -f "$PROJECTDIR/import/wp-config.php" ]]; then


		echo -e "${BLUE}FULL SITE BACKUP DETECTED${RESET}"


		echo -e "WP core files are being removed..."
		(
			cd "$PROJECTDIR/import/"
			find . -mindepth 1 -maxdepth 1 ! -name 'wp-content' -exec rm -rf '{}' \;
		)
		echo -e "WP core files removed ... ${GREEN}done${RESET}"


		if [[ -f "$PROJECTDIR/import/wp-content/mysql.sql" ]]; then

			echo -e "Moving the DB file..."
			mv "$PROJECTDIR/import/wp-content/mysql.sql" "$PROJECTDIR/import/mysql.sql"
			echo -e "DB file moved ... ${GREEN}done${RESET}"

		fi


		if [[ -f "$PROJECTDIR/import/wp-content/advanced-cache.php" ]]; then

			rm -rf "$PROJECTDIR/import/wp-content/advanced-cache.php"
			echo -e "'wp-content/advanced-cache.php' file removed ... ${GREEN}done${RESET}"

		fi


		if [[ -d "$PROJECTDIR/import/wp-content/cache/" ]] || [[ -d "$PROJECTDIR/import/wp-content/uploads/cache/" ]]; then

			rm -rf "$PROJECTDIR/import/wp-content/cache/"
			rm -rf "$PROJECTDIR/import/wp-content/uploads/cache/"
			echo -e "'cache' folders removed ... ${GREEN}done${RESET}"

		fi


		if [[ -d "$PROJECTDIR/import/wp-content/mu-plugins/" ]]; then

			rm -rf "$PROJECTDIR/import/wp-content/mu-plugins/"
			echo -e "'mu-plugins' folder removed ... ${GREEN}done${RESET}"

		fi


		if [[ -d "$PROJECTDIR/import/wp-content/plugins/hyperdb" ]]; then

			rm -rf "$PROJECTDIR/import/wp-content/plugins/hyperdb"
			rm -rf "$PROJECTDIR/import/wp-content/plugins/hyperdb-1"
			rm -rf "$PROJECTDIR/import/wp-content/plugins/hyperdb-1-1"
			echo -e "'hyperdb' plugin removed ... ${GREEN}done${RESET}"

		fi


		if [[ -d "$PROJECTDIR/import/wp-content/plugins/really-simple-ssl" ]]; then

			rm -rf "$PROJECTDIR/import/wp-content/plugins/really-simple-ssl"
			echo -e "'really-simple-ssl' plugin removed ... ${GREEN}done${RESET}"

		fi


		echo -e "${BLUE}FULL SITE BACKUP PREPARATION COMPLETE.${RESET}"


	fi


	# Create target folders if not exist
	if [[ ! -d "$PROJECTDIR/database/dump/" ]]; then

		mkdir -p "$PROJECTDIR/database/dump/"

	fi

	if [[ ! -d "$PROJECTDIR/wp/wp-content/" ]]; then

		mkdir -p "$PROJECTDIR/wp/wp-content/"

	fi


	# Move the SQL file
	if [[ -f "$PROJECTDIR/import/db.sql" ]]; then

		rm -rf "$PROJECTDIR/database/dump/wordpress_data.sql"
		mv "$PROJECTDIR/import/db.sql" "$PROJECTDIR/database/dump/wordpress_data.sql"
		echo -e "SQL file moved ... ${GREEN}done${RESET}"

	elif [[ -f "$PROJECTDIR/import/mysql.sql" ]]; then

		rm -rf "$PROJECTDIR/database/dump/wordpress_data.sql"
		mv "$PROJECTDIR/import/mysql.sql" "$PROJECTDIR/database/dump/wordpress_data.sql"
		echo -e "SQL file moved ... ${GREEN}done${RESET}"

	else

		echo -e "${RED}'db.sql' or 'mysql.sql' file does not exist in '$BASEDIR/site/import/' folder.${RESET}"
		exit

	fi


	# Remove existing MySQL files if exists
	if [[ $INSTALLED != "yes" ]] && [[ -d "$PROJECTDIR/database/mysql/" ]]; then

		rm -rf "$PROJECTDIR/database/mysql/"

	fi


	# Move the wp-content folder
	if [[ -d "$PROJECTDIR/import/wp-content/" ]]; then

		rm -rf "$PROJECTDIR/wp/tmp_wp-content/"
		rm -rf "$PROJECTDIR/wp/wp-content/"
		mv "$PROJECTDIR/import/wp-content" "$PROJECTDIR/wp/wp-content"
		echo -e "'wp-content' folder moved in place ... ${GREEN}done${RESET}"

	fi


	# Remove the import folder if successful
	if [[ ! -d "$PROJECTDIR/import/wp-content/" ]] && [[ ! -f "$PROJECTDIR/import/db.sql" ]] && [[ ! -f "$PROJECTDIR/import/mysql.sql" ]]; then

		rm -rf "$PROJECTDIR/import/"
		echo -e "'import' folder removed ... ${GREEN}done${RESET}"


	else

		echo -e "${RED}IMPORT ERROR${RESET}"
		exit

	fi


}

function make_temporary () {


	# Make the wp-content folder temporary
	if [[ -d "$PROJECTDIR/wp/wp-content" ]]; then

		echo -e "'wp-content' folder is being temporary..."
		rm -rf "$BUILDERDIR/temp/${SLUG}_wp-content"
		mv "$PROJECTDIR/wp/wp-content" "$BUILDERDIR/temp/${SLUG}_wp-content"
		echo -e "'wp-content' folder has been made temporary ... ${GREEN}done${RESET}"

	fi


}

function make_permanent () {


	# Make the wp-content folder temporary
	if [[ -d "$BUILDERDIR/temp/${SLUG}_wp-content" ]]; then

		echo -e "'wp-content' folder is being permenant..."
		rm -rf "$PROJECTDIR/wp/wp-content"
		mv "$BUILDERDIR/temp/${SLUG}_wp-content" "$PROJECTDIR/wp/wp-content"
		echo -e "'wp-content' folder has been made permenant ... ${GREEN}done${RESET}"

	fi


}

function install_npm () {


	# If package.json exist in theme folder
	if [[ -f "$PROJECTDIR/wp/wp-content/themes/$SLUG/package.json" ]]; then



		# If Gulp not installed, build the gulp
		if [[ ! -d "$PROJECTDIR/wp/wp-content/themes/$SLUG/node_modules" ]] || [[ ! -d "$PROJECTDIR/wp/wp-content/themes/$SLUG/node_modules/gulp" ]]; then


			# RUN THE GULP
			echo "NPM packages are installing..."
			(
				cd "$PROJECTDIR/wp/wp-content/themes/$SLUG"
				npm run build
			)
			echo -e "NPM packages installed ... ${GREEN}done${RESET}"


		fi



		# If Gulp file exist in theme folder
		if [[ -f "$PROJECTDIR/wp/wp-content/themes/$SLUG/gulpfile.js" ]]; then


			# RUN THE GULP
			echo "GULP is running..."
			(
				cd "$PROJECTDIR/wp/wp-content/themes/$SLUG"
				npm start
			)


		fi



	fi


}




# FIND CURRENT OS
OS="Unknown"
if [[ "$OSTYPE" == "linux-gnu" ]]; then
        OS="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="MacOS"
elif [[ "$OSTYPE" == "cygwin" ]]; then
        # POSIX compatibility layer and Linux environment emulation for Windows
		OS="cygwin"
elif [[ "$OSTYPE" == "msys" ]]; then
        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
		OS="msys"
elif [[ "$OSTYPE" == "win32" ]]; then
        OS="Win32"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
        OS="FreeBSD"
fi
#echo "Operating System: ${OS}"


# CHECK IF OS SUPPORTED
if [[ $OS != "MacOS" ]]; then

	echo -e "${RED}Projector only works on Mac OS systems yet.${RESET}"
	exit

fi




# CHECK IF DOCKER INSTALLED
if [[ ! -d "/Applications/Docker.app" ]]; then

	echo -e "${RED}Docker is not installed to your computer. Please install and try again.${RESET}"
	exit

fi




# CHECK DOCKER WHETHER OR NOT RUNNING
rep=$(docker ps -q &>/dev/null)
status=$?
if [[ "$status" != "0" ]]; then

    echo 'Docker is opening...'
    open /Applications/Docker.app


    while [[ "$status" != "0" ]]; do

        echo 'Docker is starting...'
        sleep 3

        rep=$(docker ps -q &>/dev/null)
        status=$?

    done

    echo -e "${GREEN}Docker connected${RESET}"

fi