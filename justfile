
# Set the shell to execute commands.
set shell := ['/bin/dash', '-euc']
# Pass positional arguments to recipes.
set positional-arguments := true
# Load `.env` files.
set dotenv-load := true


# Path to the `just` executable.
just := quote(just_executable())
# Alias for the project root directory.
here := justfile_directory()
# Alias for the call site directory.
call_site := invocation_directory()


# Get the main project directory from the `MAIN` environment variable
main := env_var('MAIN')
# List of projects.
projects := main + ' character class'
# Directory containing scripts usable in runnable data.
export SCRIPTS := 'scripts'
# Add scripts to PATH.
export PATH := here / SCRIPTS + ':' + env_var('PATH')

# Default template file name.
template := '.template'

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
    exec {{quote(SCRIPTS / 'roll')}} "$@"
alias r := roll


### General Utilities ###

# Get the project root.
@root: 
    echo {{quote(here)}}
alias home := root

# Get a `PATH` including project scripts.
@path:
    echo "$PATH"

# Clean intermediate files.
clean:
    for i in {{projects}} ; do {{just}} "$i"/clean ; done
