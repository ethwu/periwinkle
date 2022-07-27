
# Set the shell to execute commands.
set shell := ['/bin/dash', '-euc']
# Initialize scripts with utilities.
script := '/bin/dash -u
onfail() { status=$? ; test $status -ne 0 && { >&2 printf "$@" ; >&2 echo ; exit $status ; } ; }'
# Pass positional arguments to recipes.
set positional-arguments := true

# Path to the just executable.
just := quote(just_executable())
# Alias for the justfile directory.
here := justfile_directory()
# Alias for the call site.
call_site := invocation_directory()
# The default editor.
editor := quote(env_var_or_default('VISUAL', env_var('EDITOR')))

# The parent justfile.
parent := justfile_directory() / '..' / 'justfile'

export SCRIPTS := `just -f ../justfile --evaluate SCRIPTS`
export PATH := `just -f ../justfile --evaluate PATH`

# Directory to keep cached `get` results.
export CACHE_DIR := here / '.cache'


@_default:
    exec {{just}} show

# List all files in the system.
@list:
    exa --tree --git-ignore --ignore-glob="$(cat .ignore | sd '(\w)\n(\w)' '$1|$2')"
alias ls := list

# Show an entry in the system interactively.
@show *query:
    exec open "$(exec select "$@")"
alias s := show

# Query for the conents of a file. If the file has a #!, invokes it as a script.
@get *query:
    exec get "$@"

# Get the contents of a file. If the file has a #!, invokes it as a script.
@open file:
    exec open {{quote(file)}}


## Editing Utilities ##

# Get the project root.
@root: 
    echo {{quote(here)}}
alias home := root

# Edit a file that matches the given query.
@edit *query:
    file="$(exec select "$@")" && exec {{editor}} "$file"
alias ed := edit


### General Utilities ###

# Find the path of the first file that matches the given query.
@find +query:
    exec find "$@"
alias fd := find

# Find all files that match the given query.
@find-all *query:
    exec find-all "$@"
alias fda := find-all

# Select a file that matches the given query interactively.
@select *query:
    exec select "$@"
alias sel := select

# Clean intermediate files.
clean:
    rm -rf {{quote(CACHE_DIR / '*')}}

# Call a recipe on the parent `justfile`.
@super *args:
    cd {{quote(call_site)}} && exec {{just}} -f {{quote(here) / '..' / 'justfile'}} "$@"
