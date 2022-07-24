
fd_flags := '--ignore-case'
rg_flags := '--smart-case'

# The default editor.
editor := env_var_or_default('VISUAL', env_var('EDITOR'))

# Search for the given query in the system.
@search +query:
    rg '' {{rg_flags}} --no-line-number --passthru $(exec just findall {{query}})

# Find the path of the first file that matches the given query.
@find +query:
    exec just findall '{{query}}' | rg --multiline '(?-m)^.*\n$'

# Find all files that match the given query.
@find-all +query:
    fd {{fd_flags}} --full-path '{{replace(query, ' ', '.*')}}'
alias findall := find-all

# Get the contents of a file.
open +query:
    #! /bin/sh
    filepath="$(exec just find '{{query}}')"
    if test -f "$filepath" && IFS= read -r line < "$filepath" ; then
        case "$line" in
            ("#!"*) perl "$filepath" ;;
            *) cat "$filepath" ;;
        esac
    fi
alias get := open

# Edit a file that matches the given query.
@edit +query:
    file="$(exec just find '{{query}}' | fzf --select-1 --exit-0)" && {{editor}} "$file"

# List all files in the system.
@list:
    exa --git-ignore --tree --ignore-glob='justfile|README.*'

# Get the modifier of a given ability score.
@modifier score:
    echo $(( $(just get '{{score}}') / 2 - 5 ))

