#!/bin/bash -ex
# Copyright (C) 2014 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Build script to build and install gerrit and plugins

plugins="codenvy cookbook-plugin delete-project javamelody reviewers serviceuser wip"
release=master
bucket=$(curl http://metadata/0.1/meta-data/attributes/gstorage_bucket)

# Wipe out the directory
rm -rf *

# Buck
mkdir ~/pgm
cd ~/pgm
git clone https://gerrit.googlesource.com/buck
cd ~/pgm/buck
ant
mkdir ~/bin
ln -s `pwd`/bin/buck ~/bin/
export PATH=~/bin:$PATH

mkdir ~/projects
cd ~/projects

# checkout gerrit
git clone --recursive https://gerrit.googlesource.com/gerrit
cd ~/projects/gerrit
git checkout $release

# build gerrit
buck build all &> gerrit_$release.log

if [ $? -ne 0 ]
then
    echo "gerrit failed to build with exit code $?"
    gsutil cp gerrit_$release.log gs://$bucket/plugins/$release/
    exit 1
fi

# install api
buck build api_install &> gerrit_api_$release.log
if [ $? -ne 0 ]
then
    echo "api failed to build with exit code $?"
    gsutil cp gerrit_api_$release.log gs://$bucket/plugins/$release/
    exit 1
fi

for p in $plugins; do

# clone plugin
cd ~/projects
git clone git clone https://gerrit.googlesource.com/plugins/$p

# link to the plugins directory
cd ~/projects/gerrit/plugins
ln -s ../../$p .

# build plugin
cd ~/projects/gerrit
buck build plugins/$p:$p &> $p_$release.log

if [ $? -ne 0 ]
then
    echo "plugin $p failed to build with exit code $?"
    gsutil cp $p_$release.log gs://$bucket/plugins/$release/$p/
    exit 1
else
    gsutil cp buck-out/gen/plugins/$p/$p.jar gs://$bucket/plugins/$release/$p/    
fi

done
