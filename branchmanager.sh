source ~/Branch-Manager/helpFile.sh
bm () {
	BMREPO_check=$(git rev-parse --git-dir 2> /dev/null)
	numberString="^[0-9]+$"
	BMCHECK_HELP=true

	for arg; do
		case $arg in
			-help)
				bm help $1
				BMCHECK_HELP=false
			;;
		esac
	done

	if [ $BMREPO_check ]; then
		if [ $BMCHECK_HELP == true ]; then
			curdir=$(pwd)
			currentBranch=$(git symbolic-ref --short -q HEAD)
			remoteDir=$(git config remote.origin.url)
			re='^[0-9]+$'

			case $1 in
				'_edit') code ~/Branch-Manager/branchmanager.sh;;
				'new'|'n')
								clearIt
								status=$(git status)
								fixed=${status: -37}
								if [[ $fixed == "nothing to commit, working tree clean" ]]; then
									branch=$(git symbolic-ref --short -q HEAD)
										if [[ $branch != $BMGLOBES_defaultBranch ]]; then
											_runCMD "git checkout  $BMGLOBES_defaultBranch" true
										else
											echo "In $BMGLOBES_defaultBranch"
										fi
										_runCMD "git pull origin $BMGLOBES_defaultBranch" true
										_runCMD "git branch $2" true
										_runCMD "git checkout $2" true
									if [[ $readallbm == false ]]; then bm; fi;
								else
									_runCMD "git checkout -b $2" true
									bm . "Changes from $currentBranch"
									_runCMD "git checkout $BMGLOBES_defaultBranch" true
									_runCMD "git pull origin $BMGLOBES_defaultBranch" true
									_runCMD "git checkout $2" true
									_runCMD "git merge $BMGLOBES_defaultBranch" true

									if [[ $readallbm == false ]]; then bm s; fi;
								fi

				;;
				'rename' | 'rn')
								checkit=$(git ls-remote $remoteDir $currentBranch)
								git branch -m $2
								if [[ -n $checkit ]]; then
									printf "Rename remote branch? "
									read -r -p '' response
									if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
										git push origin :$currentBranch $2
										git push origin -u $2
									fi
								fi
				;;
				'clear')
								if [[ $2 == '-f' ]]; then
									_runCMD "git add ." true
								fi
								used=true
								git stash
								printf "\e[31mPermanetly clear stash on \e[32m$currentBranch\e[31m? \e[37m"
								read -r -p '' response
								if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
									_runCMD "git stash clear" true
								fi
								status=$(git status)
								fixed=${status: -37}
								if [[ $fixed != "nothing to commit, working tree clean" ]]; then
									echo
									printf "\e[31mCouldn't clear entire stash\e[37m\n"
									printf "Use \e[35mbm clear -f\e[37m to force bm clear\n"
								fi
				;;

				'compop')
								clearIt
								printf "\e[31mPermanetly delete last commit on \e[32m$currentBranch\e[31m? \e[37m"
								read -r -p '' response
								if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
									_runCMD "git reset --hard HEAD^" true
									bm log
								fi
				;;
				
				'.'|'acp')
								if [[ $currentBranch != $BMGLOBES_defaultBranch ]] || [[ $3 == '-f' ]]; then
									if [[ -n $2 ]] && [[ $3 != '-m' ]]; then
										clearIt
										_runCMD "git add ." false
										git add .
										_runCMD "git commit -m '$2'" false
										git commit -m "$2"
										checkit=$(git ls-remote $remoteDir $currentBranch) 
										if [[ -n $checkit ]]; then
											_runCMD "git push" false
											git push
										fi
									fi
									if [[ -z $2 ]]; then
										git add .
									fi
									if [[ $3 != '-d' ]]; then clearIt; fi
									bm s
									used=true
								fi
				;;

				'log')
								_BM_header "$currentBranch" "\e[35m"
								tmp="..$currentBranch"
								tmpN=5
								if [[ -n $2 ]]; then tmpN=$2; fi;
								if [[ $currentBranch == $BMGLOBES_defaultBranch ]]; then tmp=''; fi;
								_runCMD "git log $BMGLOBES_defaultBranch$tmp --graph --pretty=format:'%Cred%h%Creset | %C(bold blue)%an:%Creset %s %n%Cblue%cr%Creset' --abbrev-commit --date=relative" false
								git log -n $tmpN $BMGLOBES_defaultBranch$tmp --graph --pretty=format:'%Cred%h%Creset | %C(bold blue)%an:%Creset %s %n%Cblue%cr%Creset' --abbrev-commit --date=relative
				;;

				'rm-file')
								hash=$(git merge-base $BMGLOBES_defaultBranch $currentBranch)
								git checkout $hash $2
								git commit -m "Remove $2 from commit"
				;;

				'status'|'s')
								SHOWALLDETAILS=false
								SHOWDETAILS=false
								SHOWLOGS=false
								for arg; do
									if [[ $arg != $1 ]]; then
										case $arg in
											-a) 
												SHOWALLDETAILS=true 
												SHOWDETAILS=true;;
											-d) SHOWDETAILS=true ;;
											-l) SHOWLOGS=true ;;
											-dl) 
												SHOWDETAILS=true
												SHOWLOGS=true 
											;;
											\?) ;;
										esac
									fi;
								done							
								echo
								status=$(git status)
								fixed=${status: -37}
								if [[ $fixed == "nothing to commit, working tree clean" ]]; then
									tmp=$(git rev-parse --short HEAD)
									_BM_header "Commit Hash: $tmp" "\e[35m"
									if [[ $SHOWDETAILS == true ]]; then				
										git diff $BMGLOBES_defaultBranch...$currentBranch --stat
									else
										git diff $BMGLOBES_defaultBranch...$currentBranch --stat | tail -n1
									fi
								else
									_BM_header "Changes" "\e[34m"
									git diff $BMGLOBES_defaultBranch...$currentBranch --stat | tail -n1
									_runCMD "git diff --stat" true
									tmp=$(git diff --stat)
									echo $tmp
									if [[ -z $tmp ]]; then
										tmp=$(git diff --name-only --cached)
										if [[ -n $tmp ]]; then
											printf "\e[32mStaged File(s)\n\e[37m"; 
											git diff --name-only --cached
										fi
									fi
									_runCMD "git ls-files . --exclude-standard --others" false
									tmp=$(git ls-files --exclude-standard --others | wc -l)
									tmp="$(echo -e "${tmp}" | tr -d '[:space:]')"
									if [[ $tmp > 0 ]]; then
											echo
											printf "\e[36m$tmp Untracked File(s)\n\e[37m"; 
											echo "$(git ls-files --exclude-standard --others)"
									fi;
									echo
									printf "Use \e[34mbm . <des>\e[37m to Add/Commit/Push\n\n"
								fi

								if [[ $SHOWALLDETAILS == true ]]; then
									echo
									tmp="..$currentBranch"
									if [[ $currentBranch == $BMGLOBES_defaultBranch ]]; then tmp=''; fi;
									_runCMD "git diff $BMGLOBES_defaultBranch$tmp" true
								fi

								if [[ $1 == 'sc' ]] && [[ $2 != 'all' ]]; then
									bm check
								fi
								if [[ $2 == 'all' ]]; then
									bm check
									echo
									bm log
								fi
								used=true
								if [[ $SHOWLOGS == true ]]; then echo; bm log; fi;
				;;

				'pushup')
								_runCMD "git push --set-upstream origin $currentBranch" true
								bm remote
				;;

				'remote')
								check=false
								for arg; do
									if [[ $arg != $1 ]]; then
										case $arg in
											-list)
												git branch -a
												check=true
											;;
											-get)
												git fetch
												check=true
											;;
											-check) 
												tmp=$(git branch -a | egrep 'remotes/origin/${currentBranch}')
												if [[ -z $tmp ]]; then
													echo "Remote branch exists!"
												fi
												check=true
											;;
										esac
									fi;
								done					
								if [[ $check == false ]]; then
									tmp="https://github.$(git config remote.origin.url | cut -f2 -d. | tr ':' /)"
									_runCMD "open $tmp/tree/$currentBranch" true
								fi
				;;

				'update'|'u')
							status=$(git status)
							fixed=${status: -37}
							if [[ $fixed == "nothing to commit, working tree clean" ]]; then
								echo
								if [[ $currentBranch != $BMGLOBES_defaultBranch ]]; then
									_runCMD "git checkout $BMGLOBES_defaultBranch" true "\e[37m"
									echo
								fi
								_runCMD "git pull origin $BMGLOBES_defaultBranch" true "\e[33m"
								echo
								if [[ -z $2 ]] && [[ $currentBranch != $BMGLOBES_defaultBranch ]]; then
									_runCMD "git checkout $currentBranch" true "\e[37m"
									echo
									_runCMD "git merge $BMGLOBES_defaultBranch" true "\e[32m"
									echo
								fi

								if [[ $2 == 'all' ]]; then
									for branch in $(git branch | grep "[^* ]+" -Eo);
									do
										if [[ $branch != $BMGLOBES_defaultBranch ]]; then
											_runCMD "git checkout $branch" true
											_runCMD "git merge $BMGLOBES_defaultBranch" true
										fi
										br+=($branch)
									done
									if [[ $branch != $currentBranch ]]; then 
										echo
										_runCMD "git checkout $currentBranch " true
									fi
								fi
								used=true
							else
								echo
								printf "\e[31m"
								echo "Your local changes would be overwritten."
								echo "Please commit your changes or stash them before you switch branches."
								printf "\e[37m"
							fi
				;;

				'default-b')
								BMGLOBES_defaultBranch=$2
				;;

				'delete')
								clearIt
								used=true
								status=$(git status)
								fixed=${status: -37}
								if [[ $fixed == "nothing to commit, working tree clean" ]]; then
									bm s
									printf "\e[31mPermanetly delete \e[32m$currentBranch\e[31m? \e[37m"
									read -r -p '' response
									if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
										clearIt
											branch=$(git symbolic-ref --short -q HEAD)
											if [[ $branch != $BMGLOBES_defaultBranch ]]
												then
													_runCMD "git checkout $BMGLOBES_defaultBranch" true
													_runCMD "git branch -D $branch" true
											fi
											if [[ $branch == $BMGLOBES_defaultBranch ]]
												then
													echo "Can't delete $BMGLOBES_defaultBranch"
											fi
										bm
									else
											printf "\e[37mGood Choice\n"
									fi
								else
									echo
									printf "\e[31mCouldn't delete branch\e[37m\n"
									echo "Commit your changes or"
									printf "Use \e[35mbm clear\e[37m to clear all changes and try again\n"
									bm s
								fi
				;;

				'diff')
									git diff $BMGLOBES_defaultBranch..HEAD -- $2
				;;
				''|*[[:digit:]]*)
									ll=0
									br=()
									current=$(git symbolic-ref --short -q HEAD)
									if [[ -z $1 ]]; then
									projectName=${PWD##*/}
									_BM_header "$projectName" "\e[33m"
									fi

									status=$(git status | head -n1)
									fixed=${status:0:4}
									if [[ $fixed != 'HEAD' ]]; then

										for branch in $(git branch | grep "[^* ]+" -Eo);
										do
											if [ -z $1 ]
											then
												ll=`expr $ll + 1`
												color='\e[37m'
												colorUpdate=''
												selected='  '
												if [[ $branch == $current ]]; then
													color='\e[32m'
													selected='☆ '
												fi
												displayText="$color$selected$ll. $colorUpdate$branch"
												spaces=$(_BM_getRemainingSpace 55 "$color$selected$ll. $colorUpdate$branch")
												printf "│ ${displayText}${spaces}\e[37m│\n"
											fi
											br+=($branch)
										done
									else
										displayText="$status"
										spaces=$(_BM_getRemainingSpace 49 "$displayText")
										printf "│ ${displayText}${spaces}\e[37m│\n"
									fi
										
									if [ -z $1 ]
									then
										printf "\e[37m╰──────────────────────────────────────────────────╯\n"
										echo
										echo $remoteDir
									else
										if [[ $1 == 0 ]]; then 
											coBranch=$BMGLOBES_defaultBranch
										else
											opt=`expr $1 - 1`
											coBranch=${br[@]:$opt:1}
										fi
										_runCMD "git checkout $coBranch" true
									fi	
					;;
					'help')
									if [[ -z $2 ]]; then
										echo
										printf "bm \e[34mcmd\e[37m\n"
										echo "---------"
										_echoR "[blank]" "List all branchs"
										_echoR "[branch name]" "Checkout (branch name)"
										_echoR "new | n" "Create new branch"
										_echoR ". | acp" "Commit all changes"
										_echoR "status | s" "Get status of branch"
										_echoR "update | u" "Update (default branch) and merge into (current branch)"
										_echoR "rename | rn" "Rename current branch"
										_echoR "delete" "Delete current branch"
										_echoR "remote" "Open github remote branch"
										_echoR "clear" "Delete any uncommitted changes in branch"
										_echoR "compop" "Delete last commit"
										_echoR "log" "Log commit history"
										_echoR "rm-file" "Remove a file from commit history"
										_echoR "pushup" "set upstream remote branch"
										_echoR "diff" "Get the difference for specific file"
									else
										showHelp $2
									fi
					;;
					*)
									git checkout $1
									_BM_header $1
					;;
				esac
			fi
		else
			case $1 in
				'init')
							if [ -z $4 ]; then
								echo "Initializing GIT.."
								git init
								git add .
								git commit -m 'Create new repo'
								echo "Initializing GITHUB.."
								git remote add origin "https://github.com/$2/$3.git"
								gitterCheck=$(git rev-parse --git-dir 2> /dev/null);
								if [ $gitterCheck ]; then
									repoCheck=$(git remote -v)
									if [ $repoCheck ]; then
										echo "Initialized remote branch"	
										git push -u origin master
									else
										echo "Couldn't initialize remote branch"
									fi
								fi
							else
								echo "Bunches of oats"
							fi
				;;			
			esac
		fi
}

