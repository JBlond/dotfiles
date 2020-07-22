# this script is a part of blesh (https://github.com/akinomyoga/ble.sh) under BSD-3-Clause license
ble/is-function ble-edit/bind/load-keymap-definition:vi && return
function ble-edit/bind/load-keymap-definition:vi { :; }
source "$_ble_base/keymap/vi_digraph.sh"
bleopt/declare -n keymap_vi_macro_depth 64
function ble/keymap:vi/k2c {
  local key=$1
  local flag=$((key&_ble_decode_MaskFlag)) char=$((key&_ble_decode_MaskChar))
  if ((flag==0&&(32<=char&&char<_ble_decode_FunctionKeyBase))); then
    ret=$char
    return 0
  elif ((flag==_ble_decode_Ctrl&&63<=char&&char<128&&(char&0x1F)!=0)); then
    ((char=char==63?127:char&0x1F))
    ret=$char
    return 0
  else
    return 1
  fi
}
function ble/string#index-of-chars {
  local chars=$2 index=${3:-0}
  local text=${1:index}
  local cut=${text%%["$chars"]*}
  if ((${#cut}<${#text})); then
    ((ret=index+${#cut}))
    return 0
  else
    ret=-1
    return 1
  fi
}
function ble/string#last-index-of-chars {
  local text=$1 chars=$2 index=$3
  [[ $index ]] && text=${text::index}
  local cut=${text%["$chars"]*}
  if ((${#cut}<${#text})); then
    ((ret=${#cut}))
    return 0
  else
    ret=-1
    return 1
  fi
}
function ble-edit/content/nonbol-eolp {
  local pos=${1:-$_ble_edit_ind}
  ! ble-edit/content/bolp "$pos" && ble-edit/content/eolp "$pos"
}
function ble/keymap:vi/string#encode-rot13 {
  local text=$*
  local -a buff=() ch
  for ((i=0;i<${#text};i++)); do
    ch=${text:i:1}
    if [[ $ch == [A-Z] ]]; then
      ch=${_ble_util_string_upper_list%%"$ch"*}
      ch=${_ble_util_string_upper_list:(${#ch}+13)%26:1}
    elif [[ $ch == [a-z] ]]; then
      ch=${_ble_util_string_lower_list%%"$ch"*}
      ch=${_ble_util_string_lower_list:(${#ch}+13)%26:1}
    fi
    ble/array#push buff "$ch"
  done
  IFS= eval 'ret="${buff[*]-}"'
}
_ble_keymap_vi_REX_WORD=$'[a-zA-Z0-9_]+|[!-/:-@[-`{-~]+|[^ \t\na-zA-Z0-9!-/:-@[-`{-~]+'
function ble/widget/vi_imap/__default__ {
  local flag=$((KEYS[0]&_ble_decode_MaskFlag)) code=$((KEYS[0]&_ble_decode_MaskChar))
  if ((flag&_ble_decode_Meta)); then
    ble/keymap:vi/imap-repeat/pop
    local esc=27 # ESC
    ble-decode-key "$esc" $((KEYS[0]&~_ble_decode_Meta)) "${KEYS[@]:1}"
    return 0
  fi
  if local ret; ble/keymap:vi/k2c "${KEYS[0]}"; then
    local -a KEYS; KEYS=("$ret")
    ble/widget/self-insert
    return 0
  fi
  return 125
}
function ble/widget/vi-command/decompose-meta {
  local flag=$((KEYS[0]&_ble_decode_MaskFlag)) code=$((KEYS[0]&_ble_decode_MaskChar))
  if ((flag&_ble_decode_Meta)); then
    local esc=$((_ble_decode_Ctrl|0x5b)) # C-[ (もしくは esc=27 ESC?)
    ble-decode/keylog/pop
    old_suppress=$_ble_decode_keylog_depth
    local _ble_decode_keylog_depth=$((old_suppress-1))
    ble-decode-key "$esc" $((KEYS[0]&~_ble_decode_Meta)) "${KEYS[@]:1}"
    return 0
  fi
  return 125
}
function ble/widget/vi_omap/__default__ {
  ble/widget/vi-command/decompose-meta || ble/widget/vi-command/bell
  return 0
}
function ble/widget/vi_omap/cancel {
  ble/keymap:vi/adjust-command-mode
  return 0
}
_ble_keymap_vi_irepeat_count=
_ble_keymap_vi_irepeat=()
function ble/keymap:vi/imap-repeat/pop {
  local top_index=$((${#_ble_keymap_vi_irepeat[*]}-1))
  ((top_index>=0)) && unset -v '_ble_keymap_vi_irepeat[top_index]'
}
function ble/keymap:vi/imap-repeat/push {
  ble/array#push _ble_keymap_vi_irepeat "${KEYS[*]-}:$WIDGET"
}
function ble/keymap:vi/imap-repeat/reset {
  local count=${1-}
  _ble_keymap_vi_irepeat_count=
  _ble_keymap_vi_irepeat=()
  ((count>1)) && _ble_keymap_vi_irepeat_count=$count
}
function ble/keymap:vi/imap-repeat/process {
  if ((_ble_keymap_vi_irepeat_count>1)); then
    local repeat=$_ble_keymap_vi_irepeat_count
    local -a widgets; widgets=("${_ble_keymap_vi_irepeat[@]}")
    local i widget
    for ((i=1;i<repeat;i++)); do
      for widget in "${widgets[@]}"; do
        ble-decode/widget/call "${widget#*:}" ${widget%%:*}
      done
    done
  fi
}
function ble/keymap:vi/imap/invoke-widget {
  local WIDGET=$1
  local -a KEYS; KEYS=("${@:2}")
  ble/keymap:vi/imap-repeat/push
  builtin eval -- "$WIDGET"
}
function ble/keymap:vi/imap/invoke-widget-charwise {
  local WIDGET=$1; shift
  local -a KEYS=()
  for KEYS; do
    ble/keymap:vi/imap-repeat/push
    builtin eval -- "$WIDGET"
  done
}
_ble_keymap_vi_imap_white_list=(
  self-insert
  batch-insert
  nop
  magic-space
  delete-backward-{c,f,s,u}word
  copy{,-forward,-backward}-{c,f,s,u}word
  copy-region{,-or}
  clear-screen
  command-help
  display-shell-version
  redraw-line
)
function ble/keymap:vi/imap/is-command-white {
  if [[ $1 == ble/widget/self-insert ]]; then
    return 0
  elif [[ $1 == ble/widget/* ]]; then
    local cmd=${1#ble/widget/}; cmd=${cmd%%[$' \t\n']*}
    [[ $cmd == vi_imap/* || " ${_ble_keymap_vi_imap_white_list[*]} " == *" $cmd "*  ]] && return 0
  fi
  return 1
}
function ble/widget/vi_imap/__before_widget__ {
  if ble/keymap:vi/imap/is-command-white "$WIDGET"; then
    ble/keymap:vi/imap-repeat/push
  else
    if ((_ble_keymap_vi_mark_edit_dbeg>=0)); then
      ble/keymap:vi/mark/end-edit-area
      ble/keymap:vi/repeat/record-insert
      ble/keymap:vi/mark/start-edit-area
    fi
    ble/keymap:vi/imap-repeat/reset
  fi
}
function ble/widget/vi_imap/complete {
  ble/keymap:vi/imap-repeat/pop
  ble/keymap:vi/undo/add more
  ble/widget/complete "$@"
}
function ble/keymap:vi/complete/insert.hook {
  [[ $_ble_decode_keymap == vi_imap ||
       $_ble_decode_keymap == auto_complete ]] || return
  local original=${comp_text:insert_beg:insert_end-insert_beg}
  local q="'" Q="'\''"
  local WIDGET="ble/widget/complete-insert '${original//$q/$Q}' '${insert//$q/$Q}' '${suffix//$q/$Q}'"
  ble/keymap:vi/imap-repeat/push
  [[ $_ble_decode_keymap == vi_imap ]] &&
    ble/keymap:vi/undo/add more
}
ble/array#push _ble_complete_insert_hook ble/keymap:vi/complete/insert.hook
function ble-decode/keymap:vi_imap/bind-complete {
  ble-bind -f 'C-i'                 'vi_imap/complete'
  ble-bind -f 'TAB'                 'vi_imap/complete'
  ble-bind -f 'C-TAB'               'menu-complete'
  ble-bind -f 'auto_complete_enter' 'auto-complete-enter'
  ble-bind -f 'C-x /' 'menu-complete context=filename'
  ble-bind -f 'C-x ~' 'menu-complete context=username'
  ble-bind -f 'C-x $' 'menu-complete context=variable'
  ble-bind -f 'C-x @' 'menu-complete context=hostname'
  ble-bind -f 'C-x !' 'menu-complete context=command'
  ble-bind -f 'C-]'     'sabbrev-expand'
  ble-bind -f 'C-x C-r' 'dabbrev-expand'
  ble-bind -f 'C-x *' 'complete insert_all:context=glob'
  ble-bind -f 'C-x g' 'complete show_menu:context=glob'
}
_ble_keymap_vi_insert_overwrite=
_ble_keymap_vi_insert_leave=
_ble_keymap_vi_single_command=
_ble_keymap_vi_single_command_overwrite=
bleopt/declare -n keymap_vi_nmap_name $'\e[1m~\e[m'
bleopt/declare -v term_vi_imap ''
bleopt/declare -v term_vi_nmap ''
bleopt/declare -v term_vi_omap ''
bleopt/declare -v term_vi_xmap ''
bleopt/declare -v term_vi_smap ''
bleopt/declare -v term_vi_cmap ''
bleopt/declare -v keymap_vi_imap_cursor ''
bleopt/declare -v keymap_vi_nmap_cursor ''
bleopt/declare -v keymap_vi_omap_cursor ''
bleopt/declare -v keymap_vi_xmap_cursor ''
bleopt/declare -v keymap_vi_smap_cursor ''
bleopt/declare -v keymap_vi_cmap_cursor ''
function ble/keymap:vi/update-mode-name {
  local kmap=$_ble_decode_keymap cursor=
  if [[ $kmap == vi_imap ]]; then
    ble/util/buffer "$bleopt_term_vi_imap"
    ble/term/cursor-state/set-internal "$bleopt_keymap_vi_imap_cursor"
  elif [[ $kmap == vi_nmap ]]; then
    ble/util/buffer "$bleopt_term_vi_nmap"
    ble/term/cursor-state/set-internal "$bleopt_keymap_vi_nmap_cursor"
  elif [[ $kmap == vi_xmap ]]; then
    ble/util/buffer "$bleopt_term_vi_xmap"
    ble/term/cursor-state/set-internal "$bleopt_keymap_vi_xmap_cursor"
  elif [[ $kmap == vi_smap ]]; then
    ble/util/buffer "$bleopt_term_vi_smap"
    ble/term/cursor-state/set-internal "$bleopt_keymap_vi_smap_cursor"
  elif [[ $kmap == vi_omap ]]; then
    ble/util/buffer "$bleopt_term_vi_omap"
    ble/term/cursor-state/set-internal "$bleopt_keymap_vi_omap_cursor"
  elif [[ $kmap == vi_cmap ]]; then
    ble-edit/info/default text ''
    ble/util/buffer "$bleopt_term_vi_cmap"
    ble/term/cursor-state/set-internal "$bleopt_keymap_vi_cmap_cursor"
    return
  fi
  local show= overwrite=
  if [[ $kmap == vi_imap ]]; then
    show=1 overwrite=$_ble_edit_overwrite_mode
  elif [[ $_ble_keymap_vi_single_command && ( $kmap == vi_nmap || $kmap == vi_omap ) ]]; then
    show=1 overwrite=$_ble_keymap_vi_single_command_overwrite
  elif [[ $kmap == vi_[xs]map ]]; then
    show=x overwrite=$_ble_keymap_vi_single_command_overwrite
  fi
  local name=$bleopt_keymap_vi_nmap_name
  if [[ $show ]]; then
    if [[ $overwrite == R ]]; then
      name='REPLACE'
    elif [[ $overwrite ]]; then
      name='VREPLACE'
    else
      name='INSERT'
    fi
    if [[ $_ble_keymap_vi_single_command ]]; then
      local ret; ble/string#tolower "$name"; name="($ret)"
    fi
    if [[ $show == x ]]; then
      local mark_type=${_ble_edit_mark_active%+}
      local visual_name='VISUAL'
      [[ $kmap == vi_smap ]] && visual_name='SELECT'
      if [[ $mark_type == vi_line ]]; then
        visual_name=$visual_name' LINE'
      elif [[ $mark_type == vi_block ]]; then
        visual_name=$visual_name' BLOCK'
      fi
      if [[ $_ble_keymap_vi_single_command ]]; then
        name="$name $visual_name"
      else
        name=$visual_name
      fi
    fi
    name=$'\e[1m-- '$name$' --\e[m'
  fi
  if [[ $_ble_keymap_vi_reg_record ]]; then
    name=$name$' \e[1;31mREC @'$_ble_keymap_vi_reg_record_char$'\e[m'
  fi
  ble-edit/info/default ansi "$name" # 6ms
}
function ble/widget/vi_imap/normal-mode.impl {
  local opts=$1
  ble/keymap:vi/mark/set-local-mark 94 "$_ble_edit_ind" # `^
  ble/keymap:vi/mark/end-edit-area
  [[ :$opts: == *:InsertLeave:* ]] && eval "$_ble_keymap_vi_insert_leave"
  _ble_edit_mark_active=
  _ble_edit_overwrite_mode=
  _ble_keymap_vi_insert_leave=
  _ble_keymap_vi_single_command=
  _ble_keymap_vi_single_command_overwrite=
  ble-edit/content/bolp || ((_ble_edit_ind--))
  ble-decode/keymap/push vi_nmap
}
function ble/widget/vi_imap/normal-mode {
  ble/keymap:vi/imap-repeat/pop
  ble/keymap:vi/imap-repeat/process
  ble/keymap:vi/repeat/record-insert
  ble/widget/vi_imap/normal-mode.impl InsertLeave
  ble/keymap:vi/update-mode-name
  return 0
}
function ble/widget/vi_imap/normal-mode-without-insert-leave {
  ble/keymap:vi/imap-repeat/pop
  ble/keymap:vi/repeat/record-insert
  ble/widget/vi_imap/normal-mode.impl
  ble/keymap:vi/update-mode-name
  return 0
}
function ble/widget/vi_imap/single-command-mode {
  local single_command=1
  local single_command_overwrite=$_ble_edit_overwrite_mode
  ble-edit/content/eolp && _ble_keymap_vi_single_command=2
  ble/keymap:vi/imap-repeat/pop
  ble/widget/vi_imap/normal-mode.impl
  _ble_keymap_vi_single_command=$single_command
  _ble_keymap_vi_single_command_overwrite=$single_command_overwrite
  ble/keymap:vi/update-mode-name
  return 0
}
function ble/keymap:vi/needs-eol-fix {
  [[ $_ble_decode_keymap == vi_nmap || $_ble_decode_keymap == vi_omap ]] || return 1
  [[ $_ble_keymap_vi_single_command ]] && return 1
  local index=${1:-$_ble_edit_ind}
  ble-edit/content/nonbol-eolp "$index"
}
function ble/keymap:vi/adjust-command-mode {
  if [[ $_ble_decode_keymap == vi_[xs]map ]]; then
    ble/keymap:vi/xmap/remove-eol-extension
  fi
  local kmap_popped=
  if [[ $_ble_decode_keymap == vi_omap ]]; then
    ble-decode/keymap/pop
    kmap_popped=1
  fi
  if [[ $_ble_keymap_vi_search_activate ]]; then
    if [[ $_ble_decode_keymap != vi_[xs]map ]]; then
      _ble_edit_mark_active=$_ble_keymap_vi_search_activate
    fi
    _ble_keymap_vi_search_matched=1
    _ble_keymap_vi_search_activate=
  else
    [[ $_ble_edit_mark_active == vi_search ]] && _ble_edit_mark_active=
    ((_ble_keymap_vi_search_matched)) && _ble_keymap_vi_search_matched=
  fi
  if [[ $_ble_decode_keymap == vi_nmap && $_ble_keymap_vi_single_command ]]; then
    if ((_ble_keymap_vi_single_command==2)); then
      local index=$((_ble_edit_ind+1))
      ble-edit/content/nonbol-eolp "$index" && _ble_edit_ind=$index
    fi
    ble/widget/vi_nmap/.insert-mode 1 "$_ble_keymap_vi_single_command_overwrite" resume
    ble/keymap:vi/repeat/clear-insert
  elif [[ $kmap_popped ]]; then
    ble/keymap:vi/update-mode-name
  fi
  return 0
}
function ble/widget/vi-command/bell {
  ble/widget/.bell "$1"
  ble/keymap:vi/adjust-command-mode
  return 0
}
function ble/widget/vi_nmap/.insert-mode {
  [[ $_ble_decode_keymap == vi_[xs]map ]] && ble-decode/keymap/pop
  [[ $_ble_decode_keymap == vi_omap ]] && ble-decode/keymap/pop
  local arg=$1 overwrite=$2
  ble/keymap:vi/imap-repeat/reset "$arg"
  _ble_edit_mark_active=
  _ble_edit_overwrite_mode=$overwrite
  _ble_keymap_vi_insert_leave=
  _ble_keymap_vi_insert_overwrite=$overwrite
  _ble_keymap_vi_single_command=
  _ble_keymap_vi_single_command_overwrite=
  _ble_keymap_vi_search_matched=
  ble-decode/keymap/pop
  ble/keymap:vi/update-mode-name
  ble/keymap:vi/mark/start-edit-area
  if [[ :$opts: != *:resume:* ]]; then
    ble/keymap:vi/mark/commit-edit-area "$_ble_edit_ind" "$_ble_edit_ind"
  fi
}
function ble/widget/vi_nmap/insert-mode {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi_nmap/.insert-mode "$ARG"
  ble/keymap:vi/repeat/record
  return 0
}
function ble/widget/vi_nmap/append-mode {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  if ! ble-edit/content/eolp; then
    ((_ble_edit_ind++))
  fi
  ble/widget/vi_nmap/.insert-mode "$ARG"
  ble/keymap:vi/repeat/record
  return 0
}
function ble/widget/vi_nmap/append-mode-at-end-of-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local ret; ble-edit/content/find-logical-eol
  _ble_edit_ind=$ret
  ble/widget/vi_nmap/.insert-mode "$ARG"
  ble/keymap:vi/repeat/record
  return 0
}
function ble/widget/vi_nmap/insert-mode-at-beginning-of-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local ret; ble-edit/content/find-logical-bol
  _ble_edit_ind=$ret
  ble/widget/vi_nmap/.insert-mode "$ARG"
  ble/keymap:vi/repeat/record
  return 0
}
function ble/widget/vi_nmap/insert-mode-at-first-non-space {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/first-non-space
  [[ ${_ble_edit_str:_ble_edit_ind:1} == [$' \t'] ]] &&
    ((_ble_edit_ind++)) # 逆eol補正
  ble/widget/vi_nmap/.insert-mode "$ARG"
  ble/keymap:vi/repeat/record
  return 0
}
function ble/widget/vi_nmap/insert-mode-at-previous-point {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local ret
  ble/keymap:vi/mark/get-local-mark 94 && _ble_edit_ind=$ret
  ble/widget/vi_nmap/.insert-mode "$ARG"
  ble/keymap:vi/repeat/record
  return 0
}
function ble/widget/vi_nmap/replace-mode {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi_nmap/.insert-mode "$ARG" R
  ble/keymap:vi/repeat/record
  return 0
}
function ble/widget/vi_nmap/virtual-replace-mode {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi_nmap/.insert-mode "$ARG" 1
  ble/keymap:vi/repeat/record
  return 0
}
function ble/widget/vi-command/accept-line {
  ble/keymap:vi/clear-arg
  ble/widget/vi_nmap/.insert-mode
  ble/keymap:vi/repeat/clear-insert
  [[ $_ble_keymap_vi_reg_record ]] &&
    ble/widget/vi_nmap/record-register
  ble/widget/accept-line
}
function ble/widget/vi-command/accept-single-line-or {
  if ble-edit/is-single-complete-line; then
    ble/widget/vi-command/accept-line
  else
    ble/widget/"$@"
  fi
}
_ble_keymap_vi_oparg=
_ble_keymap_vi_opfunc=
_ble_keymap_vi_reg=
_ble_keymap_vi_register=()
_ble_keymap_vi_register_onplay=
function ble/keymap:vi/clear-arg {
  _ble_edit_arg=
  _ble_keymap_vi_oparg=
  _ble_keymap_vi_opfunc=
  _ble_keymap_vi_reg=
}
function ble/keymap:vi/get-arg {
  local default_value=$1
  REG=$_ble_keymap_vi_reg
  FLAG=$_ble_keymap_vi_opfunc
  if [[ ! $_ble_edit_arg && ! $_ble_keymap_vi_oparg ]]; then
    ARG=$default_value
  else
    ARG=$((10#${_ble_edit_arg:-1}*10#${_ble_keymap_vi_oparg:-1}))
  fi
  ble/keymap:vi/clear-arg
}
function ble/keymap:vi/register#load {
  local reg=$1
  if [[ $reg ]] && ((reg!=34)); then
    if [[ $reg == 37 ]]; then # "%
      _ble_edit_kill_type=
      _ble_edit_kill_ring=$HISTFILE
      return 0
    fi
    local value=${_ble_keymap_vi_register[reg]}
    if [[ $value == */* ]]; then
      _ble_edit_kill_type=${value%%/*}
      _ble_edit_kill_ring=${value#*/}
      return 0
    else
      _ble_edit_kill_type=
      _ble_edit_kill_ring=
      return 1
    fi
  fi
}
function ble/keymap:vi/register#set {
  local reg=$1 type=$2 content=$3
  if [[ $reg == +* ]]; then
    local value=${_ble_keymap_vi_register[reg]}
    if [[ $value == */* ]]; then
      local otype=${value%%/*}
      local oring=${value#*/}
      if [[ $otype == L ]]; then
        if [[ $type == q ]]; then
          type=L content=${oring%$'\n'}$content # V + * → V
        else
          type=L content=$oring$content # V + * → V
        fi
      elif [[ $type == L ]]; then
        type=L content=$oring$'\n'$content # C-v + V, v + V → V
      elif [[ $otype == B:* ]]; then
        if [[ $type == B:* ]]; then
          type=$otype' '${type#B:}
          content=$oring$'\n'$content # C-v + C-v → C-v
        elif [[ $type == q ]]; then
          local ret; ble/string#count-char "$content" $'\n'
          ble/string#repeat ' 0' "$ret"
          type=$otype$ret
          content=$oring$$content # C-v + q → C-v
        else
          local ret; ble/string#count-char "$content" $'\n'
          ble/string#repeat ' 0' $((ret+1))
          type=$otype$ret
          content=$oring$'\n'$content # C-v + v → C-v
        fi
      else
        type= content=$oring$content # v + C-v, v + v, v + q → v
      fi
    fi
  fi
  [[ $type == L && $content != *$'\n' ]] && content=$content$'\n'
  local suppress_default=
  [[ $type == q ]] && type= suppress_default=1
  if [[ ! $reg ]] || ((reg==34)); then # ""
    _ble_edit_kill_type=$type
    _ble_edit_kill_ring=$content
    return 0
  elif ((reg==58||reg==46||reg==37||reg==126)); then # ": ". "% "~
    ble/widget/.bell "attempted to write on a read-only register #$reg"
    return 1
  elif ((reg==95)); then # "_
    return 0
  else
    if [[ ! $suppress_default ]]; then
      _ble_edit_kill_type=$type
      _ble_edit_kill_ring=$content
    fi
    _ble_keymap_vi_register[reg]=$type/$content
    return 0
  fi
}
function ble/keymap:vi/register#set-yank {
  ble/keymap:vi/register#set "$@" || return 1
  local reg=$1 type=$2 content=$3
  if [[ $reg == '' || $reg == 34 ]]; then
    ble/keymap:vi/register#set 48 "$type" "$content" # "0
  fi
}
_ble_keymap_vi_register_49_widget_list=(
  ble/widget/vi-command/search-matchpair-or
  ble/widget/vi-command/percentage-line
  ble/widget/vi-command/goto-mark
  ble/widget/vi-command/search-forward
  ble/widget/vi-command/search-backward
  ble/widget/vi-command/search-repeat
  ble/widget/vi-command/search-reverse-repeat
)
function ble/keymap:vi/register#set-edit {
  ble/keymap:vi/register#set "$@" || return 1
  local reg=$1 type=$2 content=$3
  if [[ $reg == '' || $reg == 34 ]]; then
    local widget=${WIDGET%%[$' \t\n']*}
    if [[ $content == *$'\n'* || " $widget " == " ${_ble_keymap_vi_register_49_widget_list[*]} " ]]; then
      local n
      for ((n=9;n>=2;n--)); do
        _ble_keymap_vi_register[48+n]=${_ble_keymap_vi_register[48+n-1]}
      done
      ble/keymap:vi/register#set 49 "$type" "$content" # "1
    else
      ble/keymap:vi/register#set 45 "$type" "$content" # "-
    fi
  fi
}
function ble/keymap:vi/register#play {
  local reg=$1 value
  if [[ $reg ]] && ((reg!=34)); then
    value=${_ble_keymap_vi_register[reg]}
    if [[ $value == */* ]]; then
      value=${value#*/}
    else
      value=
    fi
  else
    value=$_ble_edit_kill_ring
  fi
  local _ble_keymap_vi_register_onplay=1
  local i len=${#value} ret
  local -a chars=()
  for ((i=0;i<len;i++)); do
    ble/util/s2c "$value" "$i"
    ((ret==27)) && ret=$_ble_decode_IsolatedESC
    ble/array#push chars "$ret"
  done
  ble-decode-char "${chars[@]}"
}
function ble/keymap:vi/register#dump/escape {
  local text=$1
  local out= i=0 iN=${#text}
  while ((i<iN)); do
    local tail=${text:i}
    if ble/util/isprint+ "$tail"; then
      out=$out$BASH_REMATCH
      ((i+=${#BASH_REMATCH}))
    else
      ble/util/s2c "$tail"
      local code=$ret
      if ((code<32)); then
        ble/util/c2s $((code+64))
        out=$out$_ble_term_rev^$ret$_ble_term_sgr0
      elif ((code==127)); then
        out=$out$_ble_term_rev^?$_ble_term_sgr0
      elif ((128<=code&&code<160)); then
        ble/util/c2s $((code-64))
        out=$out${_ble_term_rev}M-^$ret$_ble_term_sgr0
      else
        out=$out${tail::1}
      fi
      ((i++))
    fi
  done
  ret=$out
}
function ble/keymap:vi/register#dump {
  local k ret out=
  local value type content
  for k in 34 "${!_ble_keymap_vi_register[@]}"; do
    if ((k==34)); then
      type=$_ble_edit_kill_type
      content=$_ble_edit_kill_ring
    else
      value=${_ble_keymap_vi_register[k]}
      type=${value%%/*} content=${value#*/}
    fi
    ble/util/c2s "$k"; k=$ret
    case $type in
    (L)   type=line ;;
    (B:*) type=block ;;
    (*)   type=char ;;
    esac
    ble/keymap:vi/register#dump/escape "$content"; content=$ret
    out=$out'"'$k' ('$type') '$content$'\n'
  done
  ble-edit/info/show ansi "$out"
  return 0
}
function ble/widget/vi-command:reg { ble/keymap:vi/register#dump; }
function ble/widget/vi-command:regi { ble/keymap:vi/register#dump; }
function ble/widget/vi-command:regis { ble/keymap:vi/register#dump; }
function ble/widget/vi-command:regist { ble/keymap:vi/register#dump; }
function ble/widget/vi-command:registe { ble/keymap:vi/register#dump; }
function ble/widget/vi-command:register { ble/keymap:vi/register#dump; }
function ble/widget/vi-command:registers { ble/keymap:vi/register#dump; }
function ble/widget/vi-command/append-arg {
  local ret ch=$1
  if [[ ! $ch ]]; then
    local code=$((KEYS[0]&_ble_decode_MaskChar))
    ((code==0)) && return 1
    ble/util/c2s "$code"; ch=$ret
  fi
  ble/util/assert '[[ ! ${ch//[0-9]} ]]'
  if [[ $ch == 0 && ! $_ble_edit_arg ]]; then
    ble/widget/vi-command/beginning-of-line
    return
  fi
  _ble_edit_arg="$_ble_edit_arg$ch"
  return 0
}
function ble/widget/vi-command/register {
  _ble_decode_key__hook="ble/widget/vi-command/register.hook"
}
function ble/widget/vi-command/register.hook {
  local key=$1
  ble/keymap:vi/clear-arg
  local ret
  if ble/keymap:vi/k2c "$key" && local c=$ret; then
    if ((65<=c&&c<91)); then # A-Z
      _ble_keymap_vi_reg=+$((c+32))
      return 0
    elif ((97<=c&&c<123||48<=c&&c<58||c==45||c==58||c==46||c==37||c==35||c==61||c==42||c==43||c==126||c==95||c==47)); then # a-z 0-9 - : . % # = * + ~ _ /
      _ble_keymap_vi_reg=$c
      return 0
    elif ((c==34)); then # ""
      _ble_keymap_vi_reg=$c
      return 0
    fi
  fi
  ble/widget/vi-command/bell
  return 1
}
_ble_keymap_vi_reg_record=
_ble_keymap_vi_reg_record_char=
_ble_keymap_vi_reg_record_play=0
function ble/widget/vi_nmap/record-register {
  if [[ $_ble_keymap_vi_register_onplay ]]; then
    ble/keymap:vi/clear-arg
    ble/keymap:vi/adjust-command-mode
    return 0
  fi
  if [[ $_ble_keymap_vi_reg_record ]]; then
    ble/keymap:vi/clear-arg
    local -a ret
    ble-decode/keylog/pop
    ble-decode/keylog/end; local -a keys; keys=("${ret[@]}")
    ble/util/c2s 155; local csi=$ret
    local key
    local -a buff=()
    for key in "${keys[@]}"; do
      if ble-decode-key/ischar "$key"; then
        ble/util/c2s "$key"
        if ((${#ret}==1)); then
          ble/array#push buff "$ret"
          continue
        fi
      fi
      local c=$((key&_ble_decode_MaskChar))
      if (((key&_ble_decode_MaskFlag)==_ble_decode_Ctrl&&(c==64||91<=c&&c<=95||97<=c&&c<=122))); then
        if ((c!=64)); then
          ble/util/c2s $((c&0x1F))
          ble/array#push buff "$ret"
          continue
        fi
      fi
      local mod=1
      (((key&_ble_decode_Shft)&&(mod+=0x01),
        (key&_ble_decode_Altr)&&(mod+=0x02),
        (key&_ble_decode_Ctrl)&&(mod+=0x04),
        (key&_ble_decode_Supr)&&(mod+=0x08),
        (key&_ble_decode_Hypr)&&(mod+=0x10),
        (key&_ble_decode_Meta)&&(mod+=0x20)))
      ble/array#push buff "${csi}27;$mod;$c~"
    done
    IFS= eval 'local value="${buff[*]-}"'
    ble/keymap:vi/register#set "$_ble_keymap_vi_reg_record" q "$value"
    _ble_keymap_vi_reg_record=
    ble/keymap:vi/update-mode-name
  else
    _ble_decode_key__hook="ble/widget/vi_nmap/record-register.hook"
  fi
}
function ble/widget/vi_nmap/record-register.hook {
  local key=$1
  ble/keymap:vi/clear-arg
  local ret
  if ble/keymap:vi/k2c "$key" && local c=$ret; then
    local reg=
    if ((65<=c&&c<91)); then # q{A-Z}
      reg=+$((c+32))
    elif ((48<=c&&c<58||97<=c&&c<123)); then # q{0-9a-z}
      reg=$c
    elif ((c==34)); then # q"
      reg=$c
    fi
    if [[ $reg ]]; then
      ble/util/c2s "$c"
      _ble_keymap_vi_reg_record=$reg
      _ble_keymap_vi_reg_record_char=$ret
      ble-decode/keylog/start
      ble/keymap:vi/update-mode-name
      return 0
    fi
  fi
  ble/widget/vi-command/bell "invalid register key=$key"
  return 1
}
function ble/widget/vi_nmap/play-register {
  _ble_decode_key__hook="ble/widget/vi_nmap/play-register.hook"
}
function ble/widget/vi_nmap/play-register.hook {
  ble/keymap:vi/clear-arg
  local depth=$_ble_keymap_vi_reg_record_play
  if ((depth>=bleopt_keymap_vi_macro_depth)) || ble/util/is-stdin-ready; then
    return 1 # 無限ループを防ぐため
  fi
  local _ble_keymap_vi_reg_record_play=$((depth+1))
  local key=$1
  local ret
  if ble/keymap:vi/k2c "$key" && local c=$ret; then
    ((65<=c&&c<91)) && ((c+=32)) # A-Z -> a-z
    if ((48<=c&&c<58||97<=c&&c<123)); then # 0-9a-z
      ble/keymap:vi/register#play "$c" && return
    fi
  fi
  ble/widget/vi-command/bell
  return 1
}
function ble/widget/vi-command/operator {
  local ret opname=$1
  if [[ $_ble_decode_keymap == vi_[xs]map ]]; then
    local ARG FLAG REG; ble/keymap:vi/get-arg ''
    local a=$_ble_edit_ind b=$_ble_edit_mark
    ((a<=b||(a=_ble_edit_mark,b=_ble_edit_ind)))
    ble/widget/vi_xmap/.save-visual-state
    local ble_keymap_vi_mark_active=$_ble_edit_mark_active # used in call-operator-blockwise
    local mark_type=${_ble_edit_mark_active%+}
    ble/widget/vi_xmap/exit
    local ble_keymap_vi_opmode=$mark_type
    if [[ $mark_type == vi_line ]]; then
      ble/keymap:vi/call-operator-linewise "$opname" "$a" "$b" "$ARG" "$REG"
    elif [[ $mark_type == vi_block ]]; then
      ble/keymap:vi/call-operator-blockwise "$opname" "$a" "$b" "$ARG" "$REG"
    else
      local end=$b
      ((end<${#_ble_edit_str}&&end++))
      ble/keymap:vi/call-operator-charwise "$opname" "$a" "$end" "$ARG" "$REG"
    fi; local ext=$?
    ((ext==148)) && return 148
    ((ext)) && ble/widget/.bell
    ble/keymap:vi/adjust-command-mode
    return "$ext"
  elif [[ $_ble_decode_keymap == vi_nmap ]]; then
    ble-decode/keymap/push vi_omap
    _ble_keymap_vi_oparg=$_ble_edit_arg
    _ble_keymap_vi_opfunc=$opname
    _ble_edit_arg=
    ble/keymap:vi/update-mode-name
  elif [[ $_ble_decode_keymap == vi_omap ]]; then
    local opname1=${_ble_keymap_vi_opfunc%%:*}
    if [[ $opname == "$opname1" ]]; then
      ble/widget/vi_nmap/linewise-operator "$_ble_keymap_vi_opfunc"
    else
      ble/keymap:vi/clear-arg
      ble/widget/vi-command/bell
      return 1
    fi
  fi
  return 0
}
function ble/widget/vi_nmap/linewise-operator {
  local opname=${1%%:*} opflags=${1#*:}
  local ARG FLAG REG; ble/keymap:vi/get-arg 1 # _ble_edit_arg is consumed here
  if ((ARG==1)) || [[ ${_ble_edit_str:_ble_edit_ind} == *$'\n'* ]]; then
    if [[ :$opflags: == *:vi_char:* || :$opflags: == *:vi_block:* ]]; then
      local beg=$_ble_edit_ind
      local ret; ble-edit/content/find-logical-bol "$beg" $((ARG-1)); local end=$ret
      ((beg<=end)) || local beg=$end end=$beg
      if [[ :$opflags: == *:vi_block:* ]]; then
        ble/keymap:vi/call-operator-blockwise "$opname" "$beg" "$end" '' "$REG"
      else
        ble/keymap:vi/call-operator-charwise "$opname" "$beg" "$end" '' "$REG"
      fi
    else
      ble/keymap:vi/call-operator-linewise "$opname" "$_ble_edit_ind" "$_ble_edit_ind:$((ARG-1))" '' "$REG"; local ext=$?
    fi
    if ((ext==0)); then
      ble/keymap:vi/adjust-command-mode
      return 0
    elif ((ext==148)); then
      return 148
    fi
  fi
  ble/widget/vi-command/bell
  return 1
}
function ble/widget/vi_nmap/copy-current-line {
  ble/widget/vi_nmap/linewise-operator y
}
function ble/widget/vi_nmap/kill-current-line {
  ble/widget/vi_nmap/linewise-operator d
}
function ble/widget/vi_nmap/kill-current-line-and-insert {
  ble/widget/vi_nmap/linewise-operator c
}
function ble/widget/vi-command/beginning-of-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local ret; ble-edit/content/find-logical-bol; local beg=$ret
  ble/widget/vi-command/exclusive-goto.impl "$beg" "$FLAG" "$REG" nobell
}
function ble/keymap:vi/call-operator {
  ble/keymap:vi/mark/start-edit-area
  local _ble_keymap_vi_mark_suppress_edit=1
  ble/keymap:vi/operator:"$@"; local ext=$?
  ble/util/unlocal _ble_keymap_vi_mark_suppress_edit
  ble/keymap:vi/mark/end-edit-area
  if ((ext==0)); then
    if ble/is-function ble/keymap:vi/operator:"$1".record; then
      ble/keymap:vi/operator:"$1".record
    else
      ble/keymap:vi/repeat/record
    fi
  fi
  return "$ext"
}
function ble/keymap:vi/call-operator-charwise {
  local ch=$1 beg=$2 end=$3 arg=$4 reg=$5
  ((beg<=end||(beg=$3,end=$2)))
  if ble/is-function ble/keymap:vi/operator:"$ch"; then
    local ble_keymap_vi_operator_index=
    ble/keymap:vi/call-operator "$ch" "$beg" "$end" char "$arg" "$reg"; local ext=$?
    ((ext==148)) && return 148
    local index=${ble_keymap_vi_operator_index:-$beg}
    ble/keymap:vi/needs-eol-fix "$index" && ((index--))
    _ble_edit_ind=$index
    return 0
  else
    return 1
  fi
}
function ble/keymap:vi/call-operator-linewise {
  local ch=$1 a=$2 b=$3 arg=$4 reg=$5 ia=0 ib=0
  [[ $a == *:* ]] && local a=${a%%:*} ia=${a#*:}
  [[ $b == *:* ]] && local b=${b%%:*} ib=${b#*:}
  local ret
  ble-edit/content/find-logical-bol "$a" "$ia"; local beg=$ret
  ble-edit/content/find-logical-eol "$b" "$ib"; local end=$ret
  if ble/is-function ble/keymap:vi/operator:"$ch"; then
    local ble_keymap_vi_operator_index=
    ((end<${#_ble_edit_str}&&end++))
    ble/keymap:vi/call-operator "$ch" "$beg" "$end" line "$arg" "$reg"; local ext=$?
    ((ext==148)) && return 148
    if [[ $ble_keymap_vi_operator_index ]]; then
      local index=$ble_keymap_vi_operator_index
    else
      ble-edit/content/find-logical-bol "$beg"; beg=$ret # operator 中で beg が変更されているかも
      ble-edit/content/find-non-space "$beg"; local index=$ret
    fi
    ble/keymap:vi/needs-eol-fix "$index" && ((index--))
    _ble_edit_ind=$index
    return 0
  else
    return 1
  fi
}
function ble/keymap:vi/call-operator-blockwise {
  local ch=$1 beg=$2 end=$3 arg=$4 reg=$5
  if ble/is-function ble/keymap:vi/operator:"$ch"; then
    local mark_active=${ble_keymap_vi_mark_active:-vi_block}
    local sub_ranges sub_x1 sub_x2
    _ble_edit_mark_active=$mark_active ble/keymap:vi/extract-block "$beg" "$end"
    local nrange=${#sub_ranges[@]}
    ((nrange)) || return 1
    local ble_keymap_vi_operator_index=
    local beg=${sub_ranges[0]}; beg=${beg%%:*}
    local end=${sub_ranges[nrange-1]}; end=${end#*:}; end=${end%%:*}
    ble/keymap:vi/call-operator "$ch" "$beg" "$end" block "$arg" "$reg"
    ((ext==148)) && return 148
    local index=${ble_keymap_vi_operator_index:-$beg}
    ble/keymap:vi/needs-eol-fix "$index" && ((index--))
    _ble_edit_ind=$index
    return 0
  else
    return 1
  fi
}
function ble/keymap:vi/operator:d {
  local context=$3 arg=$4 reg=$5 # beg end は上書きする
  if [[ $context == line ]]; then
    ble/keymap:vi/register#set-edit "$reg" L "${_ble_edit_str:beg:end-beg}" || return 1
    if ((end==${#_ble_edit_str}&&beg>0)); then
      local ret
      ((beg--))
      ble-edit/content/find-logical-bol "$beg"
      ble-edit/content/find-non-space "$ret"
      ble_keymap_vi_operator_index=$ret
    fi
    ble/widget/.delete-range "$beg" "$end"
  elif [[ $context == block ]]; then
    local -a afill=() atext=() arep=()
    local sub shift=0 slpad0=
    local smin smax slpad srpad sfill stext
    for sub in "${sub_ranges[@]}"; do
      stext=${sub#*:*:*:*:*:}
      ble/string#split sub : "$sub"
      smin=${sub[0]} smax=${sub[1]}
      slpad=${sub[2]} srpad=${sub[3]}
      sfill=${sub[4]}
      [[ $slpad0 ]] || slpad0=$slpad # 最初の slpad
      ble/array#push afill "$sfill"
      ble/array#push atext "$stext"
      local ret; ble/string#repeat ' ' $((slpad+srpad))
      ble/array#push arep $((smin+shift)):$((smax+shift)):"$ret"
      ((shift+=(slpad+srpad)-(smax-smin)))
    done
    IFS=$'\n' eval 'local yank_content="${atext[*]-}"'
    local yank_type=B:"${afill[*]-}"
    ble/keymap:vi/register#set-edit "$reg" "$yank_type" "$yank_content" || return 1
    local rep
    for rep in "${arep[@]}"; do
      smin=${rep%%:*}; rep=${rep:${#smin}+1}
      smax=${rep%%:*}; rep=${rep:${#smax}+1}
      ble/widget/.replace-range "$smin" "$smax" "$rep" 1
    done
    ((beg+=slpad)) # fix start position
  else
    if ((beg<end)); then
      if [[ $ble_keymap_vi_opmode != vi_char && ${_ble_edit_str:beg:end-beg} == *$'\n'* ]]; then
        if local rex=$'(^|\n)([ \t]*)$'; [[ ${_ble_edit_str::beg} =~ $rex ]]; then
          local prefix=${BASH_REMATCH[2]}
          if rex=$'^[ \t]*(\n|$)'; [[ ${_ble_edit_str:end} =~ $rex ]]; then
            local suffix=$BASH_REMATCH
            ((beg-=${#prefix},end+=${#suffix}))
            ble/keymap:vi/operator:d "$beg" "$end" line "$arg" "$reg"
            return
          fi
        fi
      fi
      ble/keymap:vi/register#set-edit "$reg" '' "${_ble_edit_str:beg:end-beg}" || return 1
      ble/widget/.delete-range "$beg" "$end" 0
    fi
  fi
  return 0
}
function ble/keymap:vi/operator:c {
  local context=$3 arg=$4 reg=$5 # beg は上書き対象
  if [[ $context == line ]]; then
    ble/keymap:vi/register#set-edit "$reg" L "${_ble_edit_str:beg:end-beg}" || return 1
    local end2=$end
    ((end2)) && [[ ${_ble_edit_str:end2-1:1} == $'\n' ]] && ((end2--))
    local indent= ret
    ble-edit/content/find-non-space "$beg"; local nol=$ret
    ((beg<nol)) && indent=${_ble_edit_str:beg:nol-beg}
    ble/widget/.replace-range "$beg" "$end2" "$indent" 1
    ble/widget/vi_nmap/.insert-mode
  elif [[ $context == block ]]; then
    ble/keymap:vi/operator:d "$@" || return 1 # @var beg will be overwritten here
    local sub=${sub_ranges[0]}
    local smin=${sub%%:*} sub=${sub#*:}
    local smax=${sub%%:*} sub=${sub#*:}
    local slpad=${sub%%:*} sub=${sub#*:}
    ((smin+=slpad,smax=smin,slpad=0))
    sub_ranges[0]=$smin:$smax:$slpad:$sub
    ble/widget/vi_xmap/block-insert-mode.impl insert
  else
    local ble_keymap_vi_opmode=vi_char
    ble/keymap:vi/operator:d "$@" || return 1
    ble/widget/vi_nmap/.insert-mode
  fi
  return 0
}
function ble/keymap:vi/operator:y.record { :; }
function ble/keymap:vi/operator:y {
  local beg=$1 end=$2 context=$3 arg=$4 reg=$5
  local yank_type= yank_content=
  if [[ $context == line ]]; then
    ble_keymap_vi_operator_index=$_ble_edit_ind # operator:y では現在位置を動かさない
    yank_type=L
    yank_content=${_ble_edit_str:beg:end-beg}
  elif [[ $context == block ]]; then
    local sub
    local -a afill=() atext=()
    for sub in "${sub_ranges[@]}"; do
      local sub4=${sub#*:*:*:*:}
      local sfill=${sub4%%:*} stext=${sub4#*:}
      ble/array#push afill "$sfill"
      ble/array#push atext "$stext"
    done
    IFS=$'\n' eval 'local yank_content="${atext[*]-}"'
    yank_type=B:"${afill[*]-}"
  else
    yank_type=
    yank_content=${_ble_edit_str:beg:end-beg}
  fi
  if [[ $keymap_vi_operator_d ]]; then
    ble/keymap:vi/register#set-edit "$reg" "$yank_type" "$yank_content" || return 1
  else
    ble/keymap:vi/register#set-yank "$reg" "$yank_type" "$yank_content" || return 1
  fi
  ble/keymap:vi/mark/commit-edit-area "$beg" "$end"
  return 0
}
function ble/keymap:vi/operator:tr.impl {
  local beg=$1 end=$2 context=$3 filter=$4
  if [[ $context == block ]]; then
    local isub=${#sub_ranges[@]}
    while ((isub--)); do
      ble/string#split sub : "${sub_ranges[isub]}"
      local smin=${sub[0]} smax=${sub[1]}
      local ret; "$filter" "${_ble_edit_str:smin:smax-smin}"
      ble/widget/.replace-range "$smin" "$smax" "$ret" 1
    done
  else
    local ret; "$filter" "${_ble_edit_str:beg:end-beg}"
    ble/widget/.replace-range "$beg" "$end" "$ret" 1
  fi
  return 0
}
function ble/keymap:vi/operator:u {
  ble/keymap:vi/operator:tr.impl "$1" "$2" "$3" ble/string#tolower
}
function ble/keymap:vi/operator:U {
  ble/keymap:vi/operator:tr.impl "$1" "$2" "$3" ble/string#toupper
}
function ble/keymap:vi/operator:toggle_case {
  ble/keymap:vi/operator:tr.impl "$1" "$2" "$3" ble/string#toggle-case
}
function ble/keymap:vi/operator:rot13 {
  ble/keymap:vi/operator:tr.impl "$1" "$2" "$3" ble/keymap:vi/string#encode-rot13
}
function ble/keymap:vi/expand-range-for-linewise-operator {
  local ret
  ble-edit/content/find-logical-bol "$beg"; beg=$ret
  ble-edit/content/find-logical-bol "$end"; local bol2=$ret
  ble-edit/content/find-non-space "$bol2"; local nol2=$ret
  if ((beg<bol2&&_ble_edit_ind<=bol2&&end<=nol2)); then
    end=$bol2
  else
    ble-edit/content/find-logical-eol "$end"; local end=$ret
    [[ ${_ble_edit_str:end:1} == $'\n' ]] && ((end++))
  fi
}
function ble/keymap:vi/string#increase-indent {
  local text=$1 delta=$2
  local space=$' \t' it=${bleopt_tab_width:-$_ble_term_it}
  local arr; ble/string#split-lines arr "$text"
  local -a arr2=()
  local line indent i len x r
  for line in "${arr[@]}"; do
    indent=${line%%[!$space]*}
    line=${line:${#indent}}
    ((x=0))
    if [[ $indent ]]; then
      ((len=${#indent}))
      for ((i=0;i<len;i++)); do
        if [[ ${indent:i:1} == ' ' ]]; then
          ((x++))
        else
          ((x=(x+it)/it*it))
        fi
      done
    fi
    ((x+=delta,x<0&&(x=0)))
    indent=
    if ((x)); then
      if ((bleopt_indent_tabs&&(r=x/it))); then
        ble/string#repeat $'\t' "$r"
        indent=$ret
        ((x%=it))
      fi
      if ((x)); then
        ble/string#repeat ' ' "$x"
        indent=$indent$ret
      fi
    fi
    ble/array#push arr2 "$indent$line"
  done
  IFS=$'\n' eval 'ret="${arr2[*]-}"'
}
function ble/keymap:vi/operator:indent.impl/increase-block-indent {
  local width=$1
  local isub=${#sub_ranges[@]}
  local sub smin slpad ret
  while ((isub--)); do
    ble/string#split sub : "${sub_ranges[isub]}"
    smin=${sub[0]} slpad=${sub[2]}
    ble/string#repeat ' ' $((slpad+width))
    ble/widget/.replace-range "$smin" "$smin" "$ret" 1
  done
}
function ble/keymap:vi/operator:indent.impl/decrease-graphical-block-indent {
  local width=$1
  local it=${bleopt_tab_width:-$_ble_term_it} cols=$_ble_textmap_cols
  local sub smin slpad ret
  local -a replaces=()
  local isub=${#sub_ranges[@]}
  while ((isub--)); do
    ble/string#split sub : "${sub_ranges[isub]}"
    smin=${sub[0]} slpad=${sub[2]}
    ble-edit/content/find-non-space "$smin"; local nsp=$ret
    ((smin<nsp)) || continue
    local ax ay bx by
    ble/textmap#getxy.out --prefix=a "$smin"
    ble/textmap#getxy.out --prefix=b "$nsp"
    local w=$(((bx-ax)-(by-ay)*cols-width))
    ((w<slpad)) && w=$slpad
    local ins=
    if ((w)); then
      local r
      if ((bleopt_indent_tabs&&(r=(ax+w)/it-ax/it))); then
        ble/string#repeat $'\t' "$r"; ins=$ret
        ((w=(ax+w)%it))
      fi
      if ((w)); then
        ble/string#repeat ' ' "$w"
        ins=$ins$ret
      fi
    fi
    ble/array#push replaces "$smin:$nsp:$ins"
  done
  local rep
  for rep in "${replaces[@]}"; do
    ble/string#split rep : "$rep"
    ble/widget/.replace-range "${rep[@]::3}" 1
  done
}
function ble/keymap:vi/operator:indent.impl/decrease-logical-block-indent {
  local width=$1
  local it=${bleopt_tab_width:-$_ble_term_it}
  local sub smin ret nsp
  local isub=${#sub_ranges[@]}
  while ((isub--)); do
    ble/string#split sub : "${sub_ranges[isub]}"
    smin=${sub[0]}
    ble-edit/content/find-non-space "$smin"; nsp=$ret
    ((smin<nsp)) || continue
    local stext=${_ble_edit_str:smin:nsp-smin}
    local i=0 n=${#stext} c=0 pad=0
    for ((i=0;i<n;i++)); do
      if [[ ${stext:i:1} == $'\t' ]]; then
        ((c+=it))
      else
        ((c++))
      fi
      if ((c>=width)); then
        pad=$((c-width))
        nsp=$((smin+i+1))
        break
      fi
    done
    local padding=
    ((pad)) && { ble/string#repeat ' ' "$pad"; padding=$ret; }
    ble/widget/.replace-range "$smin" "$nsp" "$padding" 1
  done
}
function ble/keymap:vi/operator:indent.impl {
  local delta=$1 context=$2
  ((delta)) || return 0
  if [[ $context == block ]]; then
    if ((delta>=0)); then
      ble/keymap:vi/operator:indent.impl/increase-block-indent "$delta"
    elif ble/edit/use-textmap; then
      ble/keymap:vi/operator:indent.impl/decrease-graphical-block-indent $((-delta))
    else
      ble/keymap:vi/operator:indent.impl/decrease-logical-block-indent $((-delta))
    fi
  else
    [[ $context == char ]] && ble/keymap:vi/expand-range-for-linewise-operator
    ((beg<end)) && [[ ${_ble_edit_str:end-1:1} == $'\n' ]] && ((end--))
    local ret
    ble/keymap:vi/string#increase-indent "${_ble_edit_str:beg:end-beg}" "$delta"; local content=$ret
    ble/widget/.replace-range "$beg" "$end" "$content" 1
    if [[ $context == char ]]; then
      ble-edit/content/find-non-space "$beg"
      ble_keymap_vi_operator_index=$ret
    fi
  fi
  return 0
}
function ble/keymap:vi/operator:indent-left {
  local context=$3 arg=${4:-1}
  ble/keymap:vi/operator:indent.impl $((-bleopt_indent_offset*arg)) "$context"
}
function ble/keymap:vi/operator:indent-right {
  local context=$3 arg=${4:-1}
  ble/keymap:vi/operator:indent.impl $((bleopt_indent_offset*arg)) "$context"
}
function ble/keymap:vi/string#measure-width {
  local text=$1 iN=${#1} i=0 s=0
  while ((i<iN)); do
    if ble/util/isprint+ "${text:i}"; then
      ((s+=${#BASH_REMATCH},
        i+=${#BASH_REMATCH}))
    else
      ble/util/s2c "$text" "$i"
      ble/util/c2w-edit "$ret"
      ((s+=ret,i++))
    fi
  done
  ret=$s
}
function ble/keymap:vi/string#fold/.get-interval {
  local text=$1 x=$2
  local it=${bleopt_tab_width:-${_ble_term_it:-8}}
  local i=0 iN=${#text}
  for ((i=0;i<iN;i++)); do
    if [[ ${text:i:1} == $'\t' ]]; then
      ((x=(x/it+1)*it))
    else
      ((x++))
    fi
  done
  ret=$((x-$2))
}
function ble/keymap:vi/string#fold {
  local text=$1
  local cols=${2:-${COLUMNS-80}}
  local sp=$' \t' nl=$'\n'
  local i=0 out= otmp= x=0 xtmp=0
  local isfirst=1 indent= xindent=0
  local rex='^([^'$nl$sp']+)|^(['$sp']+)|^.'
  while [[ ${text:i} =~ $rex ]]; do
    ((i+=${#BASH_REMATCH}))
    if [[ ${BASH_REMATCH[1]} ]]; then
      local word=${BASH_REMATCH[1]}
      ble/keymap:vi/string#measure-width "$word"
      if ((xtmp+ret<cols||xtmp<=xindent)); then
        out=$out$otmp$word
        ((x=xtmp+=ret))
      else
        out=$out$'\n'$indent$word
        ((x=xtmp=xindent+ret))
      fi
      otmp=
    else
      local w=1
      if [[ ${BASH_REMATCH[2]} ]]; then
        [[ $otmp ]] && continue # 改行直後の空白は無視
        otmp=${BASH_REMATCH[2]}
        ble/keymap:vi/string#fold/.get-interval "$otmp" "$x"; w=$ret
        [[ $isfirst ]] && indent=$otmp xindent=$ret # インデント記録
      else
        otmp=' ' w=1
      fi
      if ((x+w<cols)); then
        ((xtmp=x+w))
      else
        ((xtmp=xindent))
        otmp=$'\n'$indent
      fi
    fi
    isfirst=
  done
  ret=$out
}
function ble/keymap:vi/operator:fold/.fold-paragraphwise {
  local text=$1
  local cols=${2:-${COLUMNS:-80}}
  local nl=$'\n' sp=$' \t'
  local rex_paragraph='^((['$sp']*'$nl')*)(['$sp']*[^'$sp$nl'][^'$nl']*('$nl'|$))+'
  local i=0 out=
  while [[ ${text:i} =~ $rex_paragraph ]]; do
    ((i+=${#BASH_REMATCH}))
    local rematch1=${BASH_REMATCH[1]}
    local len1=${#rematch1}
    local paragraph=${BASH_REMATCH:len1}
    ble/keymap:vi/string#fold "$paragraph" "$cols"
    paragraph=${ret%$'\n'}$'\n'
    out=$out$rematch1$paragraph
  done
  ret=$out${text:i}
}
function ble/keymap:vi/operator:fold.impl {
  local context=$1 opts=$2
  local ret
  [[ $context != line ]] && ble/keymap:vi/expand-range-for-linewise-operator
  local old=${_ble_edit_str:beg:end-beg} oind=$_ble_edit_ind
  local cols=${COLUMNS:-80}; ((cols>80&&(cols=80)))
  ble/keymap:vi/operator:fold/.fold-paragraphwise "$old" "$cols"; local new=$ret
  ble/widget/.replace-range "$beg" "$end" "$new" 1
  if [[ :$opts: == *:preserve_point:* ]]; then
    if ((end<=oind)); then
      ble_keymap_vi_operator_index=$((beg+${#new}))
    elif ((beg<oind)); then
      ble/keymap:vi/operator:fold/.fold-paragraphwise "${old::oind-beg}" "$cols"
      ble_keymap_vi_operator_index=$((beg+${#ret}))
    fi
  else
    if [[ $new ]]; then
      ble-edit/content/find-logical-bol $((beg+${#new}-1))
      ble-edit/content/find-non-space "$ret"
      ble_keymap_vi_operator_index=$ret
    fi
  fi
  return 0
}
function ble/keymap:vi/operator:fold {
  local context=$3
  ble/keymap:vi/operator:fold.impl "$context"
}
function ble/keymap:vi/operator:fold-preserve-point {
  local context=$3
  ble/keymap:vi/operator:fold.impl "$context" preserve_point
}
_ble_keymap_vi_filter_args=()
_ble_keymap_vi_filter_repeat=()
_ble_keymap_vi_filter_history=()
_ble_keymap_vi_filter_history_edit=()
_ble_keymap_vi_filter_history_dirt=()
_ble_keymap_vi_filter_history_ind=0
_ble_keymap_vi_filter_history_onleave=()
function ble/highlight/layer:region/mark:vi_filter/get-face {
  face=region_target
}
function ble/keymap:vi/operator:filter/.cache-repeat {
  local -a _ble_keymap_vi_repeat _ble_keymap_vi_repeat_irepeat
  ble/keymap:vi/repeat/record-normal
  _ble_keymap_vi_filter_repeat=("${_ble_keymap_vi_repeat[@]}")
}
function ble/keymap:vi/operator:filter/.record-repeat {
  ble/keymap:vi/repeat/record-special && return
  local command=$1
  _ble_keymap_vi_repeat=("${_ble_keymap_vi_filter_repeat[@]}")
  _ble_keymap_vi_repeat_irepeat=()
  _ble_keymap_vi_repeat[10]=$command
}
function ble/keymap:vi/operator:filter {
  local context=$3
  [[ $context != line ]] && ble/keymap:vi/expand-range-for-linewise-operator
  _ble_keymap_vi_filter_args=("$beg" "$end" "${@:3}")
  if [[ $_ble_keymap_vi_repeat_invoke ]]; then
    local command=${_ble_keymap_vi_repeat[10]}
    ble/keymap:vi/operator:filter/.hook "$command"
    return
  else
    ble/keymap:vi/operator:filter/.cache-repeat
    _ble_edit_ind=$beg
    _ble_edit_mark=$end
    _ble_edit_mark_active=vi_filter
    ble/keymap:vi/async-commandline-mode 'ble/keymap:vi/operator:filter/.hook'
    _ble_edit_PS1='!'
    _ble_edit_history_prefix=_ble_keymap_vi_filter
    _ble_keymap_vi_cmap_before_command=ble/keymap:vi/commandline/before-command.hook
    _ble_keymap_vi_cmap_cancel_hook=ble/keymap:vi/operator:filter/cancel.hook
    _ble_syntax_lang=bash
    _ble_highlight_layer__list=(plain syntax region overwrite_mode)
    return 148
  fi
}
function ble/keymap:vi/operator:filter/cancel.hook {
  _ble_edit_mark_active= # clear mark:vi_filter
}
function ble/keymap:vi/operator:filter/.hook {
  local command=$1 # 入力されたコマンド
  if [[ ! $command ]]; then
    ble/widget/vi-command/bell
    return 1
  fi
  local beg=${_ble_keymap_vi_filter_args[0]}
  local end=${_ble_keymap_vi_filter_args[1]}
  local context=${_ble_keymap_vi_filter_args[2]}
  _ble_edit_mark_active= # clear mark:vi_filter
  local old=${_ble_edit_str:beg:end-beg} new
  old=${old%$'\n'}
  if ! ble/util/assign new 'eval "$command" <<< "$old" 2>/dev/null'; then
    ble/widget/vi-command/bell
    return 1
  fi
  new=${new%$'\n'}$'\n'
  ble/widget/.replace-range "$beg" "$end" "$new" 1
  _ble_edit_ind=$beg
  if [[ $context == line ]]; then
    ble/widget/vi-command/first-non-space
  else
    ble/keymap:vi/adjust-command-mode
  fi
  ble/keymap:vi/mark/set-previous-edit-area "$beg" $((beg+${#new}))
  ble/keymap:vi/operator:filter/.record-repeat "$command"
  return 0
}
bleopt/declare -v keymap_vi_operatorfunc ''
function ble/keymap:vi/operator:map {
  local context=$3
  if [[ $bleopt_keymap_vi_operatorfunc ]]; then
    local opfunc=ble/keymap:vi/operator:$bleopt_keymap_vi_operatorfunc
    if ble/is-function "$opfunc"; then
      "$opfunc" "$@"
      return
    fi
  fi
  return 1
}
function ble/widget/vi-command/exclusive-range.impl {
  local src=$1 dst=$2 flag=$3 reg=$4 opts=$5
  if [[ $flag ]]; then
    local opname=${flag%%:*} opflags=${flag#*:}
    if [[ :$opflags: == *:vi_line:* ]]; then
      local ble_keymap_vi_opmode=vi_line
      ble/keymap:vi/call-operator-linewise "$opname" "$src" "$dst" '' "$reg"; local ext=$?
    elif [[ :$opflags: == *:vi_block:* ]]; then
      local ble_keymap_vi_opmode=vi_line
      ble/keymap:vi/call-operator-blockwise "$opname" "$src" "$dst" '' "$reg"; local ext=$?
    elif [[ :$opflags: == *:vi_char:* ]]; then
      local ble_keymap_vi_opmode=vi_char
      if [[ :$opts: == *:inclusive:* ]]; then
        ((src<dst?dst--:(dst<src&&src--)))
      else
        if ((src<=dst)); then
          ((dst<${#_ble_edit_str})) &&
            [[ ${_ble_edit_str:dst:1} != $'\n' ]] &&
            ((dst++))
        else
          ((src<${#_ble_edit_str})) &&
            [[ ${_ble_edit_str:src:1} != $'\n' ]] &&
            ((src++))
        fi
      fi
      ble/keymap:vi/call-operator-charwise "$opname" "$src" "$dst" '' "$reg"; local ext=$?
    else
      local ble_keymap_vi_opmode=
      ble/keymap:vi/call-operator-charwise "$opname" "$src" "$dst" '' "$reg"; local ext=$?
    fi
    ((ext==148)) && return 148
    ((ext)) && ble/widget/.bell
    ble/keymap:vi/adjust-command-mode
    return "$ext"
  else
    ble/keymap:vi/needs-eol-fix "$dst" && ((dst--))
    if ((dst!=_ble_edit_ind)); then
      _ble_edit_ind=$dst
    elif [[ :$opts: != *:nobell:* ]]; then
      ble/widget/vi-command/bell
      return 1
    fi
    ble/keymap:vi/adjust-command-mode
    return 0
  fi
}
function ble/widget/vi-command/exclusive-goto.impl {
  local index=$1 flag=$2 reg=$3 opts=$4
  if [[ $flag ]]; then
    if ble-edit/content/bolp "$index"; then
      local is_linewise=
      if ((_ble_edit_ind<index)); then
        ((index--))
        rex=$'(^|\n)[ \t]*$'
        [[ ${_ble_edit_str::_ble_edit_ind} =~ $rex ]] &&
          is_linewise=1
      elif ((index<_ble_edit_ind)); then
        ble-edit/content/bolp &&
          is_linewise=1
      fi
      if [[ $is_linewise ]]; then
        ble/widget/vi-command/linewise-goto.impl "$index" "$flag" "$reg"
        return
      fi
    fi
  fi
  ble/widget/vi-command/exclusive-range.impl "$_ble_edit_ind" "$index" "$flag" "$reg" "$opts"
}
function ble/widget/vi-command/inclusive-goto.impl {
  local index=$1 flag=$2 reg=$3 opts=$4
  if [[ $flag ]]; then
    if ((_ble_edit_ind<=index)); then
      ble-edit/content/eolp "$index" || ((index++))
    else
      ble-edit/content/eolp || ((_ble_edit_ind++))
    fi
  fi
  ble/widget/vi-command/exclusive-range.impl "$_ble_edit_ind" "$index" "$flag" "$reg" "$opts:inclusive"
}
function ble/widget/vi-command/linewise-range.impl {
  local p=$1 q=$2 flag=$3 reg=$4 opts=$5
  local ret
  if [[ $q == *:* ]]; then
    local qbase=${q%%:*} qline=${q#*:}
  else
    local qbase=$q qline=0
  fi
  local bolx=; local rex=':bolx=([0-9]+):'; [[ :$opts: =~ $rex ]] && bolx=${BASH_REMATCH[1]}
  local nolx=; local rex=':nolx=([0-9]+):'; [[ :$opts: =~ $rex ]] && nolx=${BASH_REMATCH[1]}
  if [[ ! $flag ]]; then
    if [[ ! $nolx ]]; then
      if [[ ! $bolx ]]; then
        ble-edit/content/find-logical-bol "$qbase" "$qline"; bolx=$ret
      fi
      ble-edit/content/find-non-space "$bolx"; nolx=$ret
    fi
    ble-edit/content/nonbol-eolp "$nolx" && ((nolx--))
    _ble_edit_ind=$nolx
    ble/keymap:vi/adjust-command-mode
    return 0
  fi
  local opname=${flag%%:*} opflags=${flag#*:}
  if ! ble/is-function ble/keymap:vi/operator:"$opname"; then
    ble/widget/vi-command/bell
    return 1
  fi
  local bolp bolq=$bolx nolq=$nolx
  ble-edit/content/find-logical-bol "$p"; bolp=$ret
  [[ $bolq ]] || { ble-edit/content/find-logical-bol "$qbase" "$qline"; bolq=$ret; }
  if [[ :$opts: == *:require_multiline:* ]]; then
    local is_single_line=$((bolq==bolp))
    if ((bolq==bolp)); then
      ble/widget/vi-command/bell
      return 1
    fi
  fi
  if [[ :$opflags: == *:vi_char:* || :$opflags: == *:vi_block:* ]]; then
    local beg=$p end
    if [[ :$opts: == *:preserve_column:* ]]; then
      local index
      ble/keymap:vi/get-index-of-relative-line "$qbase" "$qline"; end=$index
    elif [[ :$opts: == *:goto_bol:* ]]; then
      end=$bolq
    else
      [[ $nolq ]] || { ble-edit/content/find-non-space "$bolq"; nolq=$ret; }
      end=$nolq
    fi
    ((beg<=end)) || local beg=$end end=$beg
    if [[ :$opflags: == *:vi_block:* ]]; then
      local ble_keymap_vi_opmode=vi_block
      ble/keymap:vi/call-operator "$opname" "$beg" "$end" block '' "$reg"; local ext=$?
    else
      local ble_keymap_vi_opmode=vi_char
      ble/keymap:vi/call-operator "$opname" "$beg" "$end" char '' "$reg"; local ext=$?
    fi
    if ((ext)); then
      ((ext==148)) && return 148
      ble/widget/vi-command/bell
      return "$ext"
    fi
  else
    local beg end
    if ((bolp<=bolq)); then
      ble-edit/content/find-logical-eol "$bolq"; beg=$bolp end=$ret
    else
      ble-edit/content/find-logical-eol "$bolp"; beg=$bolq end=$ret
    fi
    ((end<${#_ble_edit_str}&&end++))
    local ble_keymap_vi_opmode=
    [[ :$opflags: == *:vi_line:* ]] && ble_keymap_vi_opmode=vi_line
    ble/keymap:vi/call-operator "$opname" "$beg" "$end" line '' "$reg"; local ext=$?
    if ((ext)); then
      ((ext==148)) && return 148
      ble/widget/vi-command/bell
      return "$ext"
    fi
    local ind=$_ble_edit_ind
    if [[ $opname == [cd] ]]; then
      _ble_edit_ind=$beg
      ble/widget/vi-command/first-non-space
    elif [[ :$opts: == *:preserve_column:* ]]; then # j k
      if ((beg<ind)); then
        ble/string#count-char "${_ble_edit_str:beg:ind-beg}" $'\n'
        ((ret=-ret))
      elif ((ind<beg)); then
        ble/string#count-char "${_ble_edit_str:ind:beg-ind}" $'\n'
      else
        ret=0
      fi
      if ((ret)); then
        local index; ble/keymap:vi/get-index-of-relative-line "$_ble_edit_ind" "$ret"
        ble/keymap:vi/needs-eol-fix "$index" && ((index--))
        _ble_edit_ind=$index
      fi
    elif [[ :$opts: == *:goto_bol:* ]]; then # 行指向 yis
      _ble_edit_ind=$beg
    else # + - gg G L H
      if ((beg==bolq||ind<beg)) || [[ ${_ble_edit_str:beg:ind-beg} == *$'\n'* ]] ; then
        if ((bolq<=bolp)) && [[ $nolq ]]; then
          local nolb=$nolq
        else
          ble-edit/content/find-non-space "$beg"; local nolb=$ret
        fi
        ble-edit/content/nonbol-eolp "$nolb" && ((nolb--))
        ((ind<beg||nolb<ind)) && _ble_edit_ind=$nolb
      fi
    fi
  fi
  ble/keymap:vi/adjust-command-mode
  return 0
}
function ble/widget/vi-command/linewise-goto.impl {
  ble/widget/vi-command/linewise-range.impl "$_ble_edit_ind" "$@"
}
function ble/keymap:vi/async-read-char.hook {
  local command=${@:1:$#-1} key=${@:$#}
  if ((key==(_ble_decode_Ctrl|0x6B))); then # C-k
    ble-decode/keymap/push vi_digraph
    _ble_keymap_vi_digraph__hook="$command"
  else
    eval "$command $key"
  fi
}
function ble/keymap:vi/async-read-char {
  _ble_decode_key__hook="ble/keymap:vi/async-read-char.hook $*"
  return 148
}
_ble_keymap_vi_mark_Offset=32
_ble_keymap_vi_mark_hindex=
_ble_keymap_vi_mark_local=()
_ble_keymap_vi_mark_global=()
_ble_keymap_vi_mark_history=()
_ble_keymap_vi_mark_edit_dbeg=-1
_ble_keymap_vi_mark_edit_dend=-1
_ble_keymap_vi_mark_edit_dend0=-1
ble/array#push _ble_edit_dirty_observer ble/keymap:vi/mark/shift-by-dirty-range
ble/array#push _ble_edit_history_onleave ble/keymap:vi/mark/history-onleave.hook
function ble/keymap:vi/mark/history-onleave.hook {
  if [[ $_ble_decode_keymap == vi_[inoxs]map ]]; then
    ble/keymap:vi/mark/set-local-mark 34 "$_ble_edit_ind" # `"
  fi
}
function ble/keymap:vi/mark/update-mark-history {
  local h; ble-edit/history/get-index -v h
  if [[ ! $_ble_keymap_vi_mark_hindex ]]; then
    _ble_keymap_vi_mark_hindex=$h
  elif ((_ble_keymap_vi_mark_hindex!=h)); then
    local imark value
    local -a save=()
    for imark in "${!_ble_keymap_vi_mark_local[@]}"; do
      local value=${_ble_keymap_vi_mark_local[imark]}
      ble/array#push save "$imark:$value"
    done
    _ble_keymap_vi_mark_history[_ble_keymap_vi_mark_hindex]="${save[*]-}"
    _ble_keymap_vi_mark_local=()
    local entry
    for entry in ${_ble_keymap_vi_mark_history[h]-}; do
      imark=${entry%%:*} value=${entry#*:}
      _ble_keymap_vi_mark_local[imark]=$value
    done
    _ble_keymap_vi_mark_hindex=$h
  fi
}
function ble/keymap:vi/mark/shift-by-dirty-range {
  local beg=$1 end=$2 end0=$3 reason=$4
  if [[ $4 == edit ]]; then
    ble/dirty-range#update --prefix=_ble_keymap_vi_mark_edit_d "${@:1:3}"
    ble/keymap:vi/xmap/update-dirty-range "$@"
    ble/keymap:vi/mark/update-mark-history
    local shift=$((end-end0))
    local imark
    for imark in "${!_ble_keymap_vi_mark_local[@]}"; do
      local value=${_ble_keymap_vi_mark_local[imark]}
      local index=${value%%:*} rest=${value#*:}
      ((index<beg)) || _ble_keymap_vi_mark_local[imark]=$((index<end0?beg:index+shift)):$rest
    done
    local h; ble-edit/history/get-index -v h
    for imark in "${!_ble_keymap_vi_mark_global[@]}"; do
      local value=${_ble_keymap_vi_mark_global[imark]}
      [[ $value == "$h":* ]] || continue
      local h=${value%%:*}; value=${value:${#h}+1}
      local index=${value%%:*}; value=${value:${#index}+1}
      ((index<beg)) || _ble_keymap_vi_mark_global[imark]=$h:$((index<end0?beg:index+shift)):$value
    done
    ble/keymap:vi/mark/set-local-mark 46 "$beg" # `.
  else
    ble/dirty-range#clear --prefix=_ble_keymap_vi_mark_edit_d
    if [[ $4 == newline && $_ble_decode_keymap != vi_cmap ]]; then
      ble/keymap:vi/mark/set-local-mark 96 0 # ``
    fi
  fi
}
function ble/keymap:vi/mark/set-global-mark {
  local c=$1 index=$2 ret
  ble/keymap:vi/mark/update-mark-history
  ble-edit/content/find-logical-bol "$index"; local bol=$ret
  local h; ble-edit/history/get-index -v h
  _ble_keymap_vi_mark_global[c]=$h:$bol:$((index-bol))
}
function ble/keymap:vi/mark/set-local-mark {
  local c=$1 index=$2 ret
  ble/keymap:vi/mark/update-mark-history
  ble-edit/content/find-logical-bol "$index"; local bol=$ret
  _ble_keymap_vi_mark_local[c]=$bol:$((index-bol))
}
function ble/keymap:vi/mark/get-mark.impl {
  local index=$1 bytes=$2
  local len=${#_ble_edit_str}
  ((index>len&&(index=len)))
  ble-edit/content/find-logical-bol "$index"; index=$ret
  ble-edit/content/find-logical-eol "$index"; local eol=$ret
  ((index+=bytes,index>eol&&(index=eol))) # ToDo: calculate by byte offset
  ret=$index
  return 0
}
function ble/keymap:vi/mark/get-local-mark {
  local c=$1
  ble/keymap:vi/mark/update-mark-history
  local value=${_ble_keymap_vi_mark_local[c]}
  [[ $value ]] || return 1
  local data
  ble/string#split data : "$value"
  ble/keymap:vi/mark/get-mark.impl "${data[0]}" "${data[1]}" # -> ret
}
_ble_keymap_vi_mark_suppress_edit=
function ble/keymap:vi/mark/set-previous-edit-area {
  [[ $_ble_keymap_vi_mark_suppress_edit ]] && return
  local beg=$1 end=$2
  ((beg<end)) && ! ble-edit/content/bolp "$end" && ((end--))
  ble/keymap:vi/mark/set-local-mark 91 "$beg" # `[
  ble/keymap:vi/mark/set-local-mark 93 "$end" # `]
  ble/keymap:vi/undo/add
}
function ble/keymap:vi/mark/start-edit-area {
  [[ $_ble_keymap_vi_mark_suppress_edit ]] && return
  ble/dirty-range#clear --prefix=_ble_keymap_vi_mark_edit_d
}
function ble/keymap:vi/mark/commit-edit-area {
  local beg=$1 end=$2
  ble/dirty-range#update --prefix=_ble_keymap_vi_mark_edit_d "$beg" "$end" "$end"
}
function ble/keymap:vi/mark/end-edit-area {
  [[ $_ble_keymap_vi_mark_suppress_edit ]] && return
  local beg=$_ble_keymap_vi_mark_edit_dbeg
  local end=$_ble_keymap_vi_mark_edit_dend
  ((beg>=0)) && ble/keymap:vi/mark/set-previous-edit-area "$beg" "$end"
}
function ble/keymap:vi/mark/set-jump {
  ble/keymap:vi/mark/set-local-mark 96 "$_ble_edit_ind"
}
function ble/widget/vi-command/set-mark {
  _ble_decode_key__hook="ble/widget/vi-command/set-mark.hook"
  return 148
}
function ble/widget/vi-command/set-mark.hook {
  local key=$1
  ble/keymap:vi/clear-arg
  local ret
  if ble/keymap:vi/k2c "$key" && local c=$ret; then
    if ((65<=c&&c<91)); then # A-Z
      ble/keymap:vi/mark/set-global-mark "$c" "$_ble_edit_ind"
      ble/keymap:vi/adjust-command-mode
      return 0
    elif ((97<=c&&c<123||c==91||c==93||c==60||c==62||c==96||c==39)); then # a-z [ ] < > ` '
      ((c==39)) && c=96 # m' は m` に読み替える
      ble/keymap:vi/mark/set-local-mark "$c" "$_ble_edit_ind"
      ble/keymap:vi/adjust-command-mode
      return 0
    fi
  fi
  ble/widget/vi-command/bell
  return 1
}
function ble/widget/vi-command/goto-mark.impl {
  local index=$1 flag=$2 reg=$3 opts=$4
  [[ $flag ]] || ble/keymap:vi/mark/set-jump # ``
  if [[ :$opts: == *:line:* ]]; then
    ble/widget/vi-command/linewise-goto.impl "$index" "$flag" "$reg"
  else
    ble/widget/vi-command/exclusive-goto.impl "$index" "$flag" "$reg" nobell
  fi
}
function ble/widget/vi-command/goto-local-mark.impl {
  local c=$1 opts=$2 ret
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  if ble/keymap:vi/mark/get-local-mark "$c" && local index=$ret; then
    ble/widget/vi-command/goto-mark.impl "$index" "$FLAG" "$REG" "$opts"
  else
    ble/widget/vi-command/bell
    return 1
  fi
}
function ble/widget/vi-command/goto-global-mark.impl {
  local c=$1 opts=$2
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/keymap:vi/mark/update-mark-history
  local value=${_ble_keymap_vi_mark_global[c]}
  if [[ ! $value ]]; then
    ble/widget/vi-command/bell
    return 1
  fi
  local data
  ble/string#split data : "$value"
  if ((_ble_edit_history_ind!=data[0])); then
    if [[ $FLAG ]]; then
      ble/widget/vi-command/bell
      return 1
    fi
    ble-edit/history/goto "${data[0]}"
  fi
  local ret
  ble/keymap:vi/mark/get-mark.impl "${data[1]}" "${data[2]}"
  ble/widget/vi-command/goto-mark.impl "$ret" "$FLAG" "$REG" "$opts"
}
function ble/widget/vi-command/goto-mark {
  _ble_decode_key__hook="ble/widget/vi-command/goto-mark.hook ${1:-char}"
  return 148
}
function ble/widget/vi-command/goto-mark.hook {
  local opts=$1 key=$2
  local ret
  if ble/keymap:vi/k2c "$key" && local c=$ret; then
    if ((65<=c&&c<91)); then # A-Z
      ble/widget/vi-command/goto-global-mark.impl "$c" "$opts"
      return
    elif ((_ble_keymap_vi_mark_Offset<=c)); then
      ((c==39)) && c=96 # `' は `` に読み替える
      ble/widget/vi-command/goto-local-mark.impl "$c" "$opts"
      return
    fi
  fi
  ble/keymap:vi/clear-arg
  ble/widget/vi-command/bell
  return 1
}
_ble_keymap_vi_repeat=()
_ble_keymap_vi_repeat_insert=()
_ble_keymap_vi_repeat_irepeat=()
_ble_keymap_vi_repeat_invoke=
function ble/keymap:vi/repeat/record-special {
  [[ $_ble_keymap_vi_mark_suppress_edit ]] && return 0
  if [[ $_ble_keymap_vi_repeat_invoke ]]; then
    [[ $repeat_arg ]] && _ble_keymap_vi_repeat[3]=$repeat_arg
    [[ ! ${_ble_keymap_vi_repeat[5]} ]] && _ble_keymap_vi_repeat[5]=$repeat_reg
    return 0
  fi
  return 1
}
function ble/keymap:vi/repeat/record-normal {
  local -a repeat; repeat=("$KEYMAP" "${KEYS[*]-}" "$WIDGET" "$ARG" "$FLAG" "$REG" '')
  if [[ $KEYMAP == vi_[xs]map ]]; then
    repeat[6]=$_ble_keymap_vi_xmap_prev_edit
  fi
  if [[ $_ble_decode_keymap == vi_imap ]]; then
    _ble_keymap_vi_repeat_insert=("${repeat[@]}")
  else
    _ble_keymap_vi_repeat=("${repeat[@]}")
    _ble_keymap_vi_repeat_irepeat=()
  fi
}
function ble/keymap:vi/repeat/record {
  ble/keymap:vi/repeat/record-special && return 0
  ble/keymap:vi/repeat/record-normal
}
function ble/keymap:vi/repeat/record-insert {
  ble/keymap:vi/repeat/record-special && return 0
  if [[ ${_ble_keymap_vi_repeat_insert-} ]]; then
    _ble_keymap_vi_repeat=("${_ble_keymap_vi_repeat_insert[@]}")
    _ble_keymap_vi_repeat_irepeat=("${_ble_keymap_vi_irepeat[@]}")
  elif ((${#_ble_keymap_vi_irepeat[@]})); then
    _ble_keymap_vi_repeat=(vi_nmap "${KEYS[*]-}" ble/widget/vi_nmap/insert-mode 1 '' '')
    _ble_keymap_vi_repeat_irepeat=("${_ble_keymap_vi_irepeat[@]}")
  fi
  ble/keymap:vi/repeat/clear-insert
}
function ble/keymap:vi/repeat/clear-insert {
  _ble_keymap_vi_repeat_insert=()
}
function ble/keymap:vi/repeat/invoke {
  local repeat_arg=$_ble_edit_arg
  local repeat_reg=$_ble_keymap_vi_reg
  local KEYMAP=${_ble_keymap_vi_repeat[0]}
  local -a KEYS=(${_ble_keymap_vi_repeat[1]})
  local WIDGET=${_ble_keymap_vi_repeat[2]}
  if [[ $KEYMAP != vi_[onxs]map ]]; then
    ble/widget/vi-command/bell
    return 1
  elif [[ $KEYMAP == vi_omap ]]; then
    ble-decode/keymap/push vi_omap
  elif [[ $KEYMAP == vi_[xs]map ]]; then
    local _ble_keymap_vi_xmap_prev_edit=${_ble_keymap_vi_repeat[6]}
    ble/widget/vi_xmap/.restore-visual-state
    ble-decode/keymap/push "$KEYMAP"
  fi
  _ble_edit_arg=
  _ble_keymap_vi_oparg=${_ble_keymap_vi_repeat[3]}
  _ble_keymap_vi_opfunc=${_ble_keymap_vi_repeat[4]}
  [[ $repeat_arg ]] && _ble_keymap_vi_oparg=$repeat_arg
  local REG=${_ble_keymap_vi_repeat[5]}
  [[ $REG ]] && _ble_keymap_vi_reg=$REG
  local _ble_keymap_vi_single_command{,_overwrite}= # single-command-mode は持続させる。
  local _ble_keymap_vi_repeat_invoke=1
  local LASTWIDGET=$_ble_decode_widget_last
  _ble_decode_widget_last=$WIDGET
  builtin eval -- "$WIDGET"
  if [[ $_ble_decode_keymap == vi_imap ]]; then
    ((_ble_keymap_vi_irepeat_count<=1?(_ble_keymap_vi_irepeat_count=2):_ble_keymap_vi_irepeat_count++))
    local -a _ble_keymap_vi_irepeat
    _ble_keymap_vi_irepeat=("${_ble_keymap_vi_repeat_irepeat[@]}")
    ble/array#push _ble_keymap_vi_irepeat '0:ble/widget/dummy' # Note: normal-mode が自分自身を pop しようとするので。
    ble/widget/vi_imap/normal-mode
  fi
  ble/util/unlocal _ble_keymap_vi_single_command{,_overwrite}
}
function ble/widget/vi_nmap/repeat {
  ble/keymap:vi/repeat/invoke
  ble/keymap:vi/adjust-command-mode
}
function ble/widget/vi-command/forward-char {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local index
  if [[ $1 == wrap ]]; then
    if [[ $FLAG || $_ble_decode_keymap == vi_[xs]map ]]; then
      ((index=_ble_edit_ind+ARG,
        index>${#_ble_edit_str}&&(index=${#_ble_edit_str})))
    else
      local nl=$'\n'
      local rex="^([^$nl]$nl?|$nl){0,$ARG}"
      [[ ${_ble_edit_str:_ble_edit_ind} =~ $rex ]]
      ((index=_ble_edit_ind+${#BASH_REMATCH}))
    fi
  else
    local line=${_ble_edit_str:_ble_edit_ind:ARG}
    line=${line%%$'\n'*}
    ((index=_ble_edit_ind+${#line}))
  fi
  ble/widget/vi-command/exclusive-goto.impl "$index" "$FLAG" "$REG"
}
function ble/widget/vi-command/backward-char {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local index
  ((ARG>_ble_edit_ind&&(ARG=_ble_edit_ind)))
  if [[ $1 == wrap ]]; then
    if [[ $FLAG || $_ble_decode_keymap == vi_[xs]map ]]; then
      ((index=_ble_edit_ind-ARG,index<0&&(index=0)))
    else
      local width=$ARG line
      while ((width<=_ble_edit_ind)); do
        line=${_ble_edit_str:_ble_edit_ind-width:width}
        line=${line//[!$'\n']$'\n'/x}
        ((${#line}>=ARG)) && break
        ((width+=ARG-${#line}))
      done
      ((index=_ble_edit_ind-width,index<0&&(index=0)))
    fi
  else
    local line=${_ble_edit_str:_ble_edit_ind-ARG:ARG}
    line=${line##*$'\n'}
    ((index=_ble_edit_ind-${#line}))
  fi
  ble/widget/vi-command/exclusive-goto.impl "$index" "$FLAG" "$REG"
}
function ble/widget/vi_nmap/forward-char-toggle-case {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local line=${_ble_edit_str:_ble_edit_ind:ARG}
  line=${line%%$'\n'*}
  local len=${#line}
  if ((len==0)); then
    ble/widget/vi-command/bell
    return 1
  fi
  local index=$((_ble_edit_ind+len))
  local ret; ble/string#toggle-case "${_ble_edit_str:_ble_edit_ind:len}"
  ble/widget/.replace-range "$_ble_edit_ind" "$index" "$ret" 1
  ble/keymap:vi/mark/set-previous-edit-area "$_ble_edit_ind" "$index"
  ble/keymap:vi/repeat/record
  ble/keymap:vi/needs-eol-fix "$index" && ((index--))
  _ble_edit_ind=$index
  ble/keymap:vi/adjust-command-mode
  return 0
}
function ble/widget/vi-command/.history-relative-line {
  local offset=$1
  ((offset)) || return 0
  if [[ ! $_ble_edit_history_loaded ]]; then
    ((offset<0)) || return 1
    ble-edit/history/load # to use _ble_edit_history_ind
  fi
  local ret count=$((offset<0?-offset:offset)) exit=1
  ((count--))
  while ((count>=0)); do
    if ((offset<0)); then
      ((_ble_edit_history_ind>0)) || return "$exit"
      ble/widget/history-prev
      ret=${#_ble_edit_str}
      ble/keymap:vi/needs-eol-fix "$ret" && ((ret--))
      _ble_edit_ind=$ret
    else
      ((_ble_edit_history_ind<${#_ble_edit_history[@]})) || return "$exit"
      ble/widget/history-next
      _ble_edit_ind=0
    fi
    exit=0
    ble/string#count-char "$_ble_edit_str" $'\n'; local nline=$((ret+1))
    ((count<nline)) && break
    ((count-=nline))
  done
  if ((count)); then
    if ((offset<0)); then
      ble-edit/content/find-logical-eol 0 $((nline-count-1))
      ble/keymap:vi/needs-eol-fix "$ret" && ((ret--))
    else
      ble-edit/content/find-logical-bol 0 "$count"
    fi
    _ble_edit_ind=$ret
  fi
  return 0
}
function ble/keymap:vi/get-index-of-relative-line {
  local ind=${1:-$_ble_edit_ind} offset=$2
  if ((offset==0)); then
    index=$ind
    return
  fi
  local count=$((offset<0?-offset:offset))
  local ret
  ble-edit/content/find-logical-bol "$ind" 0; local bol1=$ret
  ble-edit/content/find-logical-bol "$ind" "$offset"; local bol2=$ret
  if ble/edit/use-textmap; then
    local b1x b1y; ble/textmap#getxy.cur --prefix=b1 "$bol1"
    local b2x b2y; ble/textmap#getxy.cur --prefix=b2 "$bol2"
    ble-edit/content/find-logical-eol "$bol2"; local eol2=$ret
    local c1x c1y; ble/textmap#getxy.cur --prefix=c1 "$ind"
    local e2x e2y; ble/textmap#getxy.cur --prefix=e2 "$eol2"
    local x=$c1x y=$((b2y+c1y-b1y))
    ((y>e2y&&(x=e2x,y=e2y)))
    ble/textmap#get-index-at "$x" "$y" # local variable "index" is set here
  else
    ble-edit/content/find-logical-eol "$bol2"; local eol2=$ret
    ((index=bol2+ind-bol1,index>eol2&&(index=eol2)))
  fi
}
function ble/widget/vi-command/relative-line.impl {
  local offset=$1 flag=$2 reg=$3 opts=$4
  ((offset==0)) && return
  if [[ $flag ]]; then
    ble/widget/vi-command/linewise-goto.impl "$_ble_edit_ind:$offset" "$flag" "$reg" preserve_column:require_multiline
    return
  fi
  local count=$((offset<0?-offset:offset)) ret
  if ((offset<0)); then
    ble/string#count-char "${_ble_edit_str::_ble_edit_ind}" $'\n'
  else
    ble/string#count-char "${_ble_edit_str:_ble_edit_ind}" $'\n'
  fi
  ((count-=count<ret?count:ret))
  if ((count==0)); then
    local index; ble/keymap:vi/get-index-of-relative-line "$_ble_edit_ind" "$offset"
    ble/keymap:vi/needs-eol-fix "$index" && ((index--))
    _ble_edit_ind=$index
    ble/keymap:vi/adjust-command-mode
    return 0
  fi
  if [[ $_ble_decode_keymap == vi_nmap && :$opts: == *:history:* ]]; then
    if ble/widget/vi-command/.history-relative-line $((offset>=0?count:-count)) || ((nmove)); then
      ble/keymap:vi/adjust-command-mode
      return 0
    fi
  fi
  ble/widget/vi-command/bell
  return 1
}
function ble/widget/vi-command/forward-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/relative-line.impl "$ARG" "$FLAG" "$REG" history
}
function ble/widget/vi-command/backward-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/relative-line.impl $((-ARG)) "$FLAG" "$REG" history
}
function ble/widget/vi-command/graphical-relative-line.impl {
  local offset=$1 flag=$2 reg=$3 opts=$4
  local index move
  if ble/edit/use-textmap; then
    local x y ax ay
    ble/textmap#getxy.cur "$_ble_edit_ind"
    ((ax=x,ay=y+offset,
      ay<_ble_textmap_begy?(ay=_ble_textmap_begy):
      (ay>_ble_textmap_endy?(ay=_ble_textmap_endy):0)))
    ble/textmap#get-index-at "$ax" "$ay"
    ble/textmap#getxy.cur --prefix=a "$index"
    ((offset-=move=ay-y))
  else
    local ret ind=$_ble_edit_ind
    ble-edit/content/find-logical-bol "$ind" 0; local bol1=$ret
    ble-edit/content/find-logical-bol "$ind" "$offset"; local bol2=$ret
    ble-edit/content/find-logical-eol "$bol2"; local eol2=$ret
    ((index=bol2+ind-bol1,index>eol2&&(index=eol2)))
    if ((index>ind)); then
      ble/string#count-char "${_ble_edit_str:ind:index-ind}" $'\n'
      ((offset+=move=-ret))
    elif ((index<ind)); then
      ble/string#count-char "${_ble_edit_str:index:ind-index}" $'\n'
      ((offset+=move=ret))
    fi
  fi
  if ((offset==0)); then
    ble/widget/vi-command/exclusive-goto.impl "$index" "$flag" "$reg"
    return
  fi
  if [[ ! $flag && $_ble_decode_keymap == vi_nmap && :$opts: == *:history:* ]]; then
    if ble/widget/vi-command/.history-relative-line "$offset"; then
      ble/keymap:vi/adjust-command-mode
      return 0
    fi
  fi
  ((move)) && ble/widget/vi-command/exclusive-goto.impl "$index"
  ble/widget/vi-command/bell
  return 1
}
function ble/widget/vi-command/graphical-forward-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/graphical-relative-line.impl "$ARG" "$FLAG" "$REG"
}
function ble/widget/vi-command/graphical-backward-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/graphical-relative-line.impl $((-ARG)) "$FLAG" "$REG"
}
function ble/widget/vi-command/relative-first-non-space.impl {
  local arg=$1 flag=$2 reg=$3 opts=$4
  local ret ind=$_ble_edit_ind
  ble-edit/content/find-logical-bol "$ind" "$arg"; local bolx=$ret
  ble-edit/content/find-non-space "$bolx"; local nolx=$ret
  ((_ble_keymap_vi_single_command==2&&_ble_keymap_vi_single_command--))
  if [[ $flag ]]; then
    if [[ :$opts: == *:charwise:* ]]; then
      ble-edit/content/nonbol-eolp "$nolx" && ((nolx--))
      ble/widget/vi-command/exclusive-goto.impl "$nolx" "$flag" "$reg" nobell
    elif [[ :$opts: == *:multiline:* ]]; then
      ble/widget/vi-command/linewise-goto.impl "$nolx" "$flag" "$reg" require_multiline:bolx="$bolx":nolx="$nolx"
    else
      ble/widget/vi-command/linewise-goto.impl "$nolx" "$flag" "$reg" bolx="$bolx":nolx="$nolx"
    fi
    return
  fi
  local count=$((arg<0?-arg:arg)) nmove=0
  if ((count)); then
    local beg end; ((nolx<ind?(beg=nolx,end=ind):(beg=ind,end=nolx)))
    ble/string#count-char "${_ble_edit_str:beg:end-beg}" $'\n'; nmove=$ret
    ((count-=nmove))
  fi
  if ((count==0)); then
    ble/keymap:vi/needs-eol-fix "$nolx" && ((nolx--))
    _ble_edit_ind=$nolx
    ble/keymap:vi/adjust-command-mode
    return 0
  fi
  if [[ $_ble_decode_keymap == vi_nmap && :$opts: == *:history:* ]] && ble/widget/vi-command/.history-relative-line $((arg>=0?count:-count)); then
    ble/widget/vi-command/first-non-space
  elif ((nmove)); then
    ble/keymap:vi/needs-eol-fix "$nolx" && ((nolx--))
    _ble_edit_ind=$nolx
    ble/keymap:vi/adjust-command-mode
  else
    ble/widget/vi-command/bell
    return 1
  fi
}
function ble/widget/vi-command/first-non-space {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/relative-first-non-space.impl 0 "$FLAG" "$REG" charwise:history
}
function ble/widget/vi-command/forward-first-non-space {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/relative-first-non-space.impl "$ARG" "$FLAG" "$REG" multiline:history
}
function ble/widget/vi-command/backward-first-non-space {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/relative-first-non-space.impl $((-ARG)) "$FLAG" "$REG" multiline:history
}
function ble/widget/vi-command/first-non-space-forward {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/relative-first-non-space.impl $((ARG-1)) "$FLAG" "$REG" history
}
function ble/widget/vi-command/forward-eol {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  if ((ARG>1)) && [[ ${_ble_edit_str:_ble_edit_ind}  != *$'\n'* ]]; then
    ble/widget/vi-command/bell
    return 1
  fi
  local ret index
  ble-edit/content/find-logical-eol "$_ble_edit_ind" $((ARG-1)); index=$ret
  ble/keymap:vi/needs-eol-fix "$index" && ((index--))
  ble/widget/vi-command/inclusive-goto.impl "$index" "$FLAG" "$REG" nobell
  [[ $_ble_decode_keymap == vi_[xs]map ]] &&
    ble/keymap:vi/xmap/add-eol-extension # 末尾拡張
}
function ble/widget/vi-command/beginning-of-graphical-line {
  if ble/edit/use-textmap; then
    local ARG FLAG REG; ble/keymap:vi/get-arg 1
    local x y index
    ble/textmap#getxy.cur "$_ble_edit_ind"
    ble/textmap#get-index-at 0 "$y"
    ble/keymap:vi/needs-eol-fix "$index" && ((index--))
    ble/widget/vi-command/exclusive-goto.impl "$index" "$FLAG" "$REG" nobell
  else
    ble/widget/vi-command/beginning-of-line
  fi
}
function ble/widget/vi-command/graphical-first-non-space {
  if ble/edit/use-textmap; then
    local ARG FLAG REG; ble/keymap:vi/get-arg 1
    local x y index ret
    ble/textmap#getxy.cur "$_ble_edit_ind"
    ble/textmap#get-index-at 0 "$y"
    ble-edit/content/find-non-space "$index"
    ble/keymap:vi/needs-eol-fix "$ret" && ((ret--))
    ble/widget/vi-command/exclusive-goto.impl "$ret" "$FLAG" "$REG" nobell
  else
    ble/widget/vi-command/first-non-space
  fi
}
function ble/widget/vi-command/graphical-forward-eol {
  if ble/edit/use-textmap; then
    local ARG FLAG REG; ble/keymap:vi/get-arg 1
    local x y index
    ble/textmap#getxy.cur "$_ble_edit_ind"
    ble/textmap#get-index-at $((_ble_textmap_cols-1)) $((y+ARG-1))
    ble/keymap:vi/needs-eol-fix "$index" && ((index--))
    ble/widget/vi-command/inclusive-goto.impl "$index" "$FLAG" "$REG" nobell
  else
    ble/widget/vi-command/forward-eol
  fi
}
function ble/widget/vi-command/middle-of-graphical-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local index
  if ble/edit/use-textmap; then
    local x y
    ble/textmap#getxy.cur "$_ble_edit_ind"
    ble/textmap#get-index-at $((_ble_textmap_cols/2)) "$y"
    ble/keymap:vi/needs-eol-fix "$index" && ((index--))
  else
    local ret
    ble-edit/content/find-logical-bol; local bol=$ret
    ble-edit/content/find-logical-eol; local eol=$ret
    ((index=(bol+${COLUMNS:-eol})/2,
      index>eol&&(index=eol),
      bol<eol&&index==eol&&(index--)))
  fi
  ble/widget/vi-command/exclusive-goto.impl "$index" "$FLAG" "$REG" nobell
}
function ble/widget/vi-command/last-non-space {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local ret
  ble-edit/content/find-logical-eol "$_ble_edit_ind" $((ARG-1)); local index=$ret
  if ((ARG>1)) && [[ ${_ble_edit_str:_ble_edit_ind:index-_ble_edit_ind} != *$'\n'* ]]; then
    ble/widget/vi-command/bell
    return 1
  fi
  local rex=$'([^ \t\n]?[ \t]+|[^ \t\n])$'
  [[ ${_ble_edit_str::index} =~ $rex ]] && ((index-=${#BASH_REMATCH}))
  ble/widget/vi-command/inclusive-goto.impl "$index" "$FLAG" "$REG" nobell
}
_ble_keymap_vi_previous_scroll=
function ble/widget/vi_nmap/scroll.impl {
  local opts=$1
  local height=${_ble_canvas_panel_height[_ble_textarea_panel]}
  local ARG FLAG REG; ble/keymap:vi/get-arg "$_ble_keymap_vi_previous_scroll"
  _ble_keymap_vi_previous_scroll=$ARG
  [[ $ARG ]] || ((ARG=height/2))
  [[ :$opts: == *:backward:* ]] && ((ARG=-ARG))
  ble/widget/.update-textmap
  if [[ :$opts: == *:cursor:* ]]; then
    local x y index ret
    ble/textmap#getxy.cur "$_ble_edit_ind"
    ble/textmap#get-index-at 0 $((y+ARG))
    ble-edit/content/find-non-space "$index"
    ble/keymap:vi/needs-eol-fix "$ret" && ((ret--))
    _ble_edit_ind=$ret
    ble/keymap:vi/adjust-command-mode
    ((_ble_textmap_endy<height)) && return
    local ax ay
    ble/textmap#getxy.cur --prefix=a "$_ble_edit_ind"
    local max_scroll=$((_ble_textmap_endy+1-height))
    ((_ble_textarea_scroll_new+=ay-y))
    if ((_ble_textarea_scroll_new<0)); then
      _ble_textarea_scroll_new=0
    elif ((_ble_textarea_scroll_new>max_scroll)); then
      _ble_textarea_scroll_new=$max_scroll
    fi
  else
    ((_ble_textmap_endy<height)) && return
    local max_scroll=$((_ble_textmap_endy+1-height))
    ((_ble_textarea_scroll_new+=ARG))
    if ((_ble_textarea_scroll_new<0)); then
      _ble_textarea_scroll_new=0
    elif ((_ble_textarea_scroll_new>max_scroll)); then
      _ble_textarea_scroll_new=$max_scroll
    fi
    local ay=$((_ble_textarea_scroll_new+_ble_textmap_begy))
    local by=$((_ble_textarea_scroll_new+height-1))
    ((_ble_textarea_scroll_new&&ay++))
    ((_ble_textarea_scroll_new!=0&&ay<by&&ay++,
      _ble_textarea_scroll_new!=max_scroll&&ay<by&&by--))
    local x y
    ble/textmap#getxy.cur "$_ble_edit_ind"
    if ((y<ay?(y=ay,1):(y>by?(y=by,1):0))); then
      local index
      ble/textmap#get-index-at "$x" "$y"
      _ble_edit_ind=$index
    fi
    ble/keymap:vi/adjust-command-mode
  fi
}
function ble/widget/vi_nmap/forward-line-scroll {
  ble/widget/vi_nmap/scroll.impl forward:cursor
}
function ble/widget/vi_nmap/backward-line-scroll {
  ble/widget/vi_nmap/scroll.impl backward:cursor
}
function ble/widget/vi_nmap/forward-scroll {
  ble/widget/vi_nmap/scroll.impl forward
}
function ble/widget/vi_nmap/backward-scroll {
  ble/widget/vi_nmap/scroll.impl backward
}
function ble/widget/vi_nmap/pagedown {
  local height=${_ble_canvas_panel_height[_ble_textarea_panel]}
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/.update-textmap
  local x y
  ble/textmap#getxy.cur "$_ble_edit_ind"
  if ((y==_ble_textmap_endy)); then
    ble/widget/vi-command/bell
    return 1
  fi
  local vheight=$((height-_ble_textmap_begy-1))
  local ybase=$((_ble_textarea_scroll_new+height-1))
  local y1=$((ybase+(ARG-1)*(vheight-2)))
  local index ret
  ble/textmap#get-index-at 0 "$y1"
  ble-edit/content/bolp "$index" &&
    ble-edit/content/find-non-space "$index"; index=$ret
  _ble_edit_ind=$index
  local max_scroll=$((_ble_textmap_endy+1-height))
  ble/textmap#getxy.cur "$_ble_edit_ind"
  local scroll=$((y<=_ble_textmap_begy+1?0:(y-_ble_textmap_begy-1)))
  ((scroll>max_scroll&&(scroll=max_scroll)))
  _ble_textarea_scroll_new=$scroll
  ble/keymap:vi/adjust-command-mode
}
function ble/widget/vi_nmap/pageup {
  local height=${_ble_canvas_panel_height[_ble_textarea_panel]}
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/.update-textmap
  if ((!_ble_textarea_scroll_new)); then
    ble/widget/vi-command/bell
    return 1
  fi
  local vheight=$((height-_ble_textmap_begy-1))
  local ybase=$((_ble_textarea_scroll_new+_ble_textmap_begy+1))
  local y1=$((ybase-(ARG-1)*(vheight-2)))
  ((y1<_ble_textmap_begy&&(y1=_ble_textmap_begy)))
  local index ret
  ble/textmap#get-index-at 0 "$y1"
  ble-edit/content/bolp "$index" &&
    ble-edit/content/find-non-space "$index"; index=$ret
  _ble_edit_ind=$index
  local x y
  ble/textmap#getxy.cur "$_ble_edit_ind"
  local scroll=$((y-height+2))
  ((scroll<0&&(scroll=0)))
  _ble_textarea_scroll_new=$scroll
  ble/keymap:vi/adjust-command-mode
}
function ble/widget/vi_nmap/scroll-to-center.impl {
  local opts=$1
  ble/widget/.update-textmap
  local height=${_ble_canvas_panel_height[_ble_textarea_panel]}
  local ARG FLAG REG; ble/keymap:vi/get-arg ''
  if [[ ! $ARG && :$opts: == *:pagedown:* ]]; then
    local y1=$((_ble_textarea_scroll_new+height))
    local index
    ble/textmap#get-index-at 0 "$y1"
    ((_ble_edit_ind=index))
  fi
  local ret
  ble-edit/content/find-logical-bol "$_ble_edit_ind"; local bol1=$ret
  if [[ $ARG || :$opts: == *:nol:* ]]; then
    if [[ $ARG ]]; then
      ble-edit/content/find-logical-bol 0 $((ARG-1)); local bol2=$ret
    else
      local bol2=$bol1
    fi
    if [[ :$opts: == *:nol:* ]]; then
      ble-edit/content/find-non-space "$bol2"
      _ble_edit_ind=$ret
    elif ((bol1!=bol2)); then
      local b1x b1y p1x p1y dx dy
      ble/textmap#getxy.cur --prefix=b1 "$bol1"
      ble/textmap#getxy.cur --prefix=p1 "$_ble_edit_ind"
      ((dx=p1x,dy=p1y-b1y))
      local b2x b2y p2x p2y index
      ble/textmap#getxy.cur --prefix=b2 "$bol2"
      ((p2x=b2x,p2y=b2y+dy))
      ble/textmap#get-index-at "$p2x" "$p2y"
      if ble-edit/content/find-logical-bol "$index"; ((ret==bol2)); then
        _ble_edit_ind=$index
      else
        ble-edit/content/find-logical-eol "$bol2"
        _ble_edit_ind=$ret
      fi
    fi
    ble/keymap:vi/needs-eol-fix && ((_ble_edit_ind--))
  fi
  if ((_ble_textmap_endy+1>height)); then
    local max_scroll=$((_ble_textmap_endy+1-height))
    local b1x b1y
    ble/textmap#getxy.cur --prefix=b1 "$bol1"
    local scroll=
    if [[ :$opts: == *:top:* ]]; then
      ((scroll=b1y-(_ble_textmap_begy+2)))
    elif [[ :$opts: == *:bottom:* ]]; then
      ((scroll=b1y-(height-2)))
    else
      local vheight=$((height-_ble_textmap_begy-1))
      ((scroll=b1y-(_ble_textmap_begy+1+vheight/2)))
    fi
    if ((scroll<0)); then
      scroll=0
    elif ((scroll>max_scroll)); then
      scroll=$max_scroll
    fi
    _ble_textarea_scroll_new=$scroll
  fi
  ble/keymap:vi/adjust-command-mode
}
function ble/widget/vi_nmap/scroll-to-center-and-redraw {
  ble/widget/vi_nmap/scroll-to-center.impl
  ble/widget/redraw-line
}
function ble/widget/vi_nmap/scroll-to-top-and-redraw {
  ble/widget/vi_nmap/scroll-to-center.impl top
  ble/widget/redraw-line
}
function ble/widget/vi_nmap/scroll-to-bottom-and-redraw {
  ble/widget/vi_nmap/scroll-to-center.impl bottom
  ble/widget/redraw-line
}
function ble/widget/vi_nmap/scroll-to-center-non-space-and-redraw {
  ble/widget/vi_nmap/scroll-to-center.impl nol
  ble/widget/redraw-line
}
function ble/widget/vi_nmap/scroll-to-top-non-space-and-redraw {
  ble/widget/vi_nmap/scroll-to-center.impl top:nol
  ble/widget/redraw-line
}
function ble/widget/vi_nmap/scroll-to-bottom-non-space-and-redraw {
  ble/widget/vi_nmap/scroll-to-center.impl bottom:nol
  ble/widget/redraw-line
}
function ble/widget/vi_nmap/scroll-or-pagedown-and-redraw {
  ble/widget/vi_nmap/scroll-to-center.impl top:nol:pagedown
  ble/widget/redraw-line
}
function ble/widget/vi_nmap/paste.impl/block {
  local arg=${1:-1} type=$2
  local graphical=
  if [[ $type ]]; then
    [[ $type == graphical ]] && graphical=1
  else
    ble/edit/use-textmap && graphical=1
  fi
  local ret cols=$_ble_textmap_cols
  local -a afill=(${_ble_edit_kill_type:2})
  local atext; ble/string#split-lines atext "$_ble_edit_kill_ring"
  local ntext=${#atext[@]}
  if [[ $graphical ]]; then
    ble-edit/content/find-logical-bol; local bol=$ret
    local bx by x y c
    ble/textmap#getxy.cur --prefix=b "$bol"
    ble/textmap#getxy.cur "$_ble_edit_ind"
    ((y-=by,c=y*cols+x))
  else
    ble-edit/content/find-logical-bol; local bol=$ret
    local c=$((_ble_edit_ind-bol))
  fi
  local -a ins_beg=() ins_end=() ins_text=()
  local i is_newline=
  for ((i=0;i<ntext;i++)); do
    if ((i>0)); then
      ble-edit/content/find-logical-bol "$bol" 1
      if ((bol==ret)); then
        is_newline=1
      else
        bol=$ret
        [[ $graphical ]] && ble/textmap#getxy.cur --prefix=b "$bol"
      fi
    fi
    local text=${atext[i]}
    local fill=$((afill[i]))
    if ((arg>1)); then
      ret=
      ((fill)) && ble/string#repeat ' ' "$fill"
      ble/string#repeat "$text$ret" "$arg"
      text=${ret::${#ret}-fill}
    fi
    local index iend=
    if [[ $is_newline ]]; then
      index=${#_ble_edit_str}
      ble/string#repeat ' ' "$c"
      text=$'\n'$ret$text
    elif [[ $graphical ]]; then
      ble-edit/content/find-logical-eol "$bol"; local eol=$ret
      ble/textmap#get-index-at "$x" $((by+y)); ((index>eol&&(index=eol)))
      local ax ay ac; ble/textmap#getxy.out --prefix=a "$index"
      ((ay-=by,ac=ay*cols+ax))
      if ((ac<c)); then
        ble/string#repeat ' ' $((c-ac))
        text=$ret$text
        if ((index<eol)) && [[ ${_ble_edit_str:index:1} == $'\t' ]]; then
          local rx ry rc; ble/textmap#getxy.out --prefix=r $((index+1))
          ((rc=(ry-by)*cols+rx))
          ble/string#repeat ' ' $((rc-c))
          text=$text$ret
          iend=$((index+1))
        fi
      fi
      if ((index<eol&&fill)); then
        ble/string#repeat ' ' "$fill"
        text=$text$ret
      fi
    else
      ble-edit/content/find-logical-eol "$bol"; local eol=$ret
      local index=$((bol+c))
      if ((index<eol)); then
        if ((fill)); then
          ble/string#repeat ' ' "$fill"
          text=$text$ret
        fi
      elif ((index>eol)); then
        ble/string#repeat ' ' $((index-eol))
        text=$ret$text
        index=$eol
      fi
    fi
    ble/array#push ins_beg "$index"
    ble/array#push ins_end "${iend:-$index}"
    ble/array#push ins_text "$text"
  done
  ble/keymap:vi/mark/start-edit-area
  local i=${#ins_beg[@]}
  while ((i--)); do
    local ibeg=${ins_beg[i]} iend=${ins_end[i]} text=${ins_text[i]}
    ble/widget/.replace-range "$ibeg" "$iend" "$text" 1
  done
  ble/keymap:vi/mark/end-edit-area
  ble/keymap:vi/repeat/record
  ble/keymap:vi/needs-eol-fix && ((_ble_edit_ind--))
  ble/keymap:vi/adjust-command-mode
}
function ble/widget/vi_nmap/paste.impl {
  local arg=$1 reg=$2 is_after=$3
  if [[ $reg ]]; then
    local _ble_edit_kill_ring _ble_edit_kill_type
    ble/keymap:vi/register#load "$reg"
  fi
  [[ $_ble_edit_kill_ring ]] || return 0
  local ret
  if [[ $_ble_edit_kill_type == L ]]; then
    ble/string#repeat "$_ble_edit_kill_ring" "$arg"
    local content=$ret
    local index dbeg dend
    if ((is_after)); then
      ble-edit/content/find-logical-eol; index=$ret
      if ((index==${#_ble_edit_str})); then
        content=$'\n'${content%$'\n'}
        ((dbeg=index+1,dend=index+${#content}))
      else
        ((index++,dbeg=index,dend=index+${#content}-1))
      fi
    else
      ble-edit/content/find-logical-bol
      ((index=ret,dbeg=index,dend=index+${#content}-1))
    fi
    ble/widget/.replace-range "$index" "$index" "$content" 1
    _ble_edit_ind=$dbeg
    ble/keymap:vi/mark/set-previous-edit-area "$dbeg" "$dend"
    ble/keymap:vi/repeat/record
    ble/widget/vi-command/first-non-space
  elif [[ $_ble_edit_kill_type == B:* ]]; then
    if ((is_after)) && ! ble-edit/content/eolp; then
      ((_ble_edit_ind++))
    fi
    ble/widget/vi_nmap/paste.impl/block "$arg"
  else
    if ((is_after)) && ! ble-edit/content/eolp; then
      ((_ble_edit_ind++))
    fi
    ble/string#repeat "$_ble_edit_kill_ring" "$arg"
    local beg=$_ble_edit_ind
    ble/widget/.insert-string "$ret"
    local end=$_ble_edit_ind
    ble/keymap:vi/mark/set-previous-edit-area "$beg" "$end"
    ble/keymap:vi/repeat/record
    [[ $_ble_keymap_vi_single_command ]] || ((_ble_edit_ind--))
    ble/keymap:vi/needs-eol-fix && ((_ble_edit_ind--))
    ble/keymap:vi/adjust-command-mode
  fi
  return 0
}
function ble/widget/vi_nmap/paste-after {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi_nmap/paste.impl "$ARG" "$REG" 1
}
function ble/widget/vi_nmap/paste-before {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi_nmap/paste.impl "$ARG" "$REG" 0
}
function ble/widget/vi_nmap/kill-forward-char {
  _ble_keymap_vi_opfunc=d
  ble/widget/vi-command/forward-char
}
function ble/widget/vi_nmap/kill-forward-char-and-insert {
  _ble_keymap_vi_opfunc=c
  ble/widget/vi-command/forward-char
}
function ble/widget/vi_nmap/kill-backward-char {
  _ble_keymap_vi_opfunc=d
  ble/widget/vi-command/backward-char
}
function ble/widget/vi_nmap/kill-forward-line {
  _ble_keymap_vi_opfunc=d
  ble/widget/vi-command/forward-eol
}
function ble/widget/vi_nmap/kill-forward-line-and-insert {
  _ble_keymap_vi_opfunc=c
  ble/widget/vi-command/forward-eol
}
function ble/widget/vi-command/forward-word.impl {
  local arg=$1 flag=$2 reg=$3 rex_word=$4
  local ifs=$' \t\n'
  if [[ $flag == c && ${_ble_edit_str:_ble_edit_ind:1} != [$ifs] ]]; then
    ble/widget/vi-command/forward-word-end.impl "$arg" "$flag" "$reg" "$rex_word" allow_here
    return
  fi
  local b=$'[ \t]' n=$'\n'
  local rex="^((($rex_word)$n?|$b+$n?|$n)($b+$n)*$b*){0,$arg}" # 単語先頭または空行に止まる
  [[ ${_ble_edit_str:_ble_edit_ind} =~ $rex ]]
  local index=$((_ble_edit_ind+${#BASH_REMATCH}))
  if [[ $flag ]]; then
    local rematch1=${BASH_REMATCH[1]}
    if local rex="$n$b*\$"; [[ $rematch1 =~ $rex ]]; then
      local suffix_len=${#BASH_REMATCH}
      ((suffix_len<${#rematch1})) &&
        ((index-=suffix_len))
    fi
  fi
  ble/widget/vi-command/exclusive-goto.impl "$index" "$flag" "$reg"
}
function ble/widget/vi-command/forward-word-end.impl {
  local arg=$1 flag=$2 reg=$3 rex_word=$4 opts=$5
  local IFS=$' \t\n'
  local rex="^([$IFS]*($rex_word)?){0,$arg}" # 単語末端に止まる。空行には止まらない
  local offset=1; [[ :$opts: == *:allow_here:* ]] && offset=0
  [[ ${_ble_edit_str:_ble_edit_ind+offset} =~ $rex ]]
  local index=$((_ble_edit_ind+offset+${#BASH_REMATCH}-1))
  ((index<_ble_edit_ind&&(index=_ble_edit_ind)))
  [[ ! $flag && $BASH_REMATCH && ${_ble_edit_str:index:1} == [$IFS] ]] && ble/widget/.bell
  ble/widget/vi-command/inclusive-goto.impl "$index" "$flag" "$reg"
}
function ble/widget/vi-command/backward-word.impl {
  local arg=$1 flag=$2 reg=$3 rex_word=$4
  local b=$'[ \t]' n=$'\n'
  local rex="((($rex_word)$n?|$b+$n?|$n)($b+$n)*$b*){0,$arg}\$" # 単語先頭または空行に止まる
  [[ ${_ble_edit_str::_ble_edit_ind} =~ $rex ]]
  local index=$((_ble_edit_ind-${#BASH_REMATCH}))
  ble/widget/vi-command/exclusive-goto.impl "$index" "$flag" "$reg"
}
function ble/widget/vi-command/backward-word-end.impl {
  local arg=$1 flag=$2 reg=$3 rex_word=$4
  local i=$'[ \t\n]' b=$'[ \t]' n=$'\n' w="($rex_word)"
  local rex1="(^|$w$n?|$n)($b+$n)*$b*"
  local rex="($rex1)($rex1){$((arg-1))}($rex_word|$i)\$" # 単語末端または空行に止まる
  [[ ${_ble_edit_str::_ble_edit_ind+1} =~ $rex ]]
  local index=$((_ble_edit_ind+1-${#BASH_REMATCH}))
  local rematch3=${BASH_REMATCH[3]} # 最初の ($rex_word)
  [[ $rematch3 ]] && ((index+=${#rematch3}-1))
  ble/widget/vi-command/inclusive-goto.impl "$index" "$flag" "$reg"
}
function ble/widget/vi-command/forward-vword {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/forward-word.impl "$ARG" "$FLAG" "$REG" "$_ble_keymap_vi_REX_WORD"
}
function ble/widget/vi-command/forward-vword-end {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/forward-word-end.impl "$ARG" "$FLAG" "$REG" "$_ble_keymap_vi_REX_WORD"
}
function ble/widget/vi-command/backward-vword {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/backward-word.impl "$ARG" "$FLAG" "$REG" "$_ble_keymap_vi_REX_WORD"
}
function ble/widget/vi-command/backward-vword-end {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/backward-word-end.impl "$ARG" "$FLAG" "$REG" "$_ble_keymap_vi_REX_WORD"
}
function ble/widget/vi-command/forward-uword {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/forward-word.impl "$ARG" "$FLAG" "$REG" $'[^ \t\n]+'
}
function ble/widget/vi-command/forward-uword-end {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/forward-word-end.impl "$ARG" "$FLAG" "$REG" $'[^ \t\n]+'
}
function ble/widget/vi-command/backward-uword {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/backward-word.impl "$ARG" "$FLAG" "$REG" $'[^ \t\n]+'
}
function ble/widget/vi-command/backward-uword-end {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/backward-word-end.impl "$ARG" "$FLAG" "$REG" $'[^ \t\n]+'
}
function ble/widget/vi-command/nth-column {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local ret index
  ble-edit/content/find-logical-bol; local bol=$ret
  ble-edit/content/find-logical-eol; local eol=$ret
  if ble/edit/use-textmap; then
    local bx by; ble/textmap#getxy.cur --prefix=b "$bol" # Note: 先頭行はプロンプトにより bx!=0
    local ex ey; ble/textmap#getxy.cur --prefix=e "$eol"
    local dstx=$((bx+ARG-1)) dsty=$by cols=${COLUMNS:-80}
    ((dsty+=dstx/cols,dstx%=cols))
    ((dsty>ey&&(dsty=ey,dstx=ex)))
    ble/textmap#get-index-at "$dstx" "$dsty" # local variable "index" is set here
    [[ $_ble_decode_keymap != vi_[xs]map ]] &&
      ble-edit/content/nonbol-eolp "$index" && ((index--))
  else
    [[ $_ble_decode_keymap != vi_[xs]map ]] &&
      ble-edit/content/nonbol-eolp "$eol" && ((eol--))
    ((index=bol+ARG-1,index>eol?(index=eol)))
  fi
  ble/widget/vi-command/exclusive-goto.impl "$index" "$FLAG" "$REG" nobell
}
function ble/widget/vi-command/nth-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  [[ $FLAG ]] || ble/keymap:vi/mark/set-jump # ``
  ble/widget/vi-command/linewise-goto.impl 0:$((ARG-1)) "$FLAG" "$REG"
}
function ble/widget/vi-command/nth-last-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  [[ $FLAG ]] || ble/keymap:vi/mark/set-jump # ``
  ble/widget/vi-command/linewise-goto.impl ${#_ble_edit_str}:$((-(ARG-1))) "$FLAG" "$REG"
}
function ble/widget/vi-command/history-beginning {
  local ARG FLAG REG; ble/keymap:vi/get-arg 0
  if [[ $FLAG ]]; then
    if ((ARG)); then
      _ble_keymap_vi_oparg=$ARG
    else
      _ble_keymap_vi_oparg=
    fi
    _ble_keymap_vi_opfunc=$FLAG
    _ble_keymap_vi_reg=$REG
    ble/widget/vi-command/nth-line
    return
  fi
  if ((ARG)); then
    ble-edit/history/goto $((ARG-1))
  else
    ble/widget/history-beginning
  fi
  ble/keymap:vi/needs-eol-fix && ((_ble_edit_ind--))
  ble/keymap:vi/adjust-command-mode
  return 0
}
function ble/widget/vi-command/history-end {
  local ARG FLAG REG; ble/keymap:vi/get-arg 0
  if [[ $FLAG ]]; then
    _ble_keymap_vi_opfunc=$FLAG
    _ble_keymap_vi_reg=$REG
    if ((ARG)); then
      _ble_keymap_vi_oparg=$ARG
      ble/widget/vi-command/nth-line
    else
      _ble_keymap_vi_oparg=
      ble/widget/vi-command/nth-last-line
    fi
    return
  fi
  if ((ARG)); then
    ble-edit/history/goto $((ARG-1))
  else
    ble/widget/history-end
  fi
  ble/keymap:vi/needs-eol-fix && ((_ble_edit_ind--))
  ble/keymap:vi/adjust-command-mode
  return 0
}
function ble/widget/vi-command/last-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 0
  [[ $FLAG ]] || ble/keymap:vi/mark/set-jump # ``
  if ((ARG)); then
    ble/widget/vi-command/linewise-goto.impl 0:$((ARG-1)) "$FLAG" "$REG"
  else
    ble/widget/vi-command/linewise-goto.impl ${#_ble_edit_str}:0 "$FLAG" "$REG"
  fi
}
function ble/widget/vi-command/first-nol {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi-command/linewise-goto.impl 0:$((ARG-1)) "$FLAG" "$REG"
}
function ble/widget/vi-command/last-eol {
  local ARG FLAG REG; ble/keymap:vi/get-arg ''
  local ret index
  if [[ $ARG ]]; then
    ble-edit/content/find-logical-eol 0 $((ARG-1)); index=$ret
  else
    ble-edit/content/find-logical-eol ${#_ble_edit_str}; index=$ret
  fi
  ble/keymap:vi/needs-eol-fix "$index" && ((index--))
  ble/widget/vi-command/inclusive-goto.impl "$index" "$FLAG" "$REG" nobell
}
function ble/widget/vi_nmap/replace-char.impl {
  local key=$1 overwrite_mode=${2:-R}
  _ble_edit_overwrite_mode=
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local ret
  if ((key==(_ble_decode_Ctrl|91))); then # C-[
    ble/keymap:vi/adjust-command-mode
    return 27
  elif ! ble/keymap:vi/k2c "$key"; then
    ble/widget/vi-command/bell
    return 1
  fi
  local pos=$_ble_edit_ind
  ble/keymap:vi/mark/start-edit-area
  {
    local -a KEYS; KEYS=("$ret")
    local _ble_edit_arg=$ARG
    local _ble_edit_overwrite_mode=$overwrite_mode
    local ble_widget_self_insert_opts=nolineext
    ble/widget/self-insert
    ble/util/unlocal KEYS
  }
  ble/keymap:vi/mark/end-edit-area
  ble/keymap:vi/repeat/record
  ((pos<_ble_edit_ind&&_ble_edit_ind--))
  ble/keymap:vi/adjust-command-mode
  return 0
}
function ble/widget/vi_nmap/replace-char.hook {
  ble/widget/vi_nmap/replace-char.impl "$1" R
}
function ble/widget/vi_nmap/replace-char {
  _ble_edit_overwrite_mode=R
  ble/keymap:vi/async-read-char ble/widget/vi_nmap/replace-char.hook
}
function ble/widget/vi_nmap/virtual-replace-char.hook {
  ble/widget/vi_nmap/replace-char.impl "$1" 1
}
function ble/widget/vi_nmap/virtual-replace-char {
  _ble_edit_overwrite_mode=1
  ble/keymap:vi/async-read-char ble/widget/vi_nmap/virtual-replace-char.hook
}
function ble/widget/vi_nmap/connect-line-with-space {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local ret
  ble-edit/content/find-logical-eol; local eol1=$ret
  ble-edit/content/find-logical-eol "$_ble_edit_ind" $((ARG<=1?1:ARG-1)); local eol2=$ret
  ble-edit/content/find-logical-bol "$eol2"; local bol2=$ret
  if ((eol1<eol2)); then
    local text=${_ble_edit_str:eol1:eol2-eol1}
    text=${text//$'\n'/' '}
    ble/widget/.replace-range "$eol1" "$eol2" "$text"
    ble/keymap:vi/mark/set-previous-edit-area "$eol1" "$eol2"
    ble/keymap:vi/repeat/record
    _ble_edit_ind=$((bol2-1))
    ble/keymap:vi/adjust-command-mode
    return 0
  else
    ble/widget/vi-command/bell
    return 1
  fi
}
function ble/widget/vi_nmap/connect-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local ret
  ble-edit/content/find-logical-eol; local eol1=$ret
  ble-edit/content/find-logical-eol "$_ble_edit_ind" $((ARG<=1?1:ARG-1)); local eol2=$ret
  ble-edit/content/find-logical-bol "$eol2"; local bol2=$ret
  if ((eol1<eol2)); then
    local text=${_ble_edit_str:eol1:bol2-eol1}
    text=${text//$'\n'}
    ble/widget/.replace-range "$eol1" "$bol2" "$text"
    local delta=$((${#text}-(bol2-eol1)))
    ble/keymap:vi/mark/set-previous-edit-area "$eol1" $((eol2+delta))
    ble/keymap:vi/repeat/record
    _ble_edit_ind=$((bol2+delta))
    ble/keymap:vi/adjust-command-mode
    return 0
  else
    ble/widget/vi-command/bell
    return 1
  fi
}
function ble/widget/vi_nmap/insert-mode-at-forward-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local ret
  ble-edit/content/find-logical-bol; local bol=$ret
  ble-edit/content/find-logical-eol; local eol=$ret
  ble-edit/content/find-non-space "$bol"; local indent=${_ble_edit_str:bol:ret-bol}
  _ble_edit_ind=$eol
  ble/widget/.insert-string $'\n'"$indent"
  ble/widget/vi_nmap/.insert-mode "$ARG"
  ble/keymap:vi/repeat/record
  return 0
}
function ble/widget/vi_nmap/insert-mode-at-backward-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local ret
  ble-edit/content/find-logical-bol; local bol=$ret
  ble-edit/content/find-non-space "$bol"; local indent=${_ble_edit_str:bol:ret-bol}
  _ble_edit_ind=$bol
  ble/widget/.insert-string "$indent"$'\n'
  _ble_edit_ind=$((bol+${#indent}))
  ble/widget/vi_nmap/.insert-mode "$ARG"
  ble/keymap:vi/repeat/record
  return 0
}
_ble_keymap_vi_char_search=
function ble/widget/vi-command/search-char.impl/core {
  local opts=$1 key=$2
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local ret c
  [[ $opts != *p* ]]; local isprev=$?
  [[ $opts != *r* ]]; local isrepeat=$?
  if ((isrepeat)); then
    c=$key
  elif ((key==(_ble_decode_Ctrl|91))); then # C-[ -> cancel
    return 27
  else
    ble/keymap:vi/k2c "$key" || return 1
    ble/util/c2s "$ret"; local c=$ret
  fi
  [[ $c ]] || return 1
  ((isrepeat)) || _ble_keymap_vi_char_search=$c$opts
  local index
  if [[ $opts == *b* ]]; then
    ble-edit/content/find-logical-bol; local bol=$ret
    local base=$_ble_edit_ind
    ((isrepeat&&isprev&&base--,base>bol)) || return 1
    local line=${_ble_edit_str:bol:base-bol}
    ble/string#last-index-of "$line" "$c" "$ARG"
    ((ret>=0)) || return 1
    ((index=bol+ret,isprev&&index++))
    ble/widget/vi-command/exclusive-goto.impl "$index" "$FLAG" "$REG" nobell
    return
  else
    ble-edit/content/find-logical-eol; local eol=$ret
    local base=$((_ble_edit_ind+1))
    ((isrepeat&&isprev&&base++,base<eol)) || return 1
    local line=${_ble_edit_str:base:eol-base}
    ble/string#index-of "$line" "$c" "$ARG"
    ((ret>=0)) || return 1
    ((index=base+ret,isprev&&index--))
    ble/widget/vi-command/inclusive-goto.impl "$index" "$FLAG" "$REG" nobell
    return
  fi
}
function ble/widget/vi-command/search-char.impl {
  if ble/widget/vi-command/search-char.impl/core "$1" "$2"; then
    ble/keymap:vi/adjust-command-mode
    return 0
  else
    ble/widget/vi-command/bell
    return 1
  fi
}
function ble/widget/vi-command/search-forward-char {
  ble/keymap:vi/async-read-char ble/widget/vi-command/search-char.impl f
}
function ble/widget/vi-command/search-forward-char-prev {
  ble/keymap:vi/async-read-char ble/widget/vi-command/search-char.impl fp
}
function ble/widget/vi-command/search-backward-char {
  ble/keymap:vi/async-read-char ble/widget/vi-command/search-char.impl b
}
function ble/widget/vi-command/search-backward-char-prev {
  ble/keymap:vi/async-read-char ble/widget/vi-command/search-char.impl bp
}
function ble/widget/vi-command/search-char-repeat {
  [[ $_ble_keymap_vi_char_search ]] || ble/widget/.bell
  local c=${_ble_keymap_vi_char_search::1} opts=${_ble_keymap_vi_char_search:1}
  ble/widget/vi-command/search-char.impl "r$opts" "$c"
}
function ble/widget/vi-command/search-char-reverse-repeat {
  [[ $_ble_keymap_vi_char_search ]] || ble/widget/.bell
  local c=${_ble_keymap_vi_char_search::1} opts=${_ble_keymap_vi_char_search:1}
  if [[ $opts == *b* ]]; then
    opts=f${opts//b}
  else
    opts=b${opts//f}
  fi
  ble/widget/vi-command/search-char.impl "r$opts" "$c"
}
function ble/widget/vi-command/search-matchpair/.search-forward {
  ble/string#index-of-chars "$_ble_edit_str" "$ch1$ch2" $((index+1))
}
function ble/widget/vi-command/search-matchpair/.search-backward {
  ble/string#last-index-of-chars "$_ble_edit_str" "$ch1$ch2" "$index"
}
function ble/widget/vi-command/search-matchpair-or {
  local ARG FLAG REG; ble/keymap:vi/get-arg -1
  if ((ARG>=0)); then
    _ble_keymap_vi_oparg=$ARG
    _ble_keymap_vi_opfunc=$FLAG
    _ble_keymap_vi_reg=$REG
    ble/widget/"$@"
    return
  fi
  local open='({[' close=')}]'
  local ret
  ble-edit/content/find-logical-eol; local eol=$ret
  if ! ble/string#index-of-chars "${_ble_edit_str::eol}" '(){}[]' "$_ble_edit_ind"; then
    ble/keymap:vi/adjust-command-mode
    return 1
  fi
  local index1=$ret ch1=${_ble_edit_str:ret:1}
  if [[ $ch1 == ["$open"] ]]; then
    local i=${open%%"$ch"*}; i=${#i}
    local ch2=${close:i:1}
    local searcher=ble/widget/vi-command/search-matchpair/.search-forward
  else
    local i=${close%%"$ch"*}; i=${#i}
    local ch2=${open:i:1}
    local searcher=ble/widget/vi-command/search-matchpair/.search-backward
  fi
  local index=$index1 count=1
  while "$searcher"; do
    index=$ret
    if [[ ${_ble_edit_str:ret:1} == "$ch1" ]]; then
      ((++count))
    else
      ((--count==0)) && break
    fi
  done
  if ((count)); then
    ble/keymap:vi/adjust-command-mode
    return 1
  fi
  [[ $FLAG ]] || ble/keymap:vi/mark/set-jump # ``
  ble/widget/vi-command/inclusive-goto.impl "$index" "$FLAG" "$REG" nobell
}
function ble/widget/vi-command/percentage-line {
  local ARG FLAG REG; ble/keymap:vi/get-arg 0
  local ret; ble/string#count-char "$_ble_edit_str" $'\n'; local nline=$((ret+1))
  local iline=$(((ARG*nline+99)/100))
  ble/widget/vi-command/linewise-goto.impl 0:$((iline-1)) "$FLAG" "$REG"
}
function ble/widget/vi-command/nth-byte {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ((ARG--))
  local offset=0 text=$_ble_edit_str len=${#_ble_edit_str}
  local left nleft
  while ((ARG>0&&len>1)); do
    left=${text::len/2}
    LC_ALL=C builtin eval 'nleft=${#left}'
    if ((ARG<nleft)); then
      text=$left
      ((len/=2))
    else
      text=${text:len/2}
      ((offset+=len/2,
        ARG-=nleft,
        len-=len/2))
    fi
  done
  ble/keymap:vi/needs-eol-fix "$offset" && ((offset--))
  ble/widget/vi-command/exclusive-goto.impl "$offset" "$FLAG" "$REG" nobell
}
_ble_keymap_vi_text_object=
function ble/keymap:vi/text-object/word.extend-forward {
  local rex
  flags=
  [[ ${_ble_edit_str:beg:1} == ["$ifs"] ]] && flags=${flags}A
  if [[ $_ble_decode_keymap != vi_[xs]map ]]; then
    flags=${flags}I
  elif ((_ble_edit_mark==_ble_edit_ind)); then
    flags=${flags}I
  fi
  local rex_unit
  local W='('$rex_word')' b='['$space']' n=$nl
  if [[ $type == i* ]]; then
    rex_unit='^'$W'|^'$b'+|^'$n
  elif [[ $type == a* ]]; then
    rex_unit='^'$W$b'*|^'$b'+'$W'|^'$b'*'$n'('$b'+'$n')*('$n'|'$b'*'$W')'
  else
    return 1
  fi
  local i rematch=
  for ((i=0;i<arg;i++)); do
    if ((i==0)) && [[ $flags == *I* ]]; then
      rex='('$rex_word')$|['$space']*['$ifs']$'
      [[ ${_ble_edit_str::beg+1} =~ $rex ]] &&
        ((beg-=${#BASH_REMATCH}-1,end=beg))
    else
      [[ ${_ble_edit_str:end:1} == $'\n' ]] && ((end++))
    fi
    [[ ${_ble_edit_str:end} =~ $rex_unit ]] || return 1
    rematch=$BASH_REMATCH
    ((end+=${#rematch}))
    [[ $type == a* && $rematch == *$'\n\n' ]] && ((end--))
    if ((i==0)) && [[ $flags == *I* ]] || ((i==arg-1)); then
      [[ $type == i* && $rematch == *"$nl" ]] && ((end--))
    fi
  done
  [[ ${_ble_edit_str:end-1:1} == *["$ifs"] ]] && flags=${flags}Z
  if [[ $type == a* && $flags != *[AZ]* ]]; then
    if rex='['$space']+$'; [[ ${_ble_edit_str::beg} =~ $rex ]]; then
      local p=$((beg-${#BASH_REMATCH}))
      ble-edit/content/bolp "$p" || beg=$p
    fi
  fi
  return 0
}
function ble/keymap:vi/text-object/word.extend-backward {
  local rex_unit=
  local W='('$rex_word')' b='['$space']' n=$nl
  if [[ $type == i* ]]; then
    rex_unit='('$W'|'$b'+)'$n'?$|'$n'$'
  elif [[ $type == a* ]]; then
    rex_unit=$b'*'$W$n'?$|'$W'?'$b'*('$n'('$b'+'$n')*'$b'*)?('$b$n'?|'$n')$'
  else
    return 1
  fi
  local count=$arg
  while ((count--)); do
    [[ ${_ble_edit_str::beg} =~ $rex_unit ]] || return 1
    ((beg-=${#BASH_REMATCH}))
    local match=${BASH_REMATCH%"$nl"}
    if ((beg==0&&${#match}>=2)); then
      if [[ $type == i* ]]; then
        [[ $match == ["$space"]* ]] && beg=1
      elif [[ $type == a* ]]; then
        [[ $match == *[!"$ifs"] ]] && beg=1
      fi
    fi
  done
  return 0
}
function ble/keymap:vi/text-object/word.impl {
  local arg=$1 flag=$2 reg=$3 type=$4
  local space=$' \t' nl=$'\n' ifs=$' \t\n'
  ((arg==0)) && return
  local rex_word
  if [[ $type == ?W ]]; then
    rex_word="[^$ifs]+"
  else
    rex_word=$_ble_keymap_vi_REX_WORD
  fi
  local index=$_ble_edit_ind
  if [[ $_ble_decode_keymap == vi_[xs]map ]]; then
    if ((index<_ble_edit_mark)); then
      local beg=$index
      if ble/keymap:vi/text-object/word.extend-backward; then
        _ble_edit_ind=$beg
      else
        _ble_edit_ind=0
        ble/widget/.bell
      fi
      ble/keymap:vi/adjust-command-mode
      return 0
    fi
  fi
  local beg=$index end=$index flags=
  if ! ble/keymap:vi/text-object/word.extend-forward; then
    index=${#_ble_edit_str}
    ble-edit/content/nonbol-eolp "$index" && ((index--))
    _ble_edit_ind=$index
    ble/widget/vi-command/bell
    return 1
  fi
  if [[ $_ble_decode_keymap == vi_[xs]map ]]; then
    ((end--))
    ble-edit/content/nonbol-eolp "$end" && ((end--))
    ((beg<_ble_edit_mark)) && _ble_edit_mark=$beg
    [[ $_ble_edit_mark_active == vi_line ]] &&
      _ble_edit_mark_active=vi_char
    _ble_edit_ind=$end
    ble/keymap:vi/adjust-command-mode
    return 0
  else
    ble/widget/vi-command/exclusive-range.impl "$beg" "$end" "$flag" "$reg"
  fi
}
function ble/keymap:vi/text-object:quote/.next {
  local index=${1:-$((_ble_edit_ind+1))} nl=$'\n'
  local rex="^[^$nl$quote]*$quote"
  [[ ${_ble_edit_str:index} =~ $rex ]] || return 1
  ((ret=index+${#BASH_REMATCH}-1))
  return 0
}
function ble/keymap:vi/text-object:quote/.prev {
  local index=${1:-_ble_edit_ind} nl=$'\n'
  local rex="$quote[^$nl$quote]*\$"
  [[ ${_ble_edit_str::index} =~ $rex ]] || return 1
  ((ret=index-${#BASH_REMATCH}))
  return 0
}
function ble/keymap:vi/text-object/quote.impl {
  local arg=$1 flag=$2 reg=$3 type=$4
  local ret quote=${type:1}
  if [[ $_ble_decode_keymap == vi_[xs]map ]]; then
    if ble/keymap:vi/text-object:quote/.xmap; then
      ble/keymap:vi/adjust-command-mode
      return 0
    else
      ble/widget/vi-command/bell
      return 1
    fi
  fi
  local beg= end=
  if [[ ${_ble_edit_str:_ble_edit_ind:1} == "$quote" ]]; then
    ble-edit/content/find-logical-bol; local bol=$ret
    ble/string#count-char "${_ble_edit_str:bol:_ble_edit_ind-bol}" "$quote"
    if ((ret%2==1)); then
      ((end=_ble_edit_ind+1))
      ble/keymap:vi/text-object:quote/.prev && beg=$ret
    else
      ((beg=_ble_edit_ind))
      ble/keymap:vi/text-object:quote/.next && end=$((ret+1))
    fi
  elif ble/keymap:vi/text-object:quote/.prev && beg=$ret; then
    ble/keymap:vi/text-object:quote/.next && end=$((ret+1))
  elif ble/keymap:vi/text-object:quote/.next && beg=$ret; then
    ble/keymap:vi/text-object:quote/.next $((beg+1)) && end=$((ret+1))
  fi
  if [[ $beg && $end ]]; then
    [[ $type == i* || arg -gt 1 ]] && ((beg++,end--))
    ble/widget/vi-command/exclusive-range.impl "$beg" "$end" "$flag" "$reg"
  else
    ble/widget/vi-command/bell
    return 1
  fi
}
function ble/keymap:vi/text-object:quote/.expand-xmap-range {
  local inclusive=$1
  ((end++))
  if ((inclusive==2)); then
    local rex
    rex=$'^[ \t]+'; [[ ${_ble_edit_str:end} =~ $rex ]] && ((end+=${#BASH_REMATCH}))
  elif ((inclusive==0&&end-beg>2)); then
    ((beg++,end--))
  fi
}
function ble/keymap:vi/text-object:quote/.xmap {
  local min=$_ble_edit_ind max=$_ble_edit_mark
  ((min>max)) && local min=$max max=$min
  [[ ${_ble_edit_str:min:max+1-min} == *$'\n'* ]] && return 1
  local inclusive=0
  if [[ $type == a* ]]; then
    inclusive=2
  elif ((arg>1)); then
    inclusive=1
  fi
  local ret
  if ((_ble_edit_ind==_ble_edit_mark)); then
    ble/keymap:vi/text-object:quote/.prev $((_ble_edit_ind+1)) ||
      ble/keymap:vi/text-object:quote/.next $((_ble_edit_ind+1)) || return 1
    local beg=$ret
    ble/keymap:vi/text-object:quote/.next $((beg+1)) || return 1
    local end=$ret
    ble/keymap:vi/text-object:quote/.expand-xmap-range "$inclusive"
    _ble_edit_mark=$beg
    _ble_edit_ind=$((end-1))
    return 0
  elif ((_ble_edit_ind>_ble_edit_mark)); then
    local updates_mark=
    if [[ ${_ble_edit_str:_ble_edit_ind:1} == "$quote" ]]; then
      ble/keymap:vi/text-object:quote/.next $((_ble_edit_ind+1)) || return 1; local beg=$ret
      if ble/keymap:vi/text-object:quote/.next $((beg+1)); then
        local end=$ret
      else
        local end=$beg beg=$_ble_edit_ind
      fi
    else
      ble-edit/content/find-logical-bol; local bol=$ret
      ble/string#count-char "${_ble_edit_str:bol:_ble_edit_ind-bol}" "$quote"
      if ((ret%2==0)); then
        ble/keymap:vi/text-object:quote/.next $((_ble_edit_ind+1)) || return 1; local beg=$ret
        ble/keymap:vi/text-object:quote/.next $((beg+1)) || return 1; local end=$ret
      else
        ble/keymap:vi/text-object:quote/.prev "$_ble_edit_ind" || return 1; local beg=$ret
        ble/keymap:vi/text-object:quote/.next $((_ble_edit_ind+1)) || return 1; local end=$ret
      fi
      local i1=$((_ble_edit_mark?_ble_edit_mark-1:0))
      [[ ${_ble_edit_str:i1:_ble_edit_ind-i1} != *"$quote"* ]] && updates_mark=1
    fi
    ble/keymap:vi/text-object:quote/.expand-xmap-range "$inclusive"
    [[ $updates_mark ]] && _ble_edit_mark=$beg
    _ble_edit_ind=$((end-1))
    return 0
  else
    ble-edit/content/find-logical-bol; local bol=$ret nl=$'\n'
    local rex="^([^$nl$quote]*$quote[^$nl$quote]*$quote)*[^$nl$quote]*$quote"
    [[ ${_ble_edit_str:bol:_ble_edit_ind-bol} =~ $rex ]] || return 1
    local beg=$((bol+${#BASH_REMATCH}-1))
    ble/keymap:vi/text-object:quote/.next $((beg+1)) || return 1
    local end=$ret
    ble/keymap:vi/text-object:quote/.expand-xmap-range "$inclusive"
    [[ ${_ble_edit_str:_ble_edit_ind:_ble_edit_mark+2-_ble_edit_ind} != *"$quote"* ]] && _ble_edit_mark=$((end-1))
    _ble_edit_ind=$beg
    return 0
  fi
}
function ble/keymap:vi/text-object/block.impl {
  local arg=$1 flag=$2 reg=$3 type=$4
  local ret paren=${type:1} lparen=${type:1:1} rparen=${type:2:1}
  local axis=$_ble_edit_ind
  [[ ${_ble_edit_str:axis:1} == "$lparen" ]] && ((axis++))
  local count=$arg beg=$axis
  while ble/string#last-index-of-chars "$_ble_edit_str" "$paren" "$beg"; do
    beg=$ret
    if [[ ${_ble_edit_str:beg:1} == "$lparen" ]]; then
      ((--count==0)) && break
    else
      ((++count))
    fi
  done
  if ((count)); then
    ble/widget/vi-command/bell
    return 1
  fi
  local count=$arg end=$axis
  while ble/string#index-of-chars "$_ble_edit_str" "$paren" "$end"; do
    end=$((ret+1))
    if [[ ${_ble_edit_str:end-1:1} == "$rparen" ]]; then
      ((--count==0)) && break
    else
      ((++count))
    fi
  done
  if ((count)); then
    ble/widget/vi-command/bell
    return 1
  fi
  local linewise=
  if [[ $type == *i* ]]; then
    ((beg++,end--))
    [[ ${_ble_edit_str:beg:1} == $'\n' ]] && ((beg++))
    ((beg<end)) && ble-edit/content/bolp "$end" && ((end--))
    ((beg<end)) && ble-edit/content/bolp "$beg" && ble-edit/content/eolp "$end" && linewise=1
  fi
  if [[ $_ble_decode_keymap == vi_[xs]map ]]; then
    _ble_edit_mark=$beg
    ble/widget/vi-command/exclusive-goto.impl "$end"
  elif [[ $linewise ]]; then
    ble/widget/vi-command/linewise-range.impl "$beg" "$end" "$flag" "$reg" goto_bol
  else
    ble/widget/vi-command/exclusive-range.impl "$beg" "$end" "$flag" "$reg"
  fi
}
function ble/keymap:vi/text-object:tag/.find-end-tag {
  local ifs=$' \t\n' ret rex
  rex="^<([^$ifs/>!]+)"; [[ ${_ble_edit_str:beg} =~ $rex ]] || return 1
  ble/string#escape-for-extended-regex "${BASH_REMATCH[1]}"; local tagname=$ret
  rex="^</?$tagname([$ifs]+([^>]*[^/])?)?>"
  end=$beg
  local count=0
  while ble/string#index-of-chars "$_ble_edit_str" '<' "$end" && end=$((ret+1)); do
    [[ ${_ble_edit_str:end-1} =~ $rex ]] || continue
    ((end+=${#BASH_REMATCH}-1))
    if [[ ${BASH_REMATCH::2} == '</' ]]; then
      ((--count==0)) && return 0
    else
      ((++count))
    fi
  done
  return 1
}
function ble/keymap:vi/text-object/tag.impl {
  local arg=$1 flag=$2 reg=$3 type=$4
  local ret rex
  local pivot=$_ble_edit_ind ret=$_ble_edit_ind
  if [[ ${_ble_edit_str:ret:1} == '<' ]] || ble/string#last-index-of-chars "${_ble_edit_str::_ble_edit_ind}" '<>'; then
    if rex='^<[^/][^>]*>' && [[ ${_ble_edit_str:ret} =~ $rex ]]; then
      ((pivot=ret+${#BASH_REMATCH}))
    else
      ((pivot=ret+1))
    fi
  fi
  local ifs=$' \t\n'
  local beg=$pivot count=$arg
  rex="<([^$ifs/>!]+([$ifs]+([^>]*[^/])?)?|/[^>]*)>\$"
  while ble/string#last-index-of-chars "${_ble_edit_str::beg}" '>' && beg=$ret; do
    [[ ${_ble_edit_str::beg+1} =~ $rex ]] || continue
    ((beg-=${#BASH_REMATCH}-1))
    if [[ ${BASH_REMATCH::2} == '</' ]]; then
      ((++count))
    else
      if ((--count==0)); then
        if ble/keymap:vi/text-object:tag/.find-end-tag "$beg" && ((_ble_edit_ind<end)); then
          break
        else
          ((count++))
        fi
      fi
    fi
  done
  if ((count)); then
    ble/widget/vi-command/bell
    return 1
  fi
  if [[ $type == i* ]]; then
    rex='^<[^>]*>'; [[ ${_ble_edit_str:beg:end-beg} =~ $rex ]] && ((beg+=${#BASH_REMATCH}))
    rex='<[^>]*>$'; [[ ${_ble_edit_str:beg:end-beg} =~ $rex ]] && ((end-=${#BASH_REMATCH}))
  fi
  if [[ $_ble_decode_keymap == vi_[xs]map ]]; then
    _ble_edit_mark=$beg
    ble/widget/vi-command/exclusive-goto.impl "$end"
  else
    ble/widget/vi-command/exclusive-range.impl "$beg" "$end" "$flag" "$reg"
  fi
}
function ble/keymap:vi/text-object:sentence/.beg {
  beg= is_interval=
  local pivot=$_ble_edit_ind rex=
  if ble-edit/content/bolp && ble-edit/content/eolp; then
    if rex=$'^\n+[^\n]'; [[ ${_ble_edit_str:pivot} =~ $rex ]]; then
      beg=$((pivot+${#BASH_REMATCH}-2))
    else
      if rex=$'\n+$'; [[ ${_ble_edit_str::pivot} =~ $rex ]]; then
        ((pivot-=${#BASH_REMATCH}))
      fi
    fi
  fi
  if [[ ! $beg ]]; then
    rex="^.*((^$LF?|$LF$LF)([ $HT]*)|[.!?][])'\"]*([ $HT$LF]+))"
    if [[ ${_ble_edit_str::pivot+1} =~ $rex ]]; then
      beg=${#BASH_REMATCH}
      if ((pivot<beg)); then
        local rematch34=${BASH_REMATCH[3]}${BASH_REMATCH[4]}
        if [[ $rematch34 ]]; then
          beg=$((pivot+1-${#rematch34})) is_interval=1
        else
          beg=$pivot
        fi
      fi
    else
      beg=0
    fi
  fi
}
function ble/keymap:vi/text-object:sentence/.next {
  if [[ $is_interval ]]; then
    is_interval=
    local rex=$'[ \t]*((\n[ \t]+)*\n[ \t]*)?'
    [[ ${_ble_edit_str:end} =~ $rex ]]
    local index=$((end+${#BASH_REMATCH}))
    ((end<index)) && [[ ${_ble_edit_str:index-1:1} == $'\n' ]] && ((index--))
    ((end=index))
  else
    is_interval=1
    if local rex=$'^\n+'; [[ ${_ble_edit_str:end} =~ $rex ]]; then
      ((end+=${#BASH_REMATCH}))
    elif rex="(([.!?][])\"']*)[ $HT$LF]|$LF$LF).*\$"; [[ ${_ble_edit_str:end} =~ $rex ]]; then
      local rematch2=${BASH_REMATCH[2]}
      end=$((${#_ble_edit_str}-${#BASH_REMATCH}+${#rematch2}))
    else
      local index=${#_ble_edit_str}
      ((end<index)) && [[ ${_ble_edit_str:index-1:1} == $'\n' ]] && ((index--))
      ((end=index))
    fi
  fi
}
function ble/keymap:vi/text-object/sentence.impl {
  local arg=$1 flag=$2 reg=$3 type=$4
  local LF=$'\n' HT=$'\t'
  local rex
  local beg is_interval
  ble/keymap:vi/text-object:sentence/.beg
  local end=$beg i n=$arg
  [[ $type != i* ]] && ((n*=2))
  for ((i=0;i<n;i++)); do
    ble/keymap:vi/text-object:sentence/.next
  done
  ((beg<end)) && [[ ${_ble_edit_str:end-1:1} == $'\n' ]] && ((end--))
  if [[ $type != i* && ! $is_interval ]]; then
    local ifs=$' \t\n'
    if ((end)) && [[ ${_ble_edit_str:end-1:1} != ["$ifs"] ]]; then
      rex="^.*(^$LF?|$LF$LF|[.!?][])'\"]*([ $HT$LF]))([ $HT$LF]*)\$"
      if [[ ${_ble_edit_str::beg} =~ $rex ]]; then
        local rematch2=${BASH_REMATCH[2]}
        local rematch3=${BASH_REMATCH[3]}
        ((beg-=${#rematch2}+${#rematch3}))
        [[ ${_ble_edit_str:beg:1} == $'\n' ]] && ((beg++))
      fi
    fi
  fi
  if [[ $_ble_decode_keymap == vi_[xs]map ]]; then
    _ble_edit_mark=$beg
    ble/widget/vi-command/exclusive-goto.impl "$end"
  elif ble-edit/content/bolp "$beg" && [[ ${_ble_edit_str:end:1} == $'\n' ]]; then
    ble/widget/vi-command/linewise-range.impl "$beg" "$end" "$flag" "$reg" goto_bol
  else
    ble/widget/vi-command/exclusive-range.impl "$beg" "$end" "$flag" "$reg"
  fi
}
function ble/keymap:vi/text-object/paragraph.impl {
  local arg=$1 flag=$2 reg=$3 type=$4
  local rex ret
  local beg= empty_start=
  ble-edit/content/find-logical-bol; local bol=$ret
  ble-edit/content/find-non-space "$bol"; local nol=$ret
  if rex=$'[ \t]*(\n|$)' ble-edit/content/eolp "$nol"; then
    empty_start=1
    rex=$'(^|\n)([ \t]*\n)*$'
    [[ ${_ble_edit_str::bol} =~ $rex ]]
    local rematch1=${BASH_REMATCH[1]} # Note: for bash-3.1 ${#arr[n]} bug
    ((beg=bol-(${#BASH_REMATCH}-${#rematch1})))
  else
    if rex=$'^(.*\n)?[ \t]*\n'; [[ ${_ble_edit_str::bol} =~ $rex ]]; then
      ((beg=${#BASH_REMATCH}))
    else
      ((beg=0))
    fi
  fi
  local end=$beg
  local rex_empty_line=$'([ \t]*\n|[ \t]+$)' rex_paragraph_line=$'([ \t]*[^ \t\n][^\n]*(\n|$))'
  if [[ $type == i* ]]; then
    rex="$rex_empty_line+|$rex_paragraph_line+"
  elif [[ $empty_start ]]; then
    rex="$rex_empty_line*$rex_paragraph_line+"
  else
    rex="$rex_paragraph_line+$rex_empty_line*"
  fi
  local i
  for ((i=0;i<arg;i++)); do
    if [[ ${_ble_edit_str:end} =~ $rex ]]; then
      ((end+=${#BASH_REMATCH}))
    else
      ble/widget/vi-command/bell
      return 1
    fi
  done
  if [[ $type != i* && ! $empty_start ]]; then
    if rex=$'(^|\n)[ \t]*\n$'; ! [[ ${_ble_edit_str::end} =~ $rex ]]; then
      if rex=$'(^|\n)([ \t]*\n)*$'; [[ ${_ble_edit_str::beg} =~ $rex ]]; then
        local rematch1=${BASH_REMATCH[1]}
        ((beg-=${#BASH_REMATCH}-${#rematch1}))
      fi
    fi
  fi
  ((beg<end)) && [[ ${_ble_edit_str:end-1:1} == $'\n' ]] && ((end--))
  if [[ $_ble_decode_keymap == vi_[xs]map ]]; then
    _ble_edit_mark=$beg
    ble/widget/vi-command/exclusive-goto.impl "$end"
  else
    ble/widget/vi-command/linewise-range.impl "$beg" "$end" "$flag" "$reg"
  fi
}
function ble/keymap:vi/text-object.impl {
  local arg=$1 flag=$2 reg=$3 type=$4
  case "$type" in
  ([ia][wW]) ble/keymap:vi/text-object/word.impl "$arg" "$flag" "$reg" "$type" ;;
  ([ia][\"\'\`]) ble/keymap:vi/text-object/quote.impl "$arg" "$flag" "$reg" "$type" ;;
  ([ia]['b()']) ble/keymap:vi/text-object/block.impl "$arg" "$flag" "$reg" "${type::1}()" ;;
  ([ia]['B{}']) ble/keymap:vi/text-object/block.impl "$arg" "$flag" "$reg" "${type::1}{}" ;;
  ([ia]['<>']) ble/keymap:vi/text-object/block.impl "$arg" "$flag" "$reg" "${type::1}<>" ;;
  ([ia]['][']) ble/keymap:vi/text-object/block.impl "$arg" "$flag" "$reg" "${type::1}[]" ;;
  ([ia]t) ble/keymap:vi/text-object/tag.impl "$arg" "$flag" "$reg" "$type" ;;
  ([ia]s) ble/keymap:vi/text-object/sentence.impl "$arg" "$flag" "$reg" "$type" ;;
  ([ia]p) ble/keymap:vi/text-object/paragraph.impl "$arg" "$flag" "$reg" "$type" ;;
  (*)
    ble/widget/vi-command/bell
    return 1;;
  esac
}
function ble/keymap:vi/text-object.hook {
  local key=$1
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  if ! ble-decode-key/ischar "$key"; then
    ble/widget/vi-command/bell
    return 1
  fi
  local ret; ble/util/c2s "$key"
  local type=$_ble_keymap_vi_text_object$ret
  ble/keymap:vi/text-object.impl "$ARG" "$FLAG" "$REG" "$type"
  return 0
}
function ble/keymap:vi/.check-text-object {
  ble-decode-key/ischar "${KEYS[0]}" || return 1
  local ret; ble/util/c2s "${KEYS[0]}"; local c=$ret
  [[ $c == [ia] ]] || return 1
  [[ $_ble_keymap_vi_opfunc || $_ble_decode_keymap == vi_[xs]map ]] || return 1
  _ble_keymap_vi_text_object=$c
  _ble_decode_key__hook=ble/keymap:vi/text-object.hook
  return 0
}
function ble/widget/vi-command/text-object {
  ble/keymap:vi/.check-text-object && return 0
  ble/widget/vi-command/bell
  return 1
}
_ble_keymap_vi_commandline_history=()
_ble_keymap_vi_commandline_history_edit=()
_ble_keymap_vi_commandline_history_dirt=()
_ble_keymap_vi_commandline_history_ind=0
_ble_keymap_vi_commandline_history_onleave=()
_ble_keymap_vi_cmap_is_cancel_key[63|_ble_decode_Ctrl]=1  # C-?
_ble_keymap_vi_cmap_is_cancel_key[127]=1                 # DEL
_ble_keymap_vi_cmap_is_cancel_key[104|_ble_decode_Ctrl]=1 # C-h
_ble_keymap_vi_cmap_is_cancel_key[8]=1                   # BS
function ble/keymap:vi/commandline/before-command.hook {
  if [[ ! $_ble_edit_str ]] && ((_ble_keymap_vi_cmap_is_cancel_key[KEYS[0]])); then
    ble/widget/vi_cmap/cancel
    ble-decode/widget/suppress-widget
  fi
}
function ble/widget/vi-command/commandline {
  ble/keymap:vi/clear-arg
  ble/keymap:vi/async-commandline-mode ble/widget/vi-command/commandline.hook
  _ble_edit_PS1=:
  _ble_edit_history_prefix=_ble_keymap_vi_commandline
  _ble_keymap_vi_cmap_before_command=ble/keymap:vi/commandline/before-command.hook
  return 148
}
function ble/widget/vi-command/commandline.hook {
  local command
  ble/string#split-words command "$1"
  local cmd="ble/widget/vi-command:${command[0]}"
  if ble/is-function "$cmd"; then
    "$cmd" "${command[@]:1}"; local ext=$?
  else
    ble/widget/vi-command/bell "unknown command $1"; local ext=1
  fi
  [[ $1 ]] && _ble_keymap_vi_register[58]=/$result # ":
  return "$ext"
}
function ble/widget/vi-command:w {
  if [[ $1 ]]; then
    builtin history -a "$1"
    local file=$1
  else
    builtin history -a
    local file=${HISTFILE:-'~/.bash_history'}
  fi
  local wc
  ble/util/assign wc 'wc "$file"'
  ble/string#split-words wc "$wc"
  ble-edit/info/show text "\"$file\" ${wc[0]}L, ${wc[2]}C written"
  ble/keymap:vi/adjust-command-mode
  return 0
}
function ble/widget/vi-command:q! {
  ble/widget/exit force
  return 1
}
function ble/widget/vi-command:q {
  ble/widget/exit
  ble/keymap:vi/adjust-command-mode # ジョブがあるときは終了しないので。
  return 1
}
function ble/widget/vi-command:wq {
  ble/widget/vi-command:w "$@"
  ble/widget/exit
  ble/keymap:vi/adjust-command-mode
  return 1
}
_ble_keymap_vi_search_obackward=
_ble_keymap_vi_search_ohistory=
_ble_keymap_vi_search_needle=
_ble_keymap_vi_search_activate=
_ble_keymap_vi_search_matched=
_ble_keymap_vi_search_history=()
_ble_keymap_vi_search_history_edit=()
_ble_keymap_vi_search_history_dirt=()
_ble_keymap_vi_search_history_ind=0
_ble_keymap_vi_search_history_onleave=()
bleopt/declare -v keymap_vi_search_match_current ''
function ble/highlight/layer:region/mark:vi_search/get-selection {
  ble/highlight/layer:region/mark:vi_char/get-selection
}
function ble/keymap:vi/search/matched {
  [[ $_ble_keymap_vi_search_matched || $_ble_edit_mark_active == vi_search || $_ble_keymap_vi_search_activate ]]
}
function ble/keymap:vi/search/clear-matched {
  _ble_keymap_vi_search_activate=
  _ble_keymap_vi_search_matched=
  [[ $_ble_edit_mark_active == vi_search ]] && _ble_edit_mark_active=
}
function ble/keymap:vi/search/invoke-search {
  local needle=$1
  local dir=+; ((opt_backward)) && dir=B
  local ind=$_ble_edit_ind
  if ((opt_optional_next)); then
    if ((!opt_backward)); then
      ((_ble_edit_ind<${#_ble_edit_str}&&_ble_edit_ind++))
    fi
  elif ((opt_locate)) || ! ble/keymap:vi/search/matched; then
    if ((opt_locate)) || [[ $bleopt_keymap_vi_search_match_current ]]; then
      if ((opt_backward)); then
        ble-edit/content/eolp || ((_ble_edit_ind++))
      fi
    else
      if ((!opt_backward)); then
        ble-edit/content/eolp || ((_ble_edit_ind++))
      fi
    fi
  else
    if ((!opt_backward)); then
      if [[ $_ble_decode_keymap == vi_[xs]map ]]; then
        if ble-edit/isearch/search "$@" && ((beg==_ble_edit_ind)); then
          _ble_edit_ind=$end
        else
          ((_ble_edit_ind<${#_ble_edit_str}&&_ble_edit_ind++))
        fi
      else
        ((_ble_edit_ind=_ble_edit_mark))
        ble-edit/content/eolp || ((_ble_edit_ind++))
      fi
    else
      dir=-
    fi
  fi
  ble-edit/isearch/search "$needle" "$dir":regex; local ret=$?
  _ble_edit_ind=$ind
  return "$ret"
}
function ble/widget/vi-command/search.core {
  local beg= end= is_empty_match=
  if ble/keymap:vi/search/invoke-search "$needle"; then
    if ((beg<end)); then
      ble-edit/content/bolp "$end" || ((end--))
      _ble_edit_ind=$beg # eol 補正は search.impl 側で最後に行う
      [[ $_ble_decode_keymap != vi_[xs]map ]] && _ble_edit_mark=$end
      _ble_keymap_vi_search_activate=vi_search
      return 0
    else
      opt_history=
      is_empty_match=1
    fi
  fi
  if ((opt_history)) && [[ $_ble_edit_history_loaded || opt_backward -ne 0 ]]; then
    ble-edit/history/load
    local index=$_ble_edit_history_ind
    [[ $start ]] || start=$index
    if ((opt_backward)); then
      ((index--))
    else
      ((index++))
    fi
    local _ble_edit_isearch_dir=+; ((opt_backward)) && _ble_edit_isearch_dir=-
    local _ble_edit_isearch_str=$needle
    local isearch_ntask=$ntask
    local isearch_time=0
    local isearch_progress_callback=ble-edit/isearch/.show-status-with-progress.fib
    if ((opt_backward)); then
      ble-edit/isearch/backward-search-history-blockwise regex:progress
    else
      ble-edit/isearch/forward-search-history regex:progress
    fi; local r=$?
    ble-edit/info/default
    if ((r==0)); then
      [[ $index != "$_ble_edit_history_ind" ]] &&
        ble-edit/history/goto "$index"
      if ((opt_backward)); then
        local i=${#_ble_edit_str}
        ble/keymap:vi/needs-eol-fix "$i" && ((i--))
        _ble_edit_ind=$i
      else
        _ble_edit_ind=0
      fi
      opt_locate=1 opt_history=0 ble/widget/vi-command/search.core
      return
    fi
  fi
  if ((!opt_optional_next)); then
    if [[ $is_empty_match ]]; then
      ble/widget/.bell "search: empty match"
    else
      ble/widget/.bell "search: not found"
    fi
    if [[ $_ble_edit_mark_active == vi_search ]]; then
      _ble_keymap_vi_search_activate=vi_search
    fi
  fi
  return 1
}
function ble/widget/vi-command/search.impl {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local opts=$1 needle=$2
  [[ :$opts: != *:repeat:* ]]; local opt_repeat=$? # 再検索 n N
  [[ :$opts: != *:history:* ]]; local opt_history=$? # 履歴検索が有効か
  [[ :$opts: != *:-:* ]]; local opt_backward=$? # 逆方向
  local opt_locate=0
  local opt_optional_next=0
  if ((opt_repeat)); then
    if [[ $_ble_keymap_vi_search_needle ]]; then
      needle=$_ble_keymap_vi_search_needle
      ((opt_backward^=_ble_keymap_vi_search_obackward,
        opt_history=_ble_keymap_vi_search_ohistory))
    else
      ble/widget/vi-command/bell 'no previous search'
      return 1
    fi
  else
    ble/keymap:vi/search/clear-matched
    if [[ $needle ]]; then
      _ble_keymap_vi_search_needle=$needle
      _ble_keymap_vi_search_obackward=$opt_backward
      _ble_keymap_vi_search_ohistory=$opt_history
    elif [[ $_ble_keymap_vi_search_needle ]]; then
      needle=$_ble_keymap_vi_search_needle
      _ble_keymap_vi_search_obackward=$opt_backward
      _ble_keymap_vi_search_ohistory=$opt_history
    else
      ble/widget/vi-command/bell 'no previous search'
      return 1
    fi
  fi
  local original_ind=$_ble_edit_ind
  if [[ $FLAG || $_ble_decode_keymap == vi_[xs]map ]]; then
    opt_history=0
  else
    local old_hindex; ble-edit/history/get-index -v old_hindex
  fi
  local start= # 初めの履歴番号。search.core 内で最初に履歴を読み込んだあとで設定される。
  local ntask=$ARG
  while ((ntask)); do
    ble/widget/vi-command/search.core || break
    ((ntask--))
  done
  if [[ $FLAG ]]; then
    if ((ntask)); then
      _ble_keymap_vi_search_activate=
      _ble_edit_ind=$original_ind
      ble/keymap:vi/adjust-command-mode
      return 1
    else
      if ((_ble_edit_ind==original_index)); then
        opt_optional_next=1 ble/widget/vi-command/search.core
      fi
      local index=$_ble_edit_ind
      _ble_keymap_vi_search_activate=
      _ble_edit_ind=$original_ind
      ble/widget/vi-command/exclusive-goto.impl "$index" "$FLAG" "$REG" nobell
    fi
  else
    if ((ntask<ARG)); then
      if ((opt_history)); then
        local new_hindex; ble-edit/history/get-index -v new_hindex
        ((new_hindex==old_hindex))
      fi && ble/keymap:vi/mark/set-local-mark 96 "$original_index" # ``
      if ble/keymap:vi/needs-eol-fix; then
        if ((!opt_backward&&_ble_edit_ind<_ble_edit_mark)); then
          ((_ble_edit_ind++))
        else
          ((_ble_edit_ind--))
        fi
      fi
    fi
    ble/keymap:vi/adjust-command-mode
    return 0
  fi
}
function ble/widget/vi-command/search-forward {
  ble/keymap:vi/async-commandline-mode 'ble/widget/vi-command/search.impl +:history'
  _ble_edit_PS1='/'
  _ble_edit_history_prefix=_ble_keymap_vi_search
  _ble_keymap_vi_cmap_before_command=ble/keymap:vi/commandline/before-command.hook
  return 148
}
function ble/widget/vi-command/search-backward {
  ble/keymap:vi/async-commandline-mode 'ble/widget/vi-command/search.impl -:history'
  _ble_edit_PS1='?'
  _ble_edit_history_prefix=_ble_keymap_vi_search
  _ble_keymap_vi_cmap_before_command=ble/keymap:vi/commandline/before-command.hook
  return 148
}
function ble/widget/vi-command/search-repeat {
  ble/widget/vi-command/search.impl repeat:+
}
function ble/widget/vi-command/search-reverse-repeat {
  ble/widget/vi-command/search.impl repeat:-
}
function ble/widget/vi-command/search-word.impl {
  local opts=$1
  local rex=$'^([^[:alnum:]_\n]*)([[:alnum:]_]*)'
  if ! [[ ${_ble_edit_str:_ble_edit_ind} =~ $rex ]]; then
    ble/keymap:vi/clear-arg
    ble/widget/vi-command/bell 'word is not found'
    return 1
  fi
  local end=$((_ble_edit_ind+${#BASH_REMATCH}))
  local word=${BASH_REMATCH[2]}
  if [[ ! ${BASH_REMATCH[1]} ]]; then
    rex=$'[[:alnum:]_]+$'
    [[ ${_ble_edit_str::_ble_edit_ind} =~ $rex ]] &&
      word=$BASH_REMATCH$word
  fi
  local needle=$word
  rex='\<'$needle; [[ $word =~ $rex ]] && needle=$rex
  rex=$needle'\>'; [[ $word =~ $rex ]] && needle=$rex
  if [[ $opts == backward ]]; then
    ble/widget/vi-command/search.impl -:history "$needle"
  else
    local original_ind=$_ble_edit_ind
    _ble_edit_ind=$((end-1))
    ble/widget/vi-command/search.impl +:history "$needle" && return
    _ble_edit_ind=$original_ind
    return 1
  fi
}
function ble/widget/vi-command/search-word-forward {
  ble/widget/vi-command/search-word.impl forward
}
function ble/widget/vi-command/search-word-backward {
  ble/widget/vi-command/search-word.impl backward
}
function ble/widget/vi_nmap/command-help {
  ble/keymap:vi/clear-arg
  ble/widget/command-help; local ext=$?
  ble/keymap:vi/adjust-command-mode
  return "$ext"
}
function ble/widget/vi_xmap/command-help.core {
  ble/keymap:vi/clear-arg
  local get_selection=ble/highlight/layer:region/mark:$_ble_edit_mark_active/get-selection
  ble/is-function "$get_selection" || return 1
  local selection
  "$get_selection" || return 1
  ((${#selection[*]}==2)) || return
  local comp_cword=0 comp_line=$_ble_edit_str comp_point=$_ble_edit_ind
  local -a comp_words; comp_words=("$cmd")
  local cmd=${_ble_edit_str:selection[0]:selection[1]-selection[0]}
  ble/widget/command-help.impl "$cmd"; local ext=$?
  ble/keymap:vi/adjust-command-mode
  return "$ext"
}
function ble/widget/vi_xmap/command-help {
  if ! ble/widget/vi_xmap/command-help.core; then
    ble/widget/vi-command/bell
    return 1
  fi
}
function ble/keymap:vi/setup-map {
  ble-bind -f 0 vi-command/append-arg
  ble-bind -f 1 vi-command/append-arg
  ble-bind -f 2 vi-command/append-arg
  ble-bind -f 3 vi-command/append-arg
  ble-bind -f 4 vi-command/append-arg
  ble-bind -f 5 vi-command/append-arg
  ble-bind -f 6 vi-command/append-arg
  ble-bind -f 7 vi-command/append-arg
  ble-bind -f 8 vi-command/append-arg
  ble-bind -f 9 vi-command/append-arg
  ble-bind -f y 'vi-command/operator y'
  ble-bind -f d 'vi-command/operator d'
  ble-bind -f c 'vi-command/operator c'
  ble-bind -f '<' 'vi-command/operator indent-left'
  ble-bind -f '>' 'vi-command/operator indent-right'
  ble-bind -f '!' 'vi-command/operator filter'
  ble-bind -f 'g ~' 'vi-command/operator toggle_case'
  ble-bind -f 'g u' 'vi-command/operator u'
  ble-bind -f 'g U' 'vi-command/operator U'
  ble-bind -f 'g ?' 'vi-command/operator rot13'
  ble-bind -f 'g q' 'vi-command/operator fold'
  ble-bind -f 'g w' 'vi-command/operator fold-preserve-point'
  ble-bind -f 'g @' 'vi-command/operator map'
  ble-bind -f paste_begin vi-command/bracketed-paste
  ble-bind -f 'home'    vi-command/beginning-of-line
  ble-bind -f '$'       vi-command/forward-eol
  ble-bind -f 'end'     vi-command/forward-eol
  ble-bind -f '^'       vi-command/first-non-space
  ble-bind -f '_'       vi-command/first-non-space-forward
  ble-bind -f '+'       vi-command/forward-first-non-space
  ble-bind -f 'C-m'     vi-command/forward-first-non-space
  ble-bind -f 'RET'     vi-command/forward-first-non-space
  ble-bind -f '-'       vi-command/backward-first-non-space
  ble-bind -f 'g 0'     vi-command/beginning-of-graphical-line
  ble-bind -f 'g home'  vi-command/beginning-of-graphical-line
  ble-bind -f 'g ^'     vi-command/graphical-first-non-space
  ble-bind -f 'g $'     vi-command/graphical-forward-eol
  ble-bind -f 'g end'   vi-command/graphical-forward-eol
  ble-bind -f 'g m'     vi-command/middle-of-graphical-line
  ble-bind -f 'g _'     vi-command/last-non-space
  ble-bind -f h     vi-command/backward-char
  ble-bind -f l     vi-command/forward-char
  ble-bind -f left  vi-command/backward-char
  ble-bind -f right vi-command/forward-char
  ble-bind -f 'C-?' 'vi-command/backward-char wrap'
  ble-bind -f 'DEL' 'vi-command/backward-char wrap'
  ble-bind -f 'C-h' 'vi-command/backward-char wrap'
  ble-bind -f 'BS'  'vi-command/backward-char wrap'
  ble-bind -f SP    'vi-command/forward-char wrap'
  ble-bind -f j     vi-command/forward-line
  ble-bind -f down  vi-command/forward-line
  ble-bind -f C-n   vi-command/forward-line
  ble-bind -f C-j   vi-command/forward-line
  ble-bind -f k     vi-command/backward-line
  ble-bind -f up    vi-command/backward-line
  ble-bind -f C-p   vi-command/backward-line
  ble-bind -f 'g j'    vi-command/graphical-forward-line
  ble-bind -f 'g down' vi-command/graphical-forward-line
  ble-bind -f 'g k'    vi-command/graphical-backward-line
  ble-bind -f 'g up'   vi-command/graphical-backward-line
  ble-bind -f w       vi-command/forward-vword
  ble-bind -f W       vi-command/forward-uword
  ble-bind -f b       vi-command/backward-vword
  ble-bind -f B       vi-command/backward-uword
  ble-bind -f e       vi-command/forward-vword-end
  ble-bind -f E       vi-command/forward-uword-end
  ble-bind -f 'g e'   vi-command/backward-vword-end
  ble-bind -f 'g E'   vi-command/backward-uword-end
  ble-bind -f C-right vi-command/forward-vword
  ble-bind -f S-right vi-command/forward-vword
  ble-bind -f C-left  vi-command/backward-vword
  ble-bind -f S-left  vi-command/backward-vword
  ble-bind -f 'g o'  vi-command/nth-byte
  ble-bind -f '|'    vi-command/nth-column
  ble-bind -f H      vi-command/nth-line
  ble-bind -f L      vi-command/nth-last-line
  ble-bind -f 'g g'  vi-command/history-beginning
  ble-bind -f G      vi-command/history-end
  ble-bind -f C-home vi-command/first-nol
  ble-bind -f C-end  vi-command/last-eol
  ble-bind -f 'f' vi-command/search-forward-char
  ble-bind -f 'F' vi-command/search-backward-char
  ble-bind -f 't' vi-command/search-forward-char-prev
  ble-bind -f 'T' vi-command/search-backward-char-prev
  ble-bind -f ';' vi-command/search-char-repeat
  ble-bind -f ',' vi-command/search-char-reverse-repeat
  ble-bind -f '%' 'vi-command/search-matchpair-or vi-command/percentage-line'
  ble-bind -f 'C-\ C-n' nop
  ble-bind -f ':' vi-command/commandline
  ble-bind -f '/' vi-command/search-forward
  ble-bind -f '?' vi-command/search-backward
  ble-bind -f 'n' vi-command/search-repeat
  ble-bind -f 'N' vi-command/search-reverse-repeat
  ble-bind -f '*' vi-command/search-word-forward
  ble-bind -f '#' vi-command/search-word-backward
  ble-bind -f '`' 'vi-command/goto-mark'
  ble-bind -f \'  'vi-command/goto-mark line'
  ble-bind -c 'C-z' fg
}
function ble/widget/vi_omap/operator-rot13-or-search-backward {
  if [[ $_ble_keymap_vi_opfunc == rot13 ]]; then
    ble/widget/vi-command/operator rot13
  else
    ble/widget/vi-command/search-backward
  fi
}
function ble/widget/vi_omap/switch-visual-mode.impl {
  local new_mode=$1
  local old=$_ble_keymap_vi_opfunc
  [[ $old ]] || return 1
  local new=$old:
  new=${new/:vi_char:/:}
  new=${new/:vi_line:/:}
  new=${new/:vi_block:/:}
  [[ $new_mode ]] && new=$new:$new_mode
  _ble_keymap_vi_opfunc=$new
}
function ble/widget/vi_omap/switch-to-charwise {
  ble/widget/vi_omap/switch-visual-mode.impl vi_char
}
function ble/widget/vi_omap/switch-to-linewise {
  ble/widget/vi_omap/switch-visual-mode.impl vi_line
}
function ble/widget/vi_omap/switch-to-blockwise {
  ble/widget/vi_omap/switch-visual-mode.impl vi_block
}
function ble-decode/keymap:vi_omap/define {
  local ble_bind_keymap=vi_omap
  ble/keymap:vi/setup-map
  ble-bind -f __default__ vi_omap/__default__
  ble-bind -f 'ESC' vi_omap/cancel
  ble-bind -f 'C-[' vi_omap/cancel
  ble-bind -f 'C-c' vi_omap/cancel
  ble-bind -f a   vi-command/text-object
  ble-bind -f i   vi-command/text-object
  ble-bind -f v      vi_omap/switch-to-charwise
  ble-bind -f V      vi_omap/switch-to-linewise
  ble-bind -f C-v    vi_omap/switch-to-blockwise
  ble-bind -f C-q    vi_omap/switch-to-blockwise
  ble-bind -f '~' 'vi-command/operator toggle_case'
  ble-bind -f 'u' 'vi-command/operator u'
  ble-bind -f 'U' 'vi-command/operator U'
  ble-bind -f '?' 'vi_omap/operator-rot13-or-search-backward'
  ble-bind -f 'q' 'vi-command/operator fold'
}
function ble/widget/vi-command/exit-on-empty-line {
  if [[ $_ble_edit_str ]]; then
    ble/widget/vi_nmap/forward-scroll
    return
  else
    ble/widget/exit
    ble/keymap:vi/adjust-command-mode # ジョブがあるときは終了しないので。
    return 1
  fi
}
function ble/widget/vi-command/show-line-info {
  local index count
  ble-edit/history/get-index -v index
  ble-edit/history/get-count -v count
  local hist_ratio=$(((100*index+count-1)/count))%
  local hist_stat=$'!\e[32m'$index$'\e[m / \e[32m'$count$'\e[m (\e[32m'$hist_ratio$'\e[m)'
  local ret
  ble/string#count-char "$_ble_edit_str" $'\n'; local nline=$((ret+1))
  ble/string#count-char "${_ble_edit_str::_ble_edit_ind}" $'\n'; local iline=$((ret+1))
  local line_ratio=$(((100*iline+nline-1)/nline))%
  local line_stat=$'line \e[34m'$iline$'\e[m / \e[34m'$nline$'\e[m --\e[34m'$line_ratio$'\e[m--'
  ble-edit/info/show ansi "\"$hist_stat\" $line_stat"
  ble/keymap:vi/adjust-command-mode
  return 0
}
function ble/widget/vi-command/cancel {
  if [[ $_ble_keymap_vi_single_command ]]; then
    _ble_keymap_vi_single_command=
    _ble_keymap_vi_single_command_overwrite=
    ble/keymap:vi/update-mode-name
  else
    local joblist; ble/util/joblist
    if ((${#joblist[*]})); then
      ble/array#push joblist $'Type  \e[35m:q!\e[m  and press \e[35m<Enter>\e[m to abandon all \e[31mjobs\e[m and exit Bash'
      IFS=$'\n' eval 'ble-edit/info/show ansi "${joblist[*]}"'
    else
      ble-edit/info/show ansi $'Type  \e[35m:q\e[m  and press \e[35m<Enter>\e[m to exit Bash'
    fi
  fi
  ble/widget/vi-command/bell
  return 0
}
bleopt/declare -v keymap_vi_imap_undo ''
_ble_keymap_vi_undo_suppress=
function ble/keymap:vi/undo/add {
  [[ $_ble_keymap_vi_undo_suppress ]] && return
  [[ $1 == more && $bleopt_keymap_vi_imap_undo != more ]] && return
  ble-edit/undo/add
}
function ble/widget/vi_nmap/undo {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local _ble_keymap_vi_undo_suppress=1
  ble/keymap:vi/mark/start-edit-area
  if ble-edit/undo/undo "$ARG"; then
    ble/keymap:vi/needs-eol-fix && ((_ble_edit_ind--))
    ble/keymap:vi/mark/end-edit-area
    ble/keymap:vi/adjust-command-mode
  else
    ble/widget/vi-command/bell
    return 1
  fi
}
function ble/widget/vi_nmap/redo {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local _ble_keymap_vi_undo_suppress=1
  ble/keymap:vi/mark/start-edit-area
  if ble-edit/undo/redo "$ARG"; then
    ble/keymap:vi/needs-eol-fix && ((_ble_edit_ind--))
    ble/keymap:vi/mark/end-edit-area
    ble/keymap:vi/adjust-command-mode
  else
    ble/widget/vi-command/bell
    return 1
  fi
}
function ble/widget/vi_nmap/revert {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local _ble_keymap_vi_undo_suppress=1
  ble/keymap:vi/mark/start-edit-area
  if ble-edit/undo/revert-toggle "$ARG"; then
    ble/keymap:vi/needs-eol-fix && ((_ble_edit_ind--))
    ble/keymap:vi/mark/end-edit-area
    ble/keymap:vi/adjust-command-mode
  else
    ble/widget/vi-command/bell
    return 1
  fi
}
function ble/widget/vi_nmap/increment.impl {
  local delta=$1
  ((delta==0)) && return 0
  local line=${_ble_edit_str:_ble_edit_ind}
  line=${line%%$'\n'*}
  local rex='^([^0-9]*)[0-9]+'
  if ! [[ $line =~ $rex ]]; then
    [[ $line ]] && ble/widget/.bell 'number not found'
    ble/keymap:vi/adjust-command-mode
    return 0
  fi
  local rematch1=${BASH_REMATCH[1]}
  local beg=$((_ble_edit_ind+${#rematch1}))
  local end=$((_ble_edit_ind+${#BASH_REMATCH}))
  rex='-?[0-9]*$'; [[ ${_ble_edit_str::beg} =~ $rex ]]
  ((beg-=${#BASH_REMATCH}))
  local number=${_ble_edit_str:beg:end-beg}
  local abs=${number#-}
  if [[ $abs == 0?* ]]; then
    if [[ $number == -* ]]; then
      number=-$((10#$abs))
    else
      number=$((10#$abs))
    fi
  fi
  ((number+=delta))
  if [[ $abs == 0?* ]]; then
    local wsign=$((number<0?1:0))
    local zpad=$((wsign+${#abs}-${#number}))
    if ((zpad>0)); then
      local ret; ble/string#repeat 0 "$zpad"
      number=${number::wsign}$ret${number:wsign}
    fi
  fi
  ble/widget/.replace-range "$beg" "$end" "$number" 1
  ble/keymap:vi/mark/set-previous-edit-area "$beg" $((beg+${#number}))
  ble/keymap:vi/repeat/record
  _ble_edit_ind=$((beg+${#number}-1))
  ble/keymap:vi/adjust-command-mode
  return 0
}
function ble/widget/vi_nmap/increment {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi_nmap/increment.impl "$ARG"
}
function ble/widget/vi_nmap/decrement {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vi_nmap/increment.impl $((-ARG))
}
function ble-decode/keymap:vi_nmap/define {
  local ble_bind_keymap=vi_nmap
  ble/keymap:vi/setup-map
  ble-bind -f __default__ vi-command/decompose-meta
  ble-bind -f 'ESC' vi-command/bell
  ble-bind -f 'C-[' vi-command/bell
  ble-bind -f 'C-c' vi-command/cancel
  ble-bind -f a      vi_nmap/append-mode
  ble-bind -f A      vi_nmap/append-mode-at-end-of-line
  ble-bind -f i      vi_nmap/insert-mode
  ble-bind -f insert vi_nmap/insert-mode
  ble-bind -f I      vi_nmap/insert-mode-at-first-non-space
  ble-bind -f 'g I'  vi_nmap/insert-mode-at-beginning-of-line
  ble-bind -f o      vi_nmap/insert-mode-at-forward-line
  ble-bind -f O      vi_nmap/insert-mode-at-backward-line
  ble-bind -f R      vi_nmap/replace-mode
  ble-bind -f 'g R'  vi_nmap/virtual-replace-mode
  ble-bind -f 'g i'  vi_nmap/insert-mode-at-previous-point
  ble-bind -f '~'    vi_nmap/forward-char-toggle-case
  ble-bind -f Y      vi_nmap/copy-current-line
  ble-bind -f S      vi_nmap/kill-current-line-and-insert
  ble-bind -f D      vi_nmap/kill-forward-line
  ble-bind -f C      vi_nmap/kill-forward-line-and-insert
  ble-bind -f p      vi_nmap/paste-after
  ble-bind -f P      vi_nmap/paste-before
  ble-bind -f x      vi_nmap/kill-forward-char
  ble-bind -f s      vi_nmap/kill-forward-char-and-insert
  ble-bind -f X      vi_nmap/kill-backward-char
  ble-bind -f delete vi_nmap/kill-forward-char
  ble-bind -f 'r'    vi_nmap/replace-char
  ble-bind -f 'g r'  vi_nmap/virtual-replace-char # vim で実際に試すとこの機能はない
  ble-bind -f J      vi_nmap/connect-line-with-space
  ble-bind -f 'g J'  vi_nmap/connect-line
  ble-bind -f v      vi_nmap/charwise-visual-mode
  ble-bind -f V      vi_nmap/linewise-visual-mode
  ble-bind -f C-v    vi_nmap/blockwise-visual-mode
  ble-bind -f C-q    vi_nmap/blockwise-visual-mode
  ble-bind -f 'g v'  vi-command/previous-visual-area
  ble-bind -f 'g h'    vi_nmap/charwise-select-mode
  ble-bind -f 'g H'    vi_nmap/linewise-select-mode
  ble-bind -f 'g C-h'  vi_nmap/blockwise-select-mode
  ble-bind -f .      vi_nmap/repeat
  ble-bind -f K      vi_nmap/command-help
  ble-bind -f f1     vi_nmap/command-help
  ble-bind -f 'C-d'   vi_nmap/forward-line-scroll
  ble-bind -f 'C-u'   vi_nmap/backward-line-scroll
  ble-bind -f 'C-e'   vi_nmap/forward-scroll
  ble-bind -f 'C-y'   vi_nmap/backward-scroll
  ble-bind -f 'C-f'   vi_nmap/pagedown
  ble-bind -f 'next'  vi_nmap/pagedown
  ble-bind -f 'C-b'   vi_nmap/pageup
  ble-bind -f 'prior' vi_nmap/pageup
  ble-bind -f 'z t'   vi_nmap/scroll-to-top-and-redraw
  ble-bind -f 'z z'   vi_nmap/scroll-to-center-and-redraw
  ble-bind -f 'z b'   vi_nmap/scroll-to-bottom-and-redraw
  ble-bind -f 'z RET' vi_nmap/scroll-to-top-non-space-and-redraw
  ble-bind -f 'z C-m' vi_nmap/scroll-to-top-non-space-and-redraw
  ble-bind -f 'z +'   vi_nmap/scroll-or-pagedown-and-redraw
  ble-bind -f 'z -'   vi_nmap/scroll-to-bottom-non-space-and-redraw
  ble-bind -f 'z .'   vi_nmap/scroll-to-center-non-space-and-redraw
  ble-bind -f m      vi-command/set-mark
  ble-bind -f '"'    vi-command/register
  ble-bind -f 'C-g' vi-command/show-line-info
  ble-bind -f 'q' vi_nmap/record-register
  ble-bind -f '@' vi_nmap/play-register
  ble-bind -f u   vi_nmap/undo
  ble-bind -f C-r vi_nmap/redo
  ble-bind -f U   vi_nmap/revert
  ble-bind -f C-a vi_nmap/increment
  ble-bind -f C-x vi_nmap/decrement
  ble-bind -f 'Z Z' 'vi-command:q'
  ble-bind -f 'Z Q' 'vi-command:q'
  ble-bind -f 'C-j'   'vi-command/accept-line'
  ble-bind -f 'C-RET' 'vi-command/accept-line'
  ble-bind -f 'C-m'   'vi-command/accept-single-line-or vi-command/forward-first-non-space'
  ble-bind -f 'RET'   'vi-command/accept-single-line-or vi-command/forward-first-non-space'
  ble-bind -f 'C-l'   'clear-screen'
  ble-bind -f 'C-d'   'vi-command/exit-on-empty-line' # overwrites vi_nmap/forward-scroll
  ble-bind -f 'auto_complete_enter' auto-complete-enter
}
function ble/widget/vi-rlfunc/delete-to {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  if ((0x41<=code&&code<=0x5a)); then
    ble/widget/vi_nmap/kill-forward-line
  else
    ble/widget/vi-command/operator d
  fi
}
function ble/widget/vi-rlfunc/change-to {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  if ((0x41<=code&&code<=0x5a)); then
    ble/widget/vi_nmap/kill-forward-line-and-insert
  else
    ble/widget/vi-command/operator c
  fi
}
function ble/widget/vi-rlfunc/yank-to {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  if ((0x41<=code&&code<=0x5a)); then
    ble/widget/vi_nmap/copy-current-line
  else
    ble/widget/vi-command/operator y
  fi
}
function ble/widget/vi-rlfunc/char-search {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  ((code==0)) && return 1
  ble/util/c2s "$code"
  case $ret in
  ('f') ble/widget/vi-command/search-forward-char ;;
  ('F') ble/widget/vi-command/search-backward-char ;;
  ('t') ble/widget/vi-command/search-forward-char-prev ;;
  ('T') ble/widget/vi-command/search-backward-char-prev ;;
  (';') ble/widget/vi-command/search-char-repeat ;;
  (',') ble/widget/vi-command/search-char-reverse-repeat ;;
  (*) return 1 ;;
  esac
}
function ble/widget/vi-rlfunc/next-word {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  if ((0x41<=code&&code<=0x5a)); then
    ble/widget/vi-command/forward-uword
  else
    ble/widget/vi-command/forward-vword
  fi
}
function ble/widget/vi-rlfunc/prev-word {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  if ((0x41<=code&&code<=0x5a)); then
    ble/widget/vi-command/backward-uword
  else
    ble/widget/vi-command/backward-vword
  fi
}
function ble/widget/vi-rlfunc/end-word {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  if ((0x41<=code&&code<=0x5a)); then
    ble/widget/vi-command/forward-uword-end
  else
    ble/widget/vi-command/forward-vword-end
  fi
}
function ble/widget/vi-rlfunc/put {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  if ((0x41<=code&&code<=0x5a)); then
    ble/widget/vi_nmap/paste-before
  else
    ble/widget/vi_nmap/paste-after
  fi
}
function ble/widget/vi-rlfunc/search {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  if ((code==63)); then
    ble/widget/vi-command/search-backward
  else
    ble/widget/vi-command/search-forward
  fi
}
function ble/widget/vi-rlfunc/search-again {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  if ((0x41<=code&&code<=0x5a)); then
    ble/widget/vi-command/search-reverse-repeat
  else
    ble/widget/vi-command/search-repeat
  fi
}
function ble/widget/vi-rlfunc/subst {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  if ((0x41<=code&&code<=0x5a)); then
    ble/widget/vi_nmap/kill-current-line-and-insert
  else
    ble/widget/vi_nmap/kill-forward-char-and-insert
  fi
}
function ble/keymap:vi/xmap/has-eol-extension {
  [[ $_ble_edit_mark_active == *+ ]]
}
function ble/keymap:vi/xmap/add-eol-extension {
  [[ $_ble_edit_mark_active ]] &&
    _ble_edit_mark_active=${_ble_edit_mark_active%+}+
}
function ble/keymap:vi/xmap/remove-eol-extension {
  [[ $_ble_edit_mark_active ]] &&
    _ble_edit_mark_active=${_ble_edit_mark_active%+}
}
function ble/keymap:vi/xmap/switch-type {
  local suffix; [[ $_ble_edit_mark_active == *+ ]] && suffix=+
  _ble_edit_mark_active=$1$suffix
}
function ble/keymap:vi/get-graphical-rectangle {
  local p=${1:-$_ble_edit_mark} q=${2:-$_ble_edit_ind}
  local ret
  ble-edit/content/find-logical-bol "$p"; p0=$ret
  ble-edit/content/find-logical-bol "$q"; q0=$ret
  local p0x p0y q0x q0y
  ble/textmap#getxy.out --prefix=p0 "$p0"
  ble/textmap#getxy.out --prefix=q0 "$q0"
  local plx ply qlx qly
  ble/textmap#getxy.cur --prefix=pl "$p"
  ble/textmap#getxy.cur --prefix=ql "$q"
  local prx=$plx pry=$ply qrx=$qlx qry=$qly
  ble-edit/content/eolp "$p" && ((prx++)) || ble/textmap#getxy.out --prefix=pr $((p+1))
  ble-edit/content/eolp "$q" && ((qrx++)) || ble/textmap#getxy.out --prefix=qr $((q+1))
  ((ply-=p0y,qly-=q0y,pry-=p0y,qry-=q0y,
    (ply<qly||ply==qly&&plx<qlx)?(lx=plx,ly=ply):(lx=qlx,ly=qly),
    (pry>qry||pry==qry&&prx>qrx)?(rx=prx,ry=pry):(rx=qrx,ry=qry)))
}
function ble/keymap:vi/get-logical-rectangle {
  local p=${1:-$_ble_edit_mark} q=${2:-$_ble_edit_ind}
  local ret
  ble-edit/content/find-logical-bol "$p"; p0=$ret
  ble-edit/content/find-logical-bol "$q"; q0=$ret
  ((p-=p0,q-=q0,p<=q)) || local p=$q q=$p
  lx=$p rx=$((q+1)) ly=0 ry=0
}
function ble/keymap:vi/get-rectangle {
  if ble/edit/use-textmap; then
    ble/keymap:vi/get-graphical-rectangle "$@"
  else
    ble/keymap:vi/get-logical-rectangle "$@"
  fi
}
function ble/keymap:vi/get-rectangle-height {
  local p0 q0 lx ly rx ry
  ble/keymap:vi/get-rectangle "$@"
  ble/string#count-char "${_ble_edit_str:p0:q0-p0}" $'\n'
  ((ret++))
  return 0
}
function ble/keymap:vi/extract-graphical-block-by-geometry {
  local bol1=$1 bol2=$2 x1=$3 x2=$4 y1=0 y2=0 opts=$5
  ((bol1<=bol2||(bol1=$2,bol2=$1)))
  [[ $x1 == *:* ]] && local x1=${x1%%:*} y1=${x1#*:}
  [[ $x2 == *:* ]] && local x2=${x2%%:*} y2=${x2#*:}
  local cols=$_ble_textmap_cols
  local c1=$((cols*y1+x1)) c2=$((cols*y2+x2))
  sub_x1=$c1 sub_x2=$c2
  local ret index lx ly rx ly
  ble-edit/content/find-logical-eol "$bol2"; local eol2=$ret
  local lines; ble/string#split-lines lines "${_ble_edit_str:bol1:eol2-bol1}"
  sub_ranges=()
  local min_sfill=0
  local line bol=$bol1 eol bolx boly
  local c1l c1r c2l c2r
  for line in "${lines[@]}"; do
    ((eol=bol+${#line}))
    if [[ :$opts: == *:first_line:* ]] && ((${#sub_ranges[@]})); then
      ble/array#push sub_ranges :::::
    elif [[ :$opts: == *:skip_middle:* ]] && ((0<${#sub_ranges[@]}&&${#sub_ranges[@]}<${#lines[@]}-1)); then
      ble/array#push sub_ranges :::::
    else
      ble/textmap#getxy.out --prefix=bol "$bol"
      ble/textmap#hit out "$x1" $((boly+y1)) "$bol" "$eol"
      local smin=$index x1l=$lx y1l=$ly x1r=$rx y1r=$ry
      if ble/keymap:vi/xmap/has-eol-extension; then
        local eolx eoly; ble/textmap#getxy.out --prefix=eol "$eol"
        local smax=$eol x2l=$eolx y2l=$eoly x2r=$eolx y2r=$eoly
      else
        ble/textmap#hit out "$x2" $((boly+y2)) "$bol" "$eol"
        local smax=$index x2l=$lx y2l=$ly x2r=$rx y2r=$ry
      fi
      local sfill=0 slpad=0 srpad=0
      local stext=${_ble_edit_str:smin:smax-smin}
      if ((smin<smax)); then
        ((c1l=(y1l-boly)*cols+x1l))
        if ((c1l<c1)); then
          ((slpad=c1-c1l))
          ble/util/assert '! ble-edit/content/eolp "$smin"'
          ((c1r=(y1r-boly)*cols+x1r))
          ble/util/assert '((c1r>c1))' || ((c1r=c1))
          ble/string#repeat ' ' $((c1r-c1))
          stext=$ret${stext:1}
        fi
        ((c2l=(y2l-boly)*cols+x2l))
        if ((c2l<c2)); then
          if ((smax==eol)); then
            ((sfill=c2-c2l))
          else
            ble/string#repeat ' ' $((c2-c2l))
            stext=$stext$ret
            ((smax++))
            ((c2r=(y2r-boly)*cols+x2r))
            ble/util/assert '((c2r>c2))' || ((c2r=c2))
            ((srpad=c2r-c2))
          fi
        elif ((c2l>c2)); then
          ((sfill=c2-c2l,
            sfill<min_sfill&&(min_sfill=sfill)))
        fi
      else
        if ((smin==eol)); then
          ((sfill=c2-c1))
        elif ((c2>c1)); then
          ble/string#repeat ' ' $((c2-c1))
          stext=$ret${stext:1}
          ((smax++))
          ((c1l=(y1l-boly)*cols+x1l,slpad=c1-c1l))
          ((c1r=(y1r-boly)*cols+x1r,srpad=c1r-c1))
        fi
      fi
      ble/array#push sub_ranges "$smin:$smax:$slpad:$srpad:$sfill:$stext"
    fi
    ((bol=eol+1))
  done
  if ((min_sfill<0)); then
    local isub=${#sub_ranges[@]}
    while ((isub--)); do
      local sub=${sub_ranges[isub]}
      local sub45=${sub#*:*:*:*:}
      local sfill=${sub45%%:*}
      sub_ranges[isub]=${sub::${#sub}-${#sub45}}$((sfill-min_sfill))${sub45:${#sfill}}
    done
  fi
}
function ble/keymap:vi/extract-graphical-block {
  local opts=$3
  local p0 q0 lx ly rx ry
  ble/keymap:vi/get-graphical-rectangle "$@"
  ble/keymap:vi/extract-graphical-block-by-geometry "$p0" "$q0" "$lx:$ly" "$rx:$ry" "$opts"
}
function ble/keymap:vi/extract-logical-block-by-geometry {
  local bol1=$1 bol2=$2 x1=$3 x2=$4 opts=$5
  ((bol1<=bol2||(bol1=$2,bol2=$1)))
  sub_x1=$c1 sub_x2=$c2
  local ret min_sfill=0
  local bol=$bol1 eol smin smax slpad srpad sfill
  sub_ranges=()
  while :; do
    ble-edit/content/find-logical-eol "$bol"; eol=$ret
    slpad=0 srpad=0 sfill=0
    ((smin=bol+x1,smin>eol&&(smin=eol)))
    if ble/keymap:vi/xmap/has-eol-extension; then
      ((smax=eol,
        sfill=bol+x2-eol,
        sfill<min_sfill&&(min_sfill=sfill)))
    else
      ((smax=bol+x2,smax>eol&&(sfill=smax-eol,smax=eol)))
    fi
    local stext=${_ble_edit_str:smin:smax-smin}
    ble/array#push sub_ranges "$smin:$smax:$slpad:$srpad:$sfill:$stext"
    ((bol>=bol2)) && break
    ble-edit/content/find-logical-bol "$bol" 1; bol=$ret
  done
  if ((min_sfill<0)); then
    local isub=${#sub_ranges[@]}
    while ((isub--)); do
      local sub=${sub_ranges[isub]}
      local sub45=${sub#*:*:*:*:}
      local sfill=${sub45%%:*}
      sub_ranges[isub]=${sub::${#sub}-${#sub45}}$((sfill-min_sfill))${sub45:${#sfill}}
    done
  fi
}
function ble/keymap:vi/extract-logical-block {
  local opts=$3
  local p0 q0 lx ly rx ry
  ble/keymap:vi/get-logical-rectangle "$@"
  ble/keymap:vi/extract-logical-block-by-geometry "$p0" "$q0" "$lx" "$rx" "$opts"
}
function ble/keymap:vi/extract-block {
  if ble/edit/use-textmap; then
    ble/keymap:vi/extract-graphical-block "$@"
  else
    ble/keymap:vi/extract-logical-block "$@"
  fi
}
function ble/highlight/layer:region/mark:vi_char/get-selection {
  local rmin rmax
  if ((_ble_edit_mark<_ble_edit_ind)); then
    rmin=$_ble_edit_mark rmax=$_ble_edit_ind
  else
    rmin=$_ble_edit_ind rmax=$_ble_edit_mark
  fi
  ble-edit/content/eolp "$rmax" || ((rmax++))
  selection=("$rmin" "$rmax")
}
function ble/highlight/layer:region/mark:vi_line/get-selection {
  local rmin rmax
  if ((_ble_edit_mark<_ble_edit_ind)); then
    rmin=$_ble_edit_mark rmax=$_ble_edit_ind
  else
    rmin=$_ble_edit_ind rmax=$_ble_edit_mark
  fi
  local ret
  ble-edit/content/find-logical-bol "$rmin"; rmin=$ret
  ble-edit/content/find-logical-eol "$rmax"; rmax=$ret
  selection=("$rmin" "$rmax")
}
function ble/highlight/layer:region/mark:vi_block/get-selection {
  local sub_ranges sub_x1 sub_x2
  ble/keymap:vi/extract-block
  selection=()
  local sub
  for sub in "${sub_ranges[@]}"; do
    ble/string#split sub : "$sub"
    ((sub[0]<sub[1])) || continue
    ble/array#push selection "${sub[0]}" "${sub[1]}"
  done
}
function ble/highlight/layer:region/mark:vi_char+/get-selection {
  ble/highlight/layer:region/mark:vi_char/get-selection
}
function ble/highlight/layer:region/mark:vi_line+/get-selection {
  ble/highlight/layer:region/mark:vi_line/get-selection
}
function ble/highlight/layer:region/mark:vi_block+/get-selection {
  ble/highlight/layer:region/mark:vi_block/get-selection
}
function ble/highlight/layer:region/mark:vi_char/get-face   { [[ $_ble_edit_overwrite_mode ]] && face=region_target; }
function ble/highlight/layer:region/mark:vi_char+/get-face  { ble/highlight/layer:region/mark:vi_char/get-face; }
function ble/highlight/layer:region/mark:vi_line/get-face   { ble/highlight/layer:region/mark:vi_char/get-face; }
function ble/highlight/layer:region/mark:vi_line+/get-face  { ble/highlight/layer:region/mark:vi_char/get-face; }
function ble/highlight/layer:region/mark:vi_block/get-face  { ble/highlight/layer:region/mark:vi_char/get-face; }
function ble/highlight/layer:region/mark:vi_block+/get-face { ble/highlight/layer:region/mark:vi_char/get-face; }
_ble_keymap_vi_xmap_prev_edit=vi_char:1:1
function ble/widget/vi_xmap/.save-visual-state {
  local nline nchar mark_type=${_ble_edit_mark_active%+}
  if [[ $mark_type == vi_block ]]; then
    local p0 q0 lx rx ly ry
    if ble/edit/use-textmap; then
      local cols=$_ble_textmap_cols
      ble/keymap:vi/get-graphical-rectangle
      ((lx+=ly*cols,rx+=ry*cols))
    else
      ble/keymap:vi/get-logical-rectangle
    fi
    nchar=$((rx-lx))
    local ret
    ((p0<=q0)) || local p0=$q0 q0=$p0
    ble/string#count-char "${_ble_edit_str:p0:q0-p0}" $'\n'
    nline=$((ret+1))
  else
    local ret
    local p=$_ble_edit_mark q=$_ble_edit_ind
    ((p<=q)) || local p=$q q=$p
    ble/string#count-char "${_ble_edit_str:p:q-p}" $'\n'
    nline=$((ret+1))
    local base
    if ((nline==1)) && [[ $mark_type != vi_line ]]; then
      base=$p
    else
      ble-edit/content/find-logical-bol "$q"; base=$ret
    fi
    if ble/edit/use-textmap; then
      local cols=$_ble_textmap_cols
      local bx by x y
      ble/textmap#getxy.cur --prefix=b "$base"
      ble/textmap#getxy.cur "$q"
      nchar=$((x-bx+(y-by)*cols+1))
    else
      nchar=$((q-base+1))
    fi
  fi
  _ble_keymap_vi_xmap_prev_edit=$_ble_edit_mark_active:$nchar:$nline
}
function ble/widget/vi_xmap/.restore-visual-state {
  local arg=$1; ((arg>0)) || arg=1
  local prev; ble/string#split prev : "$_ble_keymap_vi_xmap_prev_edit"
  _ble_edit_mark_active=${prev[0]:-vi_char}
  local nchar=${prev[1]:-1}
  local nline=${prev[2]:-1}
  ((nchar<1&&(nchar=1),nline<1&&(nline=1)))
  local is_x_relative=0
  if [[ ${_ble_edit_mark_active%+} == vi_block ]]; then
    ((is_x_relative=1,nchar*=arg,nline*=arg))
  elif [[ ${_ble_edit_mark_active%+} == vi_line ]]; then
    ((nline*=arg,is_x_relative=1,nchar=1))
  else
    ((nline==1?(is_x_relative=1,nchar*=arg):(nline*=arg)))
  fi
  ((nchar--,nline--))
  local index ret
  ble-edit/content/find-logical-bol "$_ble_edit_ind" 0; local b1=$ret
  ble-edit/content/find-logical-bol "$_ble_edit_ind" "$nline"; local b2=$ret
  ble-edit/content/find-logical-eol "$b2"; local e2=$ret
  if ble/keymap:vi/xmap/has-eol-extension; then
    index=$e2
  elif ble/edit/use-textmap; then
    local cols=$_ble_textmap_cols
    local b1x b1y b2x b2y x y
    ble/textmap#getxy.out --prefix=b1 "$b1"
    ble/textmap#getxy.out --prefix=b2 "$b2"
    if ((is_x_relative)); then
      ble/textmap#getxy.out "$_ble_edit_ind"
      local c=$((x+(y-b1y)*cols+nchar))
    else
      local c=$nchar
    fi
    ((y=c/cols,x=c%cols))
    local lx ly rx ry
    ble/textmap#hit out "$x" $((b2y+y)) "$b2" "$e2"
  else
    local c=$((is_x_relative?_ble_edit_ind-b1+nchar:nchar))
    ((index=b2+c,index>e2&&(index=e2)))
  fi
  _ble_edit_mark=$_ble_edit_ind
  _ble_edit_ind=$index
}
_ble_keymap_vi_xmap_prev_visual=
function ble/keymap:vi/xmap/set-previous-visual-area {
  local beg end
  local mark_type=${_ble_edit_mark_active%+}
  if [[ $mark_type == vi_block ]]; then
    local sub_ranges sub_x1 sub_x2
    ble/keymap:vi/extract-block
    local nrange=${#sub_ranges[*]}
    ((nrange)) || return
    local beg=${sub_ranges[0]%%:*}
    local sub2_slice1=${sub_ranges[nrange-1]#*:}
    local end=${sub2_slice1%%:*}
    ((beg<end)) && ! ble-edit/content/bolp "$end" && ((end--))
  else
    local beg=$_ble_edit_mark end=$_ble_edit_ind
    ((beg<=end)) || local beg=$end end=$beg
    if [[ $mark_type == vi_line ]]; then
      local ret
      ble-edit/content/find-logical-bol "$beg"; beg=$ret
      ble-edit/content/find-logical-eol "$end"; end=$ret
      ble-edit/content/bolp "$end" || ((end--))
    fi
  fi
  _ble_keymap_vi_xmap_prev_visual=$_ble_edit_mark_active
  ble/keymap:vi/mark/set-local-mark 60 "$beg" # `<
  ble/keymap:vi/mark/set-local-mark 62 "$end" # `>
}
function ble/widget/vi-command/previous-visual-area {
  local mark=$_ble_keymap_vi_xmap_prev_visual
  local ret beg= end=
  ble/keymap:vi/mark/get-local-mark 60 && beg=$ret # `<
  ble/keymap:vi/mark/get-local-mark 62 && end=$ret # `>
  [[ $beg && $end ]] || return 1
  if [[ $_ble_decode_keymap == vi_[xs]map ]]; then
    ble/keymap:vi/clear-arg
    ble/keymap:vi/xmap/set-previous-visual-area
    _ble_edit_ind=$end
    _ble_edit_mark=$beg
    _ble_edit_mark_active=$mark
    ble/keymap:vi/update-mode-name
  else
    ble/keymap:vi/clear-arg
    ble/widget/vi-command/visual-mode.impl vi_xmap "$mark"
    _ble_edit_ind=$end
    _ble_edit_mark=$beg
  fi
  return 0
}
function ble/widget/vi-command/visual-mode.impl {
  local keymap=$1 visual_type=$2
  local ARG FLAG REG; ble/keymap:vi/get-arg 0
  if [[ $FLAG ]]; then
    ble/widget/vi-command/bell
    return 1
  fi
  _ble_edit_overwrite_mode=
  _ble_edit_mark=$_ble_edit_ind
  _ble_edit_mark_active=$visual_type
  _ble_keymap_vi_xmap_insert_data= # ※矩形挿入の途中で更に xmap に入ったときはキャンセル
  ((ARG)) && ble/widget/vi_xmap/.restore-visual-state "$ARG"
  ble-decode/keymap/push "$keymap"
  ble/keymap:vi/update-mode-name
  return 0
}
function ble/widget/vi_nmap/charwise-visual-mode {
  ble/widget/vi-command/visual-mode.impl vi_xmap vi_char
}
function ble/widget/vi_nmap/linewise-visual-mode {
  ble/widget/vi-command/visual-mode.impl vi_xmap vi_line
}
function ble/widget/vi_nmap/blockwise-visual-mode {
  ble/widget/vi-command/visual-mode.impl vi_xmap vi_block
}
function ble/widget/vi_nmap/charwise-select-mode {
  ble/widget/vi-command/visual-mode.impl vi_smap vi_char
}
function ble/widget/vi_nmap/linewise-select-mode {
  ble/widget/vi-command/visual-mode.impl vi_smap vi_line
}
function ble/widget/vi_nmap/blockwise-select-mode {
  ble/widget/vi-command/visual-mode.impl vi_smap vi_block
}
function ble/widget/vi_xmap/exit {
  if [[ $_ble_decode_keymap == vi_[xs]map ]]; then
    ble/keymap:vi/xmap/set-previous-visual-area
    _ble_edit_mark_active=
    ble-decode/keymap/pop
    ble/keymap:vi/update-mode-name
    ble/keymap:vi/adjust-command-mode
  fi
  return 0
}
function ble/widget/vi_xmap/cancel {
  _ble_keymap_vi_single_command=
  _ble_keymap_vi_single_command_overwrite=
  ble-edit/content/nonbol-eolp && ((_ble_edit_ind--))
  ble/widget/vi_xmap/exit
}
function ble/widget/vi_xmap/switch-visual-mode.impl {
  local visual_type=$1
  local ARG FLAG REG; ble/keymap:vi/get-arg 0
  if [[ $FLAG ]]; then
    ble/widget/.bell
    return 1
  fi
  if [[ ${_ble_edit_mark_active%+} == "$visual_type" ]]; then
    ble/widget/vi_xmap/cancel
  else
    ble/keymap:vi/xmap/switch-type "$visual_type"
    ble/keymap:vi/update-mode-name
    return 0
  fi
}
function ble/widget/vi_xmap/switch-to-charwise {
  ble/widget/vi_xmap/switch-visual-mode.impl vi_char
}
function ble/widget/vi_xmap/switch-to-linewise {
  ble/widget/vi_xmap/switch-visual-mode.impl vi_line
}
function ble/widget/vi_xmap/switch-to-blockwise {
  ble/widget/vi_xmap/switch-visual-mode.impl vi_block
}
function ble/widget/vi_xmap/switch-to-select {
  if [[ $_ble_decode_keymap == vi_xmap ]]; then
    ble-decode/keymap/pop
    ble-decode/keymap/push vi_smap
    ble/keymap:vi/update-mode-name
  fi
}
function ble/widget/vi_xmap/switch-to-visual {
  if [[ $_ble_decode_keymap == vi_smap ]]; then
    ble-decode/keymap/pop
    ble-decode/keymap/push vi_xmap
    ble/keymap:vi/update-mode-name
  fi
}
function ble/widget/vi_xmap/switch-to-visual-blockwise {
  if [[ $_ble_decode_keymap == vi_smap ]]; then
    ble-decode/keymap/pop
    ble-decode/keymap/push vi_xmap
  fi
  if [[ ${_ble_edit_mark_active%+} != vi_block ]]; then
    ble/widget/vi_xmap/switch-to-blockwise
  else
    xble/keymap:vi/update-mode-name
  fi
}
bleopt/declare -v keymap_vi_keymodel ''
function ble/widget/vi_smap/@nomarked {
  [[ ,$bleopt_keymap_vi_keymodel, == *,stopsel,* ]] &&
    ble/widget/vi_xmap/exit
  ble/widget/"$@"
}
function ble/widget/vi_smap/self-insert {
  ble/widget/vi-command/operator c
  ble/widget/self-insert
}
function ble/widget/vi_xmap/exchange-points {
  ble/keymap:vi/xmap/remove-eol-extension
  ble/widget/exchange-point-and-mark
  return 0
}
function ble/widget/vi_xmap/exchange-boundaries {
  if [[ ${_ble_edit_mark_active%+} == vi_block ]]; then
    ble/keymap:vi/xmap/remove-eol-extension
    local sub_ranges sub_x1 sub_x2
    ble/keymap:vi/extract-block '' '' skip_middle
    local nline=${#sub_ranges[@]}
    ble/util/assert '((nline))'
    local data1; ble/string#split data1 : "${sub_ranges[0]}"
    local lpos1=${data1[0]} rpos1=$((data1[4]?data1[1]:data1[1]-1))
    if ((nline==1)); then
      local lpos2=$lpos1 rpos2=$rpos1
    else
      local data2; ble/string#split data2 : "${sub_ranges[nline-1]}"
      local lpos2=${data2[0]} rpos2=$((data2[4]?data2[1]:data2[1]-1))
    fi
    if ! ((lpos2<=_ble_edit_ind&&_ble_edit_ind<=rpos2)); then
      local lpos1=$lpos2 lpos2=$lpos1
      local rpos1=$rpos2 rpos2=$rpos1
    fi
    _ble_edit_mark=$((_ble_edit_mark==lpos1?rpos1:lpos1))
    _ble_edit_ind=$((_ble_edit_ind==lpos2?rpos2:lpos2))
    return 0
  else
    ble/widget/vi_xmap/exchange-points
  fi
}
function ble/widget/vi_xmap/visual-replace-char.hook {
  local key=$1
  _ble_edit_overwrite_mode=
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local ret
  if [[ $FLAG ]]; then
    ble/widget/.bell
    return 1
  elif ((key==(_ble_decode_Ctrl|91))); then # C-[ -> cancel
    return 27
  elif ! ble/keymap:vi/k2c "$key"; then
    ble/widget/.bell
    return 1
  fi
  local c=$ret
  ble/util/c2s "$c"; local s=$ret
  local old_mark_active=$_ble_edit_mark_active # save
  local mark_type=${_ble_edit_mark_active%+}
  ble/widget/vi_xmap/.save-visual-state
  ble/widget/vi_xmap/exit # Note: _ble_edit_mark_active will be cleared here
  if [[ $mark_type == vi_block ]]; then
    ble/util/c2w "$c"; local w=$ret
    ((w<=0)) && w=1
    local sub_ranges sub_x1 sub_x2
    _ble_edit_mark_active=$old_mark_active ble/keymap:vi/extract-block
    local n=${#sub_ranges[@]}
    if ((n==0)); then
      ble/widget/.bell
      return 1
    fi
    local width=$((sub_x2-sub_x1))
    local count=$((width/w))
    ble/string#repeat "$s" "$count"; local ins=$ret
    local pad=$((width-count*w))
    if ((pad)); then
      ble/string#repeat ' ' "$pad"; ins=$ins$ret
    fi
    local i=$n sub smin=0
    ble/keymap:vi/mark/start-edit-area
    while ((i--)); do
      ble/string#split sub : "${sub_ranges[i]}"
      local smin=${sub[0]} smax=${sub[1]}
      local slpad=${sub[2]} srpad=${sub[3]} sfill=${sub[4]}
      local ins1=$ins
      ((sfill)) && ins1=${ins1::(width-sfill)/w}
      ((slpad)) && { ble/string#repeat ' ' "$slpad"; ins1=$ret$ins1; }
      ((srpad)) && { ble/string#repeat ' ' "$srpad"; ins1=$ins1$ret; }
      ble/widget/.replace-range "$smin" "$smax" "$ins1" 1
    done
    local beg=$smin
    ble/keymap:vi/needs-eol-fix "$beg" && ((beg--))
    _ble_edit_ind=$beg
    ble/keymap:vi/mark/end-edit-area
    ble/keymap:vi/repeat/record
  else
    local beg=$_ble_edit_mark end=$_ble_edit_ind
    ((beg<=end)) || local beg=$end end=$beg
    if [[ $mark_type == vi_line ]]; then
      ble-edit/content/find-logical-bol "$beg"; local beg=$ret
      ble-edit/content/find-logical-eol "$end"; local end=$ret
    else
      ble-edit/content/eolp "$end" || ((end++))
    fi
    local ins=${_ble_edit_str:beg:end-beg}
    ins=${ins//[!$'\n']/"$s"}
    ble/widget/.replace-range "$beg" "$end" "$ins" 1
    ble/keymap:vi/needs-eol-fix "$beg" && ((beg--))
    _ble_edit_ind=$beg
    ble/keymap:vi/mark/set-previous-edit-area "$beg" "$end"
    ble/keymap:vi/repeat/record
  fi
  return 0
}
function ble/widget/vi_xmap/visual-replace-char {
  _ble_edit_overwrite_mode=R
  ble/keymap:vi/async-read-char ble/widget/vi_xmap/visual-replace-char.hook
}
function ble/widget/vi_xmap/linewise-operator.impl {
  local op=$1 opts=$2
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  if [[ $FLAG ]]; then
    ble/widget/.bell 'wrong keymap: xmap ではオペレータは設定されないはず'
    return 1
  fi
  local mark_type=${_ble_edit_mark_active%+}
  local beg=$_ble_edit_mark end=$_ble_edit_ind
  ((beg<=end)) || local beg=$end end=$beg
  local call_operator=
  if [[ :$opts: != *:force_line:* && $mark_type == vi_block ]]; then
    call_operator=ble/keymap:vi/call-operator-blockwise
    _ble_edit_mark_active=vi_block
    [[ :$opts: == *:extend:* ]] && _ble_edit_mark_active=vi_block+
  else
    call_operator=ble/keymap:vi/call-operator-linewise
    _ble_edit_mark_active=vi_line
  fi
  local ble_keymap_vi_mark_active=$_ble_edit_mark_active
  ble/widget/vi_xmap/.save-visual-state
  ble/widget/vi_xmap/exit
  "$call_operator" "$op" "$beg" "$end" "$ARG" "$REG"; local ext=$?
  ((ext==148)) && return 148
  ((ext)) && ble/widget/.bell
  ble/keymap:vi/adjust-command-mode
  return "$ext"
}
function ble/widget/vi_xmap/replace-block-lines { ble/widget/vi_xmap/linewise-operator.impl c extend; }
function ble/widget/vi_xmap/delete-block-lines { ble/widget/vi_xmap/linewise-operator.impl d extend; }
function ble/widget/vi_xmap/delete-lines { ble/widget/vi_xmap/linewise-operator.impl d force_line; }
function ble/widget/vi_xmap/copy-block-or-lines { ble/widget/vi_xmap/linewise-operator.impl y; }
function ble/widget/vi_xmap/connect-line.impl {
  local name=$1
  local ARG FLAG REG; ble/keymap:vi/get-arg 1 # ignored
  local beg=$_ble_edit_mark end=$_ble_edit_ind
  ((beg<=end)) || local beg=$end end=$beg
  local ret; ble/string#count-char "${_ble_edit_str:beg:end-beg}" $'\n'; local nline=$((ret+1))
  ble/widget/vi_xmap/.save-visual-state
  ble/widget/vi_xmap/exit # Note: _ble_edit_mark_active will be cleared here
  _ble_edit_ind=$beg
  _ble_edit_arg=$nline
  _ble_keymap_vi_oparg=
  _ble_keymap_vi_opfunc=
  _ble_keymap_vi_reg=
  "ble/widget/$name"
}
function ble/widget/vi_xmap/connect-line-with-space {
  ble/widget/vi_xmap/connect-line.impl vi_nmap/connect-line-with-space
}
function ble/widget/vi_xmap/connect-line {
  ble/widget/vi_xmap/connect-line.impl vi_nmap/connect-line
}
_ble_keymap_vi_xmap_insert_data=
_ble_keymap_vi_xmap_insert_dbeg=-1
function ble/keymap:vi/xmap/update-dirty-range {
  [[ $_ble_keymap_vi_insert_leave == ble/widget/vi_xmap/block-insert-mode.onleave ]] &&
    ((_ble_keymap_vi_xmap_insert_dbeg<0||beg<_ble_keymap_vi_xmap_insert_dbeg)) &&
    _ble_keymap_vi_xmap_insert_dbeg=$beg
}
function ble/widget/vi_xmap/block-insert-mode.impl {
  local type=$1
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local nline=${#sub_ranges[@]}
  ble/util/assert '((nline))'
  local index ins_x
  if [[ $type == append ]]; then
    local sub=${sub_ranges[0]#*:}
    local smax=${sub%%:*}
    index=$smax
    if ble/keymap:vi/xmap/has-eol-extension; then
      ins_x='$'
    else
      ins_x=$sub_x2
    fi
  else
    local sub=${sub_ranges[0]}
    local smin=${sub%%:*}
    index=$smin
    ins_x=$sub_x1
  fi
  ble/widget/vi_xmap/cancel
  _ble_edit_ind=$index
  ble/widget/vi_nmap/.insert-mode "$ARG"
  ble/keymap:vi/repeat/record
  ble/keymap:vi/mark/set-local-mark 1 "$_ble_edit_ind"
  _ble_keymap_vi_xmap_insert_dbeg=-1
  local ret display_width
  ble/string#count-char "${_ble_edit_str::_ble_edit_ind}" $'\n'; local iline=$ret
  ble-edit/content/find-logical-bol; local bol=$ret
  ble-edit/content/find-logical-eol; local eol=$ret
  if ble/edit/use-textmap; then
    local bx by ex ey
    ble/textmap#getxy.out --prefix=b "$bol"
    ble/textmap#getxy.out --prefix=e "$eol"
    ((display_width=ex+_ble_textmap_cols*(ey-by)))
  else
    ((display_width=eol-bol))
  fi
  _ble_keymap_vi_xmap_insert_data=$iline:$ins_x:$display_width:$nline
  _ble_keymap_vi_insert_leave=ble/widget/vi_xmap/block-insert-mode.onleave
  return 0
}
function ble/widget/vi_xmap/block-insert-mode.onleave {
  local data=$_ble_keymap_vi_xmap_insert_data
  [[ $data ]] || continue
  _ble_keymap_vi_xmap_insert_data=
  ble/string#split data : "$data"
  local ret
  ble-edit/content/find-logical-bol; local bol=$ret
  ble/string#count-char "${_ble_edit_str::bol}" $'\n'; ((ret==data[0])) || return  1 # 行番号
  ble/keymap:vi/mark/get-local-mark 1 || return 1; local mark=$ret # `[
  ble-edit/content/find-logical-bol "$mark"; ((bol==ret)) || return 1 # 記録行 `[ と同じか
  local has_textmap=
  if ble/edit/use-textmap; then
    local cols=$_ble_textmap_cols
    has_textmap=1
  fi
  local new_width delta
  ble-edit/content/find-logical-eol; local eol=$ret
  if [[ $has_textmap ]]; then
    local bx by ex ey
    ble/textmap#getxy.out --prefix=b "$bol"
    ble/textmap#getxy.out --prefix=e "$eol"
    ((new_width=ex+cols*(ey-by)))
  else
    ((new_width=eol-bol))
  fi
  ((delta=new_width-data[2]))
  ((delta>0)) || return 1 # 縮んだ場合は処理しない
  local x1=${data[1]}
  [[ $x1 == '$' ]] && ((x1=data[2]))
  ((x1>new_width&&(x1=new_width)))
  if ((bol<=_ble_keymap_vi_xmap_insert_dbeg&&_ble_keymap_vi_xmap_insert_dbeg<=eol)); then
    local px py
    if [[ $has_textmap ]]; then
      ble/textmap#getxy.out --prefix=p "$_ble_keymap_vi_xmap_insert_dbeg"
      ((px+=cols*(py-by)))
    else
      ((px=_ble_keymap_vi_xmap_insert_dbeg-bol))
    fi
    ((px>x1&&(x1=px)))
  fi
  local x2=$((x1+delta))
  local ins= p1 p2
  if [[ $has_textmap ]]; then
    local index lx ly rx ry
    ble/textmap#hit out $((x1%cols)) $((by+x1/cols)) "$bol" "$eol"; p1=$index
    ble/textmap#hit out $((x2%cols)) $((by+x2/cols)) "$bol" "$eol"; p2=$index
    ((lx+=(ly-by)*cols,rx+=(ry-by)*cols,lx!=rx&&p2++))
  else
    ((p1=bol+x1,p2=bol+x2))
  fi
  ins=${_ble_edit_str:p1:p2-p1}
  local -a ins_beg=() ins_text=()
  local iline=1 nline=${data[3]} strlen=${#_ble_edit_str}
  for ((iline=1;iline<nline;iline++)); do
    local index= lpad=
    if ((eol<strlen)); then
      bol=$((eol+1))
      ble-edit/content/find-logical-eol "$bol"; eol=$ret
    else
      bol=$eol lpad=$'\n'
    fi
    if [[ ${data[1]} == '$' ]]; then
      index=$eol
    elif [[ $has_textmap ]]; then
      ble/textmap#getxy.out --prefix=b "$bol"
      ble/textmap#hit out $((x1%cols)) $((by+x1/cols)) "$bol" "$eol" # -> index
      local nfill
      if ((index==eol&&(nfill=x1-lx+(ly-by)*cols)>0)); then
        ble/string#repeat ' ' "$nfill"; lpad=$lpad$ret
      fi
    else
      index=$((bol+x1))
      if ((index>eol)); then
        ble/string#repeat ' ' $((index-eol)); lpad=$lpad$ret
        ((index=eol))
      fi
    fi
    ble/array#push ins_beg "$index"
    ble/array#push ins_text "$lpad$ins"
  done
  local i=${#ins_beg[@]}
  ble/keymap:vi/mark/start-edit-area
  ble/keymap:vi/mark/commit-edit-area "$p1" "$p2"
  while ((i--)); do
    local index=${ins_beg[i]} text=${ins_text[i]}
    ble/widget/.replace-range "$index" "$index" "$text" 1
  done
  ble/keymap:vi/mark/end-edit-area
  local index
  if ble/keymap:vi/mark/get-local-mark 60 && index=$ret; then
    ble/widget/vi-command/goto-mark.impl "$index"
  else
    ble-edit/content/find-logical-bol; index=$ret
  fi
  ble-edit/content/eolp || ((index++))
  _ble_edit_ind=$index
  return 0
}
function ble/widget/vi_xmap/insert-mode {
  local mark_type=${_ble_edit_mark_active%+}
  if [[ $mark_type == vi_block ]]; then
    local sub_ranges sub_x1 sub_x2
    ble/keymap:vi/extract-block '' '' first_line
    ble/widget/vi_xmap/block-insert-mode.impl insert
  else
    local ARG FLAG REG; ble/keymap:vi/get-arg 1
    local beg=$_ble_edit_mark end=$_ble_edit_ind
    ((beg<=end)) || local beg=$end end=$beg
    if [[ $mark_type == vi_line ]]; then
      local ret
      ble-edit/content/find-logical-bol "$beg"; beg=$ret
    fi
    ble/widget/vi_xmap/cancel
    _ble_edit_ind=$beg
    ble/widget/vi_nmap/.insert-mode "$ARG"
    ble/keymap:vi/repeat/record
    return 0
  fi
}
function ble/widget/vi_xmap/append-mode {
  local mark_type=${_ble_edit_mark_active%+}
  if [[ $mark_type == vi_block ]]; then
    local sub_ranges sub_x1 sub_x2
    ble/keymap:vi/extract-block '' '' first_line
    ble/widget/vi_xmap/block-insert-mode.impl append
  else
    local ARG FLAG REG; ble/keymap:vi/get-arg 1
    local beg=$_ble_edit_mark end=$_ble_edit_ind
    ((beg<=end)) || local beg=$end end=$beg
    if [[ $mark_type == vi_line ]]; then
      if ((_ble_edit_mark>_ble_edit_ind)); then
        local ret
        ble-edit/content/find-logical-bol "$end"; end=$ret
      fi
    fi
    ble-edit/content/eolp "$end" || ((end++))
    ble/widget/vi_xmap/cancel
    _ble_edit_ind=$end
    ble/widget/vi_nmap/.insert-mode "$ARG"
    ble/keymap:vi/repeat/record
    return 0
  fi
}
function ble/widget/vi_xmap/paste.impl {
  local opts=$1
  [[ :$opts: != *:after:* ]]; local is_after=$?
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  [[ $REG ]] && ble/keymap:vi/register#load "$REG"
  local mark_type=${_ble_edit_mark_active%+}
  local kill_ring=$_ble_edit_kill_ring
  local kill_type=$_ble_edit_kill_type
  local adjustment=
  if [[ $mark_type == vi_block ]]; then
    if [[ $kill_type == L ]]; then
      if ((is_after)); then
        local ret; ble/keymap:vi/get-rectangle-height; local nline=$ret
        adjustment=lastline:$nline
      fi
    elif [[ $kill_type == B:* ]]; then
      is_after=0
    else
      is_after=0
      if [[ $kill_ring != *$'\n'* ]]; then
        ((${#kill_ring}>=2)) && adjustment=index:$((${#kill_ring}*ARG-1))
        local ret; ble/keymap:vi/get-rectangle-height; local nline=$ret
        ble/string#repeat "$kill_ring"$'\n' "$nline"; kill_ring=${ret%$'\n'}
        ble/string#repeat '0 ' "$nline"; kill_type=B:${ret% }
      fi
    fi
  elif [[ $mark_type == vi_line ]]; then
    if [[ $kill_type == L ]]; then
      is_after=0
    elif [[ $kill_type == B:* ]]; then
      is_after=0 kill_type=L kill_ring=$kill_ring$'\n'
    else
      is_after=0 kill_type=L
      [[ $kill_ring == *$'\n' ]] && kill_ring=$kill_ring$'\n'
    fi
  else
    is_after=0
    [[ $kill_type == L ]] && adjustment=newline
  fi
  ble/keymap:vi/mark/start-edit-area
  local _ble_keymap_vi_mark_suppress_edit=1
  {
    ble/widget/vi-command/operator d; local ext=$? # _ble_edit_kill_{ring,type} is set here
    if [[ $adjustment == newline ]]; then
      local -a KEYS=(10)
      ble/widget/self-insert
    elif [[ $adjustment == lastline:* ]]; then
      local ret
      ble-edit/content/find-logical-bol "$_ble_edit_ind" $((${adjustment#*:}-1))
      _ble_edit_ind=$ret
    fi
    local _ble_edit_kill_ring=$kill_ring
    local _ble_edit_kill_type=$kill_type
    ble/widget/vi_nmap/paste.impl "$ARG" '' "$is_after"
    if [[ $adjustment == index:* ]]; then
      local index=$((_ble_edit_ind+${adjustment#*:}))
      ((index>${#_ble_edit_str}&&(index=${#_ble_edit_str})))
      ble/keymap:vi/needs-eol-fix "$index" && ((index--))
      _ble_edit_ind=$index
    fi
  }
  ble/util/unlocal _ble_keymap_vi_mark_suppress_edit
  ble/keymap:vi/mark/end-edit-area
  ble/keymap:vi/repeat/record
  return "$ext"
}
function ble/widget/vi_xmap/paste-after {
  ble/widget/vi_xmap/paste.impl after
}
function ble/widget/vi_xmap/paste-before {
  ble/widget/vi_xmap/paste.impl before
}
function ble/widget/vi_xmap/increment.impl {
  local opts=$1
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  if [[ $FLAG ]]; then
    ble/widget/.bell
    return 1
  fi
  local delta=$ARG
  [[ :$opts: == *:decrease:* ]] && ((delta=-delta))
  local progress=0
  [[ :$opts: == *:progressive:* ]] && progress=$delta
  local old_mark_active=$_ble_edit_mark_active # save
  local mark_type=${_ble_edit_mark_active%+}
  ble/widget/vi_xmap/.save-visual-state
  ble/widget/vi_xmap/exit # Note: _ble_edit_mark_active will be cleared here
  if [[ $mark_type == vi_block ]]; then
    local sub_ranges sub_x1 sub_x2
    _ble_edit_mark_active=$old_mark_active ble/keymap:vi/extract-block
    if ((${#sub_ranges[@]}==0)); then
      ble/widget/.bell
      return 1
    fi
  else
    local beg=$_ble_edit_mark end=$_ble_edit_ind
    ((beg<=end)) || local beg=$end end=$beg
    if [[ $mark_type == vi_line ]]; then
      local ret
      ble-edit/content/find-logical-bol "$beg"; local beg=$ret
      ble-edit/content/find-logical-eol "$end"; local end=$ret
    else
      ble-edit/content/eolp "$end" || ((end++))
    fi
    local -a lines
    ble/string#split-lines lines "${_ble_edit_str:beg:end-beg}"
    local line index=$beg
    local -a sub_ranges
    for line in "${lines[@]}"; do
      [[ $line ]] && ble/array#push sub_ranges "$index:::::$line"
      ((index+=${#line}+1))
    done
    ((${#sub_ranges[@]})) || return 0
  fi
  local sub rex_number='^([^0-9]*)([0-9]+)' shift=0 dmin=-1 dmax=-1
  for sub in "${sub_ranges[@]}"; do
    local stext=${sub#*:*:*:*:*:}
    [[ $stext =~ $rex_number ]] || continue
    local rematch1=${BASH_REMATCH[1]}
    local rematch2=${BASH_REMATCH[2]}
    local offset=${#rematch1} length=${#rematch2}
    local number=$((10#$rematch2))
    [[ $rematch1 == *- ]] && ((number=-number,offset--,length++))
    ((number+=delta,delta+=progress))
    if [[ $rematch2 == 0?* ]]; then
      local wsign=$((number<0?1:0))
      local zpad=$((wsign+${#rematch2}-${#number}))
      if ((zpad>0)); then
        local ret; ble/string#repeat 0 "$zpad"
        number=${number::wsign}$ret${number:wsign}
      fi
    fi
    local smin=${sub%%:*}
    local beg=$((shift+smin+offset))
    local end=$((beg+length))
    ble/widget/.replace-range "$beg" "$end" "$number" 1
    ((shift+=${#number}-length,
      dmin<0&&(dmin=beg),
      dmax=beg+${#number}))
  done
  local beg=${sub_ranges[0]%%:*}
  ble/keymap:vi/needs-eol-fix "$beg" && ((beg--))
  _ble_edit_ind=$beg
  ((dmin>=0)) && ble/keymap:vi/mark/set-previous-edit-area "$dmin" "$dmax"
  ble/keymap:vi/repeat/record
  return 0
}
function ble/widget/vi_xmap/increment { ble/widget/vi_xmap/increment.impl increase; }
function ble/widget/vi_xmap/decrement { ble/widget/vi_xmap/increment.impl decrease; }
function ble/widget/vi_xmap/progressive-increment { ble/widget/vi_xmap/increment.impl progressive:increase; }
function ble/widget/vi_xmap/progressive-decrement { ble/widget/vi_xmap/increment.impl progressive:decrease; }
function ble-decode/keymap:vi_xmap/define {
  local ble_bind_keymap=vi_xmap
  ble/keymap:vi/setup-map
  ble-bind -f __default__ vi-command/decompose-meta
  ble-bind -f 'ESC' vi_xmap/exit
  ble-bind -f 'C-[' vi_xmap/exit
  ble-bind -f 'C-c' vi_xmap/cancel
  ble-bind -f '"' vi-command/register
  ble-bind -f a vi-command/text-object
  ble-bind -f i vi-command/text-object
  ble-bind -f 'C-\ C-n' vi_xmap/cancel
  ble-bind -f 'C-\ C-g' vi_xmap/cancel
  ble-bind -f v      vi_xmap/switch-to-charwise
  ble-bind -f V      vi_xmap/switch-to-linewise
  ble-bind -f C-v    vi_xmap/switch-to-blockwise
  ble-bind -f C-q    vi_xmap/switch-to-blockwise
  ble-bind -f 'g v'  vi-command/previous-visual-area
  ble-bind -f C-g    vi_xmap/switch-to-select
  ble-bind -f o vi_xmap/exchange-points
  ble-bind -f O vi_xmap/exchange-boundaries
  ble-bind -f '~' 'vi-command/operator toggle_case'
  ble-bind -f 'u' 'vi-command/operator u'
  ble-bind -f 'U' 'vi-command/operator U'
  ble-bind -f 's' 'vi-command/operator c'
  ble-bind -f 'x'    'vi-command/operator d'
  ble-bind -f delete 'vi-command/operator d'
  ble-bind -f r vi_xmap/visual-replace-char
  ble-bind -f C vi_xmap/replace-block-lines
  ble-bind -f D vi_xmap/delete-block-lines
  ble-bind -f X vi_xmap/delete-block-lines
  ble-bind -f S vi_xmap/delete-lines
  ble-bind -f R vi_xmap/delete-lines
  ble-bind -f Y vi_xmap/copy-block-or-lines
  ble-bind -f J     vi_xmap/connect-line-with-space
  ble-bind -f 'g J' vi_xmap/connect-line
  ble-bind -f I vi_xmap/insert-mode
  ble-bind -f A vi_xmap/append-mode
  ble-bind -f p vi_xmap/paste-after
  ble-bind -f P vi_xmap/paste-before
  ble-bind -f 'C-a'   vi_xmap/increment
  ble-bind -f 'C-x'   vi_xmap/decrement
  ble-bind -f 'g C-a' vi_xmap/progressive-increment
  ble-bind -f 'g C-x' vi_xmap/progressive-decrement
  ble-bind -f f1 vi_xmap/command-help
  ble-bind -f K  vi_xmap/command-help
}
function ble-decode/keymap:vi_smap/define {
  local ble_bind_keymap=vi_smap
  ble-bind -f __default__ vi-command/decompose-meta
  ble-bind -f 'ESC' vi_xmap/exit
  ble-bind -f 'C-[' vi_xmap/exit
  ble-bind -f 'C-c' vi_xmap/cancel
  ble-bind -f 'C-\ C-n' nop
  ble-bind -f 'C-\ C-n' vi_xmap/cancel
  ble-bind -f 'C-\ C-g' vi_xmap/cancel
  ble-bind -f C-v    vi_xmap/switch-to-visual-blockwise
  ble-bind -f C-q    vi_xmap/switch-to-visual-blockwise
  ble-bind -f C-g    vi_xmap/switch-to-visual
  ble-bind -f delete 'vi-command/operator d'
  ble-bind -f 'C-?'  'vi-command/operator d'
  ble-bind -f 'DEL'  'vi-command/operator d'
  ble-bind -f 'C-h'  'vi-command/operator d'
  ble-bind -f 'BS'   'vi-command/operator d'
  ble-bind -f __defchar__ vi_smap/self-insert
  ble-bind -f paste_begin vi-command/bracketed-paste
  ble-bind -f 'C-a'  vi_xmap/increment
  ble-bind -f 'C-x'  vi_xmap/decrement
  ble-bind -f f1     vi_xmap/command-help
  ble-bind -c 'C-z' fg
  ble-bind -f home      'vi_smap/@nomarked vi-command/beginning-of-line'
  ble-bind -f end       'vi_smap/@nomarked vi-command/forward-eol'
  ble-bind -f C-m       'vi_smap/@nomarked vi-command/forward-first-non-space'
  ble-bind -f RET       'vi_smap/@nomarked vi-command/forward-first-non-space'
  ble-bind -f S-home    'vi-command/beginning-of-line'
  ble-bind -f S-end     'vi-command/forward-eol'
  ble-bind -f S-C-m     'vi-command/forward-first-non-space'
  ble-bind -f S-RET     'vi-command/forward-first-non-space'
  ble-bind -f C-right   'vi_smap/@nomarked vi-command/forward-vword'
  ble-bind -f C-left    'vi_smap/@nomarked vi-command/backward-vword'
  ble-bind -f S-C-right 'vi-command/forward-vword'
  ble-bind -f S-C-left  'vi-command/backward-vword'
  ble-bind -f left      'vi_smap/@nomarked vi-command/backward-char'
  ble-bind -f right     'vi_smap/@nomarked vi-command/forward-char'
  ble-bind -f 'C-?'     'vi_smap/@nomarked vi-command/backward-char wrap'
  ble-bind -f 'DEL'     'vi_smap/@nomarked vi-command/backward-char wrap'
  ble-bind -f 'C-h'     'vi_smap/@nomarked vi-command/backward-char wrap'
  ble-bind -f 'BS'      'vi_smap/@nomarked vi-command/backward-char wrap'
  ble-bind -f SP        'vi_smap/@nomarked vi-command/forward-char wrap'
  ble-bind -f S-left    'vi-command/backward-char'
  ble-bind -f S-right   'vi-command/forward-char'
  ble-bind -f 'S-C-?'   'vi-command/backward-char wrap'
  ble-bind -f 'S-DEL'   'vi-command/backward-char wrap'
  ble-bind -f 'S-C-h'   'vi-command/backward-char wrap'
  ble-bind -f 'S-BS'    'vi-command/backward-char wrap'
  ble-bind -f S-SP      'vi-command/forward-char wrap'
  ble-bind -f down      'vi_smap/@nomarked vi-command/forward-line'
  ble-bind -f C-n       'vi_smap/@nomarked vi-command/forward-line'
  ble-bind -f C-j       'vi_smap/@nomarked vi-command/forward-line'
  ble-bind -f up        'vi_smap/@nomarked vi-command/backward-line'
  ble-bind -f C-p       'vi_smap/@nomarked vi-command/backward-line'
  ble-bind -f C-home    'vi_smap/@nomarked vi-command/first-nol'
  ble-bind -f C-end     'vi_smap/@nomarked vi-command/last-eol'
  ble-bind -f S-down    'vi-command/forward-line'
  ble-bind -f S-C-n     'vi-command/forward-line'
  ble-bind -f S-C-j     'vi-command/forward-line'
  ble-bind -f S-up      'vi-command/backward-line'
  ble-bind -f S-C-p     'vi-command/backward-line'
  ble-bind -f S-C-home  'vi-command/first-nol'
  ble-bind -f S-C-end   'vi-command/last-eol'
}
function ble/widget/vi_imap/__attach__ {
  ble/keymap:vi/update-mode-name
  return 0
}
function ble/widget/vi_imap/accept-single-line-or {
  if ble-edit/is-single-complete-line; then
    ble/keymap:vi/imap-repeat/reset
    ble/widget/accept-line
  else
    ble/widget/"$@"
  fi
}
function ble/widget/vi_imap/delete-region-or {
  if [[ $_ble_edit_mark_active ]]; then
    ble/keymap:vi/imap-repeat/reset
    if ((_ble_edit_ind!=_ble_edit_mark)); then
      ble/keymap:vi/undo/add more
      ble/widget/delete-region
      ble/keymap:vi/undo/add more
    fi
  else
    ble/widget/"$@"
  fi
}
function ble/widget/vi_imap/overwrite-mode {
  if [[ $_ble_edit_overwrite_mode ]]; then
    _ble_edit_overwrite_mode=
  else
    _ble_edit_overwrite_mode=${_ble_keymap_vi_insert_overwrite:-R}
  fi
  ble/keymap:vi/update-mode-name
  return 0
}
function ble/widget/vi_imap/delete-backward-word {
  local space=$' \t' nl=$'\n'
  local rex="($_ble_keymap_vi_REX_WORD)[$space]*\$|[$space]+\$|$nl\$"
  if [[ ${_ble_edit_str::_ble_edit_ind} =~ $rex ]]; then
    local index=$((_ble_edit_ind-${#BASH_REMATCH}))
    if ((index!=_ble_edit_ind)); then
      ble/keymap:vi/undo/add more
      ble/widget/.delete-range "$index" "$_ble_edit_ind"
      ble/keymap:vi/undo/add more
    fi
    return 0
  else
    ble/widget/.bell
    return 1
  fi
}
function ble/widget/vi_imap/quoted-insert {
  ble/keymap:vi/imap-repeat/pop
  _ble_edit_mark_active=
  _ble_decode_char__hook=ble/widget/vi_imap/quoted-insert.hook
  return 148
}
function ble/widget/vi_imap/quoted-insert.hook {
  ble/keymap:vi/imap/invoke-widget ble/widget/self-insert "$1"
}
function ble/widget/vi_imap/bracketed-paste {
  ble/keymap:vi/imap-repeat/pop
  ble/widget/bracketed-paste
  _ble_edit_bracketed_paste_proc=ble/widget/vi_imap/bracketed-paste.proc
  return 148
}
function ble/widget/vi_imap/bracketed-paste.proc {
  ble/keymap:vi/imap/invoke-widget-charwise ble/widget/self-insert "$@"
}
_ble_keymap_vi_brackated_paste_mark_active=
function ble/widget/vi-command/bracketed-paste {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1 # discard args
  _ble_keymap_vi_brackated_paste_mark_active=$_ble_edit_mark_active
  _ble_edit_mark_active=
  ble/widget/bracketed-paste
  _ble_edit_bracketed_paste_proc=ble/widget/vi-command/bracketed-paste.proc
  return 148
}
function ble/widget/vi-command/bracketed-paste.proc {
  if [[ $_ble_decode_keymap == vi_nmap ]]; then
    local isbol index=$_ble_edit_ind
    ble-edit/content/bolp && isbol=1
    ble-decode/widget/call-interactively 'ble/widget/vi_nmap/append-mode' 97
    [[ $isbol ]] && ((_ble_edit_ind=index)) # 行頭にいたときは戻る
    ble/widget/vi_imap/bracketed-paste.proc "$@"
    ble/keymap:vi/imap/invoke-widget \
      ble/widget/vi_imap/normal-mode $((_ble_decode_Ctrl|0x5b))
  elif [[ $_ble_decode_keymap == vi_[xs]map ]]; then
    local _ble_edit_mark_active=$_ble_keymap_vi_brackated_paste_mark_active
    ble-decode/widget/call-interactively 'ble/widget/vi-command/operator c' 99 || return 1
    ble/widget/vi_imap/bracketed-paste.proc "$@"
    ble/keymap:vi/imap/invoke-widget \
      ble/widget/vi_imap/normal-mode $((_ble_decode_Ctrl|0x5b))
  elif [[ $_ble_decode_keymap == vi_omap ]]; then
    ble/widget/vi_omap/cancel
    ble/widget/.bell
    return 1
  else # vi_omap
    ble/widget/.bell
    return 1
  fi
}
function ble/widget/vi_imap/insert-digraph.hook {
  local -a KEYS; KEYS=("$1")
  ble/widget/self-insert
}
function ble/widget/vi_imap/insert-digraph {
  ble-decode/keymap/push vi_digraph
  _ble_keymap_vi_digraph__hook=ble/widget/vi_imap/insert-digraph.hook
  return 0
}
function ble/widget/vi_imap/newline {
  local ret
  ble-edit/content/find-logical-bol; local bol=$ret
  ble-edit/content/find-non-space "$bol"; local nol=$ret
  ble/widget/newline
  ((bol<nol)) && ble/widget/.insert-string "${_ble_edit_str:bol:nol-bol}"
  return 0
}
function ble/widget/vi_imap/delete-backward-indent-or {
  local rex=$'(^|\n)([ \t]+)$'
  if [[ ${_ble_edit_str::_ble_edit_ind} =~ $rex ]]; then
    local rematch2=${BASH_REMATCH[2]} # Note: for bash-3.1 ${#arr[n]} bug
    if [[ $rematch2 ]]; then
      ble/keymap:vi/undo/add more
      ble/widget/.delete-range $((_ble_edit_ind-${#rematch2})) "$_ble_edit_ind"
      ble/keymap:vi/undo/add more
    fi
    return 0
  else
    ble/widget/"$@"
  fi
}
function ble-decode/keymap:vi_imap/define {
  local ble_bind_keymap=vi_imap
  local ble_bind_nometa=1
  ble-decode/keymap:safe/bind-common
  ble-decode/keymap:safe/bind-history
  ble-bind -f insert      'vi_imap/overwrite-mode'
  ble-bind -f 'C-q'       'vi_imap/quoted-insert'
  ble-bind -f 'C-v'       'vi_imap/quoted-insert'
  ble-bind -f 'C-RET'     'newline'
  ble-bind -f paste_begin 'vi_imap/bracketed-paste'
  ble-bind -f 'C-d'       'delete-region-or forward-char-or-exit'
  ble-bind -f 'C-?'       'vi_imap/delete-region-or vi_imap/delete-backward-indent-or delete-backward-char'
  ble-bind -f 'DEL'       'vi_imap/delete-region-or vi_imap/delete-backward-indent-or delete-backward-char'
  ble-bind -f 'C-h'       'vi_imap/delete-region-or vi_imap/delete-backward-indent-or delete-backward-char'
  ble-bind -f 'BS'        'vi_imap/delete-region-or vi_imap/delete-backward-indent-or delete-backward-char'
  ble-bind -f 'C-w'       'vi_imap/delete-backward-word'
  ble-bind -f 'SP'        'magic-space'
  ble-decode/keymap:vi_imap/bind-complete
  ble-bind -f  'C-j'     accept-line
  ble-bind -f  'C-RET'   accept-line
  ble-bind -f  'C-m'     'vi_imap/accept-single-line-or vi_imap/newline'
  ble-bind -f  'RET'     'vi_imap/accept-single-line-or vi_imap/newline'
  ble-bind -f  'C-g'     bell
  ble-bind -f  'C-x C-g' bell
  ble-bind -f  'C-M-g'   bell
  ble-bind -f  'C-l'     clear-screen
  ble-bind -f  'f1'      command-help
  ble-bind -f  'C-x C-v' display-shell-version
  ble-bind -c 'C-z'     fg
  ble-bind -f 'C-\' bell
  ble-bind -f 'C-^' bell
  ble-bind -f __attach__        vi_imap/__attach__
  ble-bind -f __default__       vi_imap/__default__
  ble-bind -f __before_widget__ vi_imap/__before_widget__
  ble-bind -f 'ESC' 'vi_imap/normal-mode'
  ble-bind -f 'C-[' 'vi_imap/normal-mode'
  ble-bind -f 'C-c' 'vi_imap/normal-mode-without-insert-leave'
  ble-bind -f 'C-o' 'vi_imap/single-command-mode'
}
function ble-decode/keymap:vi_imap/define-meta-bindings {
  local ble_bind_keymap=vi_imap
  ble-bind -f 'M-l'       'redraw-line'
  ble-bind -f 'M-^'       'history-expand-line'
  ble-bind -f 'M-C-m'     'newline'
  ble-bind -f 'M-RET'     'newline'
  ble-bind -f 'M-SP'      'set-mark'
  ble-bind -f 'M-w'       'copy-region-or uword'
  ble-bind -f 'M-\'       'delete-horizontal-space'
  ble-bind -f 'M-right'   '@nomarked forward-sword'
  ble-bind -f 'M-left'    '@nomarked backward-sword'
  ble-bind -f 'S-M-right' '@marked forward-sword'
  ble-bind -f 'S-M-left'  '@marked backward-sword'
  ble-bind -f 'M-d'       'kill-forward-cword'
  ble-bind -f 'M-h'       'kill-backward-cword'
  ble-bind -f 'M-delete'  'copy-forward-sword'
  ble-bind -f 'M-C-?'     'copy-backward-sword'
  ble-bind -f 'M-DEL'     'copy-backward-sword'
  ble-bind -f 'M-C-h'     'copy-backward-sword'
  ble-bind -f 'M-BS'      'copy-backward-sword'
  ble-bind -f 'M-f'       '@nomarked forward-cword'
  ble-bind -f 'M-b'       '@nomarked backward-cword'
  ble-bind -f 'M-F'       '@marked forward-cword'
  ble-bind -f 'M-B'       '@marked backward-cword'
  ble-bind -f 'M-S-f'     '@marked forward-cword'
  ble-bind -f 'M-S-b'     '@marked backward-cword'
  ble-bind -f 'M-m'       '@nomarked non-space-beginning-of-line'
  ble-bind -f 'S-M-m'     '@marked non-space-beginning-of-line'
  ble-bind -f 'M-M'       '@marked non-space-beginning-of-line'
  ble-bind -f 'M-<'       'history-beginning'
  ble-bind -f 'M->'       'history-end'
  ble-bind -f 'M-?'       'complete show_menu'
  ble-bind -f 'M-*'       'complete insert_all'
  ble-bind -f 'M-/'       'complete context=filename'
  ble-bind -f 'M-~'       'complete context=username'
  ble-bind -f 'M-$'       'complete context=variable'
  ble-bind -f 'M-@'       'complete context=hostname'
  ble-bind -f 'M-!'       'complete context=command'
  ble-bind -f "M-'"       'sabbrev-expand'
  ble-bind -f 'M-g'       'complete context=glob'
}
_ble_keymap_vi_cmap_hook=
_ble_keymap_vi_cmap_cancel_hook=
_ble_keymap_vi_cmap_before_command=
_ble_keymap_vi_cmap_history=()
_ble_keymap_vi_cmap_history_edit=()
_ble_keymap_vi_cmap_history_dirt=()
_ble_keymap_vi_cmap_history_ind=0
_ble_keymap_vi_cmap_history_onleave=()
function ble/keymap:vi/async-commandline-mode {
  local hook=$1
  _ble_keymap_vi_cmap_hook=$hook
  _ble_keymap_vi_cmap_cancel_hook=
  _ble_keymap_vi_cmap_before_command=
  ble/textarea#render
  ble/textarea#save-state _ble_keymap_vi_cmap
  _ble_keymap_vi_cmap_history_prefix=$_ble_edit_history_prefix
  ble-decode/keymap/push vi_cmap
  ble/keymap:vi/update-mode-name
  _ble_textarea_panel=1
  ble/textarea#invalidate
  _ble_edit_PS1=$PS2
  _ble_edit_prompt=("" 0 0 0 32 0 "" "")
  _ble_edit_dirty_observer=()
  ble/widget/.newline/clear-content
  _ble_edit_arg=
  ble-edit/undo/clear-all
  _ble_edit_history_prefix=_ble_keymap_vi_cmap
  _ble_syntax_lang=text
  _ble_highlight_layer__list=(plain region overwrite_mode)
}
function ble/widget/vi_cmap/accept {
  local hook=${_ble_keymap_vi_cmap_hook}
  _ble_keymap_vi_cmap_hook=
  local result=$_ble_edit_str
  [[ $result ]] && ble-edit/history/add "$result" # Note: cancel でも登録する
  local -a DRAW_BUFF=()
  ble/canvas/panel#set-height.draw "$_ble_textarea_panel" 0
  ble/canvas/bflush.draw
  ble/textarea#restore-state _ble_keymap_vi_cmap
  ble/textarea#clear-state _ble_keymap_vi_cmap
  [[ $_ble_edit_overwrite_mode ]] && ble/util/buffer "$_ble_term_civis"
  _ble_edit_history_prefix=$_ble_keymap_vi_cmap_history_prefix
  ble-decode/keymap/pop
  ble/keymap:vi/update-mode-name
  if [[ $hook ]]; then
    builtin eval -- "$hook \"\$result\""
  else
    ble/keymap:vi/adjust-command-mode
    return 0
  fi
}
function ble/widget/vi_cmap/cancel {
  _ble_keymap_vi_cmap_hook=$_ble_keymap_vi_cmap_cancel_hook
  ble/widget/vi_cmap/accept
}
function ble/widget/vi_cmap/__before_widget__ {
  if [[ $_ble_keymap_vi_cmap_before_command ]]; then
    eval "$_ble_keymap_vi_cmap_before_command"
  fi
}
function ble-decode/keymap:vi_cmap/define {
  local ble_bind_keymap=vi_cmap
  local ble_bind_nometa=
  ble-decode/keymap:safe/bind-common
  ble-decode/keymap:safe/bind-history
  ble-decode/keymap:safe/bind-complete
  ble-bind -f __before_widget__ vi_cmap/__before_widget__
  ble-bind -f 'ESC'     vi_cmap/cancel
  ble-bind -f 'C-['     vi_cmap/cancel
  ble-bind -f 'C-c'     vi_cmap/cancel
  ble-bind -f 'C-m'     vi_cmap/accept
  ble-bind -f 'RET'     vi_cmap/accept
  ble-bind -f 'C-j'     vi_cmap/accept
  ble-bind -f 'C-g'     bell
  ble-bind -f 'C-x C-g' bell
  ble-bind -f 'C-M-g'   bell
  ble-bind -f  'C-l'     redraw-line
  ble-bind -f  'M-l'     redraw-line
  ble-bind -f  'C-x C-v' display-shell-version
  ble-bind -f 'C-\' bell
  ble-bind -f 'C-]' bell
  ble-bind -f 'C-^' bell
}
function ble-decode/keymap:vi/initialize {
  local fname_keymap_cache=$_ble_base_cache/keymap.vi
  if [[ $fname_keymap_cache -nt $_ble_base/keymap/vi.sh &&
          $fname_keymap_cache -nt $_ble_base/lib/init-cmap.sh ]]; then
    source "$fname_keymap_cache" && return
  fi
  ble-edit/info/immediate-show text "ble.sh: updating cache/keymap.vi..."
  ble-decode/keymap:isearch/define
  ble-decode/keymap:nsearch/define
  ble-decode/keymap:vi_imap/define
  ble-decode/keymap:vi_nmap/define
  ble-decode/keymap:vi_omap/define
  ble-decode/keymap:vi_xmap/define
  ble-decode/keymap:vi_cmap/define
  {
    ble-decode/keymap/dump isearch
    ble-decode/keymap/dump nsearch
    ble-decode/keymap/dump vi_imap
    ble-decode/keymap/dump vi_nmap
    ble-decode/keymap/dump vi_omap
    ble-decode/keymap/dump vi_xmap
    ble-decode/keymap/dump vi_cmap
  } >| "$fname_keymap_cache"
  ble-edit/info/immediate-show text "ble.sh: updating cache/keymap.vi... done"
}
ble-decode/keymap:vi/initialize
ble/util/invoke-hook _ble_keymap_default_load_hook
ble/util/invoke-hook _ble_keymap_vi_load_hook
