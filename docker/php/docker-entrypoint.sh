#!/bin/sh

set -e

if [ -z "$1" ]; then
  ATTEMPTS_LEFT_TO_REACH_DATABASE=60
  PLUGIN_ROADRUNNER="Micro\\\\Plugin\\\\Http\\\\HttpRoadrunnerPlugin::class"
  PLUGIN_LIST_PHP_FILE="etc/plugins.php"

  if [ ! -f composer.json ]; then
  		rm -Rf tmp/
  		composer create-project "micro/micro $MICRO_VERSION" tmp --remove-vcs --stability="$STABILITY" --prefer-dist --no-progress --no-interaction --no-install

  		cd tmp
  		cp -Rp . ..
  		cd -
  		rm -Rf tmp/

  		if grep -q ^DATABASE_URL= .env; then
  			echo "To finish the installation please press Ctrl+C to stop Docker Compose and run: docker compose up --build -d --wait"
  			sleep infinity
  		fi
  	fi

  if ! composer show micro/plugin-http-roadrunner > /dev/null 2>&1; then
  	  export COMPOSER_REQUIRED_NEW_PACKAGES=1
      composer require micro/plugin-http-roadrunner --prefer-dist --no-progress --no-interaction
  fi

  if [ ! -f "$PLUGIN_LIST_PHP_FILE" ]; then
      echo "Please ensure the plugin $PLUGIN_ROADRUNNER is added to the plugin list."
  else
    if ! grep -q "$PLUGIN_ROADRUNNER" "$PLUGIN_LIST_PHP_FILE"; then
        sed -i "/];/i \ \ \ \ $PLUGIN_ROADRUNNER," "$PLUGIN_LIST_PHP_FILE"
    fi
  fi


  if [ -z "$(ls -A 'vendor/' 2>/dev/null)" ] || [ ! -z "$COMPOSER_REQUIRED_NEW_PACKAGES" ]; then
      composer install --prefer-dist --no-progress --no-interaction
  fi

  if [ -f bin/rr ]; then
    php vendor/bin/rr get --location bin/
    chmod +x bin/rr
  fi

  if [ "$( find ./migrations -iname '*.php' -print -quit )" ]; then
    php bin/console doctrine:migrations:migrate --no-interaction
  fi

  if [ ! -d ./var ]; then
     mkdir ./var
  fi

  chown -R $(whoami):www-data var
  chmod -R 770 var

  if [ -n "$ENV" ] && [ -f ".rr.$ENV.yaml" ]; then
     exec rr serve -c ".rr.$ENV.yaml"
     exit 0
  else
     exec rr serve -c ".rr.yaml"
     exit 0
  fi
fi

exec $@
