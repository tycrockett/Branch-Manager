showHelp () {
  case $1 in
    'new'|'n')
      _BM_header "new | n" "\e[34m"
      echo "- git checkout default branch (defined by rpo)"
      echo "- git pull origin default branch"
      echo "- git branch (create new branch)"
      echo "- git checkout (new branch)"
      echo
      echo "If there are changes in the current branch:"
      echo "- git checkout -b (new branch)"
      echo "- bm . 'Changes from (new branch)'"
      echo "- git checkout (default branch)"
      echo "- git pull origin (default branch)"
      echo "- git checkout (new branch)"
      echo "- git merge (default branch)"
    ;;
    'rename'|'rn')
      _BM_header "rename | rn" "\e[34m"
      echo "- git branch -m (new name)"
      echo "- Update remote branch option"
      echo "    - git push origin :(old name) (new name)"
      echo "    - git push origin -u (new name)"
    ;;
    'clear')
      _BM_header "clear" "\e[34m"
      echo "- optional switch '-f'"
      echo "  - git add ."
      echo "- git stash clear"
    ;;
    'compop')
      _BM_header "compop" "\e[34m"
      echo "- git reset --hard HEAD^"
      echo "- bm log"
    ;;
    '.'|'acp')
      _BM_header ". | acp" "\e[34m"
      echo "- If the current branch is NOT the default branch:"
      echo "  - git add ."
      echo "  - git commit -m (message)"
      echo "  - git ls-remote (remote dir) (current branch)"
      echo "  - git push"
      echo "- If message is blank:"
      echo "  - git add ."
    ;;
    'log')
      _BM_header "log" "\e[34m"
      echo "- Git log (default branch ... current branch) --graph --pretty=format:'%Cred%h%Creset | %C(bold blue)%an:%Creset %s %n%Cblue%cr%Creset' --abbrev-commit --date=relative"
      echo "- Option: Number"
      echo "    - Increases how many commits to go back in history"
    ;;
    'rm-file')
      _BM_header "log" "\e[34m"
      echo "- hash=$(git merge-base (default branch) (current branch))"
      echo "- git checkout (hash) (relative file)"
      echo "- git commit -m 'Remove (relative file) from commit'"
    ;;
    'status'|'s')
      _BM_header "status | s" "\e[34m"
      echo "- If changes don't exist:"
      echo "  - git diff (default branch)...(current branch) --stat"
      echo "  - Option: -d"
      echo "  - git diff (default branch)...(current branch) --stat | tail -n1"
      echo "- If changes DO exist:"
      echo "  - git diff (default branch)...(current branch) --stat | tail -n1"
      echo "  - git diff --stat"
      echo "  - If git diff --stat returns empty:"
      echo "    - git diff --name-only --cached"
      echo "    - git ls-files . --exclude-standard --others | wc -l"
      echo "    - echo -e '(val)' | tr -d '[:space:]'"
      echo "    - Git ls-files --exclude-standard --others"
    ;;
    'pushup')
      _BM_header "pushup" "\e[34m"
      echo "- Git push --set-upstream origin (current branch)"
      echo "- bm remote"
    ;;
    'remote')
      _BM_header "remote" "\e[34m"
      echo "- tmp='https://github.$(git config remote.origin.url | cut -f2 -d. | tr ':' /)"
      echo "- open (tmp)/tree/(current branch)"
    ;;
    'update'|'u')
      _BM_header "update | u" "\e[34m"
      echo "- If no changes exist:"
      echo "- git checkout (default branch)"
      echo "- git pull origin (default branch)"
      echo "- git checkout (current branch)"
      echo "- git merge (default branch)"
    ;;
    'default-b')
      _BM_header "'default-b" "\e[34m"
      echo "- Temporarily update default branch"
    ;;
    'delete')
      _BM_header "delete" "\e[34m"
      echo "- git checkout (default branch)"
      echo "- git branch -D (current branch)"
    ;;
    'diff')
      _BM_header "diff" "\e[34m"
      echo "- git diff (default branch)..HEAD -- (relative file)"
    ;;
    *) echo "That command doesn't exist";;
  esac
}