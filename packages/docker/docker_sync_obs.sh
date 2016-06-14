set -e

cd $(dirname $0)

. ../../package_sync_functions.sh

docker_git_version() {
	if grep -q -- '.0-dev' VERSION; then
		echo $(cat VERSION | sed "s/\.0-dev/~dev/")
	else
		echo $(cat VERSION | sed "s/-dev/~dev/")
	fi
}

package_sync_build_service https://api.opensuse.org Virtualization:containers:experimental docker https://github.com/SUSE/docker.mirror.git docker_git_version

exit 0
