# EASY-DOCKER Scripts HELP

## php/add_fpm_pool

```sh
easy_add_fpm_pool -h

[Synopsis]
    Create new php-fpm pool for <app-name> based on template
[Usage]
   easy_add_fpm_pool [-options] <app-name> [user] [group]
[Options]
    -h  print this help and exit
    -d <fpm-conf-dir>  php-fpm conf dir (default: '/usr/local/etc/php-fpm.d')
    -t <template-name>  pool template-name (default: 'pool.conf.tpl')
[Examples]
       easy_add_fpm_pool myapp myuser
       easy_add_fpm_pool -d /etc/php-fpm.d myapp php-fpm
[Defaults]
    user  : www-data
    group : If the group is not set, the default user's group will be used
```


## php/update_fpm_pool

```sh
easy_update_fpm_pool -h

[Synopsis]
    Modify a fpm-pool.conf values if specific env-vars are setted
[Usage]
    easy_update_fpm_pool [-options] [pool-name]
[Options]
    -h  print this help and exit
    -d <fpm-conf-dir>  php-fpm conf dir (default: '/usr/local/etc/php-fpm.d')
[Examples]
       easy_update_fpm_pool myapp
       FPM_USER='myuser' easy_update_fpm_pool
       FPM_LISTEN_MODE='0666' easy_update_fpm_pool -d /etc/php-fpm.d

```

## php/update_phpini

```sh
easy_update_phpini -h

[Synopsis]
    Modify php.ini values according to EnvVars values
[Usage]
    ./update_phpini.sh [-c] [-p 'phpini-path']
[Options]
    -h  print this help and exit
    -l  list ini_keys and exit
    -p   </path/to/php.ini>   set php.ini path (default: /etc/php.ini)
    -c  force php.ini creation if does not exists
[Examples]
       PHPINI_DATE_TIMEZONE='Europe/Paris' ./update_phpini.sh
       ./update_phpini.sh -p /etc/php.ini
       ./update_phpini.sh -c -p '/usr/local/etc/php/php.ini'

```

#### More information

When exporting environment variable with "PHPINI_" header, if you give it a null value, this variable will be commented in php.ini if it exists keeping its value

```sh
PHPINI_DATE_TIMEZONE= ./update_phpini.sh
./update_phpini.sh -p /etc/php.ini
cat /etc/php.ini

...
; date_timezone='Europe/Paris'
...
```

## php/alpine/add_php_ext

```sh
easy_add_php_ext -h

[Synopsis]
    Install php extensions
[Usage]
    easy_add_php_ext <ext_name> [more_ext] [...]
[Options]
    -h  print this help and exit
[Examples]
       easy_add_php_ext sockets pdo_mysql zip

```