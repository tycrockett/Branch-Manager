bm () {
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
				if [[ $3 == 'transfer' ]]; then
					git branch $2
					git checkout $2
					bm . "Create branch $2 with changes from $currentBranch"
					bm update
				else
					echo
					printf "\e[31mCouldn't create new branch\e[37m\n"
					echo "Commit your changes or"
					printf "Use \e[35mbm clear\e[37m to clear all changes and try again or\n"
					printf "Use \e[35mbm new $2 transfer\e[37m to transfer changes to the new branch\n"
					echo
					bm s
				fi
			fi
			used=true
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

		if [[ $1 == 'details' ]]; then
			git diff master..HEAD -- $2
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
		
		if [[ $1 == 'update' ]] || [[ $1 == 'rf' ]] ; then
			status=$(git status)
			fixed=${status: -37}
			if [[ $fixed == "nothing to commit, working tree clean" ]]; then
				echo
				if [[ $currentBranch != 'master' ]]; then
					_runCMD "git checkout master" true "\e[37m"
					echo
				fi
				_runCMD "git pull origin master" true "\e[33m"
				echo
				if [[ -z $2 ]] && [[ $currentBranch != 'master' ]]; then
					_runCMD "git checkout $currentBranch" true "\e[37m"
					echo
					_runCMD "git merge master" true "\e[32m"
					echo
				fi

				if [[ $2 == 'all' ]]; then
					for branch in $(git branch | grep "[^* ]+" -Eo);
					do
						if [[ $branch != 'master' ]]; then
							_runCMD "git checkout $branch" true
							_runCMD "git merge master" true
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

			if [[ $currentBranch != 'master' ]] || [[ $3 == '-f' ]]; then

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
				printf "\e[35mCommit Hash: $tmp\e[37m\n"
				if [[ $SHOWDETAILS == true ]]; then 
					git diff master...$currentBranch --stat
				else
					git diff master...$currentBranch --stat | tail -n1
				fi
			else
				git diff master...$currentBranch --stat | tail -n1
				echo
				printf "\e[34mCHANGES\e[37m\n"
				printf "\e[34m---------------------------------------------------\e[37m\n"
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
				if [[ $currentBranch == 'master' ]]; then tmp=''; fi;
				_runCMD "git diff master$tmp" true
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
			tmp="..$currentBranch"
			tmpN=5
			if [[ -n $2 ]]; then tmpN=$2; fi;
			if [[ $currentBranch == 'master' ]]; then tmp=''; fi;
			_runCMD "git log master$tmp --graph --pretty=format:'%Cred%h%Creset | %C(bold blue)%an:%Creset %s %n%Cblue%cr%Creset' --abbrev-commit --date=relative" false
			git log -n $tmpN master$tmp --graph --pretty=format:'%Cred%h%Creset | %C(bold blue)%an:%Creset %s %n%Cblue%cr%Creset' --abbrev-commit --date=relative
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
	echo
	printf "                  \e[33mBranch Manager:\e[37m\n"
	echo "---------------------------------------------------"
	echo
	echo "bm [command]"
	echo
	echo "Commands:"
	echo "[BLANK]:			List branches"
	echo "[1, 2, 3]:			Checkout branch from list"
	echo "new/n <branch>:			checkout master, pull origin master, create new branch"
	echo "rename/rn <branch>:		Rename local branch and optionally remote branch"
	echo "clear: 				Stash and optionally clear"
	echo "delete:			 	Delete current branch"
	echo "update/rf <all>: 		checkout master, pull origin master, merge to current or all branches"
	echo "pull:				git pull"
	echo "status/s:			status of branch"
	echo "< -l -d -a >:			show logs / show details / show diffs"
	echo "sc:				git status, check if remote branch exists"
	echo "check:				check if local branch has a remote branch"
	echo "pushup: 			create remote branch and push to it"
	echo ". <description>:		add, commit -m <des>, push (If remote exists)"
	echo "remote:				open remote branch in default browser"
	echo "log:				log commits in current branch"
	echo "compop:				delete last commit on current branch"
	echo "clone:				git clone --> optionally create repo keys and cmds"
	echo "repo:				display repo cmds and directory"
	echo "run:				start assigned repo run cmd"
	echo "add:				assign a keyword to current directory and add repo cmds"
	echo "list:				list all repo keys and their cmds"
	echo "repo del [key]:			delete repo keys and associated cmds"
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

_runCMD() {
	color=$3
	if [[ -z $3 ]]; then color="\e[37m"; fi;
	if [[ $readallbm == true ]]; then 
		printf "\e[30m"
		echo "	$1";
	fi;
	printf "$color"
	if [[ $2 == true ]]; then $1; fi;
}

clearIt() {
	if [[ $readallbm == false ]]; then clear; fi;
}

bm__changebranch () {
	ll=0
	br=()
	current=$(git symbolic-ref --short -q HEAD)
	if [[ -z $1 ]]; then
		echo
		printf "                  \e[33mBranch Manager:\e[37m\n"
		echo "---------------------------------------------------"
	fi
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
				#colorUpdate='\e[33m'
				selected='☆ '
			fi
			printf " $color$selected$ll. $colorUpdate$branch \n"
		fi
		br+=($branch)
	done
		
	if [ -z $1 ]
	then
		printf "\e[37m---------------------------------------------------\n"
		echo
		echo $remoteDir
	else
		opt=`expr $1 - 1`
		_runCMD "git checkout ${br[@]:$opt:1}" true
	fi
}

bm__newbranch () {
	branch=$(git symbolic-ref --short -q HEAD)
	if [[ $branch != 'master' ]]; then
		_runCMD "git checkout  master" true
	else
		echo In master
	fi
	_runCMD "git pull origin master" true
	_runCMD "git branch $1" true
	_runCMD "git checkout $1" true
}

bm__delbranch () {
	branch=$(git symbolic-ref --short -q HEAD)
	if [[ $branch != "master" ]]
		then
			_runCMD "git checkout master" true
			_runCMD "git branch -D $branch" true
	fi
	if [[ $branch == "master" ]]
		then
			echo "Can't delete master"
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

repo () {
	use='f'
	curdir=$(pwd)
	if [[ $1 == 'add' ]]; then
		use='t'
		curdir=$(pwd)
		if [[ -f ~/Branch-Manager/repos.bmx ]]; then

			echo "Directory: $curdir"
			itsDone=false
			while [[ $itsDone == false ]]; do
				printf "Key Name: "; read -r -p '' keyname
				exists=$(_repo_checkNameExists $keyname)
				if [[ $exists == $keyname ]] && [[ -n $keyname ]]; then
					itsDone=true
					echo "#$keyname" >> ~/Branch-Manager/repos.bmx
					echo "_bm_repos+=('$keyname')" >> ~/Branch-Manager/repos.bmx
					echo "_bm_dir+=('$curdir')" >> ~/Branch-Manager/repos.bmx
				else
					if [[ -z $keyname ]]; then 
						itsDone=false; 
						printf "\e[31mKeyword can't be blank\n\e[37m"; 
					else
						printf "\e[31mKeyword already exists\n\e[37m"
					fi	
				fi
			done

			printf "run Command: "; read -r -p '' runcmd; echo "_bm_run+=('$runcmd')" >> ~/Branch-Manager/repos.bmx
			printf "altrun Command: "; read -r -p '' altruncmd; echo "_bm_altrun+=('$altruncmd')" >> ~/Branch-Manager/repos.bmx			
			printf "build Command: "; read -r -p '' build; echo "_bm_build+=('$build')" >> ~/Branch-Manager/repos.bmx
			printf "altbuild Command: "; read -r -p '' altbuild; echo "_bm_altbuild+=('$altbuild')" >> ~/Branch-Manager/repos.bmx

			source ~/Branch-Manager/repos.bmx
		else
			echo "Creating new repos.bmx file. Re-enter in your command."
			_repo_create
		fi
	fi

	if [[ $1 == 'del' ]] && [[ -n $2 ]]; then
		use='t'
		sel=$(awk -v line="#"$2 '$0 == line {print NR}' ~/Branch-Manager/repos.bmx)
		echo $sel
		bln=$(_repo_getItemsLength)
		# bln=`expr $bln - 1`
		for ((idx=0; idx<bln; ++idx)); do
			apnd ~/Branch-Manager/repos.bmx $sel c ''
		done
		source ~/Branch-Manager/repos.bmx
	fi

	if [[ $1 == 'edit' ]]; then
		use='t'
		for ((idx=0; idx<${#_bm_repos[@]}; ++idx)); do
			if [[ $2 == ${_bm_repos[idx]} ]]; then
				sel=$(awk -v line="#"$2 '$0 == line {print NR}' ~/Branch-Manager/repos.bmx)
				echo $sel
				printf "\e[31m"
				echo Leave blank to keep current value
				echo Type ! to indicate an empty value
				printf "\e[37mDirectory: ${_bm_dir[idx]}\n"
				printf "Key Name: ${_bm_repos[idx]}\n"
				sel=`expr $sel + 2`
				_repo_edit "run Command (${_bm_run[idx]}): " "run" "${_bm_run[idx]}" "$sel" false
				_repo_edit "altrun Command (${_bm_altrun[idx]}): " "altrun" "${_bm_altrun[idx]}" "$sel" false
				_repo_edit "build Command (${_bm_build[idx]}): " "build" "${_bm_build[idx]}" "$sel" false
				_repo_edit "altbuild Command (${_bm_altbuild[idx]}): " "altbuild" "${_bm_altbuild[idx]}" "$sel" false
				break
			fi
		done
		source ~/Branch-Manager/repos.bmx
	fi

	if [[ $1 == 'list' ]]; then
		use='t'
		source ~/Branch-Manager/repos.bmx
		echo
		for ((idx=0; idx<${#_bm_repos[@]}; ++idx)); do
			printf "\e[32m${_bm_repos[idx]}\e[38m --> \e[37m${_bm_dir[idx]}\n"
			printf "\e[34m"
			printf "  run: \e[33m${_bm_run[idx]}\e[34m\n"
			printf "  altrun: \e[33m${_bm_altrun[idx]}\e[34m\n"
			printf "  build: \e[33m${_bm_build[idx]}\e[34m\n"
			printf "  altbuild: \e[33m${_bm_altbuild[idx]}\e[34m\n"
			printf "\e[37m\n"
		done 
	fi

	if [[ -z $1 ]]; then
		doneit='f'
		
		for ((idx=0; idx<${#_bm_repos[@]}; ++idx)); do
			if [[ $curdir == ${_bm_dir[idx]} ]]; then
				doneit='t'
				echo
				echo $remoteDir
				echo
				printf "\e[32m${_bm_repos[idx]}\e[38m --> \e[37m${_bm_dir[idx]}\n"
				printf "\e[34m"
				printf "  run: \e[33m${_bm_run[idx]}\e[34m\n"
				printf "  altrun: \e[33m${_bm_altrun[idx]}\e[34m\n"
				printf "  build: \e[33m${_bm_build[idx]}\e[34m\n"
				printf "  altbuild: \e[33m${_bm_altbuild[idx]}\e[34m\n"
				printf "\e[37m\n"
			fi
		done 
		if [[ $doneit == 'f' ]]; then
			echo $curdir
			printf "\e[34m[!] This directory does not have a repo key set up.\e[37m\n"
			printf "Use \e[35mbm add\e[37m to create a new repo key."
		fi
	fi

	if [[ $1 == 'run' ]] || [[ $1 == 'altrun' ]] || [[ $1 == 'build' ]] || [[ $1 == 'altbuild' ]]; then
		use='t'
		source ~/Branch-Manager/repos.bmx
		curdir=$(echo "$curdir" | awk '{print tolower($0)}')
		for ((idx=0; idx<${#_bm_repos[@]}; ++idx)); do
			tmpdir=$(echo "${_bm_dir[idx]}" | awk '{print tolower($0)}')
			if [[ $curdir == $tmpdir ]]; then
				if [[ $1 == 'run' ]]; then runcmd=${_bm_run[idx]}; fi
				if [[ $1 == 'altrun' ]]; then runcmd=${_bm_altrun[idx]}; fi
				if [[ $1 == 'build' ]]; then runcmd=${_bm_build[idx]}; fi
				if [[ $1 == 'altbuild' ]]; then runcmd=${_bm_altbuild[idx]}; fi
				printf "\e[32mrunning cmd: \e[37m$runcmd\n"
				$runcmd
			fi
		done
	fi

	if [[ $1 == 'remote' ]]; then
		if [ -d .git ]; then
			currentBranch=$(git symbolic-ref --short -q HEAD)
			tmp="https://github.$(git config remote.origin.url | cut -f2 -d. | tr ':' /)"
			open "$tmp/tree/$currentBranch"
		fi
	fi

	if [[ $1 == 'init' ]]; then
		use='t'
		if [[ -f ~/Branch-Manager/repos.bmx ]]; then
			rm ~/Branch-Manager/repos.bmx
			_repo_create
		else
			_repo_create
		fi
		cd $curdir
	fi

	if [[ $use == 'f' ]]; then
		for ((idx=0; idx<${#_bm_repos[@]}; ++idx)); do
			if [[ $1 == ${_bm_repos[idx]} ]]; then
				repo=$idx
			fi
		done
		if [[ -n $1 ]]; then
			cd ${_bm_dir[repo]}
			if [[ $2 == 'run' ]]; then
				printf "\e[32mrunning cmd: \e[37m${_bm_run[repo]}\n"
				${_bm_run[repo]}
			elif [[ $2 == 'altrun' ]]
			then
				printf "\e[32mrunning cmd: \e[37m${_bm_altrun[repo]}\n"
				${_bm_altrun[repo]}
			else
				$2 $3 $4
			fi
		fi
	fi
}

_repo_create () {
	if [[ ! -f ~/Branch-Manager/repos.bmx ]]; then
		touch ~/Branch-Manager/repos.bmx
		#AddNewItems
		echo '#Initialize' >> ~/Branch-Manager/repos.bmx
		echo '_bm_repos=()' >> ~/Branch-Manager/repos.bmx
		echo '_bm_dir=()' >> ~/Branch-Manager/repos.bmx
		echo '_bm_run=()' >> ~/Branch-Manager/repos.bmx
		echo '_bm_altrun=()' >> ~/Branch-Manager/repos.bmx
		echo '_bm_build=()' >> ~/Branch-Manager/repos.bmx
		echo '_bm_altbuild=()' >> ~/Branch-Manager/repos.bmx
	fi
	source ~/Branch-Manager/repos.bmx
}

_repo_checkNameExists () {
	checked=false
		for ((idx=0; idx<${#_bm_repos[@]}; ++idx)); do
			if [[ $1 == ${_bm_repos[idx]} ]]; then
				checked=true
				echo "!!Invalid!!"
			fi
		done
	if [[ $checked == false ]]; then
		echo $1
	fi
}

_repo_checker () {
	if [[ $1 == '!' ]]; then
		echo ""
	fi
	if [[ $1 == '' ]]; then
		echo "$2"	
	fi
	if [[ $1 != '!' ]] && [[ $1 != '' ]]; then
		echo "$1"
	fi
}

_repo_edit () {
	wcmd="_bm_$2+=('"
	printf "$1"
	read -r -p '' resp
	resp=$(_repo_checker "$resp" "$3")
	if [[ $5 == false ]]; then
		sel=`expr $4 + 1`
		apnd ~/Branch-Manager/repos.bmx $sel c "$wcmd$resp')"
	else
		apnd ~/Branch-Manager/repos.bmx $sel c "#$resp"
		sel=`expr $sel + 1`
		apnd ~/Branch-Manager/repos.bmx $sel c "$wcmd$resp')"
	fi
}

_repo_AddNewItem () {
	
	ln=$(_repo_getAddLine)
	job="\		echo '_bm_$1=()' >> ~/Branch-Manager/repos.bmx"
	apnd ~/Branch-Manager/branchmanager.sh $ln a "$job"

	bln=$(_repo_getItemsLength)
	apnd ~/Branch-Manager/repos.bmx $bln a "_bm_$1=()"
	for ((idx=0; idx<${#_bm_repos[@]}; ++idx)); do
		sel=$(awk -v line="#"${_bm_repos[idx]} '$0 == line {print NR}' ~/Branch-Manager/repos.bmx)
		selr=`expr $sel + $bln - 1`
		apnd ~/Branch-Manager/repos.bmx $selr a "_bm_$1+=('')"
	done
}

_repo_getItemsLength () {
	bln=$(awk -v line="#"${_bm_repos[0]} '$0 == line {print NR}' ~/Branch-Manager/repos.bmx)
	if [[ -z $bln ]]; then
		bln=$(_repo_getEndOfReposFile)
	else
		bln=`expr $bln - 1`
	fi
	echo $bln
}

_repo_getEndOfReposFile () {
	celn=$(tail -n 1 ~/Branch-Manager/repos.bmx)
	eln=$(awk -v line="$celn" '$0 == line {print NR}' ~/Branch-Manager/repos.bmx)
	echo $eln
}

_repo_getAddLine () {
	eln=$(awk -v line="		#AddNewItems" '$0 == line {print NR}' ~/Branch-Manager/branchmanager.sh)
	iln=$(_repo_getItemsLength)
	ln=`expr $eln + $iln`
	echo $ln
}

_repo_create
readallbm=false
CheckIPUpdater=$(echo $(myip) | awk '{print $(NF-1)}')
if [[ $CheckIPUpdater =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
 	direc=$(pwd)
 	cd ~/Branch-Manager
 	git pull origin master --quiet
 	cd $direc
fi
