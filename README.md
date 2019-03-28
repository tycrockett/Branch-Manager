# Branch-Manager
Add To Bash_Profile:
source ~/Branch-Manager/branchmanager.sh

bm help

bm [command]

Commands:
[BLANK]:			List branches
[1, 2, 3]:			Checkout branch from list
new/n <branch>:			checkout master, pull origin master, create new branch
rename/rn <branch>:		Rename local branch
clear: 				Stash and optionally clear
delete:			 	Delete current branch
update/rf <all>: 		checkout master, pull origin master, merge to current or all branches
pull:				git pull
status/s:			status of branch
sc:				git status, check if remote branch exists
check:				check if local branch has a remote branch
pushup: 			create remote branch and push to it
. <description>:		add, commit -m <des>, push (If remote exists)
remote:				open remote branch in default browser
log:				log commits in current branch
compop:				delete last commit on current branch
clone:				git clone --> create repo keys and cmds
repo:				display repo cmds and directory
run:				start assigned repo run cmd
add:				assign a keyword to current directory and add repo cmds
list:				list all repo keys and their cmds
repo del [key]:			delete repo keys and associated cmds

Help
