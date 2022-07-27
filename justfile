
# Set the shell to execute commands.
set shell := ['/bin/dash', '-euc']
# Pass positional arguments to recipes.
set positional-arguments := true
# Load `.env` files.
set dotenv-load := true

# Path to the `just` executable.
just := quote(just_executable()) + ' -d ' + quote(invocation_directory())
# Alias for the project root directory.
here := justfile_directory()
# Alias for the call site directory.
call_site := invocation_directory()

# Default template file name.
template := '.template'

# Get the main project directory from the `MAIN` environment variable
main := env_var('MAIN')
# List of projects.
projects := main + ' character class'
# Directory containing scripts usable in runnable data.
scripts := '.'

whoami:
    echo parent

@_default:
    exec {{just}} {{main}} show

# List all files in the system.
@list dir:
    exa --tree --git-ignore --ignore-glob="$(cat .ignore | sd '(\w)\n(\w)' '$1|$2')"
alias ls := list


## Editing Utilities ##

# Execute a template file on the given targets.
from-template +targets:
    cd {{quote(call_site)}} && perl {{quote(call_site / template)}} "$@"


## Game Utilities ##

# Roll dice.
roll *args:
    exec {{scripts}}/roll "$@"
alias r := roll


### General Utilities ###

# Get the project root.
@root: 
    echo {{quote(here)}}
alias home := root

# Get the `PATH` variable to use in runnable data scripts.
@path:
    echo {{quote(here / scripts)}}":$PATH"

# Clean intermediate files.
clean:
    for i in {{projects}} ; do {{just}} -f "$i/.justfile" clean ; done
