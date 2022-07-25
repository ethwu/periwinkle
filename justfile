
# Set the shell to execute commands.
set shell := ['dash', '-euc']
# Initialize scripts with utilities.
script := '/bin/dash -u
onfail() { status=$? ; test $status -ne 0 && >&2 echo "$@" ; exit $status ; }'
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

# Directory to keep cached `get` results.
cache_dir := join(justfile_directory(), '.cache')

fd_flags := '--ignore-case'
rg_flags := '--smart-case'
rg_colorize := '''
    rg --colors match:none --colors match:fg:blue '^(?:\./)?(.*/)' --replace '$1'  '''
fzf_flags := '--select-1 --exit-0 --filepath-word --cycle --height=50% --layout=reverse --header-first --history=' + quote(join(cache_dir, '.fzf')) + ' --preview="exec ' + just + ' get {}"'


@_default:
    cd {{cwd}} && exec {{just}} --list

# List all files in the system.
@list:
    exa --tree --git-ignore --ignore-glob="$(cat .ignore | sd '(\w)\n(\w)' '$1|$2')"
alias ls := list

# Search interactively for the given query in the system.
@search *query:
    exec {{just}} open "$(exec {{just}} find-all-interactive "$@")"
alias s := search
alias show := search

# Query for the conents of a file. If the file has a #!, invokes it as a script.
# The script is executed with the following arguments:
# - `$PWD` The directory containing the file.
# - `$0` The name of the file.
# - `$1` The relative path of the file from the root of the project (excluding `./`).
# - `$2` The absolute path to the root of the project.
@get *query:
    exec {{just}} open "$(exec {{just}} find "$@")"

# Get the contents of a file. If the file has a #!, invokes it as a script.
open file:
    #! {{script}}
    if test -f {{quote(file)}} && IFS= read -r line < {{quote(file)}} ; then
        if [ -t 1 ] ; then echo {{quote(file)}} | >&2 {{rg_colorize}} ; fi
        dir="$(dirname {{quote(file)}})" ; name="$(basename {{quote(file)}})" ; cd "$dir"
        mkdir -p {{quote(cache_dir)}}/"$dir" ; cache={{quote(join(cache_dir, file))}}
        if [ -f "$cache" ] && [ "$(head -n 1 "$cache")" = "$(cksum "$name")" ] ; then
            sed '1d' "$cache" ; exit ; fi
        cksum "$name" > "$cache"
        { case "$line" in
            ('#!'*) perl "$name" {{quote(file)}} {{here}} ;;
            *) cat "$name" ;;
        esac ; } | tee -a "$cache"
    fi
    onfail 'Could not open `{{file}}`.'


## Editing Utilities ##

# Edit a file that matches the given query.
@edit +query:
    file="$(exec {{just}} find-all-interactive "$@")" && {{editor}} "$file"
alias ed := edit

# Copy the contents of a template to the target file.
@from-template target template='.template':
    cp {{quote(join(invocation_directory(), template))}} {{quote(target)}}

# Get the modifier of a given ability score.
@modifier score:
    echo $(( $(exec {{just}} get stats/abilities/ {{quote(score)}}) / 2 - 5 )) | \
        exec {{just}} _sign
alias mod := modifier


### General Utilities ###

# Find the path of the first file that matches the given query.
@find +query:
    exec {{just}} find-all "$@" |  rg --multiline '(?-m)^.*\n$' | {{rg_colorize}}
alias fd := find

# Find all files that match the given query.
@find-all *query:
    fd {{fd_flags}} --type f --base-directory {{here}} | \
        fzf {{fzf_flags}} --exact --filter={{quote(query)}} | \
        {{rg_colorize}}
alias fda := find-all

# Find all files that match a given query interactively.
@find-all-interactive *query:
    exec {{just}} find-all "$@" | fzf {{fzf_flags}} --query={{quote(query)}} | {{rg_colorize}}

# Add a positive sign to non-negative numbers.
@_sign:
    sd '^([^-])' '+$1'

# Clean intermediate files.
clean:
    rm -rf {{join(justfile_directory(), cache_dir, '*')}}
