bm () {
	BMREPO_check=$(git rev-parse --git-dir 2> /dev/null)
	numberString="^[0-9]+$"
	if [ $BMREPO_check ]; then
		curdir=$(pwd)
		currentBranch=$(git symbolic-ref --short -q HEAD)
		remoteDir=$(git config remote.origin.url)
		re='^[0-9]+$'

		case $1 in
			'read')
							readallbm=true;
							bm $2 $3 $4
							readallbm=false;
			;;
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
			'transfer')
							git branch $2
							git checkout $2
							bm . "Create branch $2 with changes from $currentBranch"
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

								if [[ $3 == '-fix' ]]; then
									clearIt
									_runCMD "git commit -m '$2' --no-verify" false
									git commit -m "$2" --no-verify
								fi

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

			'merge')
							if [[ $BMGLOBES_defaultBranch != $currentBranch ]]; then
								git checkout $BMGLOBES_defaultBranch
								git pull origin $BMGLOBES_defaultBranch
								git merge $currentBranch
								git push origin master
								git checkout $currentBranch
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
							tmp="https://github.$(git config remote.origin.url | cut -f2 -d. | tr ':' /)"
							_runCMD "open $tmp/tree/$currentBranch" true
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
				*)
								_BM_header "Help"
				;;
			esac
		fi
}

