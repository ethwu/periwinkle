
# Set the shell to execute commands.
set shell := ['dash', '-euc']
# Initialize scripts with utilities.
script := '/bin/dash -u
onfail() { status=$? ; test $status -ne 0 && { >&2 printf "$@" ; >&2 echo ; exit $status ; } ; }'
# Pass positional arguments to recipes.
set positional-arguments := true

# Path to just.
just := quote(just_executable())
# The current working directory.
cwd := quote(invocation_directory())
# The justfile directory.
here := quote(justfile_directory())
# The default editor.
editor := quote(env_var_or_default('VISUAL', env_var('EDITOR')))

# Path to the `roll` script.
roll := quote(justfile_directory() / '.roll')

# Directory to keep cached `get` results.
cache_dir := justfile_directory() / '.cache'

fd_flags := '--ignore-case'
rg_flags := '--smart-case'
rg_colorize := '''
    rg --colors match:none --colors match:fg:blue '^(?:\./)?(.*/)' --replace '$1'  '''
fzf_flags := '--select-1 --exit-0 --filepath-word --cycle --height=50% --layout=reverse --header-first --history=' + quote(cache_dir / '.fzf') + ' --preview="exec ' + just + ' get {}"'


@_default:
    exec {{just}} show

# List all files in the system.
@list:
    exa --tree --git-ignore --ignore-glob="$(cat .ignore | sd '(\w)\n(\w)' '$1|$2')"
alias ls := list

# Show an entry in the system interactively.
@show *query:
    exec {{just}} open "$(exec {{just}} find-all-interactive "$@")"
alias s := show

# Query for the conents of a file. If the file has a #!, invokes it as a script.
# The script is executed with the following arguments:
# - `$PWD` The directory containing the file.
# - `$0` The name of the file.
# - `$1` The relative path of the file from the root of the project (excluding `./`).
# - `$2` The absolute path to the root of the project.
get *query:
    #! {{script}}
    file="$(exec {{just}} find "$@")"
    onfail 'Ambiguous query `%s`.' {{quote(query)}}
    exec {{just}} open "$file"

# Get the contents of a file. If the file has a #!, invokes it as a script.
# Returns 2 if the file cannot be opened or is empty.
open file:
    #! {{script}}
    if [ ! -f {{quote(file)}} ] ; then
        >&2 printf '`%s` is not a file.\n' {{quote(file)}}
        exit 2
    fi

    if [ -t 1 ] ; then echo {{quote(file)}} | >&2 {{rg_colorize}} ; fi
    if IFS= read -r line < {{quote(file)}} ; then
        dir="$(dirname {{quote(file)}})" ; name="$(basename {{quote(file)}})" ; cd "$dir"
        mkdir -p {{quote(cache_dir)}}/"$dir" ; cache={{quote(cache_dir / file)}}
        if [ -f "$cache" ] && [ "$(head -n 1 "$cache")" = "$(cksum "$name")" ] ; then
            sed '1d' "$cache" ; exit ; fi
        cksum "$name" > "$cache"
        { case "$line" in
            ('#!'*) perl "$name" {{quote(file)}} {{here}} ;;
            *) cat "$name" ;;
        esac ; } | tee -a "$cache"
    fi


## Editing Utilities ##

# Get the project root.
@root: 
    echo {{here}}
alias home := root

# Edit a file that matches the given query.
@edit +query:
    file="$(exec {{just}} find-all-interactive "$@")" && {{editor}} "$file"
alias ed := edit

# Copy the contents of a template to the target file.
from-template target template='.template':
    cp {{quote(invocation_directory() / template)}} {{quote(invocation_directory() / target)}}

## Game Utilities ##

# Roll dice.
@roll *args:
    exec {{roll}} "$@"
alias r := roll

# Get the modifier of a given ability score.
@modifier score:
    echo $(( $(exec {{just}} get stats/abilities/ {{quote(score)}}) / 2 - 5 )) 2> /dev/null | \
        exec {{just}} _sign
alias mod := modifier


### General Utilities ###

# Find the path of the first file that matches the given query.
@find +query:
    exec {{just}} find-all "$@" | \
        rg --multiline '(?-m)^.*\n$' | {{rg_colorize}}
alias fd := find

# Find all files that match the given query.
@find-all *query:
    fd {{fd_flags}} --type f --base-directory {{here}} | \
        fzf {{fzf_flags}} --exact --filter={{quote(query)}} | \
        {{rg_colorize}}
alias fda := find-all

# Find all files that match a given query interactively.
@find-all-interactive *query:
    exec {{just}} find-all "$@" | \
        fzf {{fzf_flags}} --query={{quote(query)}} | {{rg_colorize}}

# Get a regex pattern that accepts spaces, underscores, or hyphens in place of each other.
@whitespace-match pattern:
    echo {{quote(pattern)}} | sd '[ _-]' '[ _-]'
alias ws-match := whitespace-match

# Add a positive sign to non-negative numbers.
@_sign:
    sd '^([0-9])' '+$1'

# Clean intermediate files.
clean:
    rm -rf {{quote(justfile_directory() / cache_dir / '*')}}
