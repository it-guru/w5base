#!/bin/bash

declare -i rev

for ((rev = 1; rev < 10800; ++rev))
do
    hash=$(git svn find-rev "r$rev")
    if [ -z $hash ]; then
        break
    fi
    # TODO Pad with 0's for small values of rev
    tag="svn_r$rev"
    git tag -a -m "$tag" $tag $hash
done

