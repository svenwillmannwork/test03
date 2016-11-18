#! /bin/bash

##############################################################################
# this is to make sure that everything fits together
##############################################################################


# file which contains the version number
versionFile="version.info"

# if there is no version info file, moan and refuse
if [ ! -f $versionFile ]; then
    echo "Version file $versionFile not found, unable to create the release"
    exit 1
fi

# read version info from file
source $versionFile
echo "Try to create release for $latestrc"


# check if release branch exist and check it out 
# new release release-v1.0.0, release-v1.5.2, etc.
releaseBranchLabel="release-$latestrc"
if git rev-parse -q --verify "refs/heads/$releaseBranchLabel" >/dev/null; then
    echo "Try to checkout branch: $releaseBranchLabel"
    # try to checkout tag for previous version

	git checkout $releaseBranchLabel
	git pull
else
    echo "Can not locate the branch $releaseBranchLabel, make sure it exists"
    exit 1
fi


##############################################################################
# now check if the release branch is dirty before continuing
##############################################################################

if git status | (
    unset dirty deleted untracked newfile ahead renamed
    while read line ; do
        case "$line" in
          *modified:*)                      dirty='!' ; ;;
          *deleted:*)                       deleted='x' ; ;;
          *'Untracked files:')              untracked='?' ; ;;
          *'new file:'*)                    newfile='+' ; ;;
          *'Your branch is ahead of '*)     ahead='*' ; ;;
          *renamed:*)                       renamed='>' ; ;;
        esac
    done
    bits="$dirty$deleted$untracked$newfile$ahead$renamed"
    [ -n "$bits" ] && echo " $bits" 
) >/dev/null; then
	echo "The current branch is dirty and you need to clean it first before creating the release"
	exit 1
fi


##############################################################################
# all conditions are met so 
# now lets merge into master and tag
##############################################################################

git checkout master
git pull
git merge --no-ff --no-commit $releaseBranchLabel
echo "Try to merge $releaseBranchLabel into master"
if [[ $# -eq 0 ]]; then
	echo "Merged went well, commiting now"
	git commit -m "Merged $releaseBranchLabel into master and create the tag $latestrc for the release"
	git tag -a $latestrc -m "Tag release version $latestrc"	
	git push --tags origin master
	exit 0
else 
	echo "Merged failed and I can not create the release, going to revert"
	git merge --abort
	exit 1
fi
