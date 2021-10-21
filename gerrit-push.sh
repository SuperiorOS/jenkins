#!/usr/bin/env bash

# A gerrit script to push all repositories from a manifest

# This again, will have to be adapted based on your setup.

cwd=$PWD
cd ~/superior
PROJECTS="$(grep 'superior' .repo/manifests/snippets/superior.xml  | awk '{print $2}' | awk -F'"' '{print $2}' | uniq | grep -v caf)"
for project in ${PROJECTS}
do
    cd $project
    echo $project
    git push --force -o skip-validation $(git remote -v | head -1 | awk '{print $2}' | sed -e 's/https:\/\/github.com\/SuperiorOS/ssh:\/\/Darkstar085@review.superioros.org:29400\/SuperiorOS/') HEAD:refs/heads/twelve
    cd -
done
cd $cwd
