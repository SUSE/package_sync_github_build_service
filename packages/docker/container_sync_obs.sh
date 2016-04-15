set -ex

cd $(dirname $0)

. ../../package_sync_functions.sh

containerd_git_version() {
  echo $(cat version.go | grep "const Version" | sed -E 's/.*= "(.*)"$/\1/g')
}

package_sync_build_service https://api.opensuse.org Virtualization:containers:experimental containerd  https://github.com/docker/containerd.git containerd_git_version

exit 0
