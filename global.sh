# Colors
GREEN='\033[1;32m' # Green
BLUE='\033[1;34m' # Blue
RED='\033[1;31m' # Red
RESET='\033[0m' # No Color




# Get current directory
BASEDIR="$(pwd)"
#echo -e "BASEDIR: ${BASEDIR}"





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

else

	echo -e "${GREEN}Docker is running${RESET}"

fi



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
echo "Operating System: ${OS}"



# # Fix the missing WP_VERSION variable
# if [[ -f "${BASEDIR}/.env" ]]; then

# 	if [ -z $(grep "WP_VERSION" "${BASEDIR}/.env") ]; then 
# 		echo "WP version not found."
# 		echo "WP_VERSION=latest" >> "${BASEDIR}/.env"
# 		echo -e "WP version added ... ${GREEN}done${RESET}"
# 	fi

# fi



function sedreplace () {

	if [[ $OS == "MacOS" ]]; then

		sed -i "" "$1" "$2";

	else

		sed -i "$1" "$2";

	fi

}

function self_update () {

	# Builder updates
	echo "Updating the builder..."
	git pull
	git reset --hard
	git pull
	echo -e "Builder update complete ... ${GREEN}done${RESET}"

}

function server_permission_update () {

	echo "Fixing the server file permissions in ($1)..."
	docker-compose exec wp chown -R www-data:www-data "$1"
	# docker-compose exec wp chmod -R a=rwx $1
	docker-compose exec wp find "$1" -type d ! \( -path '*/node_modules/*' -or -path '*/.git/*' -or -name 'node_modules' -or -name '.git' \) -exec chmod 755 {} \;
	docker-compose exec wp find "$1" -type f ! \( -path '*/node_modules/*' -or -path '*/.git/*' -or -name 'node_modules' -or -name '.git' \) -exec chmod 644 {} \;
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
	command docker-compose run --no-deps --rm wpcli --allow-root "$@"
}

function update_environment {


	echo "Start updating environment files..."

	# Create the .env file from the template (local.env)
	rm -f "${BASEDIR}/.env"
	cp "${BASEDIR}/local.env" "${BASEDIR}/.env"
	echo -e ".env file created ... ${GREEN}done${RESET}"


	# Update the .env file
	sedreplace "s/DOMAIN=dev.sitename.com/DOMAIN=$DOMAIN/g" "${BASEDIR}/.env";
	sedreplace "s/WP_VERSION=latest/WP_VERSION=$WP_VERSION/g" "${BASEDIR}/.env";

	sedreplace "s/SLUG=site-name/SLUG=$SLUG/g" "${BASEDIR}/.env";
	sedreplace "s/Site Name/$NAME/g" "${BASEDIR}/.env";
	sedreplace "s/Site tagline/$DESC/g" "${BASEDIR}/.env";
	sedreplace "s/PREFIX=sitename/PREFIX=$PREFIX/g" "${BASEDIR}/.env";
	sedreplace "s/$DEFAULT_PLUGINS/$PLUGINS/g" "${BASEDIR}/.env";
	sedreplace "s/DEFAULT_PLUGINS/PLUGINS/g" "${BASEDIR}/.env";

	sedreplace "s/DEVELOPER_USERNAME=Username/DEVELOPER_USERNAME=$DEVELOPER_USERNAME/g" "${BASEDIR}/.env";
	sedreplace "s/DEVELOPER_NAME=Name/DEVELOPER_NAME=$DEVELOPER_NAME/g" "${BASEDIR}/.env";
	sedreplace "s/DEVELOPER_LAST_NAME=Lastname/DEVELOPER_LAST_NAME=$DEVELOPER_LAST_NAME/g" "${BASEDIR}/.env";
	sedreplace "s#DEVELOPER_EMAIL=name@company.com#DEVELOPER_EMAIL=$DEVELOPER_EMAIL#g" "${BASEDIR}/.env";
	sedreplace "s#DEVELOPER_URL=www.company.com#DEVELOPER_URL=$DEVELOPER_URL#g" "${BASEDIR}/.env";

	echo -e ".env file updated with the new info ... ${GREEN}done${RESET}"


	# Save the new site/.env file
	rm -f "${BASEDIR}/site/.env"
	cp "${BASEDIR}/.env" "${BASEDIR}/site/.env"
	echo -e ".env file copied to the 'site/' folder ... ${GREEN}done${RESET}"


}

