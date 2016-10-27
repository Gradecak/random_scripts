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
    stack_log="$(stack build 2>&1)"
    failure="$(echo $stack_log | grep ExitFailure)"
    if [ "$failure" != "" ];then
        echo "$stack_log"
        echo "Build Failed, See above stack log for details..."
        exit 0
    else
        project="$(getProjectName)"
        args="$(genArgString)"
        stack exec $project $args
    fi
}

build
