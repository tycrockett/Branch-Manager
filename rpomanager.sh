rpo () {
	curdir=$(pwd)
	curfolder=${PWD##*/}
	loadRepoSettings $curfolder
	if [[ $BM_REPO_directory != $curdir ]]; then
		BM_REPO_directory=''
		BM_REPO_keyname=''
		BMGLOBES_defaultBranch=''
		BM_REPO_cmds=()
	fi
	if [[ -f ~/Branch-Manager/repoPack/packs.rpx ]]; then source ~/Branch-Manager/repoPack/packs.rpx; fi
	case $1 in
		'new')
			printf "\e[32mDirectory: \e[37m$curdir\n" 
			printf "\e[32mRepo Keyname: \e[37m"
			read -r -p '' keyname
			printf "\e[32mRepo Default Branch: \e[37m"
			read -r -p '' defBranch
			initPackFile $curfolder $curdir $keyname $defBranch true
		;;
		'help')
			printf "|"
			_echoR "rpo"	"Create new repo pack to current directory"
				printf "|"
			_echoR "rpo [key]" "Go to repo directory"
			printf "|"
			_echoR "rpo list" "List all saved repo packs"
			printf "|"
			_echoR "rpo pack" "List all repo pack details"
			printf "|"
			_echoR "rpo edit" "Edit the repo keyname and default branch"
			printf "|"
			_echoR "rpo rm" "Remove repo pack"
			printf "|"
			_echoR "rpo cmd" "Create new cmd"
			printf "|"
			_echoR "rpo cmd [cmd]" "Edit [cmd]"
			printf "|"
			_echoR "rpo rm [cmd]" "Remove a cmd from a repo pack"
		;;
		'list')
			echo
			echo "Saved Packs:"
			length=0
			for ((i=0; i<${#BM_REPOS[@]}; ++i)); do
				cmdName=$(cut -d ":" -f 1 <<< "${BM_REPOS[i]}")
				len=${#cmdName}
				if [[ $len > $length ]]; then length=$len; fi
			done
			for ((i=0; i<${#BM_REPOS[@]}; ++i)); do
				cmdName=$(cut -d ":" -f 1 <<< "${BM_REPOS[i]}")
				cmd=$(cut -d ":" -f 2 <<< "${BM_REPOS[i]}")
				printf "|"
				_echoR $cmdName $cmd $length
			done
		;;
		'edit')
			if [[ $BM_REPO_directory == $curdir ]]; then
				check="$BM_REPO_keyname:$BM_REPO_directory"
				echo
				echo "Directory: $BM_REPO_directory"
				BM_REPO_keyname=$(editPrompt "Keyname ($BM_REPO_keyname): " $BM_REPO_keyname)
				BMGLOBES_defaultBranch=$(editPrompt "Default Branch: ($BMGLOBES_defaultBranch): " $BMGLOBES_defaultBranch)
				initPackFile $curfolder $curdir $BM_REPO_keyname $BMGLOBES_defaultBranch false
				rebuildCmds $curfolder
				rebuildPack $check "$BM_REPO_keyname:$BM_REPO_directory"
			fi
		;;
		'rm')
			if [[ -n $2 ]]; then
			idx=$(indexCmd $2)
				if [[ $idx != 'INVALID' ]]; then
					initPackFile $curfolder $curdir $BM_REPO_keyname $BMGLOBES_defaultBranch false
					rebuildCmds $curfolder '' $idx
				else
					echo
					echo "That command doesn't exist."
				fi
			else
				if [[ -f ~/Branch-Manager/repoPack/$curfolder.rpx ]]; then
					check="$BM_REPO_keyname:$BM_REPO_directory"
					rebuildPack $check
					del ~/Branch-Manager/repoPack/$curfolder.rpx
				else
					echo
					echo $curdir
					echo "No repo-pack exists at this directory"
				fi
			fi
		;;
		'pack')
			echo
			_print "Directory: " "green"
			_print "$BM_REPO_directory" "white" "\n"
			_print "Keyname: " "green"
			_print "$BM_REPO_keyname" "white" "\n"
			_print "Default Branch: " "green"
			_print "$BMGLOBES_defaultBranch" "white" "\n"
			_print "Commands:" "green" "\n"
			for ((i=0; i<${#BM_REPO_cmds[@]}; ++i)); do
				echo " - ${BM_REPO_cmds[i]}"
			done
		;;
		'cmd')
			if [[ -n $2 ]]; then
				initPackFile $curfolder $curdir $BM_REPO_keyname $BMGLOBES_defaultBranch false
				rebuildCmds $curfolder $2
			else
				path=~/Branch-Manager/repoPack/$curfolder.rpx
				_print "CMD Name: " "green"
				read -r -p '' cmdName
				_print "CMD: " "green"
				read -r -p '' cmd
				echo "BM_REPO_cmds+=('$cmdName:$cmd')" >> $path
			fi
		;;
		*)
			if [[ -n $1 ]]; then
				directory=$(getRepoByKeyname $1)
				if [[ $directory != 'INVALID' ]]; then
					cd $directory
					loadRepoSettings ${PWD##*/}
				else
					runCmd $1
				fi
			fi
			
		;;
	esac
}

initPackFile () {
	if [[ -f ~/Branch-Manager/repoPack/$1.rpx ]]; then
		if [[ $5 == true ]]; then
			echo
			echo "$keyname already exists!"
		else
			del ~/Branch-Manager/repoPack/$1.rpx
		fi
	fi

	if [[ ! -f ~/Branch-Manager/repoPack/$1.rpx ]]; then
		touch ~/Branch-Manager/repoPack/$1.rpx
		path=~/Branch-Manager/repoPack/$1.rpx
		echo "BM_REPO_directory='$2'" >> $path
		echo "BM_REPO_keyname='$3'" >> $path
		echo "BMGLOBES_defaultBranch='$4'" >> $path
		echo "BM_REPO_cmds=()" >> $path
		if [[ $5 == true ]]; then
			addNewPack "$3:$2"
		fi
	fi
}

addNewPack () {
	rebuildPack
	echo "BM_REPOS+=('$1')"  >> ~/Branch-Manager/repoPack/packs.rpx
}

rebuildPack () {
	if [[ -f ~/Branch-Manager/repoPack/packs.rpx ]]; then 
		source ~/Branch-Manager/repoPack/packs.rpx
		del ~/Branch-Manager/repoPack/packs.rpx 
	fi
	touch ~/Branch-Manager/repoPack/packs.rpx
	echo "BM_REPOS=()"  >> ~/Branch-Manager/repoPack/packs.rpx
	for ((i=0; i<${#BM_REPOS[@]}; ++i)); do
		if [[ -z $1 ]]; then echo "BM_REPOS+=('${BM_REPOS[i]}')" >> ~/Branch-Manager/repoPack/packs.rpx;
		else
			if [[ $1 != ${BM_REPOS[i]} ]] && [[ -z $2 ]]; then echo "BM_REPOS+=('${BM_REPOS[i]}')" >> ~/Branch-Manager/repoPack/packs.rpx; fi
			if [[ $1 == ${BM_REPOS[i]} ]] && [[ -n $2 ]]; then echo "BM_REPOS+=('$2')" >> ~/Branch-Manager/repoPack/packs.rpx; fi
		fi
	done
	source ~/Branch-Manager/repoPack/packs.rpx
}

rebuildCmds () {
	for ((i=0; i<${#BM_REPO_cmds[@]}; ++i)); do
		cmdName=$(cut -d ":" -f 1 <<< "${BM_REPO_cmds[i]}")
		cmd=$(cut -d ":" -f 2 <<< "${BM_REPO_cmds[i]}")
		if [[ $2 == $cmdName ]]; then
			cmdName=$(editPrompt "CMD Name ($cmdName): " "$cmdName")
			cmd=$(editPrompt "CMD ($cmd): " "$cmd")
		fi
		if [[ -n $3 ]] && [[ $3 != $i ]]; then
			echo "BM_REPO_cmds+=('$cmdName:$cmd')" >> ~/Branch-Manager/repoPack/$1.rpx
		fi
		if [[ -z $3 ]]; then echo "BM_REPO_cmds+=('$cmdName:$cmd')" >> ~/Branch-Manager/repoPack/$1.rpx; fi
		
	done
}

editPrompt () {
	read -r -p "$1" response
	if [[ $response == '' ]]; then
		response="$2"
	fi
	echo $response
}

loadRepoSettings () {
	BMGLOBES_defaultBranch=''
	if [[ -f ~/Branch-Manager/repoPack/$1.rpx ]]; then
		source ~/Branch-Manager/repoPack/$1.rpx
	fi
	# if [[ $BMGLOBES_defaultBranch == '' ]]; then BMGLOBES_defaultBranch='master'; fi
}

indexCmd () {
	check="INVALID"
	for ((i=0; i<${#BM_REPO_cmds[@]}; i++)); do
		cmdName=$(cut -d ":" -f 1 <<< "${BM_REPO_cmds[i]}")
		if [[ $cmdName == $1 ]]; then
			check="$i"
		fi
	done
	echo $check
}

getRepoByKeyname () {
	check="INVALID"
	for ((i=0; i<${#BM_REPOS[@]}; ++i)); do
		kn=$(cut -d ":" -f 1 <<< "${BM_REPOS[i]}")
		if [[ $kn == $1 ]] && [[ -n $1 ]]; then
			check=$(cut -d ":" -f 2 <<< "${BM_REPOS[i]}")
		fi
	done
	echo $check
}
getIndexByDirectory () {
  checked=false
  cleanDir=$(toLowerCase $1)
  for ((idx=0; idx<${#BM_REPO_keyname[@]}; ++idx)); do
    cleanRepoDir=$(toLowerCase ${BM_REPO_directory[idx]})
    if [[ $cleanDir == $cleanRepoDir ]]; then
      BM_REPO_index=$idx
      checked=true
      break
    fi
  done
  if [[ $checked == false ]]; then BM_REPO_index='INVALID'; fi
}

toLowerCase () {
  echo "$1" | awk '{print tolower($0)}'
}

runCmd () {
	for ((idx=0; idx<${#BM_REPO_cmds[@]}; ++idx)); do
		cmdName=$(cut -d ":" -f 1 <<< "${BM_REPO_cmds[idx]}")
		if [[ $cmdName == $1 ]]; then
			cmd=$(cut -d ":" -f 2 <<< "${BM_REPO_cmds[idx]}")
			_BM_header "$cmd" "\e[35m"
			$cmd
		fi
	done
}

loadRepoSettings ${PWD##*/}