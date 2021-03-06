#!/bin/bash
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
# Run this script to create the pluginbuilder instance

if [ $# != 1 ]
then
    echo "Usage: $0 ZONE" 1>&2
    echo "ZONE suggestion: us-central2-b" 1>&2
    exit 1
fi

project=google.com:gerritcodereview-build
zone=$1
name=pluginbuilder

gcutil --project $project deleteinstance \
    --force \
    --delete_boot_pd \
    --zone=$zone \
    $name

# Specifying the service account explicitly is causing GCE to choke
# Not sure what's wrong here.
# --service_account=1082785722088@project.googleusercontent.com \
gcutil --project $project addinstance \
    --zone=$zone \
    --service_account_scopes=storage-rw \
    --machine_type=n1-standard-8 \
    --image=projects/debian-cloud/global/images/debian-7-wheezy-v20140318 \
    --metadata_from_file=startup-script:$(dirname $0)/setup.sh \
    --metadata=gstorage_bucket:gerritcodereview-plugins \
    --auto_delete_boot_disk \
    $name
