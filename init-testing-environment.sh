#!/bin/bash

cd /var/www/html/

sudo -u www-data -- wp core is-installed

#1. check if wordpress is already installed/configured
if [ $? -eq 0 ]; then
  echo "core is installed"
	#2. check if the database is ready
	if ! (sudo -u www-data -- wp db check)
	then
		# wait a moment for the database container
		sleep 1
		exit 1;
	fi

	#3. init the testing instance
	sudo -u www-data -- wp scaffold plugin-tests $WP_PLUGIN_FOLDER --force

	cd wp-content/plugins/$WP_PLUGIN_FOLDER
	rm ./bin/install-wp-tests.sh
	cp /tmp/install-wp-tests.sh ./bin/
	cp /tmp/bootstrap.php ./tests/

	sudo -u www-data -- bash -c "./bin/install-wp-tests.sh $WP_TESTS_DB_NAME $WORDPRESS_DB_USER $WORDPRESS_DB_PASSWORD $WORDPRESS_DB_HOST 5.4.2 false true"
else
  echo "core is not installed"
fi

#4. back to the root WP folder
cd /var/www/html/

#5. execute the entrypoint of the parent image
bash docker-entrypoint.sh "$@"