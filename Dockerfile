FROM wordpress:5.4.2-php7.4-apache

#2. Install WP-cli and dependencies to run it
RUN apt-get update \
    && apt-get install -y \
      less \
      subversion \
      sudo \
      default-mysql-client-core \
    && curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp

# Install all mailhog
RUN apt-get install --no-install-recommends --assume-yes --quiet ca-certificates curl git &&\
    rm -rf /var/lib/apt/lists/*
RUN curl -Lsf 'https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz' | tar -C '/usr/local' -xvzf -
ENV PATH /usr/local/go/bin:$PATH
RUN go get github.com/mailhog/mhsendmail
RUN cp /root/go/bin/mhsendmail /usr/bin/mhsendmail
RUN echo 'sendmail_path = /usr/bin/mhsendmail --smtp-addr mailhog:1025' > /usr/local/etc/php/php.ini
RUN echo 'sendmail_path = /usr/bin/mhsendmail --smtp-addr mailhog:1025' >> /usr/local/etc/php/php.ini-development
RUN echo 'sendmail_path = /usr/bin/mhsendmail --smtp-addr mailhog:1025' >> /usr/local/etc/php/php.ini-production

#3. Create the files for the testing environment
RUN \
    #3.1 Install phpunit
    curl -L https://phar.phpunit.de/phpunit-7.phar -o /tmp/phpunit \
    && chmod a+x /tmp/phpunit \
    #3.2 Install wordpress
    && cp -r /usr/src/wordpress /tmp/wordpress \
    && curl https://raw.github.com/markoheijnen/wp-mysqli/master/db.php -o /tmp/wordpress/wp-content/db.php \
    #3.3 Install the testing libraries
    && svn co --quiet https://develop.svn.wordpress.org/tags/5.3.2/tests/phpunit/includes/ /tmp/wordpress-tests-lib/includes \
    && svn co --quiet https://develop.svn.wordpress.org/tags/5.3.2/tests/phpunit/data/ /tmp/wordpress-tests-lib/data \
    #3.4 set owner and permissions
    && chown -R www-data:www-data /tmp/wordpress \
    && chown -R www-data:www-data /tmp/wordpress-tests-lib

#4. Copy the script to create the testing environment when the container is started
COPY init-testing-environment.sh /usr/local/bin/
COPY install-wp-tests.sh /tmp/

#5. Run the script and send as an argument the command to run the apache service
ENTRYPOINT ["docker-entrypoint-wrapper.sh"]
ENTRYPOINT ["init-testing-environment.sh"]

#Install xdebug
RUN echo 'zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20190902/xdebug.so' > /usr/local/etc/php/php.ini
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host = host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

CMD ["apache2-foreground"]