bmn () {
	used=false
	if [[ $1 == 'readall' ]]; then
		if [[ $readallbm == true ]]; then readallbm=false; used=true; fi;
		if [[ $readallbm == false ]] && [[ $used == false ]]; then readallbm=true; fi;
		printf "\e[30m$readallbm"
		used=true;
	fi

	if [[ $1 == '_edit' ]]; then
		code ~/Branch-Manager/branchmanager.sh
		used=true
	fi

	if [[ $used == false ]] && [[ -n $1 ]]; then
		source ~/Branch-Manager/repos.bmx
		for ((idx=0; idx<${#_bm_repos[@]}; ++idx)); do
			if [[ $1 == ${_bm_repos[idx]} ]]; then
				repo $1 $2 $3 $4
				used=true
			fi
		done
	fi

	if [[ $1 == 'list' ]]; then used=true; repo list; fi
	if [[ $1 == 'add' ]]; then used=true; repo add; fi
	if [[ $1 == 'edit' ]] && [[ -n $2 ]]; then
	  used=true
		repo edit $2
	fi

	if [[ $1 == 'repo' ]]; then used=true; repo "$2" "$3"; fi
	if [[ $1 == 'run' ]]; then used=true; repo run; fi
	if [[ $1 == 'altrun' ]]; then used=true; repo altrun; fi
	if [[ $1 == 'build' ]]; then used=true; repo build; fi
	if [[ $1 == 'altbuild' ]]; then used=true; repo altbuild; fi
	
	gitterCheck=$(git rev-parse --git-dir 2> /dev/null)
	if [ $gitterCheck ] && [[ $used == false ]]; then
		curdir=$(pwd)
		currentBranch=$(git symbolic-ref --short -q HEAD)
		remoteDir=$(git config remote.origin.url)
		re='^[0-9]+$'
		if [[ -z $1 ]]; then
			bm__changebranch
			used=true
		fi
		if [[ $1 =~ $re ]]; then
			status=$(git status)
			fixed=${status: -37}
			if [[ $fixed == "nothing to commit, working tree clean" ]]; then
				bm__changebranch $1
				bm
			else
				clearIt
				echo
				printf "\e[31mCouldn't switch branches\e[37m\n"
				echo "Commit your changes or"
				printf "Use \e[35mbm clear\e[37m to clear all changes and try again\n"
				bm s
			fi
			used=true
		fi

		if [[ $1 == 'new' ]] || [[ $1 == 'n' ]]; then
			clearIt
			status=$(git status)
			fixed=${status: -37}
			if [[ $fixed == "nothing to commit, working tree clean" ]]; then
				bm__newbranch $2
				bm
			else
				echo
				printf "\e[31mCouldn't create new branch\e[37m\n"
				echo "Commit your changes or"
				printf "Use \e[35mbm clear\e[37m to clear all changes and try again or\n"
				printf "Use \e[35mbm transfer $2\e[37m to transfer changes to the new branch\n"
				echo
				bm s
			fi
			used=true
		fi

		if [[ $1 == 'transfer' ]]; then
			git branch $2
			git checkout $2
			bm . "Create branch $2 with changes from $currentBranch"
			bm update
		fi

		if [[ $1 == 'rename' ]] || [[ $1 == 'rn' ]] ; then
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
			used=true
		fi

		if [[ $1 == 'diff' ]]; then
			git diff $BMGLOBES_defaultBranch..HEAD -- $2
		fi;
		
		if [[ $1 == 'clear' ]]; then
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
		fi

		if [[ $1 == 'delete' ]]; then
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
					bm__delbranch $2
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
		fi

		if [[ $1 == 'compop' ]]; then
			used=true
			clearIt
			printf "\e[31mPermanetly delete last commit on \e[32m$currentBranch\e[31m? \e[37m"
			read -r -p '' response
			if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
				_runCMD "git reset --hard HEAD^" true
				bm log
			fi
		fi
		
		if [[ $1 == 'update' ]] || [[ $1 == 'u' ]] ; then
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
		fi

		if [[ $1 == 'pull' ]]; then
			_runCMD "git pull" true
		fi

		if [[ $1 == 'pushup' ]]; then
			_runCMD "git push --set-upstream origin $currentBranch" true
			bm remote
			used=true
		fi

		if [[ $1 == '.' ]]; then

			if [[ $currentBranch != $BMGLOBES_defaultBranch ]] || [[ $3 == '-f' ]]; then

				if [[ $3 == '-fix' ]]; then
					clearIt
					_runCMD "git commit -m '$2' --no-verify" false
					git commit -m "$2" --no-verify
				fi

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
		fi

		if [[ $1 == 'commit' ]]; then
			git commit;
		fi

		if [[ $1 == 'rm-file' ]]; then
			hashMe=$(git merge-base $BMGLOBES_defaultBranch $currentBranch)
			git checkout $hashMe $2
			git commit -m "Remove $2 from commit"
		fi

		if [[ $1 == 'status' ]] || [[ $1 == 's' ]] || [[ $1 == 'sc' ]]; then
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
		fi

		if [[ $1 == 'merge' ]]; then
			git checkout $2
			git merge $currentBranch
			git push origin $2
			bm delete
		fi

		if [[ $1 == 'check' ]]; then
			used=true
			_runCMD "git branch -a | egrep 'remotes/origin/${tytheme_curBranch}$'" false
			checkit=$(git branch -a | egrep "remotes/origin/${tytheme_curBranch}$")
			if [[ -z $checkit ]]; then
				echo
				printf "\e[34m[!] No remote branch exists\e[37m\n"
				printf "Use \e[35mbm pushup\e[37m to create an upstream branch"
				echo
			else
				printf "\e[32mRemote branch exists!\e[31m\n"
				echo
			fi;
		fi

		if [[ $1 == 'remote' ]]; then
			used=true
			tmp="https://github.$(git config remote.origin.url | cut -f2 -d. | tr ':' /)"
			_runCMD "open $tmp/tree/$currentBranch" true
		fi

		if [[ $1 == 'log' ]]; then
			used=true
			_BM_header "$currentBranch" "\e[35m"
			tmp="..$currentBranch"
			tmpN=5
			if [[ -n $2 ]]; then tmpN=$2; fi;
			if [[ $currentBranch == $BMGLOBES_defaultBranch ]]; then tmp=''; fi;
			_runCMD "git log $BMGLOBES_defaultBranch$tmp --graph --pretty=format:'%Cred%h%Creset | %C(bold blue)%an:%Creset %s %n%Cblue%cr%Creset' --abbrev-commit --date=relative" false
			git log -n $tmpN $BMGLOBES_defaultBranch$tmp --graph --pretty=format:'%Cred%h%Creset | %C(bold blue)%an:%Creset %s %n%Cblue%cr%Creset' --abbrev-commit --date=relative
		fi

		if [[ $1 == 'rb-clone' ]]; then
			used=true
			git clone --single-branch --branch $2 $remoteDir
		fi

		if [[ $1 == 'edit' ]] && [[ -z $2 ]]; then
			used=true;
			for ((idx=0; idx<${#_bm_dir[@]}; ++idx)); do
				if [[ $curdir == ${_bm_dir[idx]} ]]; then
					repo edit ${_bm_repos[idx]}
					break;
				fi
			done
		fi
		
		if [[ $1 == 'help' ]]; then used=true; fi

else

	if [[ $1 == 'clone' ]] && [[ -n $2 ]]; then 
		used=true
		protocol=${2::4}
		if [[ $protocol == 'http' ]] || [[ $protocol == 'git@' ]]; then
			if [[ $protocol == 'http' ]]; then
				printf "\e[32mCloning with HTTPS\n\e[37m"
				slashes=5
			fi
			if [[ $protocol == 'git@' ]]; then
				printf "\e[32mCloning with SSH\n\e[37m"
				slashes=2
			fi
			tmpRepo=$(cut -d "/" -f $slashes <<< $2)
			tmpRepo=${tmpRepo%.*}
			echo $tmpRepo
			printf "\e[33m"
			_runCMD "git clone $2" true
			_runCMD "cd $tmpRepo" true
			echo
			printf "\e[37m$(pwd)\n"
			echo
			printf "\e[36m"
			printf "\e[32mWould you like to add a repo key? \e[37m"
			read -r -p '' response
			if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
				repo add
			fi
		fi
	fi

	if [[ $used == false ]]; then
		printf "\n\e[33mNot a git repository:\e[37m\n"
		printf "$(pwd)\n"
	fi
fi

if [[ $1 == 'help' ]]; then
	_BM_header "Branch Manager Help" "\e[33m"
	echo
	_echoR "bm [command]" ""
	_echoR "Commands: " ""
	_echoR "[BLANK]: " "List branches"
	_echoR "[1, 2, 3]: " "Checkout branch from list"
	_echoR "new/n <branch>: " "checkout default branch, pull origin default branch, create new branch"
	_echoR "transfer <branch>: " "create a new branch and transfer all changes to new branch"
	_echoR "rename/rn <branch>: " "Rename local branch and optionally remote branch"
	_echoR "clear: " "Stash and optionally clear"
	_echoR "delete: " "Delete current branch"
	_echoR "update/rf <all>: " "checkout default branch, pull origin default branch, merge to current or all branches"
	_echoR "pull: " "git pull"
	_echoR "status/s: " "status of branch"
	_echoR "< -l -d -a >: " "show logs / show details / show diffs"
	_echoR "sc: " "git status, check if remote branch exists"
	_echoR "check: " "check if local branch has a remote branch"
	_echoR "pushup: " "create remote branch and push to it"
	_echoR "Merge <branch>: " "Merge into <branch>"
	_echoR "diff <filename>: " "show diff between default branch and specific file"
	_echoR "rm <filename>: " "removes a file from a commit"
	_echoR ". <description>: " "add, commit -m <des>, push (If remote exists)"
	_echoR "remote: " "open remote branch in default browser"
	_echoR "log: " "log commits in current branch"
	_echoR "compop: " "delete last commit on current branch"
	_echoR "clone: " "git clone --> optionally create repo keys and cmds"
	_echoR "repo: " "display repo cmds and directory"
	_echoR "run: " "start assigned repo run cmd"
	_echoR "add: " "assign a keyword to current directory and add repo cmds"
	_echoR "list: " "list all repo keys and their cmds"
	_echoR "repo del [key]: " "delete repo keys and associated cmds"
	echo
	used=true
fi
if [[ $test_branch_manager == true ]]; then
	if [[ $used == true ]]; then
		echo "$1 is a Branch Manager command"
	else
		echo "!Invalid!"
	fi
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

bm__changebranch () {
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
}

bm__newbranch () {
	branch=$(git symbolic-ref --short -q HEAD)
	if [[ $branch != $BMGLOBES_defaultBranch ]]; then
		_runCMD "git checkout  $BMGLOBES_defaultBranch" true
	else
		echo "In $BMGLOBES_defaultBranch"
	fi
	_runCMD "git pull origin $BMGLOBES_defaultBranch" true
	_runCMD "git branch $1" true
	_runCMD "git checkout $1" true
}

bm__delbranch () {
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

# ╭─╮
# │ │
# ╰─╯

source ~/Branch-Manager/rpomanager.sh