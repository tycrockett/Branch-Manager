#!/usr/bin/env bash

function prompt_command() {
    tytheme_icon='';
    tytheme_curBranch='';
    tytheme_changeDetails='';
    tytheme_GIT_UPDATER='';
    tytheme_remoteBRANCH='';
    tmp='';
    tytheme_gitterCheck=$(git rev-parse --git-dir 2> /dev/null);
    if [ $tytheme_gitterCheck ]; then

        if [ $tytheme_gitterCheck != '.git' ]; then
            tmp="${green} in $(basename "${tytheme_gitterCheck%/*}")"
        fi;

        tytheme_curBranch=$(git symbolic-ref --short -q HEAD)
        tmp=''
        if [[ $tytheme_curBranch != 'master' ]]; then tmp="...$tytheme_curBranch"; fi;
        
        tytheme_remoteCheck=$(git branch -a | egrep "remotes/origin/${tytheme_curBranch}$")
        if [[ -z $tytheme_remoteCheck ]]; then
            tytheme_icon="${bold_red}!"
            tmp=''
        else
            if [[ $tytheme_curBranch == 'master' ]]; then tytheme_icon="${bold_cyan}♔"; fi;
            if [[ $tytheme_curBranch != 'master' ]]; then tytheme_icon="${bold_cyan}☉"; fi;
            tytheme_icon="${bold_cyan}⇅"
        fi;
        
        tmp=$(git diff master$tmp --stat | tail -n1)
        if [[ -n $tmp ]]; then
            tytheme_changeDetails="\n| $tmp"
        fi

        
        if [[ -z $tytheme_remoteCheck ]]; then
            tytheme_icon="${bold_red}!"
            tmp=''
        else
            tytheme_icon="${bold_cyan}⇅"
        fi;

        tmp=$(git rev-list --count origin/master...master)
        if [[ $tmp > 0 ]]; then
            tmp1=" ${bold_blue}☝${white}"; 
            tytheme_GIT_UPDATER+=$tmp1
        else 
            (git fetch origin master &>/dev/null &); 
        fi;

        tmp=$(git status -s | egrep -c "^ ?")
        if [[ $tmp > 0 ]]; then
            tmp=$(git diff --shortstat | awk '{files+=$1; inserted+=$4; deleted+=$6;} 
                END {
                    if (files > 0) { print "|", files, "\b:", inserted + deleted, "|"}
                    if (files == 0) { print "|U|" }
                }')
            tytheme_GIT_UPDATER+=" ${bold_yellow}$tmp"
            # ⚡
        fi

	fi;
    PS1="\n${white}\W $tytheme_icon ${bold_green}$tytheme_curBranch$tytheme_remoteBRANCH$tytheme_GIT_UPDATER${blue}$tytheme_changeDetails${bold_blue}\n[>${reset_color}"
}

safe_append_prompt_command prompt_command
