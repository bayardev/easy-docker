# EASY-DOCKER

Collection of shell scripts that make easier dockers life.

Include them in your images ...

**all scripts are POSIX compliants !**

## Scripts list

- easy-add **(_MAIN_)**
- php/add_fpm_pool.sh
- php/update_fpm_pool.sh
- php/update_phpini.sh
- php/alpine/5.6/add_php_ext.sh **(_DEPRECATED_)**
- php/alpine/7.0/add_php_ext.sh **(_DEPRECATED_)**
- php/alpine/add_php_ext.sh
- test/ci_test_container.sh


## Conf files templates

- php/etc/ : php{?version}.ini, php-fpm{?version}.conf, pool{?version}.conf


## Installation

**Get _easy-add_ script.**

In dockerfile :

```dockerfile
ADD https://raw.githubusercontent.com/bayardev/easy-docker/master/easy-add /usr/local/bin/easy-add
RUN chmod +x /usr/local/bin/easy-add
```

Or directly from a machine :

```sh
# with curl
curl -sSfLk -o /usr/local/bin/easy-add https://raw.githubusercontent.com/bayardev/easy-docker/master/easy-add
chmod +x /usr/local/bin/easy-add
```

## Usage

```sh
# get help with -h
easy-add -h

[Synopsis]
    Import file(s) from https://raw.githubusercontent.com/bayardev/easy-docker/master giving only repo relative path
    After import 'chmod +x' is executed on files with .sh extension or if -x option is set
[Usage]
   easy-add [-x] [-d 'dest-dir'] [-p 'prefix'] <File_RelativePath> [Another_File] [...]
[Options]
    -h  print this help and exit
    -x  force 'chmod +x' on imported files
    -d </path/to/destination>  set Destination Folder (default: '/usr/local/bin')
    -p  <prefix_> set Prefix for imported filenames (default: 'easy_')
        To remove prefix use '-p false'
[Examples]
       easy-add  php/update_phpini.sh php/alpine/add_php_ext.sh test/ci_test_container.sh
       easy-add -b /usr/local/bin php/update_phpini.sh
       easy-add -p false php/update_phpini.sh

```

## Help

[EASY-DOCKER Scripts HELP](HELP.md)
