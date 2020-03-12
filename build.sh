#!/bin/sh
set -eux

OUTDIR=~/output/

# S3 options
bucket=public
contentType="application/x-compressed-tar"

cd
pwd

# Clone Opencast repository
rm -rf opencast || :
git clone https://github.com/opencast/opencast.git
cd opencast

branches="$(git branch -r | sed -n 's_^.*origin/r/_r/_p' | sort -h | tail -n2) develop"

for branch in $branches; do
  cd modules
  git clean -fdx .
  cd ..
  git checkout "${branch}"
  mvn clean install \
    --batch-mode \
    -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn \
    -DskipTests

  # Upload files
  for file in build/*gz; do
    basename="$(basename "${file}")"
    resource="/${bucket}/daily-builds/${basename}"
    dateValue=`date -R`
    stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
    signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${S3_SECRET} -binary | base64`
    curl -X PUT -T "${file}" \
      -H "Host: s3.opencast.org" \
      -H "Date: ${dateValue}" \
      -H "Content-Type: ${contentType}" \
      -H "Authorization: AWS ${S3_KEY}:${signature}" \
      https://s3.opencast.org${resource}
  done
done
