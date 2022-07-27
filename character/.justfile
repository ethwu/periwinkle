
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

# Directory to keep cached `get` results.
cache_dir := here / '.cache'

fd_flags := '--ignore-case'
rg_flags := '--smart-case'
# Command to colorize paths.
colorize_path := '''
    rg --colors match:none --colors match:fg:blue '(?:^\./)?(.*/|'')*' --replace '$1' '''
fzf_flags := '--select-1 --exit-0 --filepath-word --cycle --height=50% --layout=reverse --header-first --history=' + quote(cache_dir / '.fzf') + ' --preview="exec ' + just + ' get {}"'


@_default:
    exec {{just}} show

# List all files in the system.
@list:
    exa --tree --git-ignore --ignore-glob="$(cat .ignore | sd '(\w)\n(\w)' '$1|$2')"
alias ls := list

# Show an entry in the system interactively.
@show *query:
    exec {{just}} open "$(exec {{just}} select "$@")"
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

    if [ -t 1 ] ; then echo {{quote(file)}} | >&2 {{colorize_path}} ; fi
    if IFS= read -r line < {{quote(file)}} ; then
        dir="$(dirname {{quote(file)}})" ; name="$(basename {{quote(file)}})" ; cd "$dir"
        mkdir -p {{quote(cache_dir)}}/"$dir" ; cache={{quote(cache_dir / file)}}
        if [ -f "$cache" ] && [ "$(head -n 1 "$cache")" = "$(cksum "$name")" ] &&
            ! ( sed '2q;d' "$name" | rg -q 'no[-]cache' ) ; then
            sed '1d' "$cache" ; exit ; fi
        cksum "$name" > "$cache"
        { case "$line" in
            ('#!'*) PATH="$({{just}} super path)" perl "$name" {{quote(file)}} {{quote(here)}} ;;
            *) cat "$name" ;;
        esac ; } | tee -a "$cache"
    fi


## Editing Utilities ##

# Get the project root.
@root: 
    echo {{quote(here)}}
alias home := root

# Edit a file that matches the given query.
@edit *query:
    file="$(exec {{just}} select "$@")" && {{editor}} "$file"
alias ed := edit


### General Utilities ###

# Find the path of the first file that matches the given query.
@find +query:
    exec {{just}} find-all "$@" | rg --multiline '(?-m)^.*\n$' | {{colorize_path}}
alias fd := find

# Find all files that match the given query.
@find-all *query:
    filter="$(echo {{quote(query)}} | sd '^/' './')" ; \
    fd {{fd_flags}} --type f --base-directory {{quote(here)}} | \
        fzf {{fzf_flags}} --exact --filter="$filter" | \
        {{colorize_path}}
alias fda := find-all

# Select a file that matches the given query interactively.
@select *query:
    exec {{just}} find-all "$@" | sd '^(.)' './$1' | fzf {{fzf_flags}} --query={{quote(query)}} | {{colorize_path}}
alias sel := select

# Clean intermediate files.
clean:
    rm -rf {{quote(here / cache_dir / '*')}}

# Call a recipe on the parent `justfile`.
@super *args:
    cd {{quote(call_site)}} && exec {{just}} -f {{quote(here) / '..' / 'justfile'}} "$@"
