#!/bin/sh
set -eux

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
	 s3cmd put "${file}" "s3://public/daily/${basename}"
  done
done
