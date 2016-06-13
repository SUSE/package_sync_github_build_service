set -ex

cd $(dirname $0)

. ../../package_sync_functions.sh

runc_git_version() {
	if grep -q -- '.0-rc[0-9]' VERSION; then
		echo $(cat VERSION | sed "s/\.0-rc[0-9]/~dev/")
	else
		echo $(cat VERSION | sed "s/-rc[0-9]/~dev/")
	fi
}

package_sync_build_service https://api.opensuse.org Virtualization:containers:experimental runc https://github.com/opencontainers/runc.git runc_git_version

exit 0
