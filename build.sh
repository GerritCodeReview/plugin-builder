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
# Build script to build and deploy Gerrit API and plugins

plugins="
codenvy
commit-message-length-validator
cookbook-plugin
delete-project
download-commands
javamelody
replication
reviewers
reviewnotes
serviceuser
singleusergroup
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
PATH=/usr/lib/jvm/java-7-openjdk-amd64/bin:$PATH
git clone https://gerrit.googlesource.com/buck
(
    cd buck
    ant
)
PATH=$workspace/buck/bin:$PATH


gscp() {
    gsutil cp -a public-read $1 gs://$bucket/$2
}


# Checkout and build gerrit
git clone --recursive https://gerrit.googlesource.com/gerrit
code=0
(
    cd gerrit
    git checkout $release
    buck build all &> gerrit_$release.log
) || code=$?
if [ $code -ne 0 ]
then
    echo "gerrit failed to build with exit code $code" 1>&2
    gscp gerrit/gerrit_$release.log $release/
    exit 1
fi


# Build the api
code=0
(
    cd gerrit
    buck build api_install &> gerrit_api_$release.log
) || code=$?
if [ $code -ne 0 ]
then
    echo "api failed to build with exit code $code" 1>&2
    gscp gerrit/gerrit_api_$release.log $release/
    exit 1
fi


# Loop through the plugins and build them
for p in $plugins
do
    # clone plugin
    git clone https://gerrit.googlesource.com/plugins/$p
    ln -s ../../$p gerrit/plugins/$p

    # build plugin
    code=0
    (
      cd gerrit
      buck build plugins/$p:$p &> $p_$release.log
    ) || code=$?
    if [ $code -ne 0 ]
    then
        echo "plugin $p failed to build with exit code $code" 1>&2
        gscp gerrit/$p_$release.log $release/$p/
    else
        gscp gerrit/buck-out/gen/plugins/$p/$p.jar plugins/$release/$p/
    fi
done


# Update the html page
html=/tmp/index.html
echo "<html>
<head>
<title>Gerrit Plugins</title>
</head>
<body>
<ul>" > $html

for path in $(gsutil ls -r gs://gerritcodereview-plugins/ |
        egrep -v "(^|:)$" |
	egrep -o "gerritcodereview-plugins.*")
do
    echo "<li><a href=\"https://storage.cloud.google.com/$path\">$path</a></li>" >> $html
done
echo "</ul>
</body>
</html>" >> $html
gscp $html index.html
