repo () {
	curdir=$(pwd)
  if [[ -f ~/Branch-Manager/settings/initialize.rpx ]]; then loadRepoSettings; fi
	case $1 in
		'init')
			if [[ -f ~/Branch-Manager/settings/initialize.rpx ]]; then
				del ~/Branch-Manager/settings/initialize.rpx
			fi
			if [[ ! -d ~/Branch-Manager/settings ]]; then
				mkdir ~/Branch-Manager/settings
			fi
			touch ~/Branch-Manager/settings/initialize.rpx
			echo "BM_REPO_directory=()" >> ~/Branch-Manager/settings/initialize.rpx
			echo "BM_REPO_keyname=()" >> ~/Branch-Manager/settings/initialize.rpx
			echo "BM_REPO_run=()" >> ~/Branch-Manager/settings/initialize.rpx
			echo "BM_REPO_altrun=()" >> ~/Branch-Manager/settings/initialize.rpx
			echo "BM_REPO_make=()" >> ~/Branch-Manager/settings/initialize.rpx
			echo "BM_REPO_altmake=()" >> ~/Branch-Manager/settings/initialize.rpx
			echo "BM_REPO_defaultBranch=()" >> ~/Branch-Manager/settings/initialize.rpx
		;;

		'add')
			curfolder=${PWD##*/}
      getIndexByDirectory $curdir
      idx=$BM_REPO_index
      if [[ $idx == 'INVALID' ]]; then
        _BM_header "Create New Repo"
        printf "\e[32mDirectory: \e[37m$curdir\n" 
        printf "\e[32mRepo Keyname: \e[37m"
        read -r -p '' keyname
        if [[ ! -f ~/Branch-Manager/settings/$curfolder-$keyname.rpx ]]; then
          touch ~/Branch-Manager/settings/$curfolder-$keyname.rpx
          echo "directory='$curdir'" >> ~/Branch-Manager/settings/$curfolder-$keyname.rpx
          echo "keyname='$keyname'" >> ~/Branch-Manager/settings/$curfolder-$keyname.rpx
          
          putInput "Default Branch: " "defaultBranch" "master"
          putInput "Run Command: " "run"
          putInput "Alternate Run Command: " "altrun"
          putInput "Make Command: " "make"
          putInput "Alternate Make Command: " "altmake"

        else
          echo "$2 Already Exists!"
        fi
      else
        _BM_header "Directory already assigned to ${BM_REPO_keyname[idx]}" "\e[31m"
        printf "Delete \e[34m${BM_REPO_keyname[idx]}\e[37m to reassign new keyname\n"
      fi
		;;
    'edit')
			curfolder=${PWD##*/}
      getIndexByDirectory $curdir
      idx=$BM_REPO_index
      keyname=${BM_REPO_keyname[idx]}
      if [[ $idx != 'INVALID' ]]; then
        if [[ -f ~/Branch-Manager/settings/$curfolder-$keyname.rpx ]]; then
          del ~/Branch-Manager/settings/$curfolder-$keyname.rpx
        fi
        touch ~/Branch-Manager/settings/$curfolder-$keyname.rpx
        _BM_header "Edit ${BM_REPO_keyname[idx]}"
        printf "\e[34mDirectory: \e[37m${BM_REPO_directory[idx]}\n"
        printf "\e[34mRepo Keyname: \e[37m${BM_REPO_keyname[idx]}\n"
        echo "directory='$curdir'" >> ~/Branch-Manager/settings/$curfolder-$keyname.rpx
        echo "keyname='$keyname'" >> ~/Branch-Manager/settings/$curfolder-$keyname.rpx
        putInput "Default Branch (\e[36m${BM_REPO_defaultBranch[idx]}\e[32m): " "defaultBranch" "${BM_REPO_defaultBranch[idx]}"
        putInput "Run Command (\e[36m${BM_REPO_run[idx]}\e[32m): " "run" "${BM_REPO_run[idx]}"
        putInput "Alternate Run Command (\e[36m${BM_REPO_altrun[idx]}\e[32m): " "altrun" "${BM_REPO_altrun[idx]}"
        putInput "Make Command (\e[36m${BM_REPO_make[idx]}\e[32m): " "make" "${BM_REPO_make[idx]}"
        putInput "Alternate Make Command (\e[36m${BM_REPO_altmake[idx]}\e[32m): " "altmake" "${BM_REPO_altmake[idx]}"
      else
        _BM_header "${BM_REPO_keyname[idx]} doesn't exist"
      fi
    ;;

    'delete')
			curfolder=${PWD##*/}
      getIndexByDirectory $curdir
      idx=$BM_REPO_index
      if [[ -f ~/Branch-Manager/settings/$curfolder-${BM_REPO_keyname[idx]}.rpx ]]; then 
        del ~/Branch-Manager/settings/$curfolder-${BM_REPO_keyname[idx]}.rpx
      else
        _BM_header "No repo is assigned to this directory" "\e[31m"
      fi
    ;;
    
    'list')
      case $2 in
        'all')
          printf "\n${#BM_REPO_keyname[@]} Repo(s)\n"
          for ((idx=0; idx<${#BM_REPO_keyname[@]}; ++idx)); do
            listRepoSetting $idx
          done
        ;;
        *)
          getIndexByDirectory $curdir
          if [[ $BM_REPO_index != 'INVALID' ]]; then listRepoSetting $BM_REPO_index; fi
        ;;
      esac
    ;;

    'run')
      getIndexByDirectory $curdir
      idx=$BM_REPO_index
      _BM_header "Running CMD: ${BM_REPO_run[idx]}"
      ${BM_REPO_run[idx]}
    ;;
    'altrun')
      getIndexByDirectory $curdir
      idx=$BM_REPO_index
      _BM_header "Running CMD: ${BM_REPO_altrun[idx]}"
      ${BM_REPO_altrun[idx]}
    ;;
    'make')
      getIndexByDirectory $curdir
      idx=$BM_REPO_index
      _BM_header "Running CMD: ${BM_REPO_make[idx]}"
      ${BM_REPO_make[idx]}
    ;;
    'altmake')
      getIndexByDirectory $curdir
      idx=$BM_REPO_index
      _BM_header "Running CMD: ${BM_REPO_altmake[idx]}"
      ${BM_REPO_altmake[idx]}
    ;;

    *)
      for ((idx=0; idx<${#BM_REPO_keyname[@]}; ++idx)); do
        if [[ $1 == ${BM_REPO_keyname[idx]} ]]; then
          cd ${BM_REPO_directory[idx]}
        fi
      done 
    ;;

	esac
  
  tmp=$(git rev-parse --git-dir 2> /dev/null);
  if [ $tmp ]; then updateGlobes; fi

}

updateGlobes () {
  loadRepoSettings
  getIndexByDirectory $(pwd)
  idx=$BM_REPO_index
  BMGLOBES_defaultBranch=${BM_REPO_defaultBranch[idx]}
  if [[ $BMGLOBES_defaultBranch == '' ]]; then BMGLOBES_defaultBranch='master'; fi
}

listRepoSetting () {
  _BM_header "${BM_REPO_keyname[$1]}" "\e[34m"
  _echoR "Directory: " "${BM_REPO_directory[$1]}"
  _echoR "Default Branch: " "${BM_REPO_defaultBranch[$1]}"
  _echoR "Run Command: " "${BM_REPO_run[$1]}"
  _echoR "Alternate Run Command: " "${BM_REPO_altrun[$1]}"
  _echoR "Make Command: " "${BM_REPO_make[$1]}"
  _echoR "Alternate Make Command: " "${BM_REPO_altmake[$1]}"
}

loadRepoSettings () {
  arr=(~/Branch-Manager/settings/*)
  source ~/Branch-Manager/settings/initialize.rpx
  for ((i=0; i<${#arr[@]}; i++)); do
    if [[ ${arr[$i]##*/} != 'initialize.rpx' ]]; then
      source "${arr[$i]}"
      BM_REPO_directory+=("$directory")
      BM_REPO_keyname+=("$keyname")
      BM_REPO_run+=("$run")
      BM_REPO_altrun+=("$altrun")
      BM_REPO_make+=("$make")
      BM_REPO_altmake+=("$altmake")
      BM_REPO_defaultBranch+=("$defaultBranch")
    fi 
  done
}

toLowerCase () {
  echo "$1" | awk '{print tolower($0)}'
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

putInput () {
	printf "\e[32m$1 \e[37m"
	read -r -p '' resp
	if [[ -z $resp ]]; then resp="$3"; fi
  if [[ $resp == '!!' ]]; then resp=''; fi
	echo "$2='$resp'" >> ~/Branch-Manager/settings/$curfolder-$keyname.rpx
}

tmp=$(git rev-parse --git-dir 2> /dev/null);
if [ $tmp ]; then updateGlobes; fi