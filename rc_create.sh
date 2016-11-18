#! /bin/bash

#ensure version argument
if [[ $# -eq 0 ]]; then
    echo "No version argument supplied!"
    echo "usage: <script>.sh 1.5.2"
    exit 1
fi

# check if there is a version that might be ambiguous
if git ls-remote | grep $1 >/dev/null; then
    echo "!!!!!! --->"
    echo "Found something for $1 which might lead to an ambiguous version, please make it more unique!"
    read -r -p "Do you want to see the full list [y/N] " response
    case $response in
        [yY][eE][sS]|[yY]) 
            git ls-remote
            ;;
        *)
            echo "Done"
            ;;
    esac
    exit 1
fi


# file which contains the version number
versionFile="version.info"

# new version
version=$1
# add 'v' to the version if not provided
if [[ $1 != v* ]]; then version=v$1; fi

# new release release-v1.0.0, release-v1.5.2, etc.
releaseBranchLabel=release-$version


# make sure you are on master
echo "Will switch to master in order to create the release branch"
git checkout master
git pull


# check if there is a version info file, if not, create one and add to repo
if [ ! -f $versionFile ]; then
    echo "Version file $versionFile not found, will create it now"
    echo "latestrc=v0.0.0-init" > $versionFile
    git add $versionFile
    git commit -m "Create $versionFile"
    git push -u origin master
fi

# read version info from file
source $versionFile
echo "Previous release: $latestrc"


# check if tag for previous release exist otherwise us master for branch
tag=$latestrc
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
    echo "Try to checkout tag: $tag"
    # try to checkout tag for previous version

	git checkout $tag
	git pull
else
    # as the tag is not found, will use master
    echo "Tag $tag not found will stay on latest master"
fi


# create the new release branch 
echo "Create the following release branch $releaseBranchLabel"
git checkout -b $releaseBranchLabel


echo "Updating version file with: $version"
# replace version property e.g. last-release-tag=release-v1.5.1 with newly specified version number
sed -i '' "s/latestrc=[^ ]*/latestrc=$version/g" $versionFile 


# commit version number increment to release branch
echo "Commit version file to new branch: $releaseBranchLabel"
git add $versionFile
git commit -m "Incrementing version number to $version"


# push new release branch and set up the tracking information
echo "Push branch $releaseBranchLabel to origin"
git push -u origin $releaseBranchLabel

echo "Done"

