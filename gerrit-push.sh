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
    git push --force -o skip-validation $(git remote -v | head -1 | awk '{print $2}' | sed -e 's/https:\/\/github.com\/SuperiorOS/ssh:\/\/Sweeto143@gerrit.superioros.org:29418\/SuperiorOS/') HEAD:refs/heads/eleven
    cd -
done
cd $cwd