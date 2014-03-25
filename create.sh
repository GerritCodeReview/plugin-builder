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

zone=us-central2-b

gcutil --project google.com:gerritcodereview-build deleteinstance \
    --zone=$zone \
    pluginbuilder

gcutil --project google.com:gerritcodereview-build addinstance \
    --zone=$zone \
    --service_account=1082785722088@project.googleusercontent.com \
    --service_account_scopes=storage-rw \
    --machine_type=n1-standard-8 \
    --image=projects/debian-cloud/global/images/debian-7-wheezy-v20140318 \
    --metadata_from_file=startup-script:$(dirname $0)/setup.sh \
    --metadata=gstorage_bucket:gerrit-plugins \
    --auto_delete_boot_disk \
    pluginbuilder
