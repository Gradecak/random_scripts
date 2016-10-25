#!/bin/bash

function genArgString {
    args=( "${BASH_ARGV[@]}" )
    arg_string=""
    for i in "${args[@]}"; do
        arg_string="$arg_string $i"
    done
    echo "$arg_string"
}

function getProjectName {
    echo "$(ls | grep .cabal | awk -F.cabal '{print $1}')"
}

function build {
    b="$(stack build | grep Failure)"
    if [ "b" != "" ];then
        echo "Build Failed"
    else
        project="$(getProjectName)"
        args="$(genArgString)"
        stack exec $project $args
    fi
}

build
