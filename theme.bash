#!/usr/bin/env bash
white="\e[37m"
green="\e[0;32m"
bold_green="\e[1;32m"
bold_red="\e[1;31m"
blue="\e[0;34m"
bold_blue="\e[1;34m"
bold_yellow="\e[1;33m"
reset_color="\e[0;36m"
bold_cyan="\e[1;36m"
cyan="\e[0;36m"
function prompt_command() {
    branchCompletion
    rpoCompletion
    tytheme_icon='';
    tytheme_curBranch='';
    tytheme_changeDetails='';
    tytheme_GIT_UPDATER='';
    tytheme_remoteBRANCH='';
    tmp='';
    gitInfo=""
    tytheme_gitterCheck=$(git rev-parse --git-dir 2> /dev/null);
    curfolder=${PWD##*/}
    loadRepoSettings $curfolder
    if [[ $BM_REPO_directory != $(pwd) ]]; then
		BM_REPO_directory=''
		BM_REPO_keyname=''
		BMGLOBES_defaultBranch=''
		BM_REPO_cmds=()
	fi
    if [ $tytheme_gitterCheck ] && [ $BMGLOBES_defaultBranch ]; then

        if [ $tytheme_gitterCheck != '.git' ]; then
            tmp="${green} in $(basename "${tytheme_gitterCheck%/*}")"
        fi;

        tytheme_curBranch=$(git symbolic-ref --short -q HEAD)

        tmp=''
        if [[ $BMGLOBES_defaultBranch != 'master' ]]; then tmp="origin/$BMGLOBES_defaultBranch"; fi;
        if [[ $tytheme_curBranch != $BMGLOBES_defaultBranch ]]; then tmp="$BMGLOBES_defaultBranch...$tytheme_curBranch"; fi;
        if [[ $BMGLOBES_defaultBranch == 'master' && $tytheme_curBranch == 'master' ]]; then tmp="$BMGLOBES_defaultBranch"; fi;

        tmp=$(git diff "$tmp" --stat | tail -n1)
        if [[ -n $tmp ]] && [[ $tytheme_curBranch != $BMGLOBES_defaultBranch ]]; then
            tytheme_changeDetails="\n${bold_blue}│ ${blue}$tmp"
        fi

        tytheme_remoteCheck=$(git branch -a | egrep "remotes/origin/${tytheme_curBranch}$")
        if [[ -z $tytheme_remoteCheck ]]; then
            tytheme_icon="${bold_red}! "
        else
            if [[ $tytheme_curBranch == $BMGLOBES_defaultBranch ]]; then tytheme_icon="${bold_cyan}♔ "; fi;
            if [[ $tytheme_curBranch != $BMGLOBES_defaultBranch ]]; then tytheme_icon="${bold_cyan}☉ "; fi;
            if [[ $BMGLOBES_defaultBranch != '' ]]; then
            tmp=$(git rev-list --count origin/$BMGLOBES_defaultBranch...$BMGLOBES_defaultBranch)
        fi
        fi;

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
        # ${bold_blue}\n│
        # \n╰─│>
        gitInfo="${white}$tytheme_icon${bold_green}$tytheme_curBranch$tytheme_GIT_UPDATER${blue}$tytheme_changeDetails"
	fi;
    PS1="\n${bold_blue}╭─│${white} \W $gitInfo \n${bold_blue}╰${blue}|│|${white} "
}

# ╭─╮
# │ │
# ╰─╯