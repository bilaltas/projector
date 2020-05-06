ARG WORDPRESS_VERSION
FROM wordpress:$WORDPRESS_VERSION


RUN apt-get update -qq &> /dev/null
RUN apt-get install -qq -y sudo less mariadb-client &> /dev/null
RUN rm -rf /var/lib/apt/lists/*
RUN curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x /usr/local/bin/wp