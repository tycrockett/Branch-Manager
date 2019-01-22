bm () {
	if [[ $1 == '_edit' ]]; then
		code ~/branchmanager/branchmanager.sh
		used=true
	fi
	if [ -d .git ]; then
		currentBranch=$(git symbolic-ref --short -q HEAD)
		remoteDir=$(git config remote.origin.url)
		re='^[0-9]+$'
		used=false
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
				echo "$2 Successfully created"
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
			used=true
			git stash
			printf "\e[32mBranch stash successful!\n"
			printf "\e[31mPermanetly clear stash on \e[32m$currentBranch\e[31m? \e[37m"
			read -r -p '' response
			if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
				git stash clear
				printf "\e[32mCleared Stash! \e[37m \n"
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

		if [[ $1 == 'update' ]] || [[ $1 == 'rf' ]] ; then
			bm__updatebranch
			used=true
		fi

		if [[ $1 == 'pushup' ]]; then
			git push --set-upstream origin $currentBranch
			bm remote
			used=true
		fi

		if [[ $1 == 'acp' ]]; then
			cls
			git add .
			git commit -m "$2"
			echo Commit Successful
			checkit=$(git ls-remote $remoteDir $currentBranch) 
			if [[ -n $checkit ]]; then
				git push
				echo Push Successful
			fi
			bm s
			used=true
		fi

		if [[ $1 == 's' ]] || [[ $1 == 'sc' ]]; then
			bm
			echo
			status=$(git status)
			fixed=${status: -37}
			if [[ $fixed == "nothing to commit, working tree clean" ]]; then
				printf "\e[97m$fixed\e[31m\n"
			else
				git status
			fi
			if [[ $1 == 'sc' ]]; then
				bm check
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
			tmp="https://github.$(git config remote.origin.url | cut -f2 -d. | tr ':' /)"
			open "$tmp/tree/$currentBranch"
		fi

		if [[ $1 == 'help' ]]; then
			printf "                  \e[33mBranch Manager:\e[37m\n"
			echo "---------------------------------------------------"
			printf "                     ; ; ;\n"
      printf "            ;        ;  ;     ;;    ;\n"
      printf "         ;                 ;         ;  ;\n"
      printf "                         ;\n"
      printf "                        ;                ;;\n"
      printf "        ;          ;            ;              ;\n"
      printf "        ;            ';,        ;               ;\n"
      printf "        ;              'b      *\n"
      printf "         ;              '$    ;;                ;;\n"
      printf "        ;    ;           $:   ;:               ;\n"
      printf "       ;;      ;  ;;      *;  @):        ;   ; ;\n"
      printf "                    ;     :@,@):   ,;**:'   ;\n"
      printf "        ;      ;,         :@@*: ;;**'      ;   ;\n"
      printf "                 ';o;    ;:(@';@*'''  ;\n"
      printf "         ;  ;       'bq,;;:,@@*'   ,*      ;  ;\n"
      printf "                    ,pSq8,:@)'  ;p*'      ;\n"
      printf "             ;     '  ; '@@Pp@@*'    ;  ;\n"
      printf "              ;  ; ;;    Y7'.'     ;  ;\n"
      printf "                        :@):.\n"
      printf "                       .:@:'.\n"
      printf "                     .::(@:.      -Sam Blumenstein-\n"
			echo "---------------------------------------------------"
			echo
			echo "bm [command]"
			echo "Commands:"
			echo "[BLANK]:			List branches"
			echo "[1, 2, 3]:			Checkout branch from list"
			echo "new/n <branch>:			Update master and create new branch"
			echo "rename/rn <branch>:		Rename local branch"
			echo "clear: 				Stash and clear"
			echo "delete:			 	Delete current branch"
			echo "update/rf: 			Pull Master, Merge to branch"
			echo "s:				Status of branch"
			echo "pushup <branch>: 		Create remote branch and push to it"
			echo "> <description>:		Add, Commit -m <des>, Push (If remote exists)"
			echo "edit:                           Edit branchmanager.sh"
			echo "check:				Check if local branch has a remote branch"
			used=true
		fi
else
  printf "\n\e[33mNot a git repository:\e[37m\n"
	printf "$(pwd)\n"
fi
}

bm__changebranch () {
	ll=0
	br=()
	current=$(git symbolic-ref --short -q HEAD)
	if [[ -z $1 ]]; then
		echo
		printf  "\e[33mBranch Manager:\n\e[37m"
		echo ---------------
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
		printf "\e[37m --------------"
		echo
	else
		opt=`expr $1 - 1`
		git checkout ${br[@]:$opt:1}
	fi
}

bm__updatebranch () {
	branch=$(git symbolic-ref --short -q HEAD)
	if [[ $branch != 'master' ]]; then
		git checkout master
	else
		echo In master
	fi
	git pull origin master
	git checkout $branch
	git merge master
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
		sed -i "" "$2"$3'\'$'\n'$4$'\n' $1
	else
		echo
		echo "bm__apnd <filename line (a/c) text>"
	fi
}
