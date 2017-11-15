#!/bin/bash
#bootstrap css custom setting

# variable
# change all to yours below.
USERID=temp_userid
BOOTSTRAP_VER=4.0.0-beta.2

echo "PROC : install nodeJS"
curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
yum install -y nodejs
yum install -y gcc-c++ make
yum install -y libffi-devel readline-devel sqlite-devel libyaml-devel

useradd $USERID

visudo <<edit_visudo
:/root.*ALL/
o$USERID  ALL=(ALL)       ALLZZ
edit_visudo

su $USERID


mkdir -p /home/$userID/www/public/assets/css
mkdir /home/$userID/www/public/assets/js

cp -rf custom/* /home/$USERID/www/public/assets/

cd /home/$USERID/www

wget https://github.com/twbs/bootstrap/archive/v"$BOOTSTRAP_VER".zip

unzip v"$BOOTSTRAP_VER".zip

mv bootstrap-$BOOTSTRAP_VER bootstrap4

chown -R "$USERID"."$USERID" /home/$USERID
chmod 705 /home/$USERID

su $USERID
cd ~/www/bootstrap4

# install RVM & RUBY
echo "PROC : start install rvm"

if [ `rvm -v | awk '{print $1}'` != "rvm" ]
then
	gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

	gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

	\curl -L https://get.rvm.io | sudo bash -s stable

	sudo usermod -G rvm $USERID

	source /etc/profile.d/rvm.sh
else
	echo "SKIP : already installed rvm"
fi

echo "PROC : start install ruby"

if [ `ruby -v | awk '{print $1}'` != "ruby" ]
then
	sudo rvm install 2.4.1
else
	echo "SKIP : already installed ruby"
fi

echo "PROC : start install bootstrap"

sed -i 's/js-compile-\*\\""/js-compile-\*\\""\,\n    "watch-custom": "nodemon --watch \.\.\/public\/assets\/scss\/ -e scss -x \\"npm run css-custom\\"",\n    "css-custom": "npm-run-all --parallel css-lint-custom css-compile-custom --sequential css-prefix-custom css-minify-custom",\n    "css-lint-custom": "stylelint --config build\/\.stylelintrc --syntax scss \\"\.\.\/public\/assets\/scss\/\*\*\/\*\.scss\\"",\n    "css-compile-custom": "node-sass --output-style expanded --source-map true --source-map-contents true --precision 6 \.\.\/public\/assets\/scss\/custom.scss \.\.\/public\/assets\/css\/bootstrap-custom.css",\n    "css-prefix-custom": "postcss --config build\/postcss\.config\.js --replace \\"\.\.\/public\/assets\/css\/bootstrap-custom\.css\\"",\n    "css-minify-custom": "cleancss --level 1 --source-map --source-map-inline-sources --output \.\.\/public\/assets\/css\/bootstrap-custom.min.css \.\.\/public\/assets\/css\/bootstrap-custom\.css"/' package.json

npm install
npm install jquery --save-dev

sudo gem install bundler
bundle install

cp -rf node_modules/popper.js/dist/umd/popper.min.* /home/$USERID/www/public/assets/js/
cp -rf node_modules/jquery/dist/jquery.min.* /home/$USERID/www/public/assets/js/
