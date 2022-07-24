
# The default editor.
editor := env_var_or_default('VISUAL', env_var('EDITOR'))

# Search for the given query in the system.
@search file query='':
    rg '{{query}}' --no-line-number --smart-case --passthru --glob '*{{file}}*'

# Edit a file that matches the given query.
@edit file:
    file="$(fd '{{file}}' | fzf --select-1 --exit-0)" && {{editor}} "$file"

# List all files in the system.
@list:
    exa --git-ignore --tree --ignore-glob='justfile|README.*'