_echoR () {
	len=15
	if [[ -n $3 ]]; then len=`expr $3 + 2`; fi
	printf " \e[34m%${len}s\e[37m%s\n" "$1 " " $2"
}

_updateColor () {
	check=""
	case $1 in
		'green') check="\e[32m";;
		'white') check="\e[37m";;
		*) check="\e[37m";;
	esac
	echo $check
}

_print () {
	col=$(_updateColor $2)
	printf "$col$1\e[37m$3"
}

_runCMD() {
	color=$3
	if [[ -z $3 ]]; then color="\e[37m"; fi;
	if [[ $readallbm == true ]]; then 
		printf "\e[30m"
		echo "	$1";
	else
		printf "$color"
		if [[ $2 == true ]]; then $1; fi;
	fi;
}

clearIt() {
	if [[ $readallbm == false ]]; then clear; fi;
}

bm__apnd () {
	if [[ $1 != 'help' ]]; then
		sed -i "" "$2"$3'\'$'\n'"$4"$'\n' $1
	else
		echo
		echo "bm__apnd <filename line (a/c) text>"
	fi
}

apnd () {
	bm__apnd $1 $2 "$3" "$4"
}

readallbm=false

_BM_header () {
	wordLength=${#1}
	leftLength=`expr 25 - $wordLength / 2`
	leftSpaces=$(printf '%0.s ' $(seq 1 $leftLength))
	rightLength=`expr 50 - $leftLength - $wordLength`
	rightSpaces=$(printf '%0.s ' $(seq 1 $rightLength))
	printf "\e[37m"
	echo "╭──────────────────────────────────────────────────╮"
	printf "│${2}${leftSpaces}${1}${rightSpaces}\e[37m│\n"
	echo "╰──────────────────────────────────────────────────╯"
}

_BM_getRemainingSpace () {
	length=${#2}
	spaceLength=`expr $1 - $length`
	printf '%0.s ' $(seq 1 $spaceLength)
}

branchCompletion () {
	inGitRepo=$(git rev-parse --git-dir 2> /dev/null)
	if [ $inGitRepo ]; then
		BC_completionString=""
		for BC_branch in $(git branch | grep "[^* ]+" -Eo);
		do BC_completionString+=" $BC_branch"
		done
		complete -W "$BC_completionString" bm
	fi
}

newtabi(){
  osascript \
  -e 'tell application "iTerm2" to tell current window to set newWindow to (create tab with default profile)'\
  -e "tell application \"iTerm2\" to tell current session of newWindow to write text \"$1\""
}
# ╭─╮
# │ │
# ╰─╯

source ~/Branch-Manager/rpomanager.sh

# promptCommand () {
# 	echo "hello"
# 	PS1="Fish"
# }

# PROMPT_COMMAND=promptCommand