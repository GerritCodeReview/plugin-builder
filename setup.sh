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
#
# This script:
# * bootstraps the build scripts
# * installs needed packages and sets up the environment
# * kicks off a build if requested


# Grab the latest files from git and install them
# if the setup file has changed, rerun it
apt-get install git-core
oldsetup=/tmp/pb-oldsetup.sh
path=/usr/pb
cp $0 $oldsetup
rm -rf $path
git clone https://gerrit-review.googlesource.com/plugin-build $path
if [ $(sha1sum $path/setup.sh) != $(sha1sum $oldsetup) ]
then
    rm $oldsetup
    $path/setup.sh $1
    exit 0
fi


# Install the needed packages and setup the environment
apt-get install openjdk-7-jdk ant maven
rm -rf $path
echo "0 0 * * * /usr/pb/setup.sh build >> /var/log/pb.log" | crontab -u root
adduser --uid 1337 --disabled-password --gecos ,,, worker


# Kick off a build if requested
if [ $1 == build ]
then
    su worker -c $path/build.sh
fi
