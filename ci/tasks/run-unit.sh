#!/usr/bin/env bash

set -e

my_dir="$( cd $(dirname $0) && pwd )"
release_dir="$( cd ${my_dir} && cd ../.. && pwd )"
workspace_dir="$( cd ${release_dir} && cd ../../../.. && pwd )"

export GOPATH=${workspace_dir}
export PATH=${GOPATH}/bin:${PATH}

semver='1.2.3.4'
timestamp=`date -u +"%Y-%m-%dT%H:%M:%SZ"`

pushd ${release_dir} > /dev/null
  git_rev=`git rev-parse --short HEAD`
  version="${semver}-${git_rev}-${timestamp}"

  echo -e "\n Vetting packages for potential issues..."
  go vet ./...

  echo -e "\n Installing ginkgo..."
  go get github.com/onsi/ginkgo/ginkgo

  echo -e "\n Unit testing packages..."
  ginkgo -r -race -skipPackage=integration ./

  echo -e "\n Running build script to confirm everything compiles..."
  go build -ldflags "-X main.version=${version}" -o out/s3cli .

  echo -e "\n Testing version information"
  app_version=$(out/s3cli -v)
  test "${app_version}" = "version ${version}"
popd > /dev/null
