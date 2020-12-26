FROM wordpress

RUN apt -qy install $PHPIZE_DEPS \
	&& pecl install xdebug \
	&& docker-php-ext-enable xdebug

RUN touch /usr/local/etc/php/php.ini
RUN echo 'xdebug.start_with_request=yes' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.mode=off' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.client_host="host.docker.internal"' >> /usr/local/etc/php/php.ini