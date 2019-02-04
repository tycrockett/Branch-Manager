# Branch-Manager

TODO:
In Bash_Profile:
Add `source ~/BranchManager/BranchManager.sh`

TOKNOW:

Commands: (bm help)

  `[BLANK]`:			          List branches
  
  [1, 2, 3]:		        	Checkout branch from list
  
  new/n <branch>:	    		Pull master, Create new branch
  
  rename/rn <branch>:	   	Rename local branch
  
  clear: 			          	Stash and optionally clear
  
  delete:			           	Delete current branch
  
  update/rf <all>: 	    	Pull master, Merge to current or all branches
  
  status/s:		          	Status of branch
  
  sc:			              	Get status, check if remote branch exists
  
  check:		          		Check if local branch has a remote branch
  
  pushup <branch>: 	    	Create remote branch and push to it
  
  . <description>:	    	Add, Commit -m <des>, Push (If remote exists)
  
  remote:				          Open remote branch in default browser
  
  log:				            Log commits in current branch
  
  BETA:
  
    ckey <keyword>:			  Use <keyword> to cd into current dir
    
    lkey:				          List all bm keywords'
    
    dkey <keyword>:		   	Deletes bm keyword
    
    USE:
    
      <keyword> = cd into saved directory
      
      <keyword> run = cd into saved directory and start the run cmd
      
      <keyword> altrun = same as run but stats alternate run cmd
      
