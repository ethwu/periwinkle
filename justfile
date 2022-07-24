
# Set the shell to execute commands.
set shell := ['dash', '-euc']
# Initialize scripts with utilities.
script := '/bin/dash -u
onfail() { status=$? ; test $status -ne 0 && >&2 echo "$@" ; exit $status ; }'
# Pass positional arguments to recipes.
set positional-arguments := true

# Just.
just := "exec '" + just_executable() + "' -f '" + justfile() + "' -d '" + invocation_directory() + "'"
# The default editor.
editor := env_var_or_default('VISUAL', env_var('EDITOR'))

# Test expression evaluating to whether to include color.
color := '[ -t 1 -a $(tput colors) -gt 0 -a -z "${NO_COLOR+blank}" ]'
# # Interactive emphasis color.
# emph := `{{color}} && { tput bold ; tput setaf 1 ; }`
# # Interactive normal color.
# norm := `{{color}} && tput sgr0`
emph := ''
norm := ''

fd_flags := '--ignore-case'
rg_flags := '--smart-case'

fzf_flags := '--select-1 --exit-0'

@_default:
    {{just}} --list

# List all files in the system.
@list:
    exa --tree --git-ignore --ignore-glob="$(cat .ignore | sd '(\w)\n(\w)' '$1|$2')"
alias ls := list

# Search for the given query in the system.
# Only for interactive use.
@search +query:
    for f in $({{just}} find-all "$@") ; do ({{just}} _emph "$f" get "$f") ; done
alias s := search

# Get the contents of a file.
open +query:
    #! {{script}}
    filepath="$({{just}} find '{{query}}')"
    if test -f "$filepath" && IFS= read -r line < "$filepath" ; then
        case "$line" in
            ("#!"*) perl "$filepath" ;;
            *) cat "$filepath" ;;
        esac
    fi
alias get := open

# Edit a file that matches the given query.
@edit +query:
    file="$({{just}} find-all '{{query}}' | fzf {{fzf_flags}})" && {{editor}} "$file"
alias ed := edit


### Game Utilities ###

# Get the modifier of a given ability score.
@modifier score:
    echo $(( $({{just}} get stats/abilities/ '{{score}}') / 2 - 5 ))
alias mod := modifier


### General Utilities ###

# Find the path of the first file that matches the given query.
find +query:
    #! {{script}}
    files="$({{just}} find-all "$@")" || exit $?
    echo "$files" | rg {{rg_flags}} --multiline '(?-m)^.*\n$'
    onfail 'More than one file matches query `{{query}}`.'
alias fd := find

# Find all files that match the given query.
find-all +query:
    #! {{script}}
    fd {{fd_flags}} --full-path --type f '{{replace(query, ' ', '.*')}}' | rg .
    onfail 'No files match query `{{query}}`.'
alias fda := find-all

# Print with emphasis.
_emph message:
    #! {{script}}
    if [ -t 1 -a $(tput colors) -gt 0 -a -z "${NO_COLOR+blank}" ] ; then
        emph="$(tput bold)$(tput setaf 1)"
        norm="$(tput sgr0)"
    else
        emph=
        norm=
    fi
    echo "$emph{{message}}$norm"
