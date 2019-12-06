#!/bin/bash


if [[ ${DEVELOPER_EMAIL} != *@twelve12.com ]]; then

	ADMIN_EMAIL=${DEVELOPER_EMAIL}
	ADMIN_USERNAME=${DEVELOPER_USERNAME}
	ADMIN_NAME=${DEVELOPER_NAME}
	ADMIN_LAST_NAME=${DEVELOPER_LAST_NAME}
	ADMIN_URL=${DEVELOPER_URL}

else

	ADMIN_EMAIL="webdesign@twelve12.com"
	ADMIN_USERNAME="Twelve12"
	ADMIN_NAME="Bill"
	ADMIN_LAST_NAME="T."
	ADMIN_URL="https://www.twelve12.com"

fi


# WP Installation
ADMIN_PASSWORD_INFO="$(wp core install --url="http://${DOMAIN}" --title="${NAME}" --admin_user=${ADMIN_USERNAME} --admin_email=${ADMIN_EMAIL} --skip-email)"
echo "${ADMIN_PASSWORD_INFO}"
export ADMIN_ONLY_PASSWORD=`echo "${ADMIN_PASSWORD_INFO}" | head -1`


# Update admin info
wp user update ${ADMIN_USERNAME} --user_url=${ADMIN_URL} --display_name="${ADMIN_NAME} ${ADMIN_LAST_NAME}" --first_name="${ADMIN_NAME}" --last_name="${ADMIN_LAST_NAME}"

# Hide the admin bar
wp user meta update ${ADMIN_USERNAME} show_admin_bar_front 0

# Hide Welcome panel
wp user meta update ${ADMIN_USERNAME} show_welcome_panel 0


# Create the developer user
if [[ ${DEVELOPER_EMAIL} != ${ADMIN_EMAIL} ]] && [[ ${DEVELOPER_EMAIL} != "" ]]; then

	DEVELOPER_PASSWORD_INFO="$(wp user create ${DEVELOPER_USERNAME} ${DEVELOPER_EMAIL} --user_url=${ADMIN_URL} --display_name="${DEVELOPER_NAME} ${DEVELOPER_LAST_NAME}" --first_name="${DEVELOPER_NAME}" --last_name="${DEVELOPER_LAST_NAME}" --role=administrator)"
	echo "${DEVELOPER_PASSWORD_INFO}"
	DEVELOPER_ONLY_PASSWORD=${DEVELOPER_PASSWORD_INFO##*$'\n'}

	export ADMIN_ONLY_PASSWORD=${DEVELOPER_ONLY_PASSWORD}
	export ADMIN_USERNAME=${DEVELOPER_USERNAME}

	# Hide the admin bar
	wp user meta update ${DEVELOPER_USERNAME} show_admin_bar_front 0

	# Hide Welcome panel
	wp user meta update ${DEVELOPER_USERNAME} show_welcome_panel 0

fi

# Discourage search engines from indexing this site
wp option set blog_public 0

# Update the tagline
wp option update blogdescription "${DESC}"

# Update the timezone
wp option update timezone_string "${TIMEZONE}"

# Update permalink settings
wp rewrite structure "${POST_PERMALINK}"

# Activate our theme
wp theme activate $SLUG

# Delete the default themes
wp theme delete twentysixteen twentyseventeen twentynineteen twentytwenty

# Delete the default plugins
wp plugin delete akismet hello

# Install the necessary plugins
wp plugin install prevent-browser-caching --activate

# Install selected plugins
wp plugin install ${PLUGINS}

# Change the Blog category
wp term update category 1 --name=Blog --slug=blog

# Delete the default Sample Page
wp post delete 2 --force

# Add the homepage
wp post create --post_type=page --post_title='Home' --meta_input='{"_wp_page_template":"templates/home-page.php"}' --post_status=publish

# Update the static page
wp option update page_on_front 4
wp option update show_on_front page

# Add the blog page
wp post create --post_type=page --post_title='Blog' --post_status=publish

# Update the static page
wp option update page_for_posts 5