function db_backup () {


	# Register the IP before overwrite
	REAL_IP=$IP


	# Get data
	source "${BASEDIR}/local.env"
	source "${BASEDIR}/site/.env"


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
	sedreplace "s/IP=127.0.0.1/IP=${REAL_IP}/g" "${BASEDIR}/.env";


	# Save the DB backup
	echo "Backing up the DB..."
	DB_FILE="${BASEDIR}/site/database/dump/wordpress_data.sql"
	docker-compose exec db /usr/bin/mysqldump -u root --password=password wordpress_data > "${DB_FILE}"
	tail -n +2 "${DB_FILE}" > "${DB_FILE}.tmp" && mv "${DB_FILE}.tmp" "${DB_FILE}"
	echo -e "DB Backup saved in '${DB_FILE}' ... ${GREEN}done${RESET}"

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
	while ! docker-compose exec db mysqladmin --user=root --password=password --host "${IP}" ping --silent &> /dev/null ; do
		echo "Waiting for database connection..."
		sleep 3
	done
	echo -e "MySQL is ready! ... ${GREEN}done${RESET}"


}

function move_import_files () {


	# If no "import/" folder added yet
	if [[ ! -d "${BASEDIR}/site/import/" ]]; then
		
		echo -e "${BLUE}Please move your 'import/' folder to the '${BASEDIR}/site/' folder and hit enter${RESET}"
		read IMPORT
		while [[ ! -d "${BASEDIR}/site/import" ]]; do 

			echo -e "${BLUE}Please move your 'import/' folder to the '${BASEDIR}/site/' folder and hit enter${RESET}"
			read IMPORT

		done

	fi
	echo -e "'import' folder detected ... ${GREEN}done${RESET}"

	# IMPORT FOLDER NOW EXISTS


	# Prepare the backup folder
	if [[ -f "${BASEDIR}/site/import/wp-config.php" ]]; then


		echo -e "${BLUE}FULL SITE BACKUP DETECTED${RESET}"


		echo -e "WP core files are being removed..."
		(
			cd "${BASEDIR}/site/import/"
			find . -mindepth 1 -maxdepth 1 ! -name 'wp-content' -exec rm -rf '{}' \;
		)
		echo -e "WP core files removed ... ${GREEN}done${RESET}"


		if [[ -f "${BASEDIR}/site/import/wp-content/mysql.sql" ]]; then

			echo -e "Moving the DB file..."
			mv "${BASEDIR}/site/import/wp-content/mysql.sql" "${BASEDIR}/site/import/mysql.sql"
			echo -e "DB file moved ... ${GREEN}done${RESET}"

		fi


		if [[ -f "${BASEDIR}/site/import/wp-content/advanced-cache.php" ]]; then

			rm -rf "${BASEDIR}/site/import/wp-content/advanced-cache.php"
			echo -e "'wp-content/advanced-cache.php' file removed ... ${GREEN}done${RESET}"

		fi


		if [[ -d "${BASEDIR}/site/import/wp-content/cache/" ]] || [[ -d "${BASEDIR}/site/import/wp-content/uploads/cache/" ]]; then

			rm -rf "${BASEDIR}/site/import/wp-content/cache/"
			rm -rf "${BASEDIR}/site/import/wp-content/uploads/cache/"
			echo -e "'cache' folders removed ... ${GREEN}done${RESET}"

		fi


		if [[ -d "${BASEDIR}/site/import/wp-content/mu-plugins/" ]]; then

			rm -rf "${BASEDIR}/site/import/wp-content/mu-plugins/"
			echo -e "'mu-plugins' folder removed ... ${GREEN}done${RESET}"

		fi


		if [[ -d "${BASEDIR}/site/import/wp-content/plugins/hyperdb" ]]; then

			rm -rf "${BASEDIR}/site/import/wp-content/plugins/hyperdb"
			rm -rf "${BASEDIR}/site/import/wp-content/plugins/hyperdb-1"
			rm -rf "${BASEDIR}/site/import/wp-content/plugins/hyperdb-1-1"
			echo -e "'hyperdb' plugin removed ... ${GREEN}done${RESET}"

		fi


		if [[ -d "${BASEDIR}/site/import/wp-content/plugins/really-simple-ssl" ]]; then

			rm -rf "${BASEDIR}/site/import/wp-content/plugins/really-simple-ssl"
			echo -e "'really-simple-ssl' plugin removed ... ${GREEN}done${RESET}"

		fi


		echo -e "${BLUE}FULL SITE BACKUP PREPARATION COMPLETE.${RESET}"


	fi


	# Create target folders if not exist
	if [[ ! -d "${BASEDIR}/site/database/dump/" ]]; then

		mkdir -p "${BASEDIR}/site/database/dump/"

	fi

	if [[ ! -d "${BASEDIR}/site/wp/wp-content/" ]]; then

		mkdir -p "${BASEDIR}/site/wp/wp-content/"

	fi


	# Move the SQL file
	if [[ -f "${BASEDIR}/site/import/db.sql" ]]; then

		rm -rf "${BASEDIR}/site/database/dump/wordpress_data.sql"
		mv "${BASEDIR}/site/import/db.sql" "${BASEDIR}/site/database/dump/wordpress_data.sql"
		echo -e "SQL file moved ... ${GREEN}done${RESET}"

	elif [[ -f "${BASEDIR}/site/import/mysql.sql" ]]; then

		rm -rf "${BASEDIR}/site/database/dump/wordpress_data.sql"
		mv "${BASEDIR}/site/import/mysql.sql" "${BASEDIR}/site/database/dump/wordpress_data.sql"
		echo -e "SQL file moved ... ${GREEN}done${RESET}"

	else

		echo -e "${RED}'db.sql' or 'mysql.sql' file does not exist in '${BASEDIR}site/import/' folder.${RESET}"
		exit

	fi


	# Remove existing MySQL files if exists
	if [[ -d "${BASEDIR}/site/database/mysql/" ]]; then
	
		rm -rf "${BASEDIR}/site/database/mysql/"

	fi


	# Move the wp-content folder
	if [[ -d "${BASEDIR}/site/import/wp-content/" ]]; then

		rm -rf "${BASEDIR}/site/wp/tmp_wp-content/"
		rm -rf "${BASEDIR}/site/wp/wp-content/"
		mv "${BASEDIR}/site/import/wp-content" "${BASEDIR}/site/wp/wp-content"
		echo -e "'wp-content' folder moved in place ... ${GREEN}done${RESET}"

	fi


	# Remove the import folder if successful
	if [[ ! -d "${BASEDIR}/site/import/wp-content/" ]] && [[ ! -f "${BASEDIR}/site/import/db.sql" ]] && [[ ! -f "${BASEDIR}/site/import/mysql.sql" ]]; then
	
		rm -rf "${BASEDIR}/site/import/"
		echo -e "'import' folder removed ... ${GREEN}done${RESET}"


	else

		echo -e "${RED}IMPORT ERROR${RESET}"
		exit

	fi


}

