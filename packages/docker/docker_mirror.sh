set -e

TMP=$WORKSPACE
# Github
UPSTREAM="https://github.com/docker/docker.git"
BRANCH="master"
FORK="git@github.com:/SUSE/docker.mirror.git"

if [ ! -e ${TMP}/docker.git ]; then
    cd $TMP
    git clone --bare $UPSTREAM ||
        { echo "$(date) - (Github) Clone the Fork [FAIL]"; exit 1; }
fi

# Mirror Github branch (upstream)
cd $TMP/docker.git
git fetch --tags $UPSTREAM ${BRANCH}:${BRANCH} || { echo "$(date) - (Github) Fetch Upstream [FAIL]"; exit 1; }
git push -f --tags $FORK || { echo "$(date) - (Github) Push origin master [FAIL]"; exit 1; }
git push -f $FORK ${BRANCH}:${BRANCH} || { echo "$(date) - (Github) Push origin master [FAIL]"; exit 1; }

