#!/bin/bash
LOG_DIR=/var/log
ROOT_UID=0
PARAMS=1
E_XCD=66
E_NOTROOT=67
E_WRONGARGS=65

PS3='select menu : '

#bootstrap css custom setting

# variable
# change all to yours below.
USERID=laravel
HTML_DIR=www
BOOTSTRAP_VER=4.0.0-beta.2
DOMAIN_NAME=${USERID}.domain.com

if [ "$UID" -ne "$ROOT_UID" ]
then
	echo "You must run this script as root."
	exit $E_NOTROOT
fi

echo

select menu in "LARAVEL" "BOOTSTRAP"
do
    case $menu in
    ""          ) echo "select number in menu";;
    *           ) echo "## install ${menu}";break;;
    esac
done

if [ "`grep ${USERID} /etc/passwd`" == "" ];then
	useradd ${USERID}
fi

if [ "`grep ${USERID} /etc/sudoers`" == "" ];then
	visudo <<edit_visudo
:/root.*ALL/
o${USERID}  ALL=(ALL)       ALLZZ
edit_visudo
fi
if [ -e /etc/httpd/conf.d/vhost.conf ];then
	vim /etc/httpd/conf.d/vhost.conf <<edit_vhost
Go

<virtualhost *:80>
    ServerAdmin webmaster@dummy-host.example.com
    DocumentRoot /home/${USERID}/${HTML_DIR}/public
    ServerName ${DOMAIN_NAME}
    ErrorLog logs/${USERID}-error_log
    CustomLog logs/${USERID}-access_log common
</VirtualHost>ZZ
edit_vhost
else
	vim /etc/httpd/conf.d/vhost.conf <<edit_vhost
i<Directory "/home/*">
    Options FollowSymLinks
    AllowOverride all
    Require all granted
</Directory>

NameVirtualHost *:80

<virtualhost *:80>
    ServerAdmin webmaster@dummy-host.example.com
    DocumentRoot /home/${USERID}/${HTML_DIR}/public
    ServerName ${DOMAIN_NAME}
    ErrorLog logs/${USERID}-error_log
    CustomLog logs/${USERID}-access_log common
</VirtualHost>ZZ
edit_vhost
fi

if [ "${menu}" == "LARAVEL" ];then
	echo -e "\033[01;33mPROC\t\033[0m : \033[01;32mstart install \033[33mLARAVEL\033[0m"
	if [ `composer -V | awk '{print $1}'` != "Composer" ];then
		curl -sS https://getcomposer.org/installer | php
		mv composer.phar /usr/local/bin/composer
	fi

	if [ ! -e ~/.config/composer/vendor/bin/laravel ];then
		composer global require "laravel/installer"
	fi

	cd /home/${USERID}/

	~/.config/composer/vendor/bin/laravel new ${HTML_DIR}

	chown -R ${USERID}.${USERID} .

	cd ${HTML_DIR}

	find storage -type d -exec chmod 757 {} \;
	chmod 757 bootstrap/cache

	su - ${USERID} -c "cd ~/${HTML_DIR};npm install"

	echo -e "\033[01;33mPROC\t\033[0m : \033[01;32mcomplete install \033[33mLARAVEL\033[0m"
fi


