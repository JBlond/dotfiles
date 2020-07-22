# this script is a part of blesh (https://github.com/akinomyoga/ble.sh) under BSD-3-Clause license
source "$_ble_base/keymap/vi.sh"
bleopt/declare -n vim_surround_45 $'$(\r)' # ysiw-
bleopt/declare -n vim_surround_61 $'$((\r))' # ysiw=
bleopt/declare -n vim_surround_q \" # ysiwQ
bleopt/declare -n vim_surround_Q \' # ysiwq
bleopt/declare -v vim_surround_omap_bind 1
function ble/lib/vim-surround.sh/get-char-from-key {
  local key=$1
  if ! ble-decode-key/ischar "$key"; then
    local flag=$((key&_ble_decode_MaskFlag)) code=$((key&_ble_decode_MaskChar))
    if ((flag==_ble_decode_Ctrl&&63<=code&&code<128&&(code&0x1F)!=0)); then
      ((key=code==63?127:code&0x1F))
    else
      return 1
    fi
  fi
  ble/util/c2s "$key"
  return 0
}
function ble/lib/vim-surround.sh/async-inputtarget.hook {
  local mode=$1 hook=${@:2:$#-2} key=${@:$#} ret
  if ! ble/lib/vim-surround.sh/get-char-from-key "$key"; then
    ble/widget/vi-command/bell
    return 1
  fi
  local c=$ret
  if [[ :$mode: == *:digit:* && $c == [0-9] ]]; then
    _ble_edit_arg=$_ble_edit_arg$c
    _ble_decode_key__hook="ble/lib/vim-surround.sh/async-inputtarget.hook digit $hook"
    return 148
  elif [[ :$mode: == *:init:* && $c == ' ' ]]; then
    _ble_decode_key__hook="ble/lib/vim-surround.sh/async-inputtarget.hook space $hook"
    return 148
  fi
  if [[ $c == [$'\e\003'] ]]; then # C-[, C-c
    ble/widget/vi-command/bell
    return 1
  else
    [[ $c == \' ]] && c="'\''"
    [[ $mode == space ]] && c=' '$c
    eval "$hook '$c'"
  fi
}
function ble/lib/vim-surround.sh/async-inputtarget {
  _ble_decode_key__hook="ble/lib/vim-surround.sh/async-inputtarget.hook init:digit $*"
  return 148
}
function ble/lib/vim-surround.sh/async-inputtarget-noarg {
  _ble_decode_key__hook="ble/lib/vim-surround.sh/async-inputtarget.hook init $*"
  return 148
}
_ble_lib_vim_surround_previous_tag=html
function ble/lib/vim-surround.sh/load-template {
  local ins=$1
  if [[ ${ins//[0-9]} && ! ${ins//[_0-9a-zA-Z]} ]]; then
    local optname=bleopt_vim_surround_$ins
    template=${!optname}
    [[ $template ]] && return
  fi
  local ret; ble/util/s2c "$ins"
  local optname=bleopt_vim_surround_$ret
  template=${!optname}
  [[ $template ]] && return
  case "$ins" in
  (['<tT']*)
    local tag=${ins:1}; tag=${tag//$'\r'/' '}
    if [[ ! $tag ]]; then
      tag=$_ble_lib_vim_surround_previous_tag
    else
      tag=${tag%'>'}
      _ble_lib_vim_surround_previous_tag=$tag
    fi
    local end_tag=${tag%%[$' \t\n']*}
    template="<$tag>"$'\r'"</$end_tag>" ;;
  ('(') template=$'( \r )' ;;
  ('[') template=$'[ \r ]' ;;
  ('{') template=$'{ \r }' ;;
  (['b)']) template=$'(\r)' ;;
  (['r]']) template=$'[\r]' ;;
  (['B}']) template=$'{\r}' ;;
  (['a>']) template=$'<\r>' ;;
  ([a-zA-Z]) return 1 ;;
  (*) template=$ins ;;
  esac
} &>/dev/null
function ble/lib/vim-surround.sh/surround {
  local text=$1 ins=$2 opts=$3
  local instype=
  [[ $ins == $'\x1D' ]] && ins='}' instype=indent # C-], C-}
  local has_space=
  [[ $ins == ' '?* ]] && ins=${ins:1} has_space=1
  local template=
  ble/lib/vim-surround.sh/load-template "$ins" || return 1
  local prefix= suffix=
  if [[ $template == *$'\r'* ]]; then
    prefix=${template%%$'\r'*}
    suffix=${template#*$'\r'}
  else
    prefix=$template
    suffix=$template
  fi
  if [[ $prefix == *' ' && $suffix == ' '* ]]; then
    prefix=${prefix::${#prefix}-1}
    suffix=${suffix:1}
    has_space=1
  fi
  if [[ $instype == indent || :$opts: == *:linewise:* ]]; then
    ble-edit/content/find-logical-bol "$beg"; local bol=$ret
    ble-edit/content/find-non-space "$bol"; local nol=$ret
    local indent=
    if [[ $instype == indent ]] || ((bol<nol)); then
      indent=${_ble_edit_str:bol:nol-bol}
    elif [[ $has_space ]]; then
      indent=' '
    fi
    text=$indent$text
    if [[ $instype == indent || :$opts: == *:indent:* ]]; then
      ble/keymap:vi/string#increase-indent "$text" "$bleopt_indent_offset"; text=$ret
    fi
    text=$'\n'$text$'\n'$indent
  elif [[ $has_space ]]; then
    text=' '$text' '
  fi
  ret=$prefix$text$suffix
}
function ble/lib/vim-surround.sh/async-read-tagname {
  ble/keymap:vi/async-commandline-mode "$1"
  _ble_edit_PS1='<'
  _ble_keymap_vi_cmap_before_command=ble/lib/vim-surround.sh/async-read-tagname/.before-command.hook
  return 148
}
function ble/lib/vim-surround.sh/async-read-tagname/.before-command.hook {
  if [[ ${KEYS[0]} == 62 ]]; then # '>'
    ble/widget/self-insert
    ble/widget/vi_cmap/accept
    ble-decode/widget/suppress-widget
  fi
}
_ble_lib_vim_surround_ys_type= # ys | yS | vS | vgS
_ble_lib_vim_surround_ys_args=()
_ble_lib_vim_surround_ys_ranges=()
function ble/highlight/layer:region/mark:vi_surround/get-selection {
  local type=$_ble_lib_vim_surround_ys_type
  local context=${_ble_lib_vim_surround_ys_args[2]}
  if [[ $context == block ]]; then
    local -a sub_ranges
    sub_ranges=("${_ble_lib_vim_surround_ys_ranges[@]}")
    selection=()
    local sub
    for sub in "${sub_ranges[@]}"; do
      ble/string#split sub : "$sub"
      ((sub[0]<sub[1])) || continue
      ble/array#push selection "${sub[0]}" "${sub[1]}"
    done
  else
    selection=("${_ble_lib_vim_surround_ys_args[@]::2}")
    if [[ $context == char && ( $type == yS || $type == ySS || $type == vgS ) ]]; then
      local ret
      ble-edit/content/find-logical-bol "${selection[0]}"; selection[0]=$ret
      ble-edit/content/find-logical-eol "${selection[1]}"; selection[1]=$ret
    fi
  fi
}
function ble/highlight/layer:region/mark:vi_surround/get-face {
  face=region_target
}
function ble/lib/vim-surround.sh/operator.impl {
  _ble_lib_vim_surround_ys_type=$1; shift
  _ble_lib_vim_surround_ys_args=("$@")
  [[ $3 == block ]] && _ble_lib_vim_surround_ys_ranges=("${sub_ranges[@]}")
  _ble_edit_mark_active=vi_surround
  ble/lib/vim-surround.sh/async-inputtarget-noarg ble/widget/vim-surround.sh/ysurround.hook1
  ble/lib/vim-surround.sh/ysurround.repeat/entry
  return 148
}
function ble/keymap:vi/operator:yS { ble/lib/vim-surround.sh/operator.impl yS "$@"; }
function ble/keymap:vi/operator:ys { ble/lib/vim-surround.sh/operator.impl ys "$@"; }
function ble/keymap:vi/operator:ySS { ble/lib/vim-surround.sh/operator.impl ySS "$@"; }
function ble/keymap:vi/operator:yss { ble/lib/vim-surround.sh/operator.impl yss "$@"; }
function ble/keymap:vi/operator:vS { ble/lib/vim-surround.sh/operator.impl vS "$@"; }
function ble/keymap:vi/operator:vgS { ble/lib/vim-surround.sh/operator.impl vgS "$@"; }
function ble/widget/vim-surround.sh/ysurround.hook1 {
  local ins=$1
  if local rex='^ ?[<tT]$'; [[ $ins =~ $rex ]]; then
    ble/lib/vim-surround.sh/async-read-tagname "ble/widget/vim-surround.sh/ysurround.hook2 '$ins'"
  else
    ble/widget/vim-surround.sh/ysurround.core "$ins"
  fi
}
function ble/widget/vim-surround.sh/ysurround.hook2 {
  local ins=$1 tagName=$2
  ble/widget/vim-surround.sh/ysurround.core "$ins$tagName"
}
function ble/widget/vim-surround.sh/ysurround.core {
  local ins=$1
  _ble_edit_mark_active= # mark:vi_surround を解除
  local ret
  local type=$_ble_lib_vim_surround_ys_type
  local beg=${_ble_lib_vim_surround_ys_args[0]}
  local end=${_ble_lib_vim_surround_ys_args[1]}
  local context=${_ble_lib_vim_surround_ys_args[2]}
  local sub_ranges; sub_ranges=("${_ble_lib_vim_surround_ys_ranges[@]}")
  _ble_lib_vim_surround_ys_type=
  _ble_lib_vim_surround_ys_args=()
  _ble_lib_vim_surround_ys_ranges=()
  if [[ $context == block ]]; then
    local isub=${#sub_ranges[@]} sub
    local smin= smax= slpad= srpad=
    while ((isub--)); do
      local sub=${sub_ranges[isub]}
      local stext=${sub#*:*:*:*:*:}
      ble/string#split sub : "${sub::${#sub}-${#stext}}"
      smin=${sub[0]} smax=${sub[1]}
      slpad=${sub[2]} srpad=${sub[3]}
      if ! ble/lib/vim-surround.sh/surround "$stext" "$ins"; then
        ble/widget/vi-command/bell
        return 1
      fi
      stext=$ret
      ((slpad)) && { ble/string#repeat ' ' "$slpad"; stext=$ret$stext; }
      ((srpad)) && { ble/string#repeat ' ' "$srpad"; stext=$stext$ret; }
      ble/widget/.replace-range "$smin" "$smax" "$stext" 1
    done
  else
    local text=${_ble_edit_str:beg:end-beg}
    if [[ $type == ys ]]; then
      if local rex=$'[ \t\n]+$'; [[ $text =~ $rex ]]; then
        ((end-=${#BASH_REMATCH}))
        text=${_ble_edit_str:beg:end-beg}
      fi
    fi
    local opts=
    if [[ $type == yS || $type == ySS || $context == char && $type == vgS ]]; then
      opts=linewise:indent
    elif [[ $context == line ]]; then
      opts=linewise
    fi
    if ! ble/lib/vim-surround.sh/surround "$text" "$ins" "$opts"; then
      ble/widget/vi-command/bell
      return 1
    fi
    local text=$ret
    ble/widget/.replace-range "$beg" "$end" "$text" 1
  fi
  _ble_edit_ind=$beg
  if [[ $context == line ]]; then
    ble/widget/vi-command/first-non-space
  else
    ble/keymap:vi/adjust-command-mode
  fi
  ble/keymap:vi/mark/end-edit-area
  ble/lib/vim-surround.sh/ysurround.repeat/record "$type" "$ins"
  return 0
}
function ble/widget/vim-surround.sh/ysurround-current-line {
  ble/widget/vi_nmap/linewise-operator yss
}
function ble/widget/vim-surround.sh/ySurround-current-line {
  ble/widget/vi_nmap/linewise-operator ySS
}
function ble/widget/vim-surround.sh/vsurround { # vS
  ble/widget/vi-command/operator vS
}
function ble/widget/vim-surround.sh/vgsurround { # vgS
  [[ $_ble_decode_keymap == vi_xmap ]] &&
    ble/keymap:vi/xmap/add-eol-extension # 末尾拡張
  ble/widget/vi-command/operator vgS
}
_ble_lib_vim_surround_ys_repeat=()
function ble/lib/vim-surround.sh/ysurround.repeat/entry {
  local -a _ble_keymap_vi_repeat _ble_keymap_vi_repeat_irepeat
  ble/keymap:vi/repeat/record-normal
  _ble_lib_vim_surround_ys_repeat=("${_ble_keymap_vi_repeat[@]}")
}
function ble/lib/vim-surround.sh/ysurround.repeat/record {
  ble/keymap:vi/repeat/record-special && return
  local type=$1 ins=$2
  _ble_keymap_vi_repeat=("${_ble_lib_vim_surround_ys_repeat[@]}")
  _ble_keymap_vi_repeat_irepeat=()
  _ble_keymap_vi_repeat[10]=$type
  _ble_keymap_vi_repeat[11]=$ins
  case $type in
  (vS|vgS)
    _ble_keymap_vi_repeat[2]='ble/widget/vi-command/operator ysurround.repeat'
    _ble_keymap_vi_repeat[4]= ;;
  (yss|ySS)
    _ble_keymap_vi_repeat[2]='ble/widget/vi_nmap/linewise-operator ysurround.repeat'
    _ble_keymap_vi_repeat[4]= ;;
  (*)
    _ble_keymap_vi_repeat[4]=ysurround.repeat
  esac
}
function ble/keymap:vi/operator:ysurround.repeat {
  _ble_lib_vim_surround_ys_type=${_ble_keymap_vi_repeat[10]}
  _ble_lib_vim_surround_ys_args=("$@")
  [[ $3 == block ]] && _ble_lib_vim_surround_ys_ranges=("${sub_ranges[@]}")
  local ins=${_ble_keymap_vi_repeat[11]}
  ble/widget/vim-surround.sh/ysurround.core "$ins"
}
function ble/keymap:vi/operator:surround.record { :; }
function ble/keymap:vi/operator:surround {
  local beg=$1 end=$2 context=$3
  local content=$surround_content ins=$surround_ins trims=$surround_trim
  local ret
  if [[ $trims ]]; then
    ble/string#trim "$content"; content=$ret
  fi
  local opts=; [[ $surround_type == cS ]] && opts=linewise
  if ! ble/lib/vim-surround.sh/surround "$content" "$ins" "$opts"; then
    ble/widget/vi-command/bell
    return 0
  fi
  content=$ret
  ble/widget/.replace-range "$beg" "$end" "$content"
  return 0
}
function ble/keymap:vi/operator:surround-extract-region {
  surround_beg=$beg surround_end=$end
  return 148 # 強制中断する為
}
_ble_lib_vim_surround_cs=()
function ble/widget/vim-surround.sh/nmap/csurround.initialize {
  _ble_lib_vim_surround_cs=("${@:1:3}")
  return 0
}
function ble/widget/vim-surround.sh/nmap/csurround.set-delimiter {
  local type=${_ble_lib_vim_surround_cs[0]}
  local arg=${_ble_lib_vim_surround_cs[1]}
  local reg=${_ble_lib_vim_surround_cs[2]}
  _ble_lib_vim_surround_cs[3]=$1
  local trim=
  [[ $del == ' '?* ]] && trim=1 del=${del:1}
  if [[ $del == a ]]; then
    del='>'
  elif [[ $del == r ]]; then
    del=']'
  elif [[ $del == T ]]; then
    del='t' trim=1
  fi
  local obj1= obj2=
  case "$del" in
  ([wWps])      obj1=i$del obj2=i$del ;;
  ([\'\"\`])    obj1=i$del obj2=a$del arg=1 ;;
  (['bB)}>]t']) obj1=i$del obj2=a$del ;;
  (['({<['])    obj1=i$del obj2=a$del trim=1 ;;
  ([a-zA-Z])    obj1=i$del obj2=a$del ;;
  esac
  local beg end
  if [[ $obj1 && $obj2 ]]; then
    local surround_beg=$_ble_edit_ind surround_end=$_ble_edit_ind
    ble/keymap:vi/text-object.impl "$arg" surround-extract-region '' "$obj2"
    beg=$surround_beg end=$surround_end
  elif [[ $del == / ]]; then
    local rex='(/\*([^/]|/[^*])*/?){1,'$arg'}$'
    [[ ${_ble_edit_str::_ble_edit_ind+2} =~ $rex ]] || return 1
    beg=$((_ble_edit_ind+2-${#BASH_REMATCH}))
    ble/string#index-of "${_ble_edit_str:beg+2}" '*/' || return 1
    end=$((beg+ret+4))
  elif [[ $del ]]; then
    local ret
    ble-edit/content/find-logical-bol; local bol=$ret
    ble-edit/content/find-logical-eol; local eol=$ret
    local line=${_ble_edit_str:bol:eol-bol}
    local ind=$((_ble_edit_ind-bol))
    if ble/string#last-index-of "${line::ind}" "$del"; then
      beg=$ret
    elif local base=$((ind-(2*${#del}-1))); ((base>=0||(base=0)))
         ble/string#index-of "${line:base:ind+${#del}-base}" "$del"; then
      beg=$((base+ret))
    else
      return 1
    fi
    ble/string#index-of "${line:beg+${#del}}" "$del" || return 1
    end=$((beg+2*${#del}+ret))
    ((beg+=bol,end+=bol))
  fi
  _ble_lib_vim_surround_cs[11]=$del
  _ble_lib_vim_surround_cs[12]=$obj1
  _ble_lib_vim_surround_cs[13]=$obj2
  _ble_lib_vim_surround_cs[14]=$beg
  _ble_lib_vim_surround_cs[15]=$end
  _ble_lib_vim_surround_cs[16]=$arg
  _ble_lib_vim_surround_cs[17]=$trim
}
function ble/widget/vim-surround.sh/nmap/csurround.replace {
  local ins=$1
  local type=${_ble_lib_vim_surround_cs[0]}
  local arg=${_ble_lib_vim_surround_cs[1]}
  local reg=${_ble_lib_vim_surround_cs[2]}
  local del=${_ble_lib_vim_surround_cs[3]}
  local del2=${_ble_lib_vim_surround_cs[11]}
  local obj1=${_ble_lib_vim_surround_cs[12]}
  local obj2=${_ble_lib_vim_surround_cs[13]}
  local beg=${_ble_lib_vim_surround_cs[14]}
  local end=${_ble_lib_vim_surround_cs[15]}
  local arg2=${_ble_lib_vim_surround_cs[16]}
  local surround_ins=$ins
  local surround_type=$type
  local surround_trim=${_ble_lib_vim_surround_cs[17]}
  if [[ $obj1 && $obj2 ]]; then
    local ind=$_ble_edit_ind
    local _ble_edit_kill_ring _ble_edit_kill_type
    ble/keymap:vi/text-object.impl "$arg2" y '' "$obj1"; local ext=$?
    _ble_edit_ind=$ind
    ((ext!=0)) && return 1
    local surround_content=$_ble_edit_kill_ring
    ble/keymap:vi/text-object.impl "$arg2" surround '' "$obj2" || return 1
  elif [[ $del2 == / ]]; then
    local surround_content=${_ble_edit_str:beg+2:end-beg-4}
    ble/keymap:vi/call-operator surround "$beg" "$end" char '' ''
    _ble_edit_ind=$beg
  elif [[ $del2 ]]; then
    local surround_content=${_ble_edit_str:beg+${#del2}:end-beg-2*${#del2}}
    ble/keymap:vi/call-operator surround "$beg" "$end" char '' ''
    _ble_edit_ind=$beg
  else
    ble/widget/vi-command/bell
    return 1
  fi
  ble/widget/vim-surround.sh/nmap/csurround.record "$type" "$arg" "$reg" "$del" "$ins"
  ble/keymap:vi/adjust-command-mode
  return 0
}
function ble/widget/vim-surround.sh/nmap/csurround.record {
  [[ $_ble_keymap_vi_mark_suppress_edit ]] && return 0
  local type=$1 arg=$2 reg=$3 del=$4 ins=$5
  local WIDGET=ble/widget/vim-surround.sh/nmap/csurround.repeat ARG=$arg FLAG= REG=$reg
  ble/keymap:vi/repeat/record
  if [[ $_ble_decode_keymap == vi_imap ]]; then
    _ble_keymap_vi_repeat_insert[10]=$type
    _ble_keymap_vi_repeat_insert[11]=$del
    _ble_keymap_vi_repeat_insert[12]=$ins
  else
    _ble_keymap_vi_repeat[10]=$type
    _ble_keymap_vi_repeat[11]=$del
    _ble_keymap_vi_repeat[12]=$ins
  fi
}
function ble/widget/vim-surround.sh/nmap/csurround.repeat {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local type=${_ble_keymap_vi_repeat[10]}
  local del=${_ble_keymap_vi_repeat[11]}
  local ins=${_ble_keymap_vi_repeat[12]}
  ble/widget/vim-surround.sh/nmap/csurround.initialize "$type" "$ARG" "$REG" &&
    ble/widget/vim-surround.sh/nmap/csurround.set-delimiter "$del" &&
    ble/widget/vim-surround.sh/nmap/csurround.replace "$ins" && return 0
  ble/widget/vi-command/bell
  return 1
}
function ble/widget/vim-surround.sh/nmap/dsurround {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  ble/widget/vim-surround.sh/nmap/csurround.initialize ds "$ARG" "$REG"
  ble/lib/vim-surround.sh/async-inputtarget ble/widget/vim-surround.sh/nmap/dsurround.hook
}
function ble/widget/vim-surround.sh/nmap/dsurround.hook {
  local del=$1
  ble/widget/vim-surround.sh/nmap/csurround.set-delimiter "$del" &&
    ble/widget/vim-surround.sh/nmap/csurround.replace '' && return 0
  ble/widget/vi-command/bell
  return 1
}
function ble/highlight/layer:region/mark:vi_csurround/get-selection {
  local beg=${_ble_lib_vim_surround_cs[14]}
  local end=${_ble_lib_vim_surround_cs[15]}
  selection=("$beg" "$end")
}
function ble/highlight/layer:region/mark:vi_csurround/get-face {
  face=region_target
}
function ble/widget/vim-surround.sh/nmap/csurround {
  ble/widget/vim-surround.sh/nmap/csurround.impl cs
}
function ble/widget/vim-surround.sh/nmap/cSurround {
  ble/widget/vim-surround.sh/nmap/csurround.impl cS
}
function ble/widget/vim-surround.sh/nmap/csurround.impl {
  local ARG FLAG REG; ble/keymap:vi/get-arg 1
  local type=$1
  ble/widget/vim-surround.sh/nmap/csurround.initialize "$type" "$ARG" "$REG"
  ble/lib/vim-surround.sh/async-inputtarget ble/widget/vim-surround.sh/nmap/csurround.hook1
}
function ble/widget/vim-surround.sh/nmap/csurround.hook1 {
  local del=$1
  if [[ $del ]] && ble/widget/vim-surround.sh/nmap/csurround.set-delimiter "$del"; then
    _ble_edit_mark_active=vi_csurround
    ble/lib/vim-surround.sh/async-inputtarget-noarg ble/widget/vim-surround.sh/nmap/csurround.hook2
    return
  fi
  _ble_lib_vim_surround_cs=()
  ble/widget/vi-command/bell
  return 1
}
function ble/widget/vim-surround.sh/nmap/csurround.hook2 {
  local ins=$1
  if local rex='^ ?[<tT]$'; [[ $ins =~ $rex ]]; then
    ble/lib/vim-surround.sh/async-read-tagname "ble/widget/vim-surround.sh/nmap/csurround.hook3 '$ins'"
  else
    ble/widget/vim-surround.sh/nmap/csurround.hook3 "$ins"
  fi
}
function ble/widget/vim-surround.sh/nmap/csurround.hook3 {
  local ins=$1 tagName=$2
  _ble_edit_mark_active= # clear mark:vi_csurround
  ble/widget/vim-surround.sh/nmap/csurround.replace "$ins$tagName" && return 0
  ble/widget/vi-command/bell
  return 1
}
function ble/widget/vim-surround.sh/omap {
  local ret
  if ! ble/keymap:vi/k2c "${KEYS[0]}"; then
    ble/widget/.bell
    return 1
  fi
  ble/util/c2s "$ret"; local s=$ret
  local opfunc=${_ble_keymap_vi_opfunc%%:*}$s
  local opflags=${_ble_keymap_vi_opfunc#*:}
  case "$opfunc" in
  (y[sS])
    local ARG FLAG REG; ble/keymap:vi/get-arg 1
    _ble_edit_arg=$ARG
    _ble_keymap_vi_reg=$REG
    ble-decode/keymap/pop
    ble/widget/vi-command/operator "$opfunc:$opflags" ;;
  (yss)
    ble/widget/vi_nmap/linewise-operator "yss:$opflags" ;;
  (yS[sS])
    ble/widget/vi_nmap/linewise-operator "ySS:$opflags" ;;
  (ds) ble/widget/vim-surround.sh/nmap/dsurround ;;
  (cs) ble/widget/vim-surround.sh/nmap/csurround ;;
  (cS) ble/widget/vim-surround.sh/nmap/cSurround ;;
  (*) ble/widget/.bell ;;
  esac
}
ble-bind -m vi_xmap -f 'S'   vim-surround.sh/vsurround
ble-bind -m vi_xmap -f 'g S' vim-surround.sh/vgsurround
if [[ $bleopt_vim_surround_omap_bind ]]; then
  ble-bind -m vi_omap -f s 'vim-surround.sh/omap'
  ble-bind -m vi_omap -f S 'vim-surround.sh/omap'
else
  ble-bind -m vi_nmap -f 'y s'   'vi-command/operator ys'
  ble-bind -m vi_nmap -f 'y s s' 'vim-surround.sh/ysurround-current-line'
  ble-bind -m vi_nmap -f 'y S'   'vi-command/operator yS'
  ble-bind -m vi_nmap -f 'y S s' 'vim-surround.sh/ySurround-current-line'
  ble-bind -m vi_nmap -f 'y S S' 'vim-surround.sh/ySurround-current-line'
  ble-bind -m vi_nmap -f 'd s' 'vim-surround.sh/nmap/dsurround'
  ble-bind -m vi_nmap -f 'c s' 'vim-surround.sh/nmap/csurround'
  ble-bind -m vi_nmap -f 'c S' 'vim-surround.sh/nmap/cSurround'
fi
