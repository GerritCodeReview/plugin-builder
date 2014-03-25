#!/bin/bash

# Buck
mkdir ~/pgm
cd ~/pgm
git clone https://gerrit.googlesource.com/buck
cd ~/pgm/buck
ant
mkdir ~/bin
ln -s `pwd`/bin/buck ~/bin/

mkdir ~/projects
cd ~/projects

# checkout gerrit
git clone --recursive https://gerrit.googlesource.com/gerrit
cd ~/projects/gerrit

# build gerrit
buck all

# install api
buck build api_install

# build cookbook-plugin
buck build plugins/cookbook-plugin:cookbook-plugin

# deploy on google bucket
bucket=$(curl http://metadata/0.1/meta-data/attributes/gstorage_bucket)
gsutil cp buck-out/gen/plugins/cookbook-plugin/cookbook-plugin.jar gs://$bucket/plugins/master/
