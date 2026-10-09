function _git_branch_name -a gitdir
    set -l head_file "$gitdir/HEAD"
    test -f "$head_file"; or return 1
    set -l head (command cat "$head_file" 2>/dev/null)
    or return 1
    if string match -rq '^ref: refs/heads/(?<b>.+)$' -- $head
        echo $b
    else if string match -rq '^ref: (?<r>.+)$' -- $head
        echo $r
    else
        # detached HEAD: short Hash
        string sub -l 8 -- $head
    end
end

function _git_head_hash -a gitdir head
    if string match -rq '^[0-9a-f]{40,64}$' -- $head
        echo $head
        return 0
    end
    string match -rq '^ref: (?<ref>.+)$' -- $head
    or return 1

    command git rev-parse HEAD 2>/dev/null
    and return 0

    set -l dirs $gitdir

    if test -f $gitdir/commondir # Worktrees
        read -l c <$gitdir/commondir
        set -a dirs $gitdir/$c
    end

    for d in $dirs
        if test -f $d/$ref
            read -l h <$d/$ref
            and echo $h
            and return 0
        end
    end

    for d in $dirs
        test -f $d/packed-refs
        or continue
        cat $d/packed-refs 2>/dev/null | string match -rq '^(?<h>[0-9a-f]{40,64}) '(string escape --style=regex -- $ref)'$'
        and echo $h
        and return 0
    end

    return 1
end

function _git_tag_name -a gitdir
    test -f $gitdir/HEAD; or return
    set -l head (command git symbolic-ref HEAD 2>/dev/null;
    or command git rev-parse HEAD 2>/dev/null)
    set -l hash (_git_head_hash $gitdir $head)
    or return
    if test "$hash" != "$__prompt_tag_key"
        set -g __prompt_tag_key $hash
        set -g __prompt_tag_val (command git describe --tags --exact-match $hash 2>/dev/null | head -n1)
    end
    echo $__prompt_tag_val
end

# Cache leeren, wenn sich Tags ändern könnten
function _prompt_tag_cache_reset --on-event fish_postexec
    if string match -qr '^git\s+(tag|fetch|pull|clone)' -- $argv
        set -e __prompt_tag_key
    end
end

function _is_git_dirty
    set -l flags --porcelain --ignore-submodules=dirty
    test "$__prompt_git_untracked" = 0; and set flags $flags -uno
    command git status $flags 2>/dev/null | head -n1 | string length -q
end

function _is_ssh_session
    # check for the classic SSH-ENV
    if set -q SSH_CONNECTION; or set -q SSH_CLIENT; or set -q SSH_TTY
        return 0
    end
    # check for tmux with SSH: if tmux run, check if the parent shell runs with SSH
    if set -q tmux
        if string match -q '*ssh*' (ps -o cmd= -p (ps -o ppid= -p (ps -o ppid= -p (status pid))))
            return 0
        end
    end
    return 1
end

function _git_state -a gitdir
    if test -f $gitdir/MERGE_HEAD
        echo "MERGE"
    else if test -f $gitdir/REBASE_HEAD
        echo "REBASE"
    else if test -f $gitdir/CHERRY_PICK_HEAD
        echo "PICK"
    end
end

function fish_prompt
    set -l last_status $status
    set -l cyan (set_color -o cyan)
    set -l yellow (set_color -o yellow)
    set -l red (set_color -o red)
    set -l blue (set_color -o blue)
    set -l green (set_color -o green)
    set -l normal (set_color normal)

    if not set -q __prompt_static_ready
        set -q USER; and set -g __prompt_user $USER; or set -g __prompt_user (whoami)
        if _is_ssh_session
            set -g __prompt_is_ssh 1
        else
            set -g __prompt_is_ssh 0
        end
        if not set -q __fish_prompt_char
            if test (id -u) = 0
                set -g __fish_prompt_char '⚡⚡ '
            else
                set -g __fish_prompt_char 'λ '
            end
        end
        set -g __prompt_static_ready 1
    end

    if test $last_status = 0
        set status_indicator "$green✓ "
        set exit_code ""
    else
        set status_indicator "$red✗ "
        set exit_code (set_color -i a52a2a) "[" $last_status "]"
    end

    set -l cwd $blue(prompt_pwd)
    set -l branch_name
    set -l git_state
    set -l tag
    set -l gitdir (command git rev-parse --git-dir 2>/dev/null)
    if test -n "$gitdir"
        set branch_name (_git_branch_name $gitdir)
        set git_state (_git_state $gitdir)
        set tag (_git_tag_name $gitdir)
    end

    if test -n "$branch_name"
        if test $branch_name = 'master'
            set -l git_branch "master"
            set git_info \n"$normal $cyan(♆ $red$git_branch$cyan)$normal"
        else if test $branch_name = 'main'
            set -l git_branch "main"
            set git_info \n"$normal $cyan(♆ $red$git_branch$cyan)$normal"
        else
            set -l git_branch $branch_name
            set git_info \n"$normal $cyan(♆ $git_branch)$normal"
        end

        if test -n "$git_state"
            set git_info "$git_info $yellow($git_state)$normal"
        end

        if test -n "$tag"
            set git_info "$git_info $yellow(tag: $tag)$normal"
        end

        if _is_git_dirty
            set -l dirty "$yellow ✗"
            set git_info "$git_info$dirty"
        end
    end

    echo -n -s $status_indicator

    if test $__prompt_is_ssh = 1
        echo $red'ssh://'$cyan$__prompt_user$green'@'$hostname $cwd $git_info $exit_code $normal ' '
    else
        echo $cyan$__prompt_user $cwd $git_info $exit_code $normal ' '
    end
    set_color ff0000
    echo -n $__fish_prompt_char
    set_color normal
end