function make_temporary () {


	echo -e "'wp-content' folder is being temporary..."

	# Make the wp-content folder temporary
	if [[ -d "${BASEDIR}/site/wp/wp-content" ]]; then
		
		# Delete the old tmp_wp-content folder if exists
		rm -rf "${BASEDIR}/site/wp/tmp_wp-content"
		mv "${BASEDIR}/site/wp/wp-content" "${BASEDIR}/site/wp/tmp_wp-content"

		echo -e "'wp-content' folder has been made temporary ... ${GREEN}done${RESET}"

	fi


}

function make_permanent () {


	echo -e "'wp-content' folder is being permenant..."

	# Make the wp-content folder temporary
	if [[ -d "${BASEDIR}/site/wp/tmp_wp-content" ]]; then
		
		# Delete the old wp-content folder
		rm -rf "${BASEDIR}/site/wp/wp-content"
		mv "${BASEDIR}/site/wp/tmp_wp-content" "${BASEDIR}/site/wp/wp-content"

		echo -e "'wp-content' folder has been made permenant ... ${GREEN}done${RESET}"

	fi


}

function install_npm () {


	# If package.json exist in theme folder
	if [[ -f "${BASEDIR}/site/wp/wp-content/themes/${SLUG}/package.json" ]]; then



		# If Gulp not installed, build the gulp
		if [[ ! -d "${BASEDIR}/site/wp/wp-content/themes/${SLUG}/node_modules" ]] || [[ ! -d "${BASEDIR}/site/wp/wp-content/themes/${SLUG}/node_modules/gulp" ]]; then


			# RUN THE GULP
			echo "NPM packages are installing..."
			docker-compose run --no-deps --rm gulp npm run build
			echo -e "NPM packages installed ... ${GREEN}done${RESET}"


		fi



		# If Gulp file exist in theme folder
		if [[ -f "${BASEDIR}/site/wp/wp-content/themes/${SLUG}/gulpfile.js" ]]; then


			# RUN THE GULP
			echo "GULP is running..."
			docker-compose run --no-deps --rm gulp npm start


		fi



	fi


}