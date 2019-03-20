bm () {
	used=false
	if [[ $1 == 'echo' ]]; then
		test_branch_manager=true
		bm $2
		test_branch_manager=false
	fi

	if [[ $1 == '_edit' ]]; then
		code ~/Branch-Manager/branchmanager.sh
		used=true
	fi

	if [[ $used == false ]] && [[ -n $1 ]]; then
		for ((idx=0; idx<${#_bm_repos[@]}; ++idx)); do
			if [[ $1 == ${_bm_repos[idx]} ]]; then
				repo $1 $2 $3 $4
				used=true
			fi
		done
	fi

	if [[ $1 == 'list' ]]; then used=true; repo list; fi
	if [[ $1 == 'add' ]]; then used=true; repo add; fi
	if [[ $1 == 'repo' ]]; then used=true; repo $2 $3; fi
	if [[ $1 == 'edit' ]] && [[ -n $2 ]]; then
	  used=true
		repo edit $2
	fi

	if [ -d .git ] && [[ $used == false ]]; then
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
				cls
				echo
				printf "\e[31mCouldn't switch branches\e[37m\n"
				echo "Commit your changes or"
				echo "Use <bm clear> to clear all changes and try again"
				bm s
			fi
			used=true
		fi

		if [[ $1 == 'new' ]] || [[ $1 == 'n' ]]; then
			cls
			status=$(git status)
			fixed=${status: -37}
			if [[ $fixed == "nothing to commit, working tree clean" ]]; then
				bm__newbranch $2
				bm
			else
				echo
				printf "\e[31mCouldn't create new branch\e[37m\n"
				echo "Commit your changes or"
				echo "Use <bm clear> to clear all changes and try again"
				bm s
			fi
			used=true
		fi

		if [[ $1 == 'rename' ]] || [[ $1 == 'rn' ]] ; then
			git branch -m $2
			used=true
		fi
		
		if [[ $1 == 'clear' ]]; then
			if [[ $2 == '-a' ]]; then
				git add .
			fi
			used=true
			git stash
			printf "\e[31mPermanetly clear stash on \e[32m$currentBranch\e[31m? \e[37m"
			read -r -p '' response
			if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
				git stash clear
			fi
		fi

		if [[ $1 == 'delete' ]]; then
			cls
			used=true
			status=$(git status)
			fixed=${status: -37}
			if [[ $fixed == "nothing to commit, working tree clean" ]]; then
				git status
				printf "\e[31mPermanetly delete \e[32m$currentBranch\e[31m? \e[37m"
				read -r -p '' response
				if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
					cls
					bm__delbranch $2
					bm
				else
						printf "\e[37mGood Choice\n"
				fi
			else
				echo
				printf "\e[31mCouldn't delete branch\e[37m\n"
				echo "Commit your changes or"
				echo "Use <bm clear> to clear all changes and try again"
				bm s
			fi
		fi

		if [[ $1 == 'compop' ]]; then
			used=true
			cls
			printf "\e[31mPermanetly delete last commit on \e[32m$currentBranch\e[31m? \e[37m"
			read -r -p '' response
			if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
				git reset --hard HEAD^
				bm log
			fi
		fi

		if [[ $1 == 'update' ]] || [[ $1 == 'rf' ]] ; then
			printf "\e[33m"
			if [[ $currentBranch != 'master' ]]; then
				git checkout master
			fi
			git pull origin master
			printf "\e[37m"

			if [[ -z $2 ]] && [[ $currentBranch != 'master' ]]; then
				printf "\e[32m"
				git checkout $currentBranch
				printf "\e[37m"
				git merge master
			fi

			if [[ $2 == 'all' ]]; then
				for branch in $(git branch | grep "[^* ]+" -Eo);
				do
					if [[ $branch != 'master' ]]; then
						printf "\e[32m"
						git checkout $branch
						printf "\e[37m"
						git merge master
					fi
					br+=($branch)
				done
				if [[ $branch != $currentBranch ]]; then 
					echo
					printf "\e[34m"
					git checkout $currentBranch 
				fi
			fi
			used=true
		fi

		if [[ $1 == 'pull' ]]; then
			git pull
		fi

		if [[ $1 == 'pushup' ]]; then
			git push --set-upstream origin $currentBranch
			bm remote
			used=true
		fi

		if [[ $1 == '.' ]]; then

			if [[ -z $2 ]]; then
				cls
				git add .
				git commit -m ""
			fi
			if [[ -n $2 ]]; then
				cls
				git add .
				git commit -m "$2"
				checkit=$(git ls-remote $remoteDir $currentBranch) 
				if [[ -n $checkit ]]; then
					git push
				fi
			fi
			bm s
			used=true
		fi

		if [[ $1 == 'status' ]] || [[ $1 == 's' ]] || [[ $1 == 'sc' ]]; then
			bm
			echo
			status=$(git status)
			fixed=${status: -37}
			if [[ $fixed == "nothing to commit, working tree clean" ]]; then
				printf "\e[97m$fixed\e[31m\n"
			else
				git status
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
		fi

		if [[ $1 == 'check' ]]; then
			used=true
			checkit=$(git ls-remote $remoteDir $currentBranch)
			if [[ -z $checkit ]]; then
				echo
				printf "\e[34m[!] No remote branch exists\e[37m\n"
				printf "Use \e[35mbm pushup\e[37m to create an upstream branch"
				echo
			else
				printf "\e[32mRemote branch exists!\e[31m\n"
				echo
			fi
		fi

		if [[ $1 == 'remote' ]]; then
			used=true
			tmp="https://github.$(git config remote.origin.url | cut -f2 -d. | tr ':' /)"
			open "$tmp/tree/$currentBranch"
		fi

		if [[ $1 == 'log' ]]; then
			used=true
			git log master..$currentBranch --no-decorate
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
		if [[ $1 == 'run' ]]; then used=true; repo run; fi
		if [[ $1 == 'altrun' ]]; then used=true; repo altrun; fi
		if [[ $1 == 'build' ]]; then used=true; repo build; fi
		if [[ $1 == 'altbuild' ]]; then used=true; repo altbuild; fi

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
			git clone $2
			cd $tmpRepo
			printf "\e[36m"
			repo add
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
	echo "rename/rn <branch>:		Rename local branch"
	echo "clear: 				Stash and optionally clear"
	echo "delete:			 	Delete current branch"
	echo "update/rf <all>: 		checkout master, pull origin master, merge to current or all branches"
	echo "pull:				git pull"
	echo "status/s:			status of branch"
	echo "sc:				git status, check if remote branch exists"
	echo "check:				check if local branch has a remote branch"
	echo "pushup: 		create remote branch and push to it"
	echo ". <description>:		add, commit -m <des>, push (If remote exists)"
	echo "remote:				open remote branch in default browser"
	echo "log:				log commits in current branch"
	echo "compop:				delete last commit on current branch"
	echo "clone:				git clone --> create repo keys and cmds"
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
				selected=' *'
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
		git checkout ${br[@]:$opt:1}
	fi
}

bm__newbranch () {
	branch=$(git symbolic-ref --short -q HEAD)
	if [[ $branch != 'master' ]]; then
		git checkout  master
	else
		echo In master
	fi
	git pull origin master
	git branch $1
	git checkout $1
}

bm__delbranch () {
	branch=$(git symbolic-ref --short -q HEAD)
	if [[ $branch != "master" ]]
		then
			git checkout master
			git branch -D $branch
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

	if [[ $1 == 'del' ]]; then
		use='t'
		sel=$(awk -v line="#"$2 '$0 == line {print NR}' ~/Branch-Manager/repos.bmx)
		echo $sel
		bln=$(_repo_getItemsLength)
		bln=`expr $bln`
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
				_repo_edit "Key Name (${_bm_repos[idx]}): " "repos" "${_bm_repos[idx]}" "$sel" true; sel=`expr $sel + 1`
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
		for ((idx=0; idx<${#_bm_repos[@]}; ++idx)); do
			if [[ $curdir == ${_bm_dir[idx]} ]]; then
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
