#!/bin/bash

#############################################################################
##
## Copyright (C) 2020 The Qt Company Ltd.
## Contact: http://www.qt.io/licensing/
##
## This file is the CI build utilities of the Qt Toolkit.
##
## $QT_BEGIN_LICENSE:GPL-EXCEPT$
## Commercial License Usage
## Licensees holding valid commercial Qt licenses may use this file in
## accordance with the commercial license agreement provided with the
## Software or, alternatively, in accordance with the terms contained in
## a written agreement between you and The Qt Company. For licensing terms
## and conditions see https://www.qt.io/terms-conditions. For further
## information use the contact form at https://www.qt.io/contact-us.
##
## GNU General Public License Usage
## Alternatively, this file may be used under the terms of the GNU
## General Public License version 3 as published by the Free Software
## Foundation with exceptions as appearing in the file LICENSE.GPL3-EXCEPT
## included in the packaging of this file. Please review the following
## information to ensure the GNU General Public License requirements will
## be met: https://www.gnu.org/licenses/gpl-3.0.html.
##
## $QT_END_LICENSE$
##
#############################################################################


# Takes 2 arguments: repo_name and ref

# Needs several environment variables to be set.
# Example settings:
#ARTIFACT_NAME=install_dir-${{matrix.os}}
#ARTIFACT_NAME=install_dir-ubuntu-18.04
#ARTIFACT_EXTRACT_CMDLINE="funzip | zstd -d -c | tar -xf -"
#GITHUB_TOKEN=secret
#WORKFLOW_NAME=ninja-build.yml
#GITHUB_REPOSITORY=qt/qtsvg
# Optional
# If FORCE BRANCH is set, then the ref argument ($2) is ignored
#FORCE_BRANCH=dev


set -eu -o pipefail


error () {
    [ -z "$1" ]  ||  echo ERROR: "$1"  1>&2
    exit 1
}


repo="$1"
ref="$2"
owner=`echo "$GITHUB_REPOSITORY" | cut -d/ -f1`
[ -z "${WORKFLOW_NAME:-}" ]  &&  error "You need to set WORKFLOW_NAME"
[ -z "${ARTIFACT_NAME:-}" ]  &&  error "You need to set ARTIFACT_NAME"
[ -z "${GITHUB_TOKEN:-}" ]   &&  error "You need to set GITHUB_TOKEN"
[ -z "${ARTIFACT_EXTRACT_CMDLINE:-}" ]  \
    &&  error "You need to set ARTIFACT_EXTRACT_CMDLINE"

# You need to expand this using eval every time you execute curl
curl_params="--show-error
    --header 'Accept: application/vnd.github.v3+json'
    --header 'Authorization: Bearer $GITHUB_TOKEN'
"


echo "Trying to fetch artifact '$ARTIFACT_NAME' from workflow '$WORKFLOW_NAME' and repo '$owner/$repo'"
echo "CWD is: `pwd`"

if [ -z "${FORCE_BRANCH:-}" ]
then
    echo "Listing runs for ref:" "$ref"
    jq_args='.workflow_runs | map(select(.status=="completed" and .conclusion=="success" and .head_sha=="'"$ref"'"))[0].id'
else
    echo "FORCE_BRANCH was set, listing runs for branch:" "$FORCE_BRANCH"
    jq_args='.workflow_runs | map(select(.status=="completed" and .conclusion=="success" and .head_branch=="'"$FORCE_BRANCH"'"))[0].id'
fi

# List workflow runs; the first is the most recent one
run_id=$(
    eval curl $curl_params \
        "https://api.github.com/repos/${owner}/${repo}/actions/workflows/${WORKFLOW_NAME}/runs"  \
        | jq "$jq_args"
)

[ "$run_id" = null ]  \
    && error "Did not find any workflow runs"  \
    || echo run_id: "$run_id"

# List artifact URL and size
api_response=$(
    eval curl $curl_params \
        "https://api.github.com/repos/${owner}/${repo}/actions/runs/${run_id}/artifacts"  \
        | jq ".artifacts[] | select(.name==\"${ARTIFACT_NAME}\") | .archive_download_url, .size_in_bytes"
)

[ -z "$api_response" ] || [ "$api_response" = null ]  \
    && error "Did not find any artifacts"

# First line is the URL surrounded by double quotes, which we strip
artifact_download_url=`echo "$api_response" | sed -n '1s/"//gp'`
# Second line is the size in bytes, which we convert to kilobytes
artifact_size=`echo "$api_response" | sed -n '2p'`
artifact_size_kb=`expr $artifact_size / 1024`

echo artifact_download_url: "$artifact_download_url"
echo "Download the archived artifact (size $artifact_size_kb KB) and pipe it through command line:" "$ARTIFACT_EXTRACT_CMDLINE"

# Double the quotes around URL to avoid unsafe eval
eval curl $curl_params -Lo- '"$artifact_download_url"'  \
    \| $ARTIFACT_EXTRACT_CMDLINE

echo DONE