if [ "${menu}" == "BOOTSTRAP" ];then
	echo -e "\033[01;33mPROC\t\033[0m : \033[01;32mstart install \033[33mNODEJS\033[0m"
	if [[ `node -v` != v* ]];then
		curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
		yum install -y nodejs
		yum install -y gcc-c++ make
		yum install -y libffi-devel readline-devel sqlite-devel libyaml-devel
		echo -e "\033[01;33mPROC\t\033[0m : \033[01;32mcomplete install \033[33mNODEJS\033[0m"
	else
		echo -e "\033[01;33mSKIP\t\033[0m : \033[01;32malready installed \033[33mNODEJS\033[0m"
	fi

	mkdir -p /home/${USERID}/${HTML_DIR}/public/assets/css
	mkdir /home/${USERID}/${HTML_DIR}/public/assets/js

	cp -rf custom/* /home/${USERID}/${HTML_DIR}/public/assets/

	cd /home/${USERID}/${HTML_DIR}

	wget https://github.com/twbs/bootstrap/archive/v${BOOTSTRAP_VER}.zip

	unzip v${BOOTSTRAP_VER}.zip

	mv bootstrap-${BOOTSTRAP_VER} bootstrap4

	chown -R ${USERID}.${USERID} /home/${USERID}
	chmod 705 /home/${USERID}

	cd /home/${USERID}/${HTML_DIR}/bootstrap4

	# install RVM & RUBY
	echo -e "\033[01;33mPROC\t\033[0m : \033[01;32mstart install \033[33mrvm\033[0m"

	if [ `rvm -v | awk '{print $1}'` != "rvm" ]
	then
		su - ${USERID} -c "gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"

		su - ${USERID} -c "gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3"

		su - ${USERID} -c "\curl -L https://get.rvm.io | sudo bash -s stable"

		usermod -G rvm ${USERID}

		su - ${USERID} -c "source /etc/profile.d/rvm.sh"
		echo -e "\033[01;33mPROC\t\033[0m : \033[01;32mcomplete install \033[33mrvm\033[0m"
	else
		echo -e "\033[01;33mSKIP\t\033[0m : \033[01;32malready installed \033[33mrvm\033[0m"
	fi

	echo -e "\033[01;33mPROC\t\033[0m : \033[01;32mstart install \033[33mruby\033[0m"

	if [ `ruby -v | awk '{print $1}'` != "ruby" ]
	then
		rvm install 2.4.1
		echo -e "\033[01;33mPROC\t\033[0m : \033[01;32mcomplete install \033[33mruby\033[0m"
	else
		echo -e "\033[01;33mSKIP\t\033[0m : \033[01;32malready installed \033[33mruby\033[0m"
	fi

	echo -e "\033[01;33mPROC\t\033[0m : \033[01;32mstart install \033[33mbootstrap\033[0m"

	sed -i 's/js-compile-\*\\""/js-compile-\*\\""\,\n    "watch-custom": "nodemon --watch \.\.\/public\/assets\/scss\/ -e scss -x \\"npm run css-custom\\"",\n    "css-custom": "npm-run-all --parallel css-lint-custom css-compile-custom --sequential css-prefix-custom css-minify-custom",\n    "css-lint-custom": "stylelint --config build\/\.stylelintrc --syntax scss \\"\.\.\/public\/assets\/scss\/\*\*\/\*\.scss\\"",\n    "css-compile-custom": "node-sass --output-style expanded --source-map true --source-map-contents true --precision 6 \.\.\/public\/assets\/scss\/custom.scss \.\.\/public\/assets\/css\/bootstrap-custom.css",\n    "css-prefix-custom": "postcss --config build\/postcss\.config\.js --replace \\"\.\.\/public\/assets\/css\/bootstrap-custom\.css\\"",\n    "css-minify-custom": "cleancss --level 1 --source-map --source-map-inline-sources --output \.\.\/public\/assets\/css\/bootstrap-custom.min.css \.\.\/public\/assets\/css\/bootstrap-custom\.css"/' package.json

	su - ${USERID} -c "cd ~/${HTML_DIR}/bootstrap4;npm install"
	su - ${USERID} -c "cd ~/${HTML_DIR}/bootstrap4;npm install jquery --save-dev"

	su - ${USERID} -c "cp -rf ~/${HTML_DIR}/bootstrap4/node_modules/popper.js/dist/umd/popper.min.* ~/${HTML_DIR}/public/assets/js/"
	su - ${USERID} -c "cp -rf ~/${HTML_DIR}/bootstrap4/node_modules/jquery/dist/jquery.min.* /home/${USERID}/${HTML_DIR}/public/assets/js/"

	echo -e "\033[01;33mPROC\t\033[0m : \033[01;32mcomplete install \033[33mbootstrap\033[0m"

	echo -e "\033[01;31;43m## NOTICE ##\033[0m"
	echo -e "## you must \033[31mrelogin\033[0m and \033[31mrun\033[0m below :"
	echo -e "\t \033[01;4mgem install bundler\033[0m"
	echo -e "\t \033[01;4mbundle install\033[0m"
fi
exit 0
