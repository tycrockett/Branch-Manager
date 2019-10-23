#!/usr/bin/env bash

function prompt_command() {
    branchCompletion
    rpoCompletion
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

        tmp='';
        tytheme_remoteCheck=$(git branch -a | egrep "remotes/origin/${tytheme_curBranch}$")
        if [[ -z $tytheme_remoteCheck ]]; then
            tytheme_icon="${bold_red}!"
        else
            if [[ $tytheme_curBranch == $BMGLOBES_defaultBranch ]]; then tytheme_icon="${bold_cyan}♔"; fi;
            if [[ $tytheme_curBranch != $BMGLOBES_defaultBranch ]]; then tytheme_icon="${bold_cyan}☉"; fi;
        fi;

        tmp=''
        if [[ $BMGLOBES_defaultBranch != 'master' ]]; then tmp="origin/$BMGLOBES_defaultBranch"; fi;
        if [[ $tytheme_curBranch != $BMGLOBES_defaultBranch ]]; then tmp="$BMGLOBES_defaultBranch...$tytheme_curBranch"; fi;
        if [[ $BMGLOBES_defaultBranch == 'master' && $tytheme_curBranch == 'master' ]]; then tmp="$BMGLOBES_defaultBranch"; fi;

        # tmp=$(git diff $tmp --stat | tail -n1)
        tmp=$(git diff "$tmp" --stat | tail -n1)
        if [[ -n $tmp ]] && [[ $tytheme_curBranch != $BMGLOBES_defaultBranch ]]; then
            tytheme_changeDetails="\n| $tmp"
        fi

        if [[ $BMGLOBES_defaultBranch != '' ]]; then
            tmp=$(git rev-list --count origin/$BMGLOBES_defaultBranch...$BMGLOBES_defaultBranch)
        fi
        if [[ $tmp > 0 ]]; then
            tmp1=" ${bold_blue}☝${white}"; 
            tytheme_GIT_UPDATER+=$tmp1
        else 
            (git fetch origin $BMGLOBES_defaultBranch &>/dev/null &); 
        fi;

        tmp=$(git status -s | egrep -c "^ ?")
        if [[ $tmp > 0 ]]; then
            tmp=$(git diff --shortstat | awk '{files+=$1; inserted+=$4; deleted+=$6;} 
                END {
                    if (files > 0) { print "|", files, ":", inserted + deleted, "|"}
                    if (files == 0) { print "NOFILES"}
                }')
            if [[ $tmp == 'NOFILES' ]]; then
            tmp=$(git diff --cached --shortstat | awk '{files+=$1; inserted+=$4; deleted+=$6;} 
                END {
                    if (files > 0) { print "|STAGED: ", files, ":", inserted + deleted, "|"}
                    if (files == 0) { print "NOFILES"}
                }')
            fi
            if [[ $tmp == 'NOFILES' ]]; then tmp='|'; fi
            char=$(git ls-files --exclude-standard --others | wc -l)
            if [[ $char -gt 0 ]]; then tmp="|U:$char$tmp"; fi;
            tmp="$(echo -e "${tmp}" | tr -d '[:space:]')"
            tytheme_GIT_UPDATER+=" ${bold_yellow}$tmp"
            # ⚡
        fi

	fi;
    PS1="\n${white}\W $tytheme_icon${bold_green} $tytheme_curBranch$tytheme_GIT_UPDATER${blue}$tytheme_changeDetails${bold_blue}\n[>${reset_color}"
}

safe_append_prompt_command prompt_command
