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

plugins="
codenvy
cookbook-plugin
delete-project
javamelody
reviewers
serviceuser
wip
"
release=master
bucket=$(curl http://metadata/0.1/meta-data/attributes/gstorage_bucket)
workspace=~/workspace

# Cleanup
rm -rf $workspace
mkdir $workspace
cd $workspace

# Checkout and build buck
git clone https://gerrit.googlesource.com/buck
(
    cd buck
    ant
    mkdir ~/bin
)
PATH=$workspace/buck/bin:$PATH


# Checkout and build gerrit
git clone --recursive https://gerrit.googlesource.com/gerrit
(
    cd gerrit
    git checkout $release
    buck build all &> gerrit_$release.log
)
code=$?
if [ $code -ne 0 ]
then
    echo "gerrit failed to build with exit code $code" 1>&2
    gsutil cp gerrit_$release.log gs://$bucket/plugins/$release/
    exit 1
fi


# Build the api
(
    cd gerrit
    buck build api_install &> gerrit_api_$release.log
)
code=$?
if [ $code -ne 0 ]
then
    echo "api failed to build with exit code $code" 1>&2
    gsutil cp gerrit_api_$release.log gs://$bucket/plugins/$release/
    exit 1
fi


# Loop through the plugins and build them
for p in $plugins
do
    # clone plugin
    git clone https://gerrit.googlesource.com/plugins/$p
    ln -s ../../$p gerrit/plugins/$p

    # build plugin
    (
      cd gerrit
      buck build plugins/$p:$p &> $p_$release.log
    )
    code=$?
    if [ $code -ne 0 ]
    then
        echo "plugin $p failed to build with exit code $code" 1>&2
        gsutil cp gerrit/$p_$release.log gs://$bucket/plugins/$release/$p/
    else
        gsutil cp gerrit/buck-out/gen/plugins/$p/$p.jar \
                gs://$bucket/plugins/$release/$p/    
    fi
done
