set -ex

cd $(dirname $0)

. ../../package_sync_functions.sh

containerd_git_version() {
  for tp in {Major,Minor,Patch}; do
	  eval $tp=$(cat version.go | grep "const Version$tp" | sed -E 's/.*= ([0-9]*)$/\1/g')
  done

  echo "$Major.$Minor.$Patch"
}

package_sync_build_service https://api.opensuse.org Virtualization:containers:experimental containerd  https://github.com/docker/containerd.git containerd_git_version

exit 0
