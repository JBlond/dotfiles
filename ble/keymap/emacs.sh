# this script is a part of blesh (https://github.com/akinomyoga/ble.sh) under BSD-3-Clause license
ble/is-function ble-edit/bind/load-keymap-definition:emacs && return
function ble-edit/bind/load-keymap-definition:emacs { :; }
function ble/widget/emacs/append-arg {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  ((code==0)) && return 1
  local ret; ble/util/c2s "$code"; local ch=$ret
  if 
    if [[ $_ble_edit_arg ]]; then
      [[ $ch == [0-9] ]]
    else
      ((KEYS[0]&_ble_decode_MaskFlag))
    fi
  then
    _ble_edit_arg=$_ble_edit_arg$ch
  else
    ble/widget/self-insert
  fi
}
_ble_keymap_emacs_white_list=(
  self-insert
  batch-insert
  nop
  magic-space
  copy{,-forward,-backward}-{c,f,s,u}word
  copy-region{,-or}
  clear-screen
  command-help
  display-shell-version
  redraw-line
)
function ble/keymap:emacs/is-command-white {
  if [[ $1 == ble/widget/self-insert ]]; then
    return 0
  elif [[ $1 == ble/widget/* ]]; then
    local cmd=${1#ble/widget/}; cmd=${cmd%%[$' \t\n']*}
    [[ $cmd == emacs/* || " ${_ble_keymap_emacs_white_list[*]} " == *" $cmd "*  ]] && return 0
  fi
  return 1
}
function ble/widget/emacs/__before_widget__ {
  if ! ble/keymap:emacs/is-command-white "$WIDGET"; then
    ble-edit/undo/add
  fi
}
function ble/widget/emacs/undo {
  local arg; ble-edit/content/get-arg 1
  ble-edit/undo/undo "$arg" || ble/widget/.bell 'no more older undo history'
}
function ble/widget/emacs/redo {
  local arg; ble-edit/content/get-arg 1
  ble-edit/undo/redo "$arg" || ble/widget/.bell 'no more recent undo history'
}
function ble/widget/emacs/revert {
  local arg; ble-edit/content/clear-arg
  ble-edit/undo/revert
}
_ble_keymap_emacs_modeline=:
function ble/keymap:emacs/update-mode-name {
  local opt_multiline=; [[ $_ble_edit_str == *$'\n'* ]] && opt_multiline=1
  local mode=$opt_multiline:$_ble_edit_arg
  [[ $mode == "$_ble_keymap_emacs_modeline" ]] && return
  _ble_keymap_emacs_modeline=$mode
  local name=
  [[ $opt_multiline ]] && name=$'\e[1m-- MULTILINE --\e[m'
  if [[ $_ble_edit_arg ]]; then
    name="$name${name:+ }(arg: $_ble_edit_arg)"
  elif [[ $opt_multiline ]]; then
    name=$name$' (\e[35mRET\e[m or \e[35mC-m\e[m: insert a newline, \e[35mC-j\e[m: run)'
  fi
  ble-edit/info/default ansi "$name"
}
function ble/widget/emacs/__after_widget__ {
  ble/keymap:emacs/update-mode-name
}
function ble/widget/emacs/quoted-insert {
  _ble_edit_mark_active=
  _ble_decode_char__hook=ble/widget/emacs/quoted-insert.hook
  return 148
}
function ble/widget/emacs/quoted-insert.hook {
  ble/widget/quoted-insert.hook
  ble/keymap:emacs/update-mode-name
}
function ble/widget/emacs/bracketed-paste {
  ble/widget/bracketed-paste
  _ble_edit_bracketed_paste_proc=ble/widget/emacs/bracketed-paste.proc
  return 148
}
function ble/widget/emacs/bracketed-paste.proc {
  ble/widget/bracketed-paste.proc "$@"
  ble/keymap:emacs/update-mode-name
}
function ble-decode/keymap:emacs/define {
  local ble_bind_keymap=emacs
  local ble_bind_nometa=
  ble-decode/keymap:safe/bind-common
  ble-decode/keymap:safe/bind-history
  ble-decode/keymap:safe/bind-complete
  ble-bind -f 'C-d'      'delete-region-or forward-char-or-exit'
  ble-bind -f 'M-^'      history-expand-line
  ble-bind -f 'SP'       magic-space
  ble-bind -f __attach__        safe/__attach__
  ble-bind -f __before_widget__ emacs/__before_widget__
  ble-bind -f __after_widget__  emacs/__after_widget__
  ble-bind -f 'C-c'      discard-line
  ble-bind -f 'C-j'      accept-line
  ble-bind -f 'C-RET'    accept-line
  ble-bind -f 'C-m'      accept-single-line-or-newline
  ble-bind -f 'RET'      accept-single-line-or-newline
  ble-bind -f 'C-o'      accept-and-next
  ble-bind -f 'C-g'      bell
  ble-bind -f 'C-x C-g'  bell
  ble-bind -f 'C-M-g'    bell
  ble-bind -f 'C-l'      clear-screen
  ble-bind -f 'M-l'      redraw-line
  ble-bind -f 'f1'       command-help
  ble-bind -f 'C-x C-v'  display-shell-version
  ble-bind -c 'C-z'      fg
  ble-bind -c 'M-z'      fg
  ble-bind -f 'C-\'      bell
  ble-bind -f 'C-]'      bell
  ble-bind -f 'C-^'      bell
  ble-bind -f M-- emacs/append-arg
  ble-bind -f M-0 emacs/append-arg
  ble-bind -f M-1 emacs/append-arg
  ble-bind -f M-2 emacs/append-arg
  ble-bind -f M-3 emacs/append-arg
  ble-bind -f M-4 emacs/append-arg
  ble-bind -f M-5 emacs/append-arg
  ble-bind -f M-6 emacs/append-arg
  ble-bind -f M-7 emacs/append-arg
  ble-bind -f M-8 emacs/append-arg
  ble-bind -f M-9 emacs/append-arg
  ble-bind -f C-- emacs/append-arg
  ble-bind -f C-0 emacs/append-arg
  ble-bind -f C-1 emacs/append-arg
  ble-bind -f C-2 emacs/append-arg
  ble-bind -f C-3 emacs/append-arg
  ble-bind -f C-4 emacs/append-arg
  ble-bind -f C-5 emacs/append-arg
  ble-bind -f C-6 emacs/append-arg
  ble-bind -f C-7 emacs/append-arg
  ble-bind -f C-8 emacs/append-arg
  ble-bind -f C-9 emacs/append-arg
  ble-bind -f -   emacs/append-arg
  ble-bind -f 0   emacs/append-arg
  ble-bind -f 1   emacs/append-arg
  ble-bind -f 2   emacs/append-arg
  ble-bind -f 3   emacs/append-arg
  ble-bind -f 4   emacs/append-arg
  ble-bind -f 5   emacs/append-arg
  ble-bind -f 6   emacs/append-arg
  ble-bind -f 7   emacs/append-arg
  ble-bind -f 8   emacs/append-arg
  ble-bind -f 9   emacs/append-arg
  ble-bind -f 'C-_'       emacs/undo
  ble-bind -f 'C-DEL'     emacs/undo
  ble-bind -f 'C-BS'      emacs/undo
  ble-bind -f 'C-/'       emacs/undo
  ble-bind -f 'C-x u'     emacs/undo
  ble-bind -f 'C-x C-u'   emacs/undo
  ble-bind -f 'C-x U'     emacs/redo
  ble-bind -f 'C-x C-S-u' emacs/redo
  ble-bind -f 'M-r'       emacs/revert
  ble-bind -f 'C-q'       emacs/quoted-insert
  ble-bind -f 'C-v'       emacs/quoted-insert
  ble-bind -f paste_begin emacs/bracketed-paste
}
function ble-decode/keymap:emacs/initialize {
  local fname_keymap_cache=$_ble_base_cache/keymap.emacs
  if [[ $fname_keymap_cache -nt $_ble_base/keymap/emacs.sh &&
          $fname_keymap_cache -nt $_ble_base/lib/init-cmap.sh ]]; then
    source "$fname_keymap_cache" && return
  fi
  ble-edit/info/immediate-show text "ble.sh: updating cache/keymap.emacs..."
  ble-decode/keymap:isearch/define
  ble-decode/keymap:nsearch/define
  ble-decode/keymap:emacs/define
  {
    ble-decode/keymap/dump isearch
    ble-decode/keymap/dump nsearch
    ble-decode/keymap/dump emacs
  } >| "$fname_keymap_cache"
  ble-edit/info/immediate-show text "ble.sh: updating cache/keymap.emacs... done"
}
ble-decode/keymap:emacs/initialize
ble/util/invoke-hook _ble_keymap_default_load_hook
ble/util/invoke-hook _ble_keymap_emacs_load_hook
