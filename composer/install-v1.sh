#!/bin/bash

php -r "copy('https://getcomposer.org/download/1.10.20/composer.phar', 'composer-setup.php');"
php composer-setup.php --install-dir /usr/local/bin --filename composer1
