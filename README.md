# Branch-Manager
Add To Bash_Profile:
source ~/BranchManager/BranchManager.sh

bm [command]

	Commands:
	[BLANK]:		          	List branches
	[1, 2, 3]:		        	Checkout branch from list
	new/n <branch>:		    	Pull master, Create new branch
	rename/rn <branch>:	  	Rename local branch
	clear: 			          	Stash and optionally clear
	delete:			          	Delete current branch
	update/rf <all>: 	    	Pull master, Merge to current or all branches
	pull:			            	Git Pull
	status/s:		          	Status of branch
	sc:			              	Get status, check if remote branch exists
	check:			          	Check if local branch has a remote branch
	pushup <branch>: 	    	Create remote branch and push to it
	. <description>:	    	Add, Commit -m <des>, Push (If remote exists)
	remote:			          	Open remote branch in default browser
	log:			            	Log commits in current branch
	compop:			          	Delete last commit on current branch
	clone:		          		Git Clone --> Create repo keys and cmds
	repo:		              	Display repo cmds and directory
	run:		              	Start assigned repo run cmd
	add:		              	Assign a keyword to current directory and add repo cmds
	list:		              	List all repo keys
	repo del [key]:		     	Delete repo keys and associated cmds
