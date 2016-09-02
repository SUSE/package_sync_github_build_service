set -ex

package_sync_build_service() {

  if [ $# != 5 ];then
    echo "Usage $0 BUILD_SERVICE_API PROJECT PACKAGE UPSTREAM VERSION_METHOD"
    echo "For example:"
    echo "   $0 build.opensuse.org Virtualization:containers:experimental containerd https://github.com/docker/containerd.git container_git_version"
    exit -1
  fi

  OBS_COMMAND="osc -A $1"
  PROJECT="$2"
  PACKAGE="$3"
  UPSTREAM="$4"
  NEW_PACKAGE_VERSION_METHOD="$5"
  TMP=$WORKSPACE

  #######################################################################################################
  # First, we need to clone and fetch it from GitHub to figure out the version and other information.   #
  #######################################################################################################

  BRANCH="master"

  if [ ! -e "${TMP}/${PACKAGE}.git" ]; then
      cd $TMP
      git clone $UPSTREAM "${TMP}/${PACKAGE}.git" ||
          { echo "$(date) :: [GITHUB] clone upstream repo [FAIL]"; exit 1; }
  fi

  # Fetch latest version.
  cd "${TMP}/${PACKAGE}.git"
  git fetch $UPSTREAM ${BRANCH} || { echo "$(date) :: [GITHUB] fetch upstream repo [FAIL]"; exit 1; }
  git checkout FETCH_HEAD || { echo "$(date) :: [GITHUB] checkout upstream repo [FAIL]"; exit 1; }

  #############################################
  # Second, figure out version from the repo. #
  #############################################

  new_git_version=$(git log -n1 --pretty=format:%h)
  new_package_version=$($NEW_PACKAGE_VERSION_METHOD)
  new_version="${new_package_version}+git${new_git_version}"

  # Just to be informative.
  echo "new_git  :: ${new_git_version}"
  echo "new_ver  :: ${new_package_version}"
  echo "new_spec :: ${new_version}"

  #########################################################
  # Thirdly, clone OBS_REPO                              .#
  #########################################################

  PACKAGE_PATH="${TMP}/${PROJECT}/${PACKAGE}"

  if [ ! -e "${PACKAGE_PATH}/_service" ]; then
      cd $TMP
      $OBS_COMMAND checkout "$PROJECT" $PACKAGE ||
          { echo "$(date) :: [OBS] checkout the package [FAIL]"; exit 1; }

  fi

  # Update the state of the package repo.
  cd "${PACKAGE_PATH}"
  $OBS_COMMAND up

  #########################################################
  # Fourthly, generate fields in the package's spec file. #
  #########################################################

  # Read old version infos from OBS
  cd "${PACKAGE_PATH}"
  old_git_version=$(grep '%define git_version' ${PACKAGE}.spec | sed 's/%define git_version //')
  old_package_version=$(grep "%define ${PACKAGE}_version " ${PACKAGE}.spec | sed "s/%define ${PACKAGE}_version //")
  old_version=$(grep 'Version:' ${PACKAGE}.spec | sed 's/Version:\s*//')
  if [ "$old_git_version" == "" ];then
      echo "Sorry but I can't find the git_version definition"
      echo "Please edit the spec file and add"
      echo "%define git_version XXXX"
      exit -1
  fi
  if [ "$old_package_version" == "" ];then
      echo "Waning: I can't find the package_version definition"
      echo "This is not mandatory, so I am ignoring this."
  fi
  if [ "$old_version" == "" ];then
      echo "Sorry but I can't find the version definition"
      echo "Please edit the spec file and check the Version tag"
      exit -2
  fi

  # Just to be informative.
  echo "old_git  :: ${old_git_version}"
  echo "old_ver  :: ${old_package_version}"
  echo "old_spec :: ${old_version}"

  # Update specification file if necessary
  if [ "$new_git_version" != "$old_git_version" ] || [ -n "$($OBS_COMMAND diff)" ]; then
      echo ""
      echo "Update from ${old_version} to ${new_version}"

      message="Update to ${new_version}"

      # Replace the fields in the spec file.
      sed -E -i.bak "s/${old_git_version}/${new_git_version}/g" ${PACKAGE}.spec
      sed -E -i.bak "s/(Version:\s*).*/\1${new_version}/g" ${PACKAGE}.spec

      # Fix source filename
      sed -E -i.bak "s/(Source:\s*).*/\1%{name}-git.%{git_version}.tar.xz/g" ${PACKAGE}.spec
      sed -E -i.bak "s/%setup -q.*/%setup -q -n %{name}-git.%{git_version}/g" ${PACKAGE}.spec

      if [ "$old_package_version" != "" ]; then
          sed -E -i.bak "s/(%define ${PACKAGE}_version) ${old_package_version}/\1 ${new_package_version}/g" ${PACKAGE}.spec
      fi
      rm ${PACKAGE}.spec.bak

	  # Fix the commit inside the service file. Yes, we are editing XML with regex. Trust me, I'm a professional. :P
	  if [ -f "_service" ]; then
		  sed -E -i.bak "s/(\s*<param name=\"revision\">)[^<]*(<\/param>)/\1${new_package_version}\2/g" _service
		  rm _service.bak
	  fi

      # Sleep for a bit.
      sleep 1

      # Push.
      $OBS_COMMAND commit -m "$message" || { echo "$(date) :: [OBS] commit changes to package [FAIL]"; exit 1; }
  fi
}
