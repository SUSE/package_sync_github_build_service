set -e

. ../../package_sync_functions.sh

docker_git_version() {
  echo $(git tag | grep -E '^v[0-9]+(\.[0-9]+)*$' | sort -Vr | head -n1 | sed "s/v//")
}

package_sync_build_service https://api.opensuse.org Virtualization:containers:experimental docker https://github.com/SUSE/docker.mirror.git docker_git_version

exit 0
