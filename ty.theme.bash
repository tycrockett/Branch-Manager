#!/usr/bin/env bash

SCM_THEME_PROMPT_DIRTY=" ${bold_red}✗"
SCM_THEME_PROMPT_CLEAN=" ${bold_green}✓"
SCM_THEME_PROMPT_PREFIX=" ${green}"
SCM_THEME_PROMPT_SUFFIX="${green}"

GIT_THEME_PROMPT_DIRTY=" ${bold_red}[✗]"
GIT_THEME_PROMPT_CLEAN=" ${bold_green}[✓]"
GIT_THEME_PROMPT_PREFIX=" ${green}| "
GIT_THEME_PROMPT_SUFFIX="${green}"

RVM_THEME_PROMPT_PREFIX="|"
RVM_THEME_PROMPT_SUFFIX="|"

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

        tytheme_curBranch=$(git symbolic-ref --short -q HEAD) # "$(_git-friendly-ref)$tmp"
        if [[ $tytheme_curBranch == 'master' ]]; then tytheme_icon="♔"; tmp=''; fi;
        if [[ $tytheme_curBranch != 'master' ]]; then tytheme_icon="☉"; tmp="...$tytheme_curBranch"; fi;
        
        tmp=$(git diff master$tmp --stat | tail -n1)
        if [[ -n $tmp ]]; then
            tytheme_changeDetails="\n| $tmp"
        fi
        # tmp1=$(git status -s | egrep -c "^ ?")
        # tmp2=$(git status -s | egrep -c "^ [MARCD]")
        # if [[ $tmp1 > $tmp2 ]]; then
        #     tmp3=`expr $tmp1 - $tmp2`
        #     tytheme_changeDetails="\n| $tmp3 Untracked"; 
        # fi;

        # tmp=$(git diff --stat | tail -n1)
        # if [[ -n $tmp ]]; then 
        #     if [[ -n $tytheme_changeDetails ]]; then tytheme_changeDetails+=","; fi;
        #     if [[ -z $tytheme_changeDetails ]]; then tytheme_changeDetails="\n|"; fi;
        #    # tytheme_changeDetails+="$tmp";
        # fi;

        tytheme_remoteCheck=$(git branch -a | egrep "remotes/origin/${tytheme_curBranch}$")
        if [[ -z $tytheme_remoteCheck ]]; then
            tytheme_GIT_UPDATER+=" ${bold_red}!"
        else
            tytheme_GIT_UPDATER+=" ${bold_cyan}⇅"
        fi;

        tmp=$(git status -s | egrep -c "^ ?")
        if [[ $tmp > 0 ]]; then
            
            # tmp=$(git diff --shortstat | awk '{files+=$1; inserted+=$4; deleted+=$6} END {print "files changed", files, "lines inserted:", inserted, "lines deleted:", deleted}')
            tmp=$(git diff --shortstat | awk '{files+=$1; inserted+=$4; deleted+=$6;} 
                END {
                    if (files > 0) { print files, "\b:", inserted + deleted}
                    if (files == 0) { print "|U|" }
                }')
            tytheme_GIT_UPDATER+=" ${bold_yellow}$tmp"
            # ⚡
        fi

        tmp=$(git rev-list --count origin/master...master)
        if [[ $tmp > 0 ]]; then
            tmp1="${bold_blue}☝${white}$tmp"; 
            if [[ "$tmp" -gt "10" ]]; then tmp1="${bold_blue}☝${yellow}$tmp";  fi;
            if [[ "$tmp" -gt "25" ]]; then tmp1="${bold_blue}☝${red}$tmp";  fi;
            tytheme_GIT_UPDATER+=$tmp1
        else 
            (git fetch origin master &>/dev/null &); 
        fi;


	fi;
    #PS1="${bold_cyan}$(scm_char)${green}$(scm_prompt_info)${purple}$(ruby_version_prompt) ${yellow}\h ${reset_color}in ${green}\w ${reset_color}\n${green}→${reset_color} "
    PS1="\n${white}\W ${green}$tytheme_icon ${bold_green}$tytheme_curBranch$tytheme_remoteBRANCH$tytheme_GIT_UPDATER${blue}$tytheme_changeDetails${bold_blue}\n[>${reset_color}"
}

safe_append_prompt_command prompt_command
