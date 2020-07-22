# this script is a part of blesh (https://github.com/akinomyoga/ble.sh) under BSD-3-Clause license
if [ -z "$BASH_VERSION" ]; then
  echo "ble.sh: This shell is not Bash. Please use this script with Bash." >&3
  return 1 2>/dev/null || exit 1
fi 3>&2 >/dev/null 2>&1 # set -x 対策 #D0930
if [ -z "${BASH_VERSINFO[0]}" ] || [ "${BASH_VERSINFO[0]}" -lt 3 ]; then
  echo "ble.sh: Bash with a version under 3.0 is not supported." >&3
  return 1 2>/dev/null || exit 1
fi 3>&2 >/dev/null 2>&1 # set -x 対策 #D0930
if [[ $- != *i* ]]; then
  { ((${#BASH_SOURCE[@]})) && [[ ${BASH_SOURCE[${#BASH_SOURCE[@]}-1]} == *bashrc ]]; } ||
    builtin echo "ble.sh: This is not an interactive session." >&3
  return 1 2>/dev/null || builtin exit 1
fi 3>&2 &>/dev/null # set -x 対策 #D0930
function ble/base/adjust-bash-options {
  [[ $_ble_bash_options_adjusted ]] && return 1 || :
  _ble_bash_options_adjusted=1
  _ble_bash_sete=; [[ -o errexit ]] && _ble_bash_sete=1 && set +e
  _ble_bash_setx=; [[ -o xtrace  ]] && _ble_bash_setx=1 && set +x
  _ble_bash_setv=; [[ -o verbose ]] && _ble_bash_setv=1 && set +v
  _ble_bash_setu=; [[ -o nounset ]] && _ble_bash_setu=1 && set +u
  _ble_bash_nocasematch=
  ((_ble_bash>=30100)) && shopt -q nocasematch &&
    _ble_bash_nocasematch=1 && shopt -u nocasematch
}
function ble/base/restore-bash-options {
  [[ $_ble_bash_options_adjusted ]] || return 1
  _ble_bash_options_adjusted=
  [[ $_ble_bash_setv && ! -o verbose ]] && set -v
  [[ $_ble_bash_setu && ! -o nounset ]] && set -u
  [[ $_ble_bash_setx && ! -o xtrace  ]] && set -x
  [[ $_ble_bash_sete && ! -o errexit ]] && set -e
  if [[ $_ble_bash_nocasematch ]]; then shopt -s nocasematch; fi # Note: set -e により && は駄目
}
{
  _ble_bash_options_adjusted=
  ble/base/adjust-bash-options
} &>/dev/null # set -x 対策 #D0930
_ble_bash=$((BASH_VERSINFO[0]*10000+BASH_VERSINFO[1]*100+BASH_VERSINFO[2]))
_ble_edit_POSIXLY_CORRECT_adjusted=
_ble_edit_POSIXLY_CORRECT_set=
_ble_edit_POSIXLY_CORRECT=
function ble/base/workaround-POSIXLY_CORRECT {
  true
}
function ble/base/unset-POSIXLY_CORRECT {
  if [[ ${POSIXLY_CORRECT+set} ]]; then
    unset -v POSIXLY_CORRECT
    ble/base/workaround-POSIXLY_CORRECT
  fi
}
function ble/base/adjust-POSIXLY_CORRECT {
  [[ $_ble_edit_POSIXLY_CORRECT_adjusted ]] && return
  _ble_edit_POSIXLY_CORRECT_adjusted=1
  _ble_edit_POSIXLY_CORRECT_set=${POSIXLY_CORRECT+set}
  _ble_edit_POSIXLY_CORRECT=$POSIXLY_CORRECT
  unset -v POSIXLY_CORRECT
  ble/base/workaround-POSIXLY_CORRECT
}
function ble/base/restore-POSIXLY_CORRECT {
  if [[ ! $_ble_edit_POSIXLY_CORRECT_adjusted ]]; then return; fi # Note: set -e の為 || は駄目
  _ble_edit_POSIXLY_CORRECT_adjusted=
  if [[ $_ble_edit_POSIXLY_CORRECT_set ]]; then
    POSIXLY_CORRECT=$_ble_edit_POSIXLY_CORRECT
  else
    ble/base/unset-POSIXLY_CORRECT
  fi
}
ble/base/adjust-POSIXLY_CORRECT
builtin bind &>/dev/null # force to load .inputrc
if [[ ! -o emacs && ! -o vi ]]; then
  unset -v _ble_bash
  echo "ble.sh: ble.sh is not intended to be used with the line-editing mode disabled (--noediting)." >&2
  return 1
fi
if shopt -q restricted_shell; then
  unset -v _ble_bash
  echo "ble.sh: ble.sh is not intended to be used in restricted shells (--restricted)." >&2
  return 1
fi
if [[ ${BASH_EXECUTION_STRING+set} ]]; then
  unset -v _ble_bash
  return 1 2>/dev/null || builtin exit 1
fi
_ble_init_original_IFS=$IFS
IFS=$' \t\n'
function ble/bin/.default-utility-path {
  local cmd
  for cmd; do
    eval "function ble/bin/$cmd { command $cmd \"\$@\"; }"
  done
}
function ble/bin/.freeze-utility-path {
  local cmd path q=\' Q="'\''" fail=
  for cmd; do
    if ble/util/assign path "builtin type -P -- $cmd 2>/dev/null" && [[ $path ]]; then
      eval "function ble/bin/$cmd { '${path//$q/$Q}' \"\$@\"; }"
    else
      fail=1
    fi
  done
  ((!fail))
}
_ble_init_posix_command_list=(sed date rm mkdir mkfifo sleep stty sort awk chmod grep cat wc mv sh)
function ble/.check-environment {
  if ! type "${_ble_init_posix_command_list[@]}" &>/dev/null; then
    local cmd commandMissing=
    for cmd in "${_ble_init_posix_command_list[@]}"; do
      if ! type "$cmd" &>/dev/null; then
        commandMissing="$commandMissing\`$cmd', "
      fi
    done
    echo "ble.sh: Insane environment: The command(s), ${commandMissing}not found. Check your environment variable PATH." >&2
    local default_path=$(command -p getconf PATH 2>/dev/null)
    [[ $default_path ]] || return 1
    local original_path=$PATH
    export PATH=${default_path}${PATH:+:}${PATH}
    [[ :$PATH: == *:/bin:* ]] || PATH=/bin${PATH:+:}$PATH
    [[ :$PATH: == *:/usr/bin:* ]] || PATH=/usr/bin${PATH:+:}$PATH
    if ! type "${_ble_init_posix_command_list[@]}" &>/dev/null; then
      PATH=$original_path
      return 1
    fi
    echo "ble.sh: modified PATH=${PATH::${#PATH}-${#original_path}}:\$PATH" >&2
  fi
  if [[ ! $USER ]]; then
    echo "ble.sh: Insane environment: \$USER is empty." >&2
    if type id &>/dev/null; then
      export USER=$(id -un)
      echo "ble.sh: modified USER=$USER" >&2
    fi
  fi
  ble/bin/.default-utility-path "${_ble_init_posix_command_list[@]}"
  return 0
}
if ! ble/.check-environment; then
  _ble_bash=
  return 1
fi
if [[ $_ble_base ]]; then
  if ! ble/base/unload-for-reload &>/dev/null; then
    echo "ble.sh: ble.sh seems to be already loaded." >&2
    return 1
  fi
fi
_ble_bin_awk_solaris_xpg4=
function ble/bin/awk.use-solaris-xpg4 {
  if [[ ! $_ble_bin_awk_solaris_xpg4 ]]; then
    if [[ $OSTYPE == solaris* ]] && type /usr/xpg4/bin/awk >/dev/null; then
      _ble_bin_awk_solaris_xpg4=yes
    else
      _ble_bin_awk_solaris_xpg4=no
    fi
  fi
  [[ $_ble_bin_awk_solaris_xpg4 == yes ]] &&
    function ble/bin/awk { /usr/xpg4/bin/awk "$@"; }
}
BLE_VERSION=0.3.2+2423f4d
function ble/base/initialize-version-information {
  local version=$BLE_VERSION
  local hash=
  if [[ $version == *+* ]]; then
    hash=${version#*+}
    version=${version%%+*}
  fi
  local status=release
  if [[ $version == *-* ]]; then
    status=${version#*-}
    version=${version%%-*}
  fi
  local major=${version%%.*}; version=${version#*.}
  local minor=${version%%.*}; version=${version#*.}
  local patch=${version%%.*}
  BLE_VERSINFO=("$major" "$minor" "$patch" "$hash" "$status" noarch)
}
ble/base/initialize-version-information
_ble_bash_loaded_in_function=0
[[ ${FUNCNAME+set} ]] && _ble_bash_loaded_in_function=1
function ble/util/assign {
  builtin eval "$1=\$(builtin eval \"\${@:2}\")"
}
function ble/util/readlink {
  ret=
  local path=$1
  case "$OSTYPE" in
  (cygwin|linux-gnu)
    ble/util/assign ret 'PATH=/bin:/usr/bin readlink -f "$path"' ;;
  (darwin*|*)
    local PWD=$PWD OLDPWD=$OLDPWD
    while [[ -h $path ]]; do
      local link; ble/util/assign link 'PATH=/bin:/usr/bin readlink "$path" 2>/dev/null || true'
      [[ $link ]] || break
      if [[ $link = /* || $path != */* ]]; then
        path=$link
      else
        local dir=${path%/*}
        path=${dir%/}/$link
      fi
    done
    ret=$path ;;
  esac
}
function ble/base/.create-user-directory {
  local var=$1 dir=$2
  if [[ ! -d $dir ]]; then
    [[ ! -e $dir && -h $dir ]] && ble/bin/rm -f "$dir"
    if [[ -e $dir || -h $dir ]]; then
      echo "ble.sh: cannot create a directory '$dir' since there is already a file." >&2
      return 1
    fi
    if ! (umask 077; ble/bin/mkdir -p "$dir"); then
      echo "ble.sh: failed to create a directory '$dir'." >&2
      return 1
    fi
  elif ! [[ -r $dir && -w $dir && -x $dir ]]; then
    echo "ble.sh: permision of '$tmpdir' is not correct." >&2
    return 1
  fi
  eval "$var=\$dir"
}
function ble/base/initialize-base-directory {
  local src=$1
  local defaultDir=$2
  if [[ -h $src ]] && type -t readlink &>/dev/null; then
    local ret; ble/util/readlink "$src"; src=$ret
  fi
  if [[ -s $src && $src != */* ]]; then
    _ble_base=$PWD
  elif [[ $src == */* ]]; then
    local dir=${src%/*}
    if [[ ! $dir ]]; then
      _ble_base=/
    elif [[ $dir != /* ]]; then
      _ble_base=$PWD/$dir
    else
      _ble_base=$dir
    fi
  else
    _ble_base=${defaultDir:-$HOME/.local/share/blesh}
  fi
  [[ -d $_ble_base ]]
}
if ! ble/base/initialize-base-directory "${BASH_SOURCE[0]}"; then
  echo "ble.sh: ble base directory not found!" 1>&2
  return 1
fi
function ble/base/initialize-runtime-directory/.xdg {
  [[ $_ble_base != */out ]] || return
  local runtime_dir=${XDG_RUNTIME_DIR:-/run/user/$UID}
  if [[ ! -d $runtime_dir ]]; then
    [[ $XDG_RUNTIME_DIR ]] &&
      echo "ble.sh: XDG_RUNTIME_DIR='$XDG_RUNTIME_DIR' is not a directory." >&2
    return 1
  fi
  if ! [[ -r $runtime_dir && -w $runtime_dir && -x $runtime_dir ]]; then
    [[ $XDG_RUNTIME_DIR ]] &&
      echo "ble.sh: XDG_RUNTIME_DIR='$XDG_RUNTIME_DIR' doesn't have a proper permission." >&2
    return 1
  fi
  ble/base/.create-user-directory _ble_base_run "$runtime_dir/blesh"
}
function ble/base/initialize-runtime-directory/.tmp {
  [[ -r /tmp && -w /tmp && -x /tmp ]] || return
  local tmp_dir=/tmp/blesh
  if [[ ! -d $tmp_dir ]]; then
    [[ ! -e $tmp_dir && -h $tmp_dir ]] && ble/bin/rm -f "$tmp_dir"
    if [[ -e $tmp_dir || -h $tmp_dir ]]; then
      echo "ble.sh: cannot create a directory '$tmp_dir' since there is already a file." >&2
      return 1
    fi
    ble/bin/mkdir -p "$tmp_dir" || return
    ble/bin/chmod a+rwxt "$tmp_dir" || return
  elif ! [[ -r $tmp_dir && -w $tmp_dir && -x $tmp_dir ]]; then
    echo "ble.sh: permision of '$tmp_dir' is not correct." >&2
    return 1
  fi
  ble/base/.create-user-directory _ble_base_run "$tmp_dir/$UID"
}
function ble/base/initialize-runtime-directory {
  ble/base/initialize-runtime-directory/.xdg && return
  ble/base/initialize-runtime-directory/.tmp && return
  local tmp_dir=$_ble_base/tmp
  if [[ ! -d $tmp_dir ]]; then
    ble/bin/mkdir -p "$tmp_dir" || return
    ble/bin/chmod a+rwxt "$tmp_dir" || return
  fi
  ble/base/.create-user-directory _ble_base_run "$tmp_dir/$UID"
}
if ! ble/base/initialize-runtime-directory; then
  echo "ble.sh: failed to initialize \$_ble_base_run." 1>&2
  return 1
fi
function ble/base/clean-up-runtime-directory {
  local file pid mark removed
  mark=() removed=()
  for file in "$_ble_base_run"/[1-9]*.*; do
    [[ -e $file ]] || continue
    pid=${file##*/}; pid=${pid%%.*}
    [[ ${mark[pid]} ]] && continue
    mark[pid]=1
    if ! builtin kill -0 "$pid" &>/dev/null; then
      removed=("${removed[@]}" "$_ble_base_run/$pid."*)
    fi
  done
  ((${#removed[@]})) && ble/bin/rm -f "${removed[@]}"
}
if shopt -q failglob &>/dev/null; then
  shopt -u failglob
  ble/base/clean-up-runtime-directory
  shopt -s failglob
else
  ble/base/clean-up-runtime-directory
fi
function ble/base/initialize-cache-directory/.xdg {
  [[ $_ble_base != */out ]] || return
  local cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}
  if [[ ! -d $cache_dir ]]; then
    [[ $XDG_CACHE_HOME ]] &&
      echo "ble.sh: XDG_CACHE_HOME='$XDG_CACHE_HOME' is not a directory." >&2
    return 1
  fi
  if ! [[ -r $cache_dir && -w $cache_dir && -x $cache_dir ]]; then
    [[ $XDG_CACHE_HOME ]] &&
      echo "ble.sh: XDG_CACHE_HOME='$XDG_CACHE_HOME' doesn't have a proper permission." >&2
    return 1
  fi
  local ver=${BLE_VERSINFO[0]}.${BLE_VERSINFO[1]}
  ble/base/.create-user-directory _ble_base_cache "$cache_dir/blesh/$ver"
}
function ble/base/initialize-cache-directory {
  ble/base/initialize-cache-directory/.xdg && return
  local cache_dir=$_ble_base/cache.d
  if [[ ! -d $cache_dir ]]; then
    ble/bin/mkdir -p "$cache_dir" || return
    ble/bin/chmod a+rwxt "$cache_dir" || return
    local old_cache_dir=$_ble_base/cache
    if [[ -d $old_cache_dir && ! -h $old_cache_dir ]]; then
      mv "$old_cache_dir" "$cache_dir/$UID"
      ln -s "$cache_dir/$UID" "$old_cache_dir"
    fi
  fi
  ble/base/.create-user-directory _ble_base_cache "$cache_dir/$UID"
}
if ! ble/base/initialize-cache-directory; then
  echo "ble.sh: failed to initialize \$_ble_base_cache." 1>&2
  return 1
fi
function ble/base/print-usage-for-no-argument-command {
  local name=${FUNCNAME[1]} desc=$1; shift
  printf '%s\n' \
         "usage: $name" \
         "$desc" >&2
  [[ $1 != --help ]] && return 2
  return 0
}
function ble-reload { source "$_ble_base/ble.sh" --attach=prompt; }
_ble_base_repository='release:v0.3-master'
function ble-update {
  if (($#)); then
    ble/base/print-usage-for-no-argument-command 'Update and reload ble.sh.' "$@"
    return
  fi
  local MAKE=
  if type gmake &>/dev/null; then
    MAKE=gmake
  elif type make &>/dev/null && make --version 2>&1 | grep -qiF 'GNU Make'; then
    MAKE=make
  else
    echo "ble-update: GNU Make is not available." >&2
    return 1
  fi
  if ! type git gawk &>/dev/null; then
    local command
    for command in git gawk; do
      type "$command" ||
        echo "ble-update: '$command' command is not available." >&2
    done
    return 1
  fi
  if [[ $_ble_base_repository == release:* ]]; then
    local branch=${_ble_base_repository#*:}
    ( ble/bin/mkdir -p "$_ble_base/src" && builtin cd "$_ble_base/src" &&
        git clone --depth 1 https://github.com/akinomyoga/ble.sh "$_ble_base/src/ble.sh" -b "$branch" &&
        builtin cd ble.sh && "$MAKE" all && "$MAKE" INSDIR="$_ble_base" install ) &&
      ble-reload
    return
  fi
  if [[ $_ble_base_repository && -d $_ble_base_repository/.git ]]; then
    ( echo "cd into $_ble_base_repository..." >&2 &&
        builtin cd "$_ble_base_repository" &&
        git pull && { ! "$MAKE" -q || builtin exit 6; } && "$MAKE" all &&
        if [[ $_ble_base != "$_ble_base_repository"/out ]]; then
          "$MAKE" INSDIR="$_ble_base" install
        fi ); local ext=$?
    ((ext==6)) && return
    ((ext==0)) && ble-reload
    return "$ext"
  fi
  echo 'ble-update: git repository not found' >&2
  return 1
}
ble/bin/awk.use-solaris-xpg4
_ble_color_faces_defface_hook=()
_ble_color_faces_setface_hook=()
function bleopt {
  local error_flag=
  local -a pvars
  if (($#==0)); then
    pvars=("${!bleopt_@}")
  else
    local spec var type= value= ip=0 rex
    pvars=()
    for spec; do
      if rex='^[[:alnum:]_]+:='; [[ $spec =~ $rex ]]; then
        type=a var=${spec%%:=*} value=${spec#*:=}
      elif rex='^[[:alnum:]_]+='; [[ $spec =~ $rex ]]; then
        type=ac var=${spec%%=*} value=${spec#*=}
      elif rex='^[[:alnum:]_]+$'; [[ $spec =~ $rex ]]; then
        type=p var=$spec
      else
        echo "bleopt: unrecognized argument '$spec'" >&2
        continue
      fi
      var=bleopt_${var#bleopt_}
      if [[ $type == *c* && ! ${!var+set} ]]; then
        error_flag=1
        echo "bleopt: unknown bleopt option \`${var#bleopt_}'" >&2
        continue
      fi
      case "$type" in
      (a*)
        [[ ${!var} == "$value" ]] && continue
        if ble/is-function bleopt/check:"${var#bleopt_}"; then
          if ! bleopt/check:"${var#bleopt_}"; then
            error_flag=1
            continue
          fi
        fi
        eval "$var=\"\$value\"" ;;
      (p*) pvars[ip++]=$var ;;
      (*)  echo "bleopt: unknown type '$type' of the argument \`$spec'" >&2 ;;
      esac
    done
  fi
  if ((${#pvars[@]})); then
    local q="'" Q="'\''" var
    for var in "${pvars[@]}"; do
      if [[ ${!var+set} ]]; then
        builtin printf '%s\n' "bleopt ${var#bleopt_}='${!var//$q/$Q}'"
      else
        builtin printf '%s\n' "bleopt: invalid ble option name '${var#bleopt_}'" >&2
      fi
    done
  fi
  [[ ! $error_flag ]]
}
function bleopt/declare {
  local type=$1 name=bleopt_$2 default_value=$3
  if [[ $type == -n ]]; then
    eval ": \"\${$name:=\$default_value}\""
  else
    eval ": \"\${$name=\$default_value}\""
  fi
  return 0
}
bleopt/declare -n input_encoding UTF-8
function bleopt/check:input_encoding {
  if ! ble/is-function "ble/encoding:$value/decode"; then
    echo "bleopt: Invalid value input_encoding='$value'." \
         "A function 'ble/encoding:$value/decode' is not defined." >&2
    return 1
  elif ! ble/is-function "ble/encoding:$value/b2c"; then
    echo "bleopt: Invalid value input_encoding='$value'." \
         "A function 'ble/encoding:$value/b2c' is not defined." >&2
    return 1
  elif ! ble/is-function "ble/encoding:$value/c2bc"; then
    echo "bleopt: Invalid value input_encoding='$value'." \
         "A function 'ble/encoding:$value/c2bc' is not defined." >&2
    return 1
  elif ! ble/is-function "ble/encoding:$value/generate-binder"; then
    echo "bleopt: Invalid value input_encoding='$value'." \
         "A function 'ble/encoding:$value/generate-binder' is not defined." >&2
    return 1
  elif ! ble/is-function "ble/encoding:$value/is-intermediate"; then
    echo "bleopt: Invalid value input_encoding='$value'." \
         "A function 'ble/encoding:$value/is-intermediate' is not defined." >&2
    return 1
  fi
  if [[ $bleopt_input_encoding != "$value" ]]; then
    ble-decode/unbind
    bleopt_input_encoding=$value
    ble-decode/bind
  fi
  return 0
}
bleopt/declare -v internal_stackdump_enabled 0
bleopt/declare -n openat_base 30
bleopt/declare -v pager ''
shopt -s checkwinsize
_ble_util_upvar_setup='local var=ret ret; [[ $1 == -v ]] && var=$2 && shift 2'
_ble_util_upvar='local "${var%%\[*\]}" && ble/util/upvar "$var" "$ret"'
if ((_ble_bash>=50000)); then
  function ble/util/unlocal {
    if shopt -q localvar_unset; then
      shopt -u localvar_unset
      builtin unset -v "$@"
      shopt -s localvar_unset
    else
      builtin unset -v "$@"
    fi
  }
  function ble/util/upvar { ble/util/unlocal "${1%%\[*\]}" && builtin eval "$1=\"\$2\""; }
  function ble/util/uparr { ble/util/unlocal "$1" && builtin eval "$1=(\"\${@:2}\")"; }
else
  function ble/util/unlocal { builtin unset -v "$@"; }
  function ble/util/upvar { builtin unset -v "${1%%\[*\]}" && builtin eval "$1=\"\$2\""; }
  function ble/util/uparr { builtin unset -v "$1" && builtin eval "$1=(\"\${@:2}\")"; }
fi
function ble/util/save-vars {
  local name prefix=$1; shift
  for name; do eval "$prefix$name=\"\$$name\""; done
}
function ble/util/save-arrs {
  local name prefix=$1; shift
  for name; do eval "$prefix$name=(\"\${$name[@]}\")"; done
}
function ble/util/restore-vars {
  local name prefix=$1; shift
  for name; do eval "$name=\"\$$prefix$name\""; done
}
function ble/util/restore-arrs {
  local name prefix=$1; shift
  for name; do eval "$name=(\"\${$prefix$name[@]}\")"; done
}
_ble_array_prototype=()
function ble/array#reserve-prototype {
  local n=$1 i
  for ((i=${#_ble_array_prototype[@]};i<n;i++)); do
    _ble_array_prototype[i]=
  done
}
if ((_ble_bash>=40400)); then
  function ble/is-array { [[ ${!1@a} == *a* ]]; }
else
  function ble/is-array { compgen -A arrayvar -X \!"$1" "$1" &>/dev/null; }
fi
if ((_ble_bash>=40000)); then
  function ble/array#push {
    builtin eval "$1+=(\"\${@:2}\")"
  }
elif ((_ble_bash>=30100)); then
  function ble/array#push {
    IFS=$' \t\n' builtin eval "$1+=(\"\${@:2}\")"
  }
else
  function ble/array#push {
    while (($#>=2)); do
      builtin eval "$1[\${#$1[@]}]=\"\$2\""
      set -- "$1" "${@:3}"
    done
  }
fi
function ble/array#pop {
  eval "local i$1=\$((\${#$1[@]}-1))"
  if ((i$1>=0)); then
    eval "ret=\${$1[i$1]}"
    unset -v "$1[i$1]"
  else
    ret=
  fi
}
function ble/array#reverse {
  builtin eval "
  set -- \"\${$1[@]}\"; $1=()
  local e$1 i$1=\$#
  for e$1; do $1[--i$1]=\"\$e$1\"; done"
}
function ble/array#insert-at {
  builtin eval "$1=(\"\${$1[@]::$2}\" \"\${@:3}\" \"\${$1[@]:$2}\")"
}
function ble/array#insert-after {
  local _ble_local_script='
    local iARR=0 eARR aARR=
    for eARR in "${ARR[@]}"; do
      ((iARR++))
      [[ $eARR == "$2" ]] && aARR=iARR && break
    done
    [[ $aARR ]] && ble/array#insert-at "$1" "$aARR" "${@:3}"
  '; builtin eval "${_ble_local_script//ARR/$1}"
}
function ble/array#insert-before {
  local _ble_local_script='
    local iARR=0 eARR aARR=
    for eARR in "${ARR[@]}"; do
      [[ $eARR == "$2" ]] && aARR=iARR && break
      ((iARR++))
    done
    [[ $aARR ]] && ble/array#insert-at "$1" "$aARR" "${@:3}"
  '; builtin eval "${_ble_local_script//ARR/$1}"
}
function ble/array#remove {
  local _ble_local_script='
    local -a aARR=() eARR
    for eARR in "${ARR[@]}"; do
      [[ $eARR != "$2" ]] && ble/array#push "a$1" "$eARR"
    done
    ARR=(${ARR[@]})
  '; builtin eval "${_ble_local_script//ARR/$1}"
}
function ble/array#index {
  local _ble_local_script='
    local eARR iARR=0
    for eARR in "${ARR[@]}"; do
      [[ $eARR == "$2" ]] && { ret=$iARR; return 0; }
      ((iARR++))
    done
    ret=-1; return 1
  '; builtin eval "${_ble_local_script//ARR/$1}"
}
function ble/array#last-index {
  local _ble_local_script='
    local eARR iARR=${#ARR[@]}
    while ((iARR--)); do
      [[ ${ARR[iARR]} == "$2" ]] && { ret=$iARR; return 0; }
    done
    ret=-1; return 1
  '; builtin eval "${_ble_local_script//ARR/$1}"
}
_ble_string_prototype='        '
function ble/string#reserve-prototype {
  local n=$1 c
  for ((c=${#_ble_string_prototype};c<n;c*=2)); do
    _ble_string_prototype=$_ble_string_prototype$_ble_string_prototype
  done
}
function ble/string#repeat {
  ble/string#reserve-prototype "$2"
  ret=${_ble_string_prototype::$2}
  ret="${ret// /$1}"
}
function ble/string#common-prefix {
  local a=$1 b=$2
  ((${#a}>${#b})) && local a=$b b=$a
  b=${b::${#a}}
  if [[ $a == "$b" ]]; then
    ret=$a
    return
  fi
  local l=0 u=${#a} m
  while ((l+1<u)); do
    ((m=(l+u)/2))
    if [[ ${a::m} == "${b::m}" ]]; then
      ((l=m))
    else
      ((u=m))
    fi
  done
  ret=${a::l}
}
function ble/string#common-suffix {
  local a=$1 b=$2
  ((${#a}>${#b})) && local a=$b b=$a
  b=${b:${#b}-${#a}}
  if [[ $a == "$b" ]]; then
    ret=$a
    return
  fi
  local l=0 u=${#a} m
  while ((l+1<u)); do
    ((m=(l+u+1)/2))
    if [[ ${a:m} == "${b:m}" ]]; then
      ((u=m))
    else
      ((l=m))
    fi
  done
  ret=${a:u}
}
function ble/string#split {
  if [[ -o noglob ]]; then
    IFS=$2 builtin eval "$1=(\${*:3}\$2)"
  else
    set -f
    IFS=$2 builtin eval "$1=(\${*:3}\$2)"
    set +f
  fi
}
function ble/string#split-words {
  if [[ -o noglob ]]; then
    IFS=$' \t\n' builtin eval "$1=(\${*:2})"
  else
    set -f
    IFS=$' \t\n' builtin eval "$1=(\${*:2})"
    set +f
  fi
}
if ((_ble_bash>=40000)); then
  function ble/string#split-lines {
    mapfile -t "$1" <<< "${*:2}"
  }
else
  function ble/string#split-lines {
    ble/util/mapfile "$1" <<< "${*:2}"
  }
fi
function ble/string#count-char {
  local text=$1 char=$2
  text=${text//[!"$char"]}
  ret=${#text}
}
function ble/string#count-string {
  local text=${1//"$2"}
  ((ret=(${#1}-${#text})/${#2}))
}
function ble/string#index-of {
  local haystack=$1 needle=$2 count=${3:-1}
  ble/string#repeat '*"$needle"' "$count"; local pattern=$ret
  eval "local transformed=\${haystack#$pattern}"
  ((ret=${#haystack}-${#transformed}-${#needle},
    ret<0&&(ret=-1),ret>=0))
}
function ble/string#last-index-of {
  local haystack=$1 needle=$2 count=${3:-1}
  ble/string#repeat '"$needle"*' "$count"; local pattern=$ret
  eval "local transformed=\${haystack%$pattern}"
  if [[ $transformed == "$haystack" ]]; then
    ret=-1
  else
    ret=${#transformed}
  fi
  ((ret>=0))
}
_ble_util_string_lower_list=abcdefghijklmnopqrstuvwxyz
_ble_util_string_upper_list=ABCDEFGHIJKLMNOPQRSTUVWXYZ
function ble/string#toggle-case {
  local text=$* ch i
  local -a buff
  for ((i=0;i<${#text};i++)); do
    ch=${text:i:1}
    if [[ $ch == [A-Z] ]]; then
      ch=${_ble_util_string_upper_list%%"$ch"*}
      ch=${_ble_util_string_lower_list:${#ch}:1}
    elif [[ $ch == [a-z] ]]; then
      ch=${_ble_util_string_lower_list%%"$ch"*}
      ch=${_ble_util_string_upper_list:${#ch}:1}
    fi
    ble/array#push buff "$ch"
  done
  IFS= eval 'ret="${buff[*]-}"'
}
if ((_ble_bash>=40000)); then
  function ble/string#tolower { ret="${*,,}"; }
  function ble/string#toupper { ret="${*^^}"; }
else
  function ble/string#tolower {
    local text="$*"
    local -a buff ch
    for ((i=0;i<${#text};i++)); do
      ch=${text:i:1}
      if [[ $ch == [A-Z] ]]; then
        ch=${_ble_util_string_upper_list%%"$ch"*}
        ch=${_ble_util_string_lower_list:${#ch}:1}
      fi
      ble/array#push buff "$ch"
    done
    IFS= eval 'ret="${buff[*]-}"'
  }
  function ble/string#toupper {
    local text="$*"
    local -a buff ch
    for ((i=0;i<${#text};i++)); do
      ch=${text:i:1}
      if [[ $ch == [a-z] ]]; then
        ch=${_ble_util_string_lower_list%%"$ch"*}
        ch=${_ble_util_string_upper_list:${#ch}:1}
      fi
      ble/array#push buff "$ch"
    done
    IFS= eval 'ret="${buff[*]-}"'
  }
fi
function ble/string#trim {
  ret="$*"
  local rex=$'^[ \t\n]+'
  [[ $ret =~ $rex ]] && ret=${ret:${#BASH_REMATCH}}
  local rex=$'[ \t\n]+$'
  [[ $ret =~ $rex ]] && ret=${ret::${#ret}-${#BASH_REMATCH}}
}
function ble/string#ltrim {
  ret="$*"
  local rex=$'^[ \t\n]+'
  [[ $ret =~ $rex ]] && ret=${ret:${#BASH_REMATCH}}
}
function ble/string#rtrim {
  ret="$*"
  local rex=$'[ \t\n]+$'
  [[ $ret =~ $rex ]] && ret=${ret::${#ret}-${#BASH_REMATCH}}
}
function ble/string#escape-characters {
  ret=$1
  if [[ $ret == *["$2"]* ]]; then
    local chars1=$2 chars2=${3:-$2}
    local i n=${#chars1} a b
    for ((i=0;i<n;i++)); do
      a=${chars1:i:1} b=\\${chars2:i:1} ret=${ret//"$a"/$b}
    done
  fi
}
function ble/string#escape-for-sed-regex {
  ble/string#escape-characters "$*" '\.[*^$/'
}
function ble/string#escape-for-awk-regex {
  ble/string#escape-characters "$*" '\.[*?+|^$(){}/'
}
function ble/string#escape-for-extended-regex {
  ble/string#escape-characters "$*" '\.[*?+|^$(){}'
}
function ble/string#escape-for-bash-glob {
  ble/string#escape-characters "$*" '\*?[('
}
function ble/string#escape-for-bash-single-quote {
  ret="$*"
  local q="'" Q="'\''"
  ret=${ret//"$q"/$Q}
}
function ble/string#escape-for-bash-double-quote {
  ble/string#escape-characters "$*" '\"$`'
  local a b
  a='!' b='"\!"' ret=${ret//"$a"/$b}
}
function ble/string#escape-for-bash-escape-string {
  ble/string#escape-characters "$*" $'\\\a\b\e\f\n\r\t\v'\' '\abefnrtv'\'
}
function ble/string#escape-for-bash-specialchars {
  ble/string#escape-characters "$*" '\ ["'\''`$|&;<>()*?!^{'
  if [[ $ret == *[$']\n\t']* ]]; then
    local a b
    a=']'   b=\\$a     ret=${ret//"$a"/$b}
    a=$'\n' b="\$'\n'" ret=${ret//"$a"/$b}
    a=$'\t' b=$' \t'   ret=${ret//"$a"/$b}
  fi
}
function ble/string#escape-for-bash-specialchars-in-brace {
  ble/string#escape-characters "$*" '\ ["'\''`$|&;<>()*?!^{,}'
  if [[ $ret == *[$']\n\t']* ]]; then
    local a b
    a=']'   b=\\$a     ret=${ret//"$a"/$b}
    a=$'\n' b="\$'\n'" ret=${ret//"$a"/$b}
    a=$'\t' b=$' \t'   ret=${ret//"$a"/$b}
  fi
}
function ble/string#create-unicode-progress-bar {
  local value=$1 max=$2 width=$3
  local progress=$((value*8*width/max))
  local progress_fraction=$((progress%8)) progress_integral=$((progress/8))
  local out=
  if ((progress_integral)); then
    ble/util/c2s $((0x2588))
    ((${#ret}==1)) || ret='*' # LC_CTYPE が非対応の文字の時
    ble/string#repeat "$ret" "$progress_integral"
    out=$ret
  fi
  if ((progress_fraction)); then
    ble/util/c2s $((0x2590-progress_fraction))
    ((${#ret}==1)) || ret=$progress_fraction # LC_CTYPE が非対応の文字の時
    out=$out$ret
    ((progress_integral++))
  fi
  if ((progress_integral<width)); then
    ble/util/c2w $((0x2588))
    ble/string#repeat ' ' $((ret*(width-progress_integral)))
    out=$out$ret
  fi
  ret=$out
}
function ble/path#remove {
  local _ble_local_script='
    opts=:$opts:
    opts=${opts//:"$2":/:}
    opts=${opts#:} opts=${opts%:}'
  builtin eval "${_ble_local_script//opts/$1}"
}
function ble/path#remove-glob {
  local _ble_local_script='
    opts=:$opts:
    opts=${opts//:$2:/:}
    opts=${opts#:} opts=${opts%:}'
  builtin eval "${_ble_local_script//opts/$1}"
}
if ((_ble_bash>=40000)); then
  function ble/util/readfile { # 155ms for man bash
    local __buffer
    mapfile __buffer < "$2"
    IFS= eval "$1"'="${__buffer[*]-}"'
  }
  function ble/util/mapfile {
    mapfile -t "$1"
  }
else
  function ble/util/readfile { # 465ms for man bash
    IFS= builtin read -r -d '' "$1" < "$2"
  }
  function ble/util/mapfile {
    local _ble_local_i=0 _ble_local_val _ble_local_arr; _ble_local_arr=()
    while builtin read -r _ble_local_val || [[ $_ble_local_val ]]; do
      _ble_local_arr[_ble_local_i++]=$_ble_local_val
    done
    builtin eval "$1=(\"\${_ble_local_arr[@]}\")"
  }
fi
_ble_util_assign_base=$_ble_base_run/$$.ble_util_assign.tmp
_ble_util_assign_level=0
if ((_ble_bash>=40000)); then
  function ble/util/assign {
    local _ble_local_tmp=$_ble_util_assign_base.$((_ble_util_assign_level++))
    builtin eval "$2" >| "$_ble_local_tmp"
    local _ble_local_ret=$? _ble_local_arr=
    ((_ble_util_assign_level--))
    mapfile -t _ble_local_arr < "$_ble_local_tmp"
    IFS=$'\n' eval "$1=\"\${_ble_local_arr[*]}\""
    return "$_ble_local_ret"
  }
else
  function ble/util/assign {
    local _ble_local_tmp=$_ble_util_assign_base.$((_ble_util_assign_level++))
    builtin eval "$2" >| "$_ble_local_tmp"
    local _ble_local_ret=$?
    ((_ble_util_assign_level--))
    IFS= builtin read -r -d '' "$1" < "$_ble_local_tmp"
    eval "$1=\${$1%$'\n'}"
    return "$_ble_local_ret"
  }
fi
if ((_ble_bash>=40000)); then
  function ble/util/assign-array {
    local _ble_local_tmp=$_ble_util_assign_base.$((_ble_util_assign_level++))
    builtin eval "$2" >| "$_ble_local_tmp"
    local _ble_local_ret=$?
    ((_ble_util_assign_level--))
    mapfile -t "$1" < "$_ble_local_tmp"
    return "$_ble_local_ret"
  }
else
  function ble/util/assign-array {
    local _ble_local_tmp=$_ble_util_assign_base.$((_ble_util_assign_level++))
    builtin eval "$2" >| "$_ble_local_tmp"
    local _ble_local_ret=$?
    ((_ble_util_assign_level--))
    ble/util/mapfile "$1" < "$_ble_local_tmp"
    return "$_ble_local_ret"
  }
fi
if ((_ble_bash>=30200)); then
  function ble/is-function {
    builtin declare -F "$1" &>/dev/null
  }
else
  function ble/is-function {
    local type
    ble/util/type type "$1"
    [[ $type == function ]]
  }
fi
function ble/function#try {
  ble/is-function "$1" || return 127
  "$@"
}
if ((_ble_bash>=40100)); then
  function ble/util/set {
    builtin printf -v "$1" %s "$2"
  }
else
  function ble/util/set {
    builtin eval "$1=\"\$2\""
  }
fi
if ((_ble_bash>=30100)); then
  function ble/util/sprintf {
    builtin printf -v "$@"
  }
else
  function ble/util/sprintf {
    local -a args; args=("${@:2}")
    ble/util/assign "$1" 'builtin printf "${args[@]}"'
  }
fi
function ble/util/type {
  ble/util/assign "$1" 'builtin type -t -- "$3" 2>/dev/null' "$2"
  builtin eval "$1=\"\${$1%$_ble_term_nl}\""
}
if ((_ble_bash>=40000)); then
  function ble/util/is-stdin-ready { IFS= LC_ALL=C builtin read -t 0; } &>/dev/null
else
  function ble/util/is-stdin-ready { false; }
fi
if ((_ble_bash>=40000)); then
  function ble/util/is-running-in-subshell { [[ $$ != $BASHPID ]]; }
else
  function ble/util/is-running-in-subshell {
    ((BASH_SUBSHELL)) && return 0
    local bashpid= command='echo $PPID'
    ble/util/assign bashpid 'ble/bin/sh -c "$command"'
    [[ $$ != $bashpid ]]
  }
fi
_ble_util_openat_fdlist=()
if ((_ble_bash>=40100)); then
  function ble/util/openat {
    builtin eval "exec {$1}$2"; local _ble_local_ret=$?
    ble/array#push _ble_util_openat_fdlist "${!1}"
    return "$_ble_local_ret"
  }
else
  _ble_util_openat_nextfd=$bleopt_openat_base
  function ble/util/openat/.nextfd {
    if ((30100<=_ble_bash&&_ble_bash<30200)); then
      while [[ -e /dev/fd/$_ble_util_openat_nextfd || -e /proc/self/fd/$_ble_util_openat_nextfd ]]; do
        ((_ble_util_openat_nextfd++))
      done
    fi
    (($1=_ble_util_openat_nextfd++))
  }
  function ble/util/openat {
    local _fdvar=$1 _redirect=$2
    ble/util/openat/.nextfd "$1"
    builtin eval "exec ${!1}>&- ${!1}$2"; local _ble_local_ret=$?
    ble/array#push _ble_util_openat_fdlist "${!1}"
    return "$_ble_local_ret"
  }
fi
function ble/util/openat/finalize {
  local fd
  for fd in "${_ble_util_openat_fdlist[@]}"; do
    builtin eval "exec $fd>&-"
  done
  _ble_util_openat_fdlist=()
}
function ble/util/declare-print-definitions {
  if [[ $# -gt 0 ]]; then
    declare -p "$@" | ble/bin/awk -v _ble_bash="$_ble_bash" '
      BEGIN { decl = ""; }
      function declflush(_, isArray) {
        if (decl) {
          isArray = (decl ~ /declare +-[fFgilrtux]*[aA]/);
          if (_ble_bash < 30100) gsub(/\\\n/, "\n", decl);
          if (_ble_bash < 40000) {
            gsub(/\001\001/, "\001\002", decl);
            gsub(/\001\177/, "\177", decl);
            gsub(/\001\002/, "\001", decl);
          }
          sub(/^declare +(-[-aAfFgilrtux]+ +)?(-- +)?/, "", decl);
          if (isArray) {
            if (decl ~ /^([[:alpha:]_][[:alnum:]_]*)='\''\(.*\)'\''$/) {
              sub(/='\''\(/, "=(", decl);
              sub(/\)'\''$/, ")", decl);
              gsub(/'\'\\\\\'\''/, "'\''", decl);
            }
          }
          print decl;
          decl = "";
        }
      }
      /^declare / {
        declflush();
        decl = $0;
        next;
      }
      { decl = decl "\n" $0; }
      END { declflush(); }
    '
  fi
}
if ((_ble_bash>=40200)); then
  function ble/util/print-global-definitions {
    local __ble_hidden_only=
    [[ $1 == --hidden-only ]] && { __ble_hidden_only=1; shift; }
    (
      ((_ble_bash>=50000)) && shopt -u localvar_unset
      __ble_error=
      __ble_q="'" __ble_Q="'\''"
      __ble_MaxLoop=20
      for __ble_name; do
        ((__ble_processed_$__ble_name)) && continue
        ((__ble_processed_$__ble_name=1))
        [[ $_ble_name == __ble_* ]] && continue
        declare -g -r "$__ble_name"
        for ((__ble_i=0;__ble_i<__ble_MaxLoop;__ble_i++)); do
          __ble_value=${!__ble_name}
          unset -v "$__ble_name" || break
        done 2>/dev/null
        ((__ble_i==__ble_MaxLoop)) && __ble_error=1 __ble_value= # not found
        [[ $__ble_hidden_only && $__ble_i == 0 ]] && continue
        echo "declare $__ble_name='${__ble_value//$__ble_q//$__ble_Q}'"
      done
      [[ ! $__ble_error ]]
    ) 2>/dev/null
  }
else
  function ble/util/print-global-definitions {
    local __ble_hidden_only=
    [[ $1 == --hidden-only ]] && { __ble_hidden_only=1; shift; }
    (
      ((_ble_bash>=50000)) && shopt -u localvar_unset
      __ble_error=
      __ble_q="'" __ble_Q="'\''"
      __ble_MaxLoop=20
      for __ble_name; do
        ((__ble_processed_$__ble_name)) && continue
        ((__ble_processed_$__ble_name=1))
        [[ $_ble_name == __ble_* ]] && continue
        __ble_value= __ble_found=
        for ((__ble_i=0;__ble_i<__ble_MaxLoop;__ble_i++)); do
          [[ ${!__ble_name+set} ]] && __ble_value=${!__ble_name} __ble_found=$__ble_i
          unset -v "$__ble_name" 2>/dev/null
        done
        [[ $__ble_found ]] || __ble_error= __ble_value= # not found
        [[ $__ble_hidden_only && $__ble_found == 0 ]] && continue
        echo "declare $__ble_name='${__ble_value//$__ble_q//$__ble_Q}'"
      done
      [[ ! $__ble_error ]]
    ) 2>/dev/null
  }
fi
function ble/util/eval-pathname-expansion {
  ret=()
  eval "ret=($1)" 2>/dev/null
}
_ble_util_rex_isprint='^[ -~]+'
function ble/util/isprint+ {
  LC_COLLATE=C ble/util/isprint+.impl "$@"
} &>/dev/null # Note: suppress LC_COLLATE errors #D1205
function ble/util/isprint+.impl {
  [[ $1 =~ $_ble_util_rex_isprint ]]
}
if ((_ble_bash>=40200)); then
  function ble/util/strftime {
    if [[ $1 = -v ]]; then
      builtin printf -v "$2" "%($3)T" "${4:--1}"
    else
      builtin printf "%($1)T" "${2:--1}"
    fi
  }
else
  function ble/util/strftime {
    if [[ $1 = -v ]]; then
      ble/util/assign "$2" 'ble/bin/date +"$3" $4'
    else
      ble/bin/date +"$1" $2
    fi
  }
fi
function ble-measure/.loop {
  eval "function _target { $2; }"
  local _i _n=$1
  for ((_i=0;_i<_n;_i++)); do
    _target
  done
}
if [[ $ZSH_VERSION ]]; then
  _ble_measure_resolution=1000 # [usec]
  function ble-measure/.time {
    local result
    result=$({ time ( ble-measure/.loop "$n" "$*" ; ) } 2>&1 )
    result=${result##*cpu }
    local rex='(([0-9]+):)?([0-9]+)\.([0-9]+) total$'
    if [[ $result =~ $rex ]]; then
      if [[ -o KSH_ARRAYS ]]; then
        local m=${match[1]} s=${match[2]} ms=${match[3]}
      else
        local m=${match[1]} s=${match[2]} ms=${match[3]}
      fi
      m=${m:-0} ms=${ms}000; ms=${ms:0:3}
      ((utot=((10#$m*60+10#$s)*1000+10#$ms)*1000,
        usec=utot/n))
      return 0
    else
      echo "ble-measure: failed to read the result of \`time': $result." >&2
      utot=0 usec=0
      return 1
    fi
  }
elif ((BASH_VERSINFO[0]>=5)); then
  _ble_measure_resolution=1 # [usec]
  function ble-measure/.time {
    local command="$*"
    local time1=${EPOCHREALTIME//.}
    ble-measure/.loop "$n" "$*" &>/dev/null
    local time2=${EPOCHREALTIME//.}
    ((utot=time2-time1,usec=utot/n))
    ((utot>0))
  }
else
  _ble_measure_resolution=1000 # [usec]
  function ble-measure/.time {
    utot=0 usec=0
    local word utot1 usec1
    local head=
    for word in $({ time ble-measure/.loop "$n" "$*" &>/dev/null;} 2>&1); do
      local rex='(([0-9])+m)?([0-9]+)(\.([0-9]+))?s'
      if [[ $word =~  $rex ]]; then
        local m=${BASH_REMATCH[2]}
        local s=${BASH_REMATCH[3]}
        local ms=${BASH_REMATCH[5]}000; ms=${ms::3}
        ((utot1=((10#$m*60+10#$s)*1000+10#$ms)*1000,
          usec1=utot1/n))
        (((utot1>utot)&&(utot=utot1),
          (usec1>usec)&&(usec=usec1)))
        head=
      else
        head="$head$word "
      fi
    done
    [[ $utot1 ]]
  }
fi
_ble_measure_base= # [nsec]
_ble_measure_time=1 # 同じ倍率で _ble_measure_time 回計測して最小を取る。
_ble_measure_threshold=100000 # 一回の計測が threshold [usec] 以上になるようにする
function ble-measure {
  if [[ ! $_ble_measure_base ]]; then
    _ble_measure_base=0 nsec=0
    ble-measure a=1 &>/dev/null
    _ble_measure_base=$nsec
  fi
  local prev_n= prev_utot=
  local -i n
  for n in {1,10,100,1000,10000}\*{1,2,5}; do
    [[ $prev_n ]] && ((n/prev_n<=10 && prev_utot*n/prev_n<_ble_measure_threshold*2/5 && n!=50000)) && continue
    local utot=0 usec=0
    printf '%s (x%d)...' "$*" "$n" >&2
    ble-measure/.time "$*" || return 1
    printf '\r\e[2K' >&2
    prev_n=$n prev_utot=$utot
    ((utot >= _ble_measure_threshold)) || continue
    if [[ $_ble_measure_time ]]; then
      local min_utot=$utot i
      for ((i=2;i<=_ble_measure_time;i++)); do
        printf '%s' "$* (x$n $i/$_ble_measure_time)..." >&2
        ble-measure/.time "$*" && ((utot<min_utot)) && min_utot=$utot
        printf '\r\e[2K' >&2
      done
      utot=$min_utot
    fi
    local nsec0=$_ble_measure_base
    local reso=$_ble_measure_resolution
    local awk=ble/bin/awk
    type "$awk" &>/dev/null || awk=awk
    "$awk" -v utot=$utot -v nsec0=$nsec0 -v n=$n -v reso=$reso -v title="$* (x$n)" \
      ' function genround(x, mod) { return int(x / mod + 0.5) * mod; }
          BEGIN { printf("%12.2f usec/eval: %s\n", genround(utot / n - nsec0 / 1000, reso / 10.0 / n), title); exit }'
    ((ret=utot/n))
    if ((n>=1000)); then
      ((nsec=utot/(n/1000)))
    else
      ((nsec=utot*1000/n))
    fi
    ((ret-=nsec0/1000,nsec-=nsec0))
    return
  done
}
function ble/util/msleep/.check-builtin-sleep {
  local ret; ble/util/readlink "$BASH"
  local bash_prefix=${ret%/*/*}
  if [[ -s $bash_prefix/lib/bash/sleep ]] &&
    (enable -f "$bash_prefix/lib/bash/sleep" sleep && builtin sleep 0.0) &>/dev/null; then
    enable -f "$bash_prefix/lib/bash/sleep" sleep
    return 0
  else
    return 1
  fi
}
function ble/util/msleep/.check-sleep-decimal-support {
  local version; ble/util/assign version 'LANG=C ble/bin/sleep --version 2>&1'
  [[ $version == *'GNU coreutils'* || $OSTYPE == darwin* && $version == 'usage: sleep seconds' ]]
}
_ble_util_msleep_delay=2000 # [usec]
function ble/util/msleep/.core {
  local sec=${1%%.*}
  ((10#${1##*.}&&sec++)) # 小数部分は切り上げ
  ble/bin/sleep "$sec"
}
function ble/util/msleep {
  local v=$((1000*$1-_ble_util_msleep_delay))
  ((v<=0)) && v=0
  ble/util/sprintf v '%d.%06d' $((v/1000000)) $((v%1000000))
  ble/util/msleep/.core "$v"
}
_ble_util_msleep_calibrate_count=0
function ble/util/msleep/.calibrate-loop {
  local _ble_measure_threshold=10000
  local ret nsec _ble_measure_time=1 v=0
  _ble_util_msleep_delay=0 ble-measure 'ble/util/msleep 1'
  local delay=$((nsec/1000-1000)) count=$_ble_util_msleep_calibrate_count
  ((_ble_util_msleep_delay=(count*_ble_util_msleep_delay+delay)/(count+1)))
}
function ble/util/msleep/calibrate {
  ble/util/msleep/.calibrate-loop &>/dev/null
  ((++_ble_util_msleep_calibrate_count<5)) &&
    ble/util/idle.continue
}
if ((_ble_bash>=40400)) && ble/util/msleep/.check-builtin-sleep; then
  _ble_util_msleep_builtin_available=1
  _ble_util_msleep_delay=300
  function ble/util/msleep/.core { builtin sleep "$1"; }
elif ((_ble_bash>=40000)) && [[ $OSTYPE != haiku* && $OSTYPE != minix* ]]; then
  if [[ $OSTYPE == cygwin* ]]; then
    _ble_util_msleep_delay1=10000 # short msleep にかかる時間 [usec]
    _ble_util_msleep_delay2=50000 # /bin/sleep 0 にかかる時間 [usec]
    _ble_util_msleep_calibrated=0
    function ble/util/msleep/.core2 {
      ((v-=_ble_util_msleep_delay2))
      ble/bin/sleep $((v/1000000))
      ((v%=1000000))
    }
    function ble/util/msleep {
      local v=$((1000*$1-_ble_util_msleep_delay1))
      ((v<=0)) && v=100
      ((v>1000000+_ble_util_msleep_delay2)) &&
        ble/util/msleep/.core2
      ble/util/sprintf v '%d.%06d' $((v/1000000)) $((v%1000000))
      ! builtin read -t "$v" v < /dev/udp/0.0.0.0/80
    }
    function ble/util/msleep/.calibrate-loop {
      local _ble_measure_threshold=10000
      local ret nsec _ble_measure_time=1 v=0
      _ble_util_msleep_delay1=0 ble-measure 'ble/util/msleep 1'
      local delay=$((nsec/1000-1000)) count=$_ble_util_msleep_calibrate_count
      ((_ble_util_msleep_delay1=(count*_ble_util_msleep_delay1+delay)/(count+1)))
      _ble_util_msleep_delay2=0 ble-measure 'ble/util/msleep/.core2'
      local delay=$((nsec/1000))
      ((_ble_util_msleep_delay2=(count*_ble_util_msleep_delay2+delay)/(count+1)))
    }
  else
    _ble_util_msleep_delay=300
    _ble_util_msleep_fd=
    _ble_util_msleep_tmp=$_ble_base_run/$$.ble_util_msleep.pipe
    if [[ ! -p $_ble_util_msleep_tmp ]]; then
      [[ -e $_ble_util_msleep_tmp ]] && ble/bin/rm -rf "$_ble_util_msleep_tmp"
      ble/bin/mkfifo "$_ble_util_msleep_tmp"
    fi
    ble/util/openat _ble_util_msleep_fd "<> $_ble_util_msleep_tmp"
    function ble/util/msleep {
      local v=$((1000*$1-_ble_util_msleep_delay))
      ((v<=0)) && v=100
      ble/util/sprintf v '%d.%06d' $((v/1000000)) $((v%1000000))
      ! builtin read -u "$_ble_util_msleep_fd" -t "$v" v
    }
  fi
elif ble/bin/.freeze-utility-path sleepenh; then
  function ble/util/msleep/.core { ble/bin/sleepenh "$1" &>/dev/null; }
elif ble/bin/.freeze-utility-path usleep; then
  function ble/util/msleep {
    local v=$((1000*$1-_ble_util_msleep_delay))
    ((v<=0)) && v=0
    ble/bin/usleep "$v" &>/dev/null
  }
elif ble/util/msleep/.check-sleep-decimal-support; then
  function ble/util/msleep/.core { ble/bin/sleep "$1"; }
fi
function ble/util/sleep {
  local msec=$((${1%%.*}*1000))
  if [[ $1 == *.* ]]; then
    frac=${1##*.}000
    ((msec+=10#${frac::3}))
  fi
  ble/util/msleep "$msec"
}
function ble/util/conditional-sync {
  local command=$1
  local cancel=${2:-'! ble-decode/has-input'}
  local weight=$3; ((weight<=0&&(weight=100)))
  local opts=$4
  [[ :$opts: == *:progressive-weight:* ]] &&
    local weight_max=$weight weight=1
  (
    eval "$command" & local pid=$!
    while
      ble/util/msleep "$weight"
      [[ :$opts: == *:progressive-weight:* ]] &&
        ((weight<<=1,weight>weight_max&&(weight=weight_max)))
      builtin kill -0 "$pid" &>/dev/null
    do
      if ! eval "$cancel"; then
        builtin kill "$pid" &>/dev/null
        return 148
      fi
    done
  )
}
function ble/util/cat {
  local content=
  if [[ $1 && $1 != - ]]; then
    IFS= builtin read -r -d '' content < "$1"
  else
    IFS= builtin read -r -d '' content
  fi
  printf %s "$content"
}
_ble_util_less_fallback=
function ble/util/get-pager {
  if [[ ! $_ble_util_less_fallback ]]; then
    if type -t less &>/dev/null; then
      _ble_util_less_fallback=less
    elif type -t pager &>/dev/null; then
      _ble_util_less_fallback=pager
    elif type -t more &>/dev/null; then
      _ble_util_less_fallback=more
    else
      _ble_util_less_fallback=cat
    fi
  fi
  eval "$1"'=${bleopt_pager:-${PAGER:-$_ble_util_less_fallback}}'
}
function ble/util/pager {
  local pager; ble/util/get-pager pager
  eval "$pager \"\$@\""
}
if type date &>/dev/null && date -r / +%s &>/dev/null; then
  function ble/util/getmtime { date -r "$1" +'%s %N' 2>/dev/null; }
elif type stat &>/dev/null; then
  if stat -c %Y / &>/dev/null; then
    function ble/util/getmtime { stat -c %Y "$1" 2>/dev/null; }
  elif stat -f %m / &>/dev/null; then
    function ble/util/getmtime { stat -f %m "$1" 2>/dev/null; }
  fi
fi
ble/is-function ble/util/getmtime ||
  function ble/util/getmtime { ble/util/strftime '%s %N'; }
_ble_util_buffer=()
function ble/util/buffer {
  _ble_util_buffer[${#_ble_util_buffer[@]}]="$*"
}
function ble/util/buffer.print {
  ble/util/buffer "$*"$'\n'
}
function ble/util/buffer.flush {
  IFS= builtin eval 'builtin echo -n "${_ble_util_buffer[*]-}"'
  _ble_util_buffer=()
}
function ble/util/buffer.clear {
  _ble_util_buffer=()
}
function ble/dirty-range#load {
  local _prefix=
  if [[ $1 == --prefix=* ]]; then
    _prefix=${1#--prefix=}
    ((beg=${_prefix}beg,
      end=${_prefix}end,
      end0=${_prefix}end0))
  fi
}
function ble/dirty-range#clear {
  local _prefix=
  if [[ $1 == --prefix=* ]]; then
    _prefix=${1#--prefix=}
    shift
  fi
  ((${_prefix}beg=-1,
    ${_prefix}end=-1,
    ${_prefix}end0=-1))
}
function ble/dirty-range#update {
  local _prefix=
  if [[ $1 == --prefix=* ]]; then
    _prefix=${1#--prefix=}
    shift
    [[ $_prefix ]] && local beg end end0
  fi
  local begB=$1 endB=$2 endB0=$3
  ((begB<0)) && return
  local begA endA endA0
  ((begA=${_prefix}beg,endA=${_prefix}end,endA0=${_prefix}end0))
  local delta
  if ((begA<0)); then
    ((beg=begB,
      end=endB,
      end0=endB0))
  else
    ((beg=begA<begB?begA:begB))
    if ((endA<0||endB<0)); then
      ((end=-1,end0=-1))
    else
      ((end=endB,end0=endA0,
        (delta=endA-endB0)>0?(end+=delta):(end0-=delta)))
    fi
  fi
  if [[ $_prefix ]]; then
    ((${_prefix}beg=beg,
      ${_prefix}end=end,
      ${_prefix}end0=end0))
  fi
}
function ble/urange#clear {
  local prefix=
  if [[ $1 == --prefix=* ]]; then
    prefix=${1#*=}; shift
  fi
  ((${prefix}umin=-1,${prefix}umax=-1))
}
function ble/urange#update {
  local prefix=
  if [[ $1 == --prefix=* ]]; then
    prefix=${1#*=}; shift
  fi
  local min=$1 max=$2
  ((0<=min&&min<max)) || return
  (((${prefix}umin<0||min<${prefix}umin)&&(${prefix}umin=min),
    (${prefix}umax<0||${prefix}umax<max)&&(${prefix}umax=max)))
}
function ble/urange#shift {
  local prefix=
  if [[ $1 == --prefix=* ]]; then
    prefix=${1#*=}; shift
  fi
  local dbeg=$1 dend=$2 dend0=$3 shift=$4
  ((dbeg>=0)) || return
  [[ $shift ]] || ((shift=dend-dend0))
  ((${prefix}umin>=0&&(
      dbeg<=${prefix}umin&&(${prefix}umin<=dend0?(${prefix}umin=dend):(${prefix}umin+=shift)),
      dbeg<=${prefix}umax&&(${prefix}umax<=dend0?(${prefix}umax=dbeg):(${prefix}umax+=shift))),
    ${prefix}umin<${prefix}umax||(
      ${prefix}umin=-1,
      ${prefix}umax=-1)))
}
_ble_util_joblist_jobs=
_ble_util_joblist_list=()
_ble_util_joblist_events=()
function ble/util/joblist {
  local jobs0
  ble/util/assign jobs0 'jobs'
  if [[ $jobs0 == "$_ble_util_joblist_jobs" ]]; then
    joblist=("${_ble_util_joblist_list[@]}")
    return
  elif [[ ! $jobs0 ]]; then
    _ble_util_joblist_jobs=
    _ble_util_joblist_list=()
    joblist=()
    return
  fi
  local lines list ijob
  ble/string#split lines $'\n' "$jobs0"
  if ((${#lines[@]})); then
    ble/util/joblist.split list "${lines[@]}"
  else
    list=()
  fi
  if [[ $jobs0 != "$_ble_util_joblist_jobs" ]]; then
    for ijob in "${!list[@]}"; do
      if [[ ${_ble_util_joblist_list[ijob]} && ${list[ijob]#'['*']'[-+ ]} != "${_ble_util_joblist_list[ijob]#'['*']'[-+ ]}" ]]; then
        if [[ ${list[ijob]} != *'__ble_suppress_joblist__'* ]]; then
          ble/array#push _ble_util_joblist_events "${list[ijob]}"
        fi
        list[ijob]=
      fi
    done
  fi
  ble/util/assign _ble_util_joblist_jobs 'jobs'
  _ble_util_joblist_list=()
  if [[ $_ble_util_joblist_jobs != "$jobs0" ]]; then
    ble/string#split lines $'\n' "$_ble_util_joblist_jobs"
    ble/util/joblist.split _ble_util_joblist_list "${lines[@]}"
    for ijob in "${!list[@]}"; do
      local job0=${list[ijob]}
      if [[ $job0 && ! ${_ble_util_joblist_list[ijob]} ]]; then
        if [[ $job0 != *'__ble_suppress_joblist__'* ]]; then
          ble/array#push _ble_util_joblist_events "$job0"
        fi
      fi
    done
  else
    for ijob in "${!list[@]}"; do
      [[ ${list[ijob]} ]] &&
        _ble_util_joblist_list[ijob]=${list[ijob]}
    done
  fi
  joblist=("${_ble_util_joblist_list[@]}")
} 2>/dev/null
function ble/util/joblist.split {
  local arr=$1; shift
  local line ijob= rex_ijob='^\[([0-9]+)\]'
  for line; do
    [[ $line =~ $rex_ijob ]] && ijob=${BASH_REMATCH[1]}
    [[ $ijob ]] && eval "$arr[ijob]=\${$arr[ijob]}\${$arr[ijob]:+\$_ble_term_nl}\$line"
  done
}
function ble/util/joblist.check {
  local joblist
  ble/util/joblist
}
function ble/util/joblist.has-events {
  local joblist
  ble/util/joblist
  ((${#_ble_util_joblist_events[@]}))
}
function ble/util/joblist.flush {
  local joblist
  ble/util/joblist
  ((${#_ble_util_joblist_events[@]})) || return
  printf '%s\n' "${_ble_util_joblist_events[@]}"
  _ble_util_joblist_events=()
}
function ble/util/joblist.bflush {
  local joblist out
  ble/util/joblist
  ((${#_ble_util_joblist_events[@]})) || return
  ble/util/sprintf out '%s\n' "${_ble_util_joblist_events[@]}"
  ble/util/buffer "$out"
  _ble_util_joblist_events=()
}
function ble/util/joblist.clear {
  _ble_util_joblist_jobs=
  _ble_util_joblist_list=()
}
function ble/util/save-editing-mode {
  if [[ -o emacs ]]; then
    builtin eval "$1=emacs"
  elif [[ -o vi ]]; then
    builtin eval "$1=vi"
  else
    builtin eval "$1=none"
  fi
}
function ble/util/restore-editing-mode {
  case "${!1}" in
  (emacs) set -o emacs ;;
  (vi) set -o vi ;;
  (none) set +o emacs ;;
  esac
}
function ble/util/reset-keymap-of-editing-mode {
  if [[ -o emacs ]]; then
    set -o emacs
  elif [[ -o vi ]]; then
    set -o vi
  fi
}
function ble/util/test-rl-variable {
  local rl_variables; ble/util/assign rl_variables 'builtin bind -v'
  if [[ $rl_variables == *"set $1 on"* ]]; then
    return 0
  elif [[ $rl_variables == *"set $1 off"* ]]; then
    return 1
  elif (($#>=2)); then
    (($2))
    return
  else
    return 2
  fi
}
function ble/util/read-rl-variable {
  ret=$2
  local rl_variables; ble/util/assign rl_variables 'builtin bind -v'
  local rhs=${rl_variables#*$'\n'"set $1 "}
  [[ $rhs != "$rl_variables" ]] && ret=${rhs%%$'\n'*}
}
function ble/util/invoke-hook {
  local -a hooks; eval "hooks=(\"\${$1[@]}\")"
  local hook ext=0
  for hook in "${hooks[@]}"; do eval "$hook" || ext=$?; done
  return "$ext"
}
function ble/util/.read-arguments-for-no-option-command {
  local commandname=$1; shift
  flags= args=()
  local flag_literal=
  while (($#)); do
    local arg=$1; shift
    if [[ ! $flag_literal ]]; then
      case $arg in
      (--) flag_literal=1 ;;
      (--help) flags=h$flags ;;
      (-*)
        echo "$commandname: unrecognized option '$arg'" >&2
        flags=e$flags ;;
      (*)
        ble/array#push args "$arg" ;;
      esac
    else
      ble/array#push args "$arg"
    fi
  done
}
function ble/util/autoload {
  local file=$1; shift
  local q=\' Q="'\''" funcname
  for funcname; do
    builtin eval "function $funcname {
      unset -f $funcname
      ble/util/import '${file//$q/$Q}'
      $funcname \"\$@\"
    }"
  done
}
function ble/util/autoload/.print-usage {
  echo 'usage: ble-autoload SCRIPTFILE FUNCTION...'
  echo '  Setup delayed loading of functions defined in the specified script file.'
} >&2    
function ble/util/autoload/.read-arguments {
  file= flags= functions=()
  local args
  ble/util/.read-arguments-for-no-option-command ble-autoload "$@"
  local arg index=0
  for arg in "${args[@]}"; do
    if [[ ! $arg ]]; then
      if ((index==0)); then
        echo 'ble-autoload: the script filename should not be empty.' >&2
      else
        echo 'ble-autoload: function names should not be empty.' >&2
      fi
      flags=e$flags
    fi
    ((index++))
  done
  [[ $flags == *h* ]] && return
  if ((${#args[*]}==0)); then
    echo 'ble-autoload: script filename is not specified.' >&2
    flags=e$flags
  elif ((${#args[*]}==1)); then
    echo 'ble-autoload: function names are not specified.' >&2
    flags=e$flags
  fi
  file=${args[0]} functions=("${#args[@]:1}")
}
function ble-autoload {
  local file flags
  local -a functions=()
  ble/util/autoload/.read-arguments "$@"
  if [[ $flags == *[eh]* ]]; then
    [[ $flags == *e* ]] && echo
    ble/util/autoload/.print-usage
    [[ $flags == *e* ]] && return 2
    return 0
  fi
  ble/util/autoload "$file" "${functions[@]}"
}
_ble_util_import_guards=()
function ble/util/import {
  local file=$1
  if [[ $file == /* ]]; then
    local guard=ble/util/import/guard:$1
    ble/is-function "$guard" && return 0
    if [[ -f $file ]]; then
      source "$file"
    else
      return 1
    fi && eval "function $guard { :; }" &&
      ble/array#push _ble_util_import_guards "$guard"
  else
    local guard=ble/util/import/guard:ble/$1
    ble/is-function "$guard" && return 0
    if [[ -f $_ble_base/$file ]]; then
      source "$_ble_base/$file"
    elif [[ -f $_ble_base/local/$file ]]; then
      source "$_ble_base/local/$file"
    elif [[ -f $_ble_base/share/$file ]]; then
      source "$_ble_base/share/$file"
    else
      return 1
    fi && eval "function $guard { :; }" &&
      ble/array#push _ble_util_import_guards "$guard"
  fi
}
function ble/util/import/finalize {
  local guard
  for guard in "${_ble_util_import_guards[@]}"; do
    unset -f "$guard"
  done
}
function ble/util/import/.read-arguments {
  flags= files=()
  local args
  ble/util/.read-arguments-for-no-option-command ble-import "$@"
  [[ $flags == *h* ]] && return
  if ((!${#args[@]})); then
    echo 'ble-import: argument is not specified.' >&2
    flags=e$flags
  fi
  files=("${args[@]}")
}
function ble-import {
  local files flags
  ble/util/import/.read-arguments "$@"
  if [[ $flags == *[eh]* ]]; then
    [[ $flags == *e* ]] && echo
    {
      echo 'usage: ble-import SCRIPT_FILE...'
      echo '  Search and source script files that have not yet been loaded.'
    } >&2
    [[ $flags == *e* ]] && return 2
    return 0
  fi
  local file
  for file in "${files[@]}"; do
    ble/util/import "$file"
  done
}
_ble_util_stackdump_title=stackdump
function ble/util/stackdump {
  ((bleopt_internal_stackdump_enabled)) || return
  local message=$1
  local i nl=$'\n'
  local message="$_ble_term_sgr0$_ble_util_stackdump_title: $message$nl"
  for ((i=1;i<${#FUNCNAME[*]};i++)); do
    message="$message  @ ${BASH_SOURCE[i]}:${BASH_LINENO[i]} (${FUNCNAME[i]})$nl"
  done
  builtin echo -n "$message" >&2
}
function ble-stackdump {
  local flags args
  ble/util/.read-arguments-for-no-option-command ble-stackdump "$@"
  if [[ $flags == *[eh]* ]]; then
    [[ $flags == *e* ]] && echo
    {
      echo 'usage: ble-stackdump command [message]'
      echo '  Print stackdump.'
    } >&2
    [[ $flags == *e* ]] && return 2
    return 0
  fi
  ble/util/stackdump "${args[*]}"
}
function ble/util/assert {
  local expr=$1 message=$2
  local _ble_util_stackdump_title='assertion failure'
  if ! builtin eval -- "$expr"; then
    shift
    ble/util/stackdump "$expr$_ble_term_nl$message"
    return 1
  else
    return 0
  fi
}
function ble-assert {
  local flags args
  ble/util/.read-arguments-for-no-option-command ble-assert "$@"
  if [[ $flags != *h* ]]; then
    if ((${#args[@]}==0)); then
      echo 'ble-assert: command is not specified.' >&2
      flags=e$flags
    fi
  fi
  if [[ $flags == *[eh]* ]]; then
    [[ $flags == *e* ]] && echo
    {
      echo 'usage: ble-assert command [message]'
      echo '  Evaluate command and print stackdump on fail.'
    } >&2
    [[ $flags == *e* ]] && return 2
    return 0
  fi
  ble/util/assert "${args[0]}" "${args[*]:1}"
}
_ble_util_clock_base=
_ble_util_clock_reso=
_ble_util_clock_type=
function ble/util/clock/.initialize {
  if ((_ble_bash>=50000)) && [[ $EPOCHREALTIME == *.???* ]]; then
    _ble_util_clock_base=$((10#${EPOCHREALTIME%.*}))
    _ble_util_clock_reso=1
    _ble_util_clock_type=EPOCHREALTIME
    function ble/util/clock {
      local now=$EPOCHREALTIME
      local integral=$((10#${now%%.*}-_ble_util_clock_base))
      local mantissa=${now#*.}000; mantissa=${mantissa::3}
      ((ret=integral*1000+10#$mantissa))
    }
  elif [[ -r /proc/uptime ]] && {
         local uptime
         ble/util/readfile uptime /proc/uptime
         ble/string#split-words uptime "$uptime"
         [[ $uptime == *.* ]]; }; then
    _ble_util_clock_base=$((10#${uptime%.*}))
    _ble_util_clock_reso=10
    _ble_util_clock_type=uptime
    function ble/util/clock {
      local now
      ble/util/readfile now /proc/uptime
      ble/string#split-words now "$now"
      local integral=$((10#${now%%.*}-_ble_util_clock_base))
      local fraction=${now#*.}000; fraction=${fraction::3}
      ((ret=integral*1000+10#$fraction))
    }
  elif ((_ble_bash>=40200)); then
    printf -v _ble_util_clock_base '%(%s)T'
    _ble_util_clock_reso=1000
    _ble_util_clock_type=printf
    function ble/util/clock {
      local now; printf -v now '%(%s)T'
      ((ret=(now-_ble_util_clock_base)*1000))
    }
  else
    ble/util/strftime -v _ble_util_clock_base '%s'
    _ble_util_clock_reso=1000
    _ble_util_clock_type=date
    function ble/util/clock {
      ble/util/strftime -v ret '%s'
      ((ret=(ret-_ble_util_clock_base)*1000))
    }
  fi
}
ble/util/clock/.initialize
if ((_ble_bash>=40000)); then
  function ble/util/idle/IS_IDLE { ! ble/util/is-stdin-ready; }
  _ble_util_idle_sclock=0
  function ble/util/idle/.sleep {
    local msec=$1
    ((msec<=0)) && return 0
    ble/util/msleep "$msec"
    ((_ble_util_idle_sclock+=msec))
  }
  function ble/util/idle.clock/.initialize {
    function ble/util/idle.clock/.initialize { :; }
    function ble/util/idle.clock/.restart { :; }
    if [[ ! $_ble_util_clock_type || $_ble_util_clock_type == date ]]; then
      function ble/util/idle.clock {
        ret=$_ble_util_idle_sclock
      }
    elif ((_ble_util_clock_reso<=100)); then
      function ble/util/idle.clock {
        ble/util/clock
      }
    else
      _ble_util_idle_aclock_shift=
      _ble_util_idle_aclock_tick_rclock=
      _ble_util_idle_aclock_tick_sclock=
      function ble/util/idle.clock/.restart {
        _ble_util_idle_aclock_shift=
        _ble_util_idle_aclock_tick_rclock=
        _ble_util_idle_aclock_tick_sclock=
      }
      function ble/util/idle/.adjusted-clock {
        local resolution=$_ble_util_clock_reso
        local sclock=$_ble_util_idle_sclock
        local ret; ble/util/clock; local rclock=$((ret/resolution*resolution))
        if [[ $_ble_util_idle_aclock_tick_rclock != "$rclock" ]]; then
          if [[ $_ble_util_idle_aclock_tick_rclock && ! $_ble_util_idle_aclock_shift ]]; then
            local delta=$((sclock-_ble_util_idle_aclock_tick_sclock))
            ((_ble_util_idle_aclock_shift=delta<resolution?resolution-delta:0))
          fi
          _ble_util_idle_aclock_tick_rclock=$rclock
          _ble_util_idle_aclock_tick_sclock=$sclock
        fi
        ((ret=rclock+(sclock-_ble_util_idle_aclock_tick_sclock)-_ble_util_idle_aclock_shift))
      }
      function ble/util/idle.clock {
        ble/util/idle/.adjusted-clock
      }
    fi
  }
  if [[ ! $bleopt_idle_interval ]]; then
    if ((_ble_bash>50000)) && [[ $_ble_util_msleep_builtin_available ]]; then
      bleopt_idle_interval=20
    else
      bleopt_idle_interval='ble_util_idle_elapsed>600000?500:(ble_util_idle_elapsed>60000?200:(ble_util_idle_elapsed>5000?100:20))'
    fi
  fi
  _ble_util_idle_task=()
  function ble/util/idle.do {
    local IFS=$' \t\n'
    ble/util/idle/IS_IDLE || return 1
    ((${#_ble_util_idle_task[@]}==0)) && return 1
    ble/util/buffer.flush >&2
    ble/util/idle.clock/.initialize
    ble/util/idle.clock/.restart
    local _idle_start=$_ble_util_idle_sclock
    local _idle_is_first=1
    local _idle_processed=
    while :; do
      local _idle_key
      local _idle_next_time= _idle_next_itime= _idle_running= _idle_waiting=
      for _idle_key in "${!_ble_util_idle_task[@]}"; do
        ble/util/idle/IS_IDLE || { [[ $_idle_processed ]]; return; }
        local _idle_to_process=
        local _idle_status=${_ble_util_idle_task[_idle_key]%%:*}
        case ${_idle_status::1} in
        (R) _idle_to_process=1 ;;
        (I) [[ $_idle_is_first ]] && _idle_to_process=1 ;;
        (S) ble/util/idle/.check-clock "$_idle_status" && _idle_to_process=1 ;;
        (W) ble/util/idle/.check-clock "$_idle_status" && _idle_to_process=1 ;;
        (F) [[ -s ${_idle_status:1} ]] && _idle_to_process=1 ;;
        (E) [[ -e ${_idle_status:1} ]] && _idle_to_process=1 ;;
        (P) ! builtin kill -0 ${_idle_status:1} &>/dev/null && _idle_to_process=1 ;;
        (C) eval -- "${_idle_status:1}" && _idle_to_process=1 ;;
        (*) unset -v '_ble_util_idle_task[_idle_key]'
        esac
        if [[ $_idle_to_process ]]; then
          local _idle_command=${_ble_util_idle_task[_idle_key]#*:}
          _idle_processed=1
          ble/util/idle.do/.call-task "$_idle_command"
          (($?==148)) && return 0
        elif [[ $_idle_status == [FEPC]* ]]; then
          _idle_waiting=1
        fi
      done
      _idle_is_first=
      ble/util/idle.do/.sleep-until-next; local ext=$?
      ((ext==148)) && break
      [[ $_idle_next_itime$_idle_next_time$_idle_running$_idle_waiting ]] || break
    done
    [[ $_idle_processed ]]
  }
  function ble/util/idle.do/.call-task {
    local _command=$1
    local ble_util_idle_status=
    local ble_util_idle_elapsed=$((_ble_util_idle_sclock-_idle_start))
    builtin eval "$_command"; local ext=$?
    if ((ext==148)); then
      _ble_util_idle_task[_idle_key]=R:$_command
    elif [[ $ble_util_idle_status ]]; then
      _ble_util_idle_task[_idle_key]=$ble_util_idle_status:$_command
      if [[ $ble_util_idle_status == [WS]* ]]; then
        local scheduled_time=${ble_util_idle_status:1}
        if [[ $ble_util_idle_status == W* ]]; then
          local next=_idle_next_itime
        else
          local next=_idle_next_time
        fi
        if [[ ! ${!next} ]] || ((scheduled_time<next)); then
          builtin eval "$next=\$scheduled_time"
        fi
      elif [[ $ble_util_idle_status == R ]]; then
        _idle_running=1
      elif [[ $ble_util_idle_status == [FEPC]* ]]; then
        _idle_waiting=1
      fi
    else
      unset -v '_ble_util_idle_task[_idle_key]'
    fi
    return "$ext"
  }
  function ble/util/idle/.check-clock {
    local status=$1
    if [[ $status == W* ]]; then
      local next=_idle_next_itime
      local current_time=$_ble_util_idle_sclock
    elif [[ $status == S* ]]; then
      local ret
      local next=_idle_next_time
      ble/util/idle.clock; local current_time=$ret
    else
      return 1
    fi
    local scheduled_time=${status:1}
    if ((scheduled_time<=current_time)); then
      return 0
    elif [[ ! ${!next} ]] || ((scheduled_time<next)); then
      builtin eval "$next=\$scheduled_time"
    fi
    return 1
  }
  function ble/util/idle.do/.sleep-until-next {
    ble/util/idle/IS_IDLE || return 148
    [[ $_idle_running ]] && return
    local isfirst=1
    while
      local sleep_amount=
      if [[ $_idle_next_itime ]]; then
        local clock=$_ble_util_idle_sclock
        local sleep1=$((_idle_next_itime-clock))
        if [[ ! $sleep_amount ]] || ((sleep1<sleep_amount)); then
          sleep_amount=$sleep1
        fi
      fi
      if [[ $_idle_next_time ]]; then
        local ret; ble/util/idle.clock; local clock=$ret
        local sleep1=$((_idle_next_time-clock))
        if [[ ! $sleep_amount ]] || ((sleep1<sleep_amount)); then
          sleep_amount=$sleep1
        fi
      fi
      [[ $isfirst && $_idle_waiting ]] || ((sleep_amount>0))
    do
      local ble_util_idle_elapsed=$((_ble_util_idle_sclock-_idle_start))
      local interval=$((bleopt_idle_interval))
      if [[ ! $sleep_amount ]] || ((interval<sleep_amount)); then
        sleep_amount=$interval
      fi
      ble/util/idle/.sleep "$sleep_amount"
      ble/util/idle/IS_IDLE || return 148
      isfirst=
    done
  }
  function ble/util/idle.push/.impl {
    local base=$1 entry=$2
    local i=$base
    while [[ ${_ble_util_idle_task[i]} ]]; do ((i++)); done
    _ble_util_idle_task[i]=$entry
  }
  function ble/util/idle.push {
    ble/util/idle.push/.impl 0 "R:$*"
  }
  function ble/util/idle.push-background {
    ble/util/idle.push/.impl 10000 "R:$*"
  }
  function ble/util/is-running-in-idle {
    [[ ${ble_util_idle_status+set} ]]
  }
  function ble/util/idle.sleep {
    [[ ${ble_util_idle_status+set} ]] || return 1
    local ret; ble/util/idle.clock
    ble_util_idle_status=S$((ret+$1))
  }
  function ble/util/idle.isleep {
    [[ ${ble_util_idle_status+set} ]] || return 1
    ble_util_idle_status=W$((_ble_util_idle_sclock+$1))
  }
  function ble/util/idle.wait-user-input {
    [[ ${ble_util_idle_status+set} ]] || return 1
    ble_util_idle_status=I
  }
  function ble/util/idle.wait-process {
    [[ ${ble_util_idle_status+set} ]] || return 1
    ble_util_idle_status=P$1
  }
  function ble/util/idle.wait-file-content {
    [[ ${ble_util_idle_status+set} ]] || return 1
    ble_util_idle_status=F$1
  }
  function ble/util/idle.wait-filename {
    [[ ${ble_util_idle_status+set} ]] || return 1
    ble_util_idle_status=E$1
  }
  function ble/util/idle.wait-condition {
    [[ ${ble_util_idle_status+set} ]] || return 1
    ble_util_idle_status=C$1
  }
  function ble/util/idle.continue {
    [[ ${ble_util_idle_status+set} ]] || return 1
    ble_util_idle_status=R
  }
  ble/util/idle.push-background 'ble/util/msleep/calibrate'
else
  function ble/util/idle.do { false; }
fi
_ble_util_fiberchain=()
_ble_util_fiberchain_prefix=
function ble/util/fiberchain#initialize {
  _ble_util_fiberchain=()
  _ble_util_fiberchain_prefix=$1
}
function ble/util/fiberchain#resume/.core {
  _ble_util_fiberchain=()
  local fib_clock=0
  local fib_ntask=$#
  while (($#)); do
    ((fib_ntask--))
    local fiber=${1%%:*} fib_suspend= fib_kill=
    local argv; ble/string#split-words argv "$fiber"
    [[ $1 == *:* ]] && fib_suspend=${1#*:}
    "$_ble_util_fiberchain_prefix/$argv.fib" "${argv[@]:1}"
    if [[ $fib_kill ]]; then
      break
    elif [[ $fib_suspend ]]; then
      _ble_util_fiberchain=("$fiber:$fib_suspend" "${@:2}")
      return 148
    fi
    shift
  done
}
function ble/util/fiberchain#resume {
  ble/util/fiberchain#resume/.core "${_ble_util_fiberchain[@]}"
}
function ble/util/fiberchain#push {
  ble/array#push _ble_util_fiberchain "$@"
}
function ble/util/fiberchain#clear {
  _ble_util_fiberchain=()
}
bleopt/declare -v vbell_default_message ' Wuff, -- Wuff!! '
bleopt/declare -v vbell_duration 2000
bleopt/declare -n vbell_align left
function ble-term/.initialize {
  if [[ $_ble_base/lib/init-term.sh -nt $_ble_base_cache/$TERM.term ]]; then
    source "$_ble_base/lib/init-term.sh"
  else
    source "$_ble_base_cache/$TERM.term"
  fi
  ble/string#reserve-prototype "$_ble_term_it"
}
ble-term/.initialize
function ble-term/put {
  BUFF[${#BUFF[@]}]=$1
}
function ble-term/cup {
  local x=$1 y=$2 esc=$_ble_term_cup
  esc=${esc//'%x'/$x}
  esc=${esc//'%y'/$y}
  esc=${esc//'%c'/$((x+1))}
  esc=${esc//'%l'/$((y+1))}
  BUFF[${#BUFF[@]}]=$esc
}
function ble-term/flush {
  IFS= builtin eval 'builtin echo -n "${BUFF[*]}"'
  BUFF=()
}
function ble/term/audible-bell {
  builtin echo -n '' 1>&2
}
_ble_term_visible_bell_ftime=$_ble_base_run/$$.visible-bell.time
_ble_term_visible_bell_show='%message%'
_ble_term_visible_bell_clear=
function ble/term/visible-bell/.initialize {
  local -a BUFF=()
  ble-term/put "$_ble_term_ri$_ble_term_sc$_ble_term_sgr0"
  ble-term/cup 0 0
  ble-term/put "$_ble_term_el%message%$_ble_term_sgr0$_ble_term_rc${_ble_term_cud//'%d'/1}"
  IFS= builtin eval '_ble_term_visible_bell_show="${BUFF[*]}"'
  BUFF=()
  ble-term/put "$_ble_term_sc$_ble_term_sgr0"
  ble-term/cup 0 0
  ble-term/put "$_ble_term_el2$_ble_term_rc"
  IFS= builtin eval '_ble_term_visible_bell_clear="${BUFF[*]}"'
}
ble/term/visible-bell/.initialize
function ble/term/visible-bell/defface.hook {
  ble/color/defface vbell       reverse
  ble/color/defface vbell_flash reverse,fg=green
  ble/color/defface vbell_erase bg=252
}
ble/array#push _ble_color_faces_defface_hook ble/term/visible-bell/defface.hook
_ble_term_visible_bell_prev=()
function ble/term/visible-bell/.show {
  local message=$1 sgr=$2 x=$3 y=$4
  if [[ $opt_canvas ]]; then
    local x0=0 y0=0
    if [[ $bleopt_vbell_align == right ]]; then
      ((x0=COLUMNS-1-x,x0<0&&(x0=0)))
    elif [[ $bleopt_vbell_align == center ]]; then
      ((x0=(COLUMNS-1-x)/2,x0<0&&(x0=0)))
    fi
    local -a DRAW_BUFF=()
    ble/canvas/put.draw "$_ble_term_ri$_ble_term_sc$_ble_term_sgr0"
    ble/canvas/put-cup.draw $((y0+1)) $((x0+1))
    ble/canvas/put.draw "$sgr$message$_ble_term_sgr0"
    ble/canvas/put.draw "$_ble_term_rc"
    ble/canvas/put-cud.draw 1
    ble/canvas/flush.draw
    _ble_term_visible_bell_prev=("$message" "$x0" "$y0" "$x" "$y")
  else
    builtin echo -n "${_ble_term_visible_bell_show//'%message%'/$message}"
    _ble_term_visible_bell_prev=("$message")
  fi
} >&2
function ble/term/visible-bell/.update {
  local sgr=$1
  local message=${_ble_term_visible_bell_prev[0]}
  if ((${#_ble_term_visible_bell_prev[@]}==5)); then
    local x0=${_ble_term_visible_bell_prev[1]}
    local y0=${_ble_term_visible_bell_prev[2]}
    local x=${_ble_term_visible_bell_prev[3]}
    local y=${_ble_term_visible_bell_prev[4]}
    local -a DRAW_BUFF=()
    ble/canvas/put.draw "$_ble_term_ri$_ble_term_sc$_ble_term_sgr0"
    ble/canvas/put-cup.draw $((y0+1)) $((x0+1))
    ble/canvas/put.draw "$sgr$message$_ble_term_sgr0"
    ble/canvas/put.draw "$_ble_term_rc"
    ble/canvas/put-cud.draw 1
    ble/canvas/flush.draw
  else
    builtin echo -n "${_ble_term_visible_bell_show//'%message%'/$sgr$message}"
  fi
} >&2
function ble/term/visible-bell/.clear {
  if ((${#_ble_term_visible_bell_prev[@]}==5)); then
    local x0=${_ble_term_visible_bell_prev[1]}
    local y0=${_ble_term_visible_bell_prev[2]}
    local x=${_ble_term_visible_bell_prev[3]}
    local y=${_ble_term_visible_bell_prev[4]}
    local sgr; ble/color/face2sgr vbell_erase
    local -a DRAW_BUFF=()
    ble/canvas/put.draw "$_ble_term_sc$_ble_term_sgr0"
    ble/canvas/put-cup.draw $((y0+1)) $((x0+1))
    ble/canvas/put.draw "$sgr"
    ble/canvas/put-spaces.draw "$x"
    ble/canvas/put.draw "$_ble_term_sgr0$_ble_term_rc"
    ble/canvas/flush.draw
  else
    builtin echo -n "$_ble_term_visible_bell_clear"
  fi
  >| "$_ble_term_visible_bell_ftime"
} >&2
function ble/term/visible-bell/.erase-previous-visible-bell {
  local -a workers=()
  eval 'workers=("$_ble_base_run/$$.visible-bell."*)' &>/dev/null # failglob 対策
  local workerfile
  for workerfile in "${workers[@]}"; do
    if [[ -s $workerfile && ! ( $workerfile -ot $_ble_term_visible_bell_ftime ) ]]; then
      ble/term/visible-bell/.clear
      break
    fi
  done
}
function ble/term/visible-bell/.create-workerfile {
  local i=0
  while
    workerfile=$_ble_base_run/$$.visible-bell.$i
    [[ -s $workerfile ]]
  do ((i++)); done
  echo 1 >| "$workerfile"
}
function ble/term/visible-bell/.worker {
  ble/util/msleep 50
  [[ $workerfile -ot $_ble_term_visible_bell_ftime ]] && return >| "$workerfile"
  ble/term/visible-bell/.update "$sgr2"
  if [[ :$opts: == *:persistent:* ]]; then
    local dead_workerfile=$_ble_base_run/$$.visible-bell.Z
    builtin echo 1 >| "$dead_workerfile"
    return >| "$workerfile"
  fi
  local msec=$bleopt_vbell_duration
  ble/util/msleep "$msec"
  [[ $workerfile -ot $_ble_term_visible_bell_ftime ]] && return >| "$workerfile"
  ble/term/visible-bell/.clear
  >| "$workerfile"
}
function ble/term/visible-bell {
  local cols=${COLUMNS:-80}
  local message=$1 opts=$2
  message=${message:-$bleopt_vbell_default_message}
  local opt_canvas= x= y=
  if ble/is-function ble/canvas/trace-text; then
    opt_canvas=1
    local ret lines=1 sgr0= sgr1=
    ble/canvas/trace-text "$message" nonewline:external-sgr
    message=$ret
  else
    message=${message::cols}
  fi
  local sgr0=$_ble_term_sgr0
  local sgr1=${_ble_term_setaf[2]}$_ble_term_rev
  local sgr2=$_ble_term_rev
  local sgr
  ble/color/face2sgr vbell_flash; sgr1=$sgr
  ble/color/face2sgr vbell; sgr2=$sgr
  ble/term/visible-bell/.erase-previous-visible-bell
  ble/term/visible-bell/.show "$message" "$sgr1" "$x" "$y"
  local workerfile; ble/term/visible-bell/.create-workerfile
  ( ble/term/visible-bell/.worker __ble_suppress_joblist__ 1>/dev/null & )
}
function ble/term/visible-bell/cancel-erasure {
  >| "$_ble_term_visible_bell_ftime"
}
_ble_term_stty_state=
_ble_term_stty_flags_enter=()
_ble_term_stty_flags_leave=()
ble/array#push _ble_term_stty_flags_enter kill undef erase undef intr undef quit undef susp undef
ble/array#push _ble_term_stty_flags_leave kill '' erase '' intr '' quit '' susp ''
function ble/term/stty/.initialize-flags {
  local stty; ble/util/assign stty 'stty -a'
  if [[ $stty == *' lnext '* ]]; then
    ble/array#push _ble_term_stty_flags_enter lnext undef
    ble/array#push _ble_term_stty_flags_leave lnext ''
  fi
  if [[ $stty == *' werase '* ]]; then
    ble/array#push _ble_term_stty_flags_enter werase undef
    ble/array#push _ble_term_stty_flags_leave werase ''
  fi
}
ble/term/stty/.initialize-flags
function ble/term/stty/initialize {
  ble/bin/stty -ixon -echo -nl -icrnl -icanon \
               "${_ble_term_stty_flags_enter[@]}"
  _ble_term_stty_state=1
}
function ble/term/stty/leave {
  [[ ! $_ble_term_stty_state ]] && return
  ble/bin/stty echo -nl icanon \
               "${_ble_term_stty_flags_leave[@]}"
  _ble_term_stty_state=
}
function ble/term/stty/enter {
  [[ $_ble_term_stty_state ]] && return
  ble/bin/stty -echo -nl -icrnl -icanon \
               "${_ble_term_stty_flags_enter[@]}"
  _ble_term_stty_state=1
}
function ble/term/stty/finalize {
  ble/term/stty/leave
}
function ble/term/stty/TRAPEXIT {
  ble/bin/stty echo -nl \
               "${_ble_term_stty_flags_leave[@]}"
}
bleopt/declare -v term_cursor_external 0
_ble_term_cursor_current=unknown
_ble_term_cursor_internal=0
_ble_term_cursor_hidden_current=unknown
_ble_term_cursor_hidden_internal=reveal
function ble/term/cursor-state/.update {
  local state=$(($1))
  [[ $_ble_term_cursor_current == "$state" ]] && return
  ble/util/buffer "${_ble_term_Ss//@1/$state}"
  _ble_term_cursor_current=$state
}
function ble/term/cursor-state/set-internal {
  _ble_term_cursor_internal=$1
  [[ $_ble_term_state == internal ]] &&
    ble/term/cursor-state/.update "$1"
}
function ble/term/cursor-state/.update-hidden {
  local state=$1
  [[ $state != hidden ]] && state=reveal
  [[ $_ble_term_cursor_hidden_current == "$state" ]] && return
  if [[ $state == hidden ]]; then
    ble/util/buffer "$_ble_term_civis"
  else
    ble/util/buffer "$_ble_term_cvvis"
  fi
  _ble_term_cursor_hidden_current=$state
}
function ble/term/cursor-state/hide {
  _ble_term_cursor_hidden_internal=hidden
  [[ $_ble_term_state == internal ]] &&
    ble/term/cursor-state/.update-hidden hidden
}
function ble/term/cursor-state/reveal {
  _ble_term_cursor_hidden_internal=reveal
  [[ $_ble_term_state == internal ]] &&
    ble/term/cursor-state/.update-hidden reveal
}
function ble/term/bracketed-paste-mode/enter {
  ble/util/buffer $'\e[?2004h'
}
function ble/term/bracketed-paste-mode/leave {
  ble/util/buffer $'\e[?2004l'
}
_ble_term_DA1R=
_ble_term_DA2R=
function ble/term/DA1/notify { _ble_term_DA1R=$1; }
function ble/term/DA2/notify { _ble_term_DA2R=$1; }
_ble_term_CPR_hook=
function ble/term/CPR/request.buff {
  _ble_term_CPR_hook=$1
  ble/util/buffer $'\e[6n'
  return 148
}
function ble/term/CPR/request.draw {
  _ble_term_CPR_hook=$1
  ble/canvas/put.draw $'\e[6n'
  return 148
}
function ble/term/CPR/notify {
  local hook=$_ble_term_CPR_hook
  _ble_term_CPR_hook=
  [[ ! $hook ]] || "$hook" "$1" "$2"
}
bleopt/declare -v term_modifyOtherKeys_external auto
bleopt/declare -v term_modifyOtherKeys_internal auto
_ble_term_modifyOtherKeys_current=
function ble/term/modifyOtherKeys/.update {
  [[ $1 == "$_ble_term_modifyOtherKeys_current" ]] && return
  case $1 in
  (0) ble/util/buffer $'\e[>4;0m\e[m' ;;
  (1) ble/util/buffer $'\e[>4;1m\e[m' ;;
  (2) ble/util/buffer $'\e[>4;1m\e[>4;2m\e[m' ;;
  esac
  _ble_term_modifyOtherKeys_current=$1
}
function ble/term/modifyOtherKeys/.supported {
  [[ $_ble_term_DA2R == '1;'* ]] && return 1
  [[ $MWG_LOGINTERM == rosaterm ]] && return 1
  [[ $TERM == linux ]] && return 1
  return 0
}
function ble/term/modifyOtherKeys/enter {
  local value=$bleopt_term_modifyOtherKeys_internal
  if [[ $value == auto ]]; then
    value=2
    ble/term/modifyOtherKeys/.supported || value=
  fi
  ble/term/modifyOtherKeys/.update "$value"
}
function ble/term/modifyOtherKeys/leave {
  local value=$bleopt_term_modifyOtherKeys_external
  if [[ $value == auto ]]; then
    value=1
    ble/term/modifyOtherKeys/.supported || value=
  fi
  ble/term/modifyOtherKeys/.update "$value"
}
_ble_term_rl_convert_meta_adjusted=
_ble_term_rl_convert_meta_external=
function ble/term/rl-convert-meta/enter {
  [[ $_ble_term_rl_convert_meta_adjusted ]] && return
  _ble_term_rl_convert_meta_adjusted=1
  if ble/util/test-rl-variable convert-meta; then
    _ble_term_rl_convert_meta_external=on
    builtin bind 'set convert-meta off'
  else
    _ble_term_rl_convert_meta_external=off
  fi
}
function ble/term/rl-convert-meta/leave {
  [[ $_ble_term_rl_convert_meta_adjusted ]] || return
  _ble_term_rl_convert_meta_adjusted=
  [[ $_ble_term_rl_convert_meta_external == on ]] &&
    builtin bind 'set convert-meta on'
}
_ble_term_state=external
function ble/term/enter {
  [[ $_ble_term_state == internal ]] && return
  ble/term/stty/enter
  ble/term/bracketed-paste-mode/enter
  ble/term/modifyOtherKeys/enter
  ble/term/cursor-state/.update "$_ble_term_cursor_internal"
  ble/term/cursor-state/.update-hidden "$_ble_term_cursor_hidden_internal"
  ble/term/rl-convert-meta/enter
  _ble_term_state=internal
}
function ble/term/leave {
  [[ $_ble_term_state == external ]] && return
  ble/term/stty/leave
  ble/term/bracketed-paste-mode/leave
  ble/term/modifyOtherKeys/leave
  ble/term/cursor-state/.update "$bleopt_term_cursor_external"
  ble/term/cursor-state/.update-hidden reveal
  ble/term/rl-convert-meta/leave
  _ble_term_cursor_current=unknown # vim は復元してくれない
  _ble_term_cursor_hidden_current=unknown
  _ble_term_state=external
}
function ble/term/finalize {
  ble/term/stty/finalize
  ble/term/leave
  ble/util/buffer.flush >&2
}
function ble/term/initialize {
  ble/term/stty/initialize
  ble/term/enter
}
_ble_util_s2c_table_enabled=
if ((_ble_bash>=40100)); then
  function ble/util/s2c {
    builtin printf -v ret '%d' "'${1:$2:1}"
  }
elif ((_ble_bash>=40000&&!_ble_bash_loaded_in_function)); then
  declare -A _ble_util_s2c_table
  _ble_util_s2c_table_enabled=1
  function ble/util/s2c {
    [[ $_ble_util_cache_locale != "$LC_ALL:$LC_CTYPE:$LANG" ]] &&
      ble/util/.cache/update-locale
    local s=${1:$2:1}
    ret=${_ble_util_s2c_table[x$s]}
    [[ $ret ]] && return
    ble/util/sprintf ret %d "'$s"
    _ble_util_s2c_table[x$s]=$ret
  }
elif ((_ble_bash>=40000)); then
  function ble/util/s2c {
    ble/util/sprintf ret %d "'${1:$2:1}"
  }
else
  function ble/util/s2c {
    local s=${1:$2:1}
    if [[ $s == [''-''] ]]; then
      ble/util/sprintf ret %d "'$s"
      return
    fi
    local bytes byte
    ble/util/assign bytes '
      while IFS= builtin read -r -n 1 byte; do
        builtin printf "%d " "'\''$byte"
      done <<< "$s"
    '
    "ble/encoding:$bleopt_input_encoding/b2c" $bytes
  }
fi
if ((_ble_bash>=40200)); then
  function ble/util/.has-bashbug-printf-uffff {
    ((40200<=_ble_bash&&_ble_bash<40500)) || return 1
    local LC_ALL=C.UTF-8 2>/dev/null # Workaround: CentOS 7 に C.UTF-8 がなかった
    local ret
    builtin printf -v ret '\uFFFF'
    ((${#ret}==2))
  }
  if ble/util/.has-bashbug-printf-uffff; then
    function ble/util/c2s-impl {
      if ((0xE000<=$1&&$1<=0xFFFF)) && [[ $_ble_util_cache_ctype == *.utf-8 || $_ble_util_cache_ctype == *.utf8 ]]; then
        builtin printf -v ret '\\x%02x' $((0xE0|$1>>12&0x0F)) $((0x80|$1>>6&0x3F)) $((0x80|$1&0x3F))
      else
        builtin printf -v ret '\\U%08x' "$1"
      fi
      builtin eval "ret=\$'$ret'"
    }
  else
    function ble/util/c2s-impl {
      builtin printf -v ret '\\U%08x' "$1"
      builtin eval "ret=\$'$ret'"
    }
  fi
else
  _ble_text_xdigit=(0 1 2 3 4 5 6 7 8 9 A B C D E F)
  _ble_text_hexmap=()
  for ((i=0;i<256;i++)); do
    _ble_text_hexmap[i]=${_ble_text_xdigit[i>>4&0xF]}${_ble_text_xdigit[i&0xF]}
  done
  function ble/util/c2s-impl {
    if (($1<0x80)); then
      builtin eval "ret=\$'\\x${_ble_text_hexmap[$1]}'"
      return
    fi
    local bytes i iN seq=
    ble/encoding:UTF-8/c2b "$1"
    for ((i=0,iN=${#bytes[@]};i<iN;i++)); do
      seq="$seq\\x${_ble_text_hexmap[bytes[i]&0xFF]}"
    done
    builtin eval "ret=\$'$seq'"
  }
fi
_ble_util_c2s_table=()
function ble/util/c2s {
  [[ $_ble_util_cache_locale != "$LC_ALL:$LC_CTYPE:$LANG" ]] &&
    ble/util/.cache/update-locale
  ret=${_ble_util_c2s_table[$1]-}
  if [[ ! $ret ]]; then
    ble/util/c2s-impl "$1"
    _ble_util_c2s_table[$1]=$ret
  fi
}
function ble/util/c2bc {
  "ble/encoding:$bleopt_input_encoding/c2bc" "$1"
}
_ble_util_cache_locale=
_ble_util_cache_ctype=
function ble/util/.cache/update-locale {
  _ble_util_cache_locale=$LC_ALL:$LC_CTYPE:$LANG
  local ret; ble/string#tolower "${LC_ALL:-${LC_CTYPE:-$LANG}}"
  if [[ $_ble_util_cache_ctype != "$ret" ]]; then
    _ble_util_cache_ctype=$ret
    _ble_util_c2s_table=()
    [[ $_ble_util_s2c_table_enabled ]] &&
      _ble_util_s2c_table=()
  fi
}
function ble/util/s2chars {
  local text=$1 n=${#1} i chars
  chars=()
  for ((i=0;i<n;i++)); do
    ble/util/s2c "$text" "$i"
    ble/array#push chars "$ret"
  done
  ret=("${chars[@]}")
}
function ble/util/c2keyseq {
  local char=$(($1))
  case $char in
  (7)   ret='\a' ;;
  (8)   ret='\b' ;;
  (9)   ret='\t' ;;
  (10)  ret='\n' ;;
  (11)  ret='\v' ;;
  (12)  ret='\f' ;;
  (13)  ret='\r' ;;
  (27)  ret='\e' ;;
  (92)  ret='\\' ;;
  (127) ret='\d' ;;
  (*)
    if ((char<32||128<=char&&char<160)); then
      local char7=$((char&0xFF))
      if ((1<=char7&&char7<=26)); then
        ble/util/c2s $((char7+96))
      else
        ble/util/c2s $((char7+64))
      fi
      ret='\C-'$ret
      ((char&0x80)) && ret='\M-'$ret
    else
      ble/util/c2s "$char"
    fi ;;
  esac
}
function ble/util/chars2keyseq {
  local char str=
  for char; do
    ble/util/c2keyseq "$char"
    str=$str$ret
  done
  ret=$str
}
function ble/util/keyseq2chars {
  local keyseq=$1 chars
  local rex='^([^\]*)\\([0-7]{1,3}|x{1,2}|(C-(\\M-)?|M-(\\C-)?)*.)'
  chars=()
  while [[ $keyseq =~ $rex ]]; do
    local text=${BASH_REMATCH[1]} esc=${BASH_REMATCH[2]}
    keyseq=${keyseq:${#BASH_REMATCH}}
    ble/util/s2chars "$text"
    ble/array#push chars "${ret[@]}"
    local mflags=
    case $esc in
    (x?*) ble/array#push chars $((16#${esc#x}));;
    ([0-7]*) ble/array#push chars $((8#$esc)) ;;
    (a) ble/array#push chars 7 ;;
    (b) ble/array#push chars 8 ;;
    (t) ble/array#push chars 9 ;;
    (n) ble/array#push chars 10 ;;
    (v) ble/array#push chars 11 ;;
    (f) ble/array#push chars 12 ;;
    (r) ble/array#push chars 13 ;;
    (e) ble/array#push chars 27 ;;
    (d) ble/array#push chars 127 ;;
    ('C-?')    ble/array#push chars 127 ;;
    ('M-\C-?') ble/array#push chars 255 ;;
    ('C-'?)    mflags=sc  ;;
    ('C-\M-'?) mflags=sec ;;
    ('M-'?)    mflags=sm  ;;
    ('M-\C-'?) mflags=scm ;;
    (*)        mflags=s   ;;
    esac
    if [[ $mflags == *s* ]]; then
      ble/util/s2c "${esc:${#esc}-1}"; local key=$ret
      [[ $mflags == *e* ]] && ble/array#push chars 27
      [[ $mflags == *c* ]] && ((key&=0x1F))
      [[ $mflags == *m* ]] && ((key|=0x80))
      ble/array#push chars "$key"
    fi
  done
  ble/util/s2chars "$keyseq"
  ble/array#push chars "${ret[@]}"
  ret=("${chars[@]}")
}
function ble/encoding:UTF-8/b2c {
  local bytes b0 n i
  bytes=("$@")
  ret=0
  ((b0=bytes[0]&0xFF,
    n=b0>0xF0
    ?(b0>0xFC?5:(b0>0xF8?4:3))
    :(b0>0xE0?2:(b0>0xC0?1:0)),
    ret=b0&0x3F>>n))
  for ((i=1;i<=n;i++)); do
    ((ret=ret<<6|0x3F&bytes[i]))
  done
}
function ble/encoding:UTF-8/c2b {
  local code=$1 n i
  ((code=code&0x7FFFFFFF,
    n=code<0x80?0:(
      code<0x800?1:(
        code<0x10000?2:(
          code<0x200000?3:(
            code<0x4000000?4:5))))))
  if ((n==0)); then
    bytes=(code)
  else
    bytes=()
    for ((i=n;i;i--)); do
      ((bytes[i]=0x80|code&0x3F,
        code>>=6))
    done
    ((bytes[0]=code&0x3F>>n|0xFF80>>n))
  fi
}
function ble/encoding:C/b2c {
  local byte=$1
  ((ret=byte&0xFF))
}
function ble/encoding:C/c2b {
  local code=$1
  bytes=($((code&0xFF)))
}
function ble/util/is-unicode-output {
  [[ ${LC_ALL:-${LC_CTYPE:-$LANG}} == *.UTF-8 ]]
}
ble/bin/.freeze-utility-path "${_ble_init_posix_command_list[@]}" # <- this uses ble/util/assign.
ble/bin/.freeze-utility-path man
ble/bin/awk.use-solaris-xpg4
bleopt/declare -v decode_error_char_abell ''
bleopt/declare -v decode_error_char_vbell 1
bleopt/declare -v decode_error_char_discard ''
bleopt/declare -v decode_error_cseq_abell ''
bleopt/declare -v decode_error_cseq_vbell 1
bleopt/declare -v decode_error_cseq_discard 1
bleopt/declare -v decode_error_kseq_abell 1
bleopt/declare -v decode_error_kseq_vbell 1
bleopt/declare -v decode_error_kseq_discard 1
bleopt/declare -n default_keymap auto
function bleopt/check:default_keymap {
  case $value in
  (auto|emacs|vi|safe) ;;
  (*)
    echo "bleopt: Invalid value default_keymap='value'. The value should be one of \`auto', \`emacs', \`vi'." >&2
    return 1 ;;
  esac
}
function bleopt/get:default_keymap {
  ret=$bleopt_default_keymap
  if [[ $ret == auto ]]; then
    if [[ -o vi ]]; then
      ret=vi
    else
      ret=emacs
    fi
  fi
}
bleopt/declare -n decode_isolated_esc auto
function bleopt/check:decode_isolated_esc {
  case $value in
  (meta|esc|auto) ;;
  (*)
    echo "bleopt: Invalid value decode_isolated_esc='$value'. One of the values 'auto', 'meta' or 'esc' is expected." >&2
    return 1 ;;
  esac
}
function ble-decode/uses-isolated-esc {
  if [[ $bleopt_decode_isolated_esc == esc ]]; then
    return 0
  elif [[ $bleopt_decode_isolated_esc == auto ]]; then
    if local ret; bleopt/get:default_keymap; [[ $ret == vi ]]; then
      return 0
    elif [[ ! $_ble_decode_key__seq ]]; then
      local dicthead=_ble_decode_${_ble_decode_keymap}_kmap_ key=$((_ble_decode_Ctrl|91))
      builtin eval "local ent=\${$dicthead$_ble_decode_key__seq[key]-}"
      [[ ${ent:2} ]] && return 0
    fi
  fi
  return 1
}
bleopt/declare -n decode_abort_char 28
_ble_decode_Erro=0x40000000
_ble_decode_Meta=0x08000000
_ble_decode_Ctrl=0x04000000
_ble_decode_Shft=0x02000000
_ble_decode_Hypr=0x01000000
_ble_decode_Supr=0x00800000
_ble_decode_Altr=0x00400000
_ble_decode_MaskChar=0x001FFFFF
_ble_decode_MaskFlag=0x7FC00000
_ble_decode_IsolatedESC=$((0x07FF))
_ble_decode_FunctionKeyBase=0x110000
if ((_ble_bash>=40200||_ble_bash>=40000&&!_ble_bash_loaded_in_function)); then
  _ble_decode_kbd_ver=4
  _ble_decode_kbd__n=0
  if ((_ble_bash>=40200)); then
    declare -gA _ble_decode_kbd__k2c=()
  else
    declare -A _ble_decode_kbd__k2c=()
   fi
  _ble_decode_kbd__c2k=()
  function ble-decode-kbd/.set-keycode {
    local keyname=$1
    local code=$2
    : ${_ble_decode_kbd__c2k[code]:=$keyname}
    _ble_decode_kbd__k2c[$keyname]=$code
  }
  function ble-decode-kbd/.get-keycode {
    ret=${_ble_decode_kbd__k2c[$1]}
  }
else
  _ble_decode_kbd_ver=3
  _ble_decode_kbd__n=0
  _ble_decode_kbd__k2c_keys=
  _ble_decode_kbd__k2c_vals=()
  _ble_decode_kbd__c2k=()
  function ble-decode-kbd/.set-keycode {
    local keyname=$1
    local code=$2
    : ${_ble_decode_kbd__c2k[code]:=$keyname}
    _ble_decode_kbd__k2c_keys=$_ble_decode_kbd__k2c_keys:$keyname:
    _ble_decode_kbd__k2c_vals[${#_ble_decode_kbd__k2c_vals[@]}]=$code
  }
  function ble-decode-kbd/.get-keycode {
    local keyname=$1
    local tmp=${_ble_decode_kbd__k2c_keys%%:$keyname:*}
    if [[ ${#tmp} == ${#_ble_decode_kbd__k2c_keys} ]]; then
      ret=
    else
      local -a arr; ble/string#split-words arr "${tmp//:/ }"
      ret=${_ble_decode_kbd__k2c_vals[${#arr[@]}]}
    fi
  }
fi
function ble-decode-kbd/.get-keyname {
  local keycode=$1
  ret=${_ble_decode_kbd__c2k[keycode]}
  if [[ ! $ret ]] && ((keycode<_ble_decode_FunctionKeyBase)); then
    ble/util/c2s "$keycode"
  fi
}
function ble-decode-kbd/generate-keycode {
  local keyname=$1
  if ((${#keyname}==1)); then
    ble/util/s2c "$1"
  elif [[ $keyname && ! ${keyname//[a-zA-Z_0-9]} ]]; then
    ble-decode-kbd/.get-keycode "$keyname"
    if [[ ! $ret ]]; then
      ((ret=_ble_decode_FunctionKeyBase+_ble_decode_kbd__n++))
      ble-decode-kbd/.set-keycode "$keyname" "$ret"
    fi
  else
    ret=-1
    return 1
  fi
}
function ble-decode-kbd/.initialize {
  ble-decode-kbd/.set-keycode TAB  9
  ble-decode-kbd/.set-keycode RET  13
  ble-decode-kbd/.set-keycode NUL  0
  ble-decode-kbd/.set-keycode SOH  1
  ble-decode-kbd/.set-keycode STX  2
  ble-decode-kbd/.set-keycode ETX  3
  ble-decode-kbd/.set-keycode EOT  4
  ble-decode-kbd/.set-keycode ENQ  5
  ble-decode-kbd/.set-keycode ACK  6
  ble-decode-kbd/.set-keycode BEL  7
  ble-decode-kbd/.set-keycode BS   8
  ble-decode-kbd/.set-keycode HT   9  # aka TAB
  ble-decode-kbd/.set-keycode LF   10
  ble-decode-kbd/.set-keycode VT   11
  ble-decode-kbd/.set-keycode FF   12
  ble-decode-kbd/.set-keycode CR   13 # aka RET
  ble-decode-kbd/.set-keycode SO   14
  ble-decode-kbd/.set-keycode SI   15
  ble-decode-kbd/.set-keycode DLE  16
  ble-decode-kbd/.set-keycode DC1  17
  ble-decode-kbd/.set-keycode DC2  18
  ble-decode-kbd/.set-keycode DC3  19
  ble-decode-kbd/.set-keycode DC4  20
  ble-decode-kbd/.set-keycode NAK  21
  ble-decode-kbd/.set-keycode SYN  22
  ble-decode-kbd/.set-keycode ETB  23
  ble-decode-kbd/.set-keycode CAN  24
  ble-decode-kbd/.set-keycode EM   25
  ble-decode-kbd/.set-keycode SUB  26
  ble-decode-kbd/.set-keycode ESC  27
  ble-decode-kbd/.set-keycode FS   28
  ble-decode-kbd/.set-keycode GS   29
  ble-decode-kbd/.set-keycode RS   30
  ble-decode-kbd/.set-keycode US   31
  ble-decode-kbd/.set-keycode SP   32
  ble-decode-kbd/.set-keycode DEL  127
  ble-decode-kbd/.set-keycode PAD  128
  ble-decode-kbd/.set-keycode HOP  129
  ble-decode-kbd/.set-keycode BPH  130
  ble-decode-kbd/.set-keycode NBH  131
  ble-decode-kbd/.set-keycode IND  132
  ble-decode-kbd/.set-keycode NEL  133
  ble-decode-kbd/.set-keycode SSA  134
  ble-decode-kbd/.set-keycode ESA  135
  ble-decode-kbd/.set-keycode HTS  136
  ble-decode-kbd/.set-keycode HTJ  137
  ble-decode-kbd/.set-keycode VTS  138
  ble-decode-kbd/.set-keycode PLD  139
  ble-decode-kbd/.set-keycode PLU  140
  ble-decode-kbd/.set-keycode RI   141
  ble-decode-kbd/.set-keycode SS2  142
  ble-decode-kbd/.set-keycode SS3  143
  ble-decode-kbd/.set-keycode DCS  144
  ble-decode-kbd/.set-keycode PU1  145
  ble-decode-kbd/.set-keycode PU2  146
  ble-decode-kbd/.set-keycode STS  147
  ble-decode-kbd/.set-keycode CCH  148
  ble-decode-kbd/.set-keycode MW   149
  ble-decode-kbd/.set-keycode SPA  150
  ble-decode-kbd/.set-keycode EPA  151
  ble-decode-kbd/.set-keycode SOS  152
  ble-decode-kbd/.set-keycode SGCI 153
  ble-decode-kbd/.set-keycode SCI  154
  ble-decode-kbd/.set-keycode CSI  155
  ble-decode-kbd/.set-keycode ST   156
  ble-decode-kbd/.set-keycode OSC  157
  ble-decode-kbd/.set-keycode PM   158
  ble-decode-kbd/.set-keycode APC  159
  local ret
  ble-decode-kbd/generate-keycode __batch_char__
  _ble_decode_KCODE_BATCH_CHAR=$ret
  ble-decode-kbd/generate-keycode __defchar__
  _ble_decode_KCODE_DEFCHAR=$ret
  ble-decode-kbd/generate-keycode __default__
  _ble_decode_KCODE_DEFAULT=$ret
  ble-decode-kbd/generate-keycode __before_widget__
  _ble_decode_KCODE_BEFORE_WIDGET=$ret
  ble-decode-kbd/generate-keycode __after_widget__
  _ble_decode_KCODE_AFTER_WIDGET=$ret
  ble-decode-kbd/generate-keycode __attach__
  _ble_decode_KCODE_ATTACH=$ret
  ble-decode-kbd/generate-keycode shift
  _ble_decode_KCODE_SHIFT=$ret
  ble-decode-kbd/generate-keycode alter
  _ble_decode_KCODE_ALTER=$ret
  ble-decode-kbd/generate-keycode control
  _ble_decode_KCODE_CONTROL=$ret
  ble-decode-kbd/generate-keycode meta
  _ble_decode_KCODE_META=$ret
  ble-decode-kbd/generate-keycode super
  _ble_decode_KCODE_SUPER=$ret
  ble-decode-kbd/generate-keycode hyper
  _ble_decode_KCODE_HYPER=$ret
  ble-decode-kbd/generate-keycode __ignore__
  _ble_decode_KCODE_IGNORE=$ret
  ble-decode-kbd/generate-keycode __error__
  _ble_decode_KCODE_ERROR=$ret
}
ble-decode-kbd/.initialize
function ble-decode-kbd {
  local kspecs; ble/string#split-words kspecs "$*"
  local kspec code codes
  codes=()
  for kspec in "${kspecs[@]}"; do
    code=0
    while [[ $kspec == ?-* ]]; do
      case "${kspec::1}" in
      (S) ((code|=_ble_decode_Shft)) ;;
      (C) ((code|=_ble_decode_Ctrl)) ;;
      (M) ((code|=_ble_decode_Meta)) ;;
      (A) ((code|=_ble_decode_Altr)) ;;
      (s) ((code|=_ble_decode_Supr)) ;;
      (H) ((code|=_ble_decode_Hypr)) ;;
      (*) ((code|=_ble_decode_Erro)) ;;
      esac
      kspec=${kspec:2}
    done
    if [[ $kspec == ? ]]; then
      ble/util/s2c "$kspec" 0
      ((code|=ret))
    elif [[ $kspec && ! ${kspec//[_0-9a-zA-Z]} ]]; then
      ble-decode-kbd/.get-keycode "$kspec"
      [[ $ret ]] || ble-decode-kbd/generate-keycode "$kspec"
      ((code|=ret))
    elif [[ $kspec == ^? ]]; then
      if [[ $kspec == '^?' ]]; then
        ((code|=0x7F))
      elif [[ $kspec == '^`' ]]; then
        ((code|=0x20))
      else
        ble/util/s2c "$kspec" 1
        ((code|=ret&0x1F))
      fi
    else
      ((code|=_ble_decode_Erro))
    fi
    codes[${#codes[@]}]=$code
  done
  ret="${codes[*]}"
}
function ble-decode-unkbd/.single-key {
  local key=$1
  local f_unknown=
  local char=$((key&_ble_decode_MaskChar))
  ble-decode-kbd/.get-keyname "$char"
  if [[ ! $ret ]]; then
    f_unknown=1
    ret=__UNKNOWN__
  fi
  ((key&_ble_decode_Shft)) && ret=S-$ret
  ((key&_ble_decode_Meta)) && ret=M-$ret
  ((key&_ble_decode_Ctrl)) && ret=C-$ret
  ((key&_ble_decode_Altr)) && ret=A-$ret
  ((key&_ble_decode_Supr)) && ret=s-$ret
  ((key&_ble_decode_Hypr)) && ret=H-$ret
  [[ ! $f_unknown ]]
}
function ble-decode-unkbd {
  local -a kspecs
  local key
  for key in $*; do
    ble-decode-unkbd/.single-key "$key"
    kspecs[${#kspecs[@]}]=$ret
  done
  ret="${kspecs[*]}"
}
function ble-decode/PROLOGUE { :; }
function ble-decode/EPILOGUE { :; }
_ble_decode_input_count=0
_ble_decode_input_buffer=()
_ble_decode_input_original_info=()
function ble-decode/.hook/show-progress {
  if [[ $_ble_edit_info_scene == store ]]; then
    _ble_decode_input_original_info=("${_ble_edit_info[@]}")
    return
  elif [[ $_ble_edit_info_scene == default ]]; then
    _ble_decode_input_original_info=()
  elif [[ $_ble_edit_info_scene != decode_input_progress ]]; then
    return
  fi
  if ((_ble_decode_input_count)); then
    local total=${#chars[@]}
    local value=$((total-_ble_decode_input_count-1))
    local label='decoding input...'
    local sgr=$'\e[1;38;5;69;48;5;253m'
  elif ((ble_decode_char_total)); then
    local total=$ble_decode_char_total
    local value=$((total-ble_decode_char_rest-1))
    local label='processing input...'
    local sgr=$'\e[1;38;5;71;48;5;253m'
  else
    return
  fi
  local mill=$((value*1000/total))
  local cent=${mill::${#mill}-1} frac=${mill:${#mill}-1}
  local text="(${cent:-0}.$frac% $label)"
  if ble/util/is-unicode-output; then
    local ret
    ble/string#create-unicode-progress-bar "$value" "$total" 10
    text=$sgr$ret$'\e[m '$text
  fi
  ble-edit/info/show ansi "$text"
  _ble_edit_info_scene=decode_input_progress
}
function ble-decode/.hook/erase-progress {
  [[ $_ble_edit_info_scene == decode_input_progress ]] || return
  if ((${#_ble_decode_input_original_info[@]})); then
    ble-edit/info/show store "${_ble_decode_input_original_info[@]}"
  else
    ble-edit/info/default
  fi
}
function ble-decode/.hook {
  if ble/util/is-stdin-ready; then
    ble/array#push _ble_decode_input_buffer "$@"
    return
  fi
  [[ $_ble_bash_options_adjusted ]] && set +v || :
  local IFS=$' \t\n'
  ble-decode/PROLOGUE
  if (($1==bleopt_decode_abort_char)); then
    local nbytes=${#_ble_decode_input_buffer[@]}
    local nchars=${#_ble_decode_char_buffer[@]}
    if ((nbytes||nchars)); then
      _ble_decode_input_buffer=()
      _ble_decode_char_buffer=()
      ble/term/visible-bell "Abort by 'bleopt decode_abort_char=$bleopt_decode_abort_char'"
      shift
    fi
  fi
  local chars
  chars=("${_ble_decode_input_buffer[@]}" "$@")
  _ble_decode_input_buffer=()
  _ble_decode_input_count=${#chars[@]}
  if ((_ble_decode_input_count>=200)); then
    local c
    for c in "${chars[@]}"; do
      ((--_ble_decode_input_count%100==0)) && ble-decode/.hook/show-progress
      ((_ble_keylogger_enabled)) && ble/array#push _ble_keylogger_bytes "$c"
      "ble/encoding:$bleopt_input_encoding/decode" "$c"
    done
  else
    local c
    for c in "${chars[@]}"; do
      ((--_ble_decode_input_count))
      ((_ble_keylogger_enabled)) && ble/array#push _ble_keylogger_bytes "$c"
      "ble/encoding:$bleopt_input_encoding/decode" "$c"
    done
  fi
  ble-decode/.hook/erase-progress
  ble-decode/EPILOGUE
}
function ble-decode-byte {
  while (($#)); do
    "ble/encoding:$bleopt_input_encoding/decode" "$1"
    shift
  done
}
_ble_decode_csi_mode=0
_ble_decode_csi_args=
_ble_decode_csimap_tilde=()
_ble_decode_csimap_alpha=()
function ble-decode-char/csi/print {
  local num ret
  for num in "${!_ble_decode_csimap_tilde[@]}"; do
    ble-decode-unkbd "${_ble_decode_csimap_tilde[num]}"
    echo "ble-bind --csi '$num~' $ret"
  done
  for num in "${!_ble_decode_csimap_alpha[@]}"; do
    local s; ble/util/c2s "$num"; s=$ret
    ble-decode-unkbd "${_ble_decode_csimap_alpha[num]}"
    echo "ble-bind --csi '$s' $ret"
  done
}
function ble-decode-char/csi/clear {
  _ble_decode_csi_mode=0
}
function ble-decode-char/csi/.modify-key {
  local mod=$(($1-1))
  if ((mod>=0)); then
    if ((33<=key&&key<_ble_decode_FunctionKeyBase)); then
      if ((mod==0x01)); then
        mod=0
      elif ((65<=key&&key<=90)); then
        ((key|=0x20))
      fi
    fi
    ((mod&0x01&&(key|=_ble_decode_Shft),
      mod&0x02&&(key|=_ble_decode_Meta),
      mod&0x04&&(key|=_ble_decode_Ctrl),
      mod&0x08&&(key|=_ble_decode_Supr),
      mod&0x10&&(key|=_ble_decode_Hypr),
      mod&0x20&&(key|=_ble_decode_Altr)))
  fi
}
function ble-decode-char/csi/.decode {
  local char=$1 rex key
  if ((char==126)); then
    if rex='^27;([1-9][0-9]*);?([1-9][0-9]*)$' && [[ $_ble_decode_csi_args =~ $rex ]]; then
      local key=$((BASH_REMATCH[2]&_ble_decode_MaskChar))
      ble-decode-char/csi/.modify-key "${BASH_REMATCH[1]}"
      csistat=$key
      return
    fi
    if rex='^([1-9][0-9]*)(;([1-9][0-9]*))?$' && [[ $_ble_decode_csi_args =~ $rex ]]; then
      key=${_ble_decode_csimap_tilde[BASH_REMATCH[1]]}
      if [[ $key ]]; then
        ble-decode-char/csi/.modify-key "${BASH_REMATCH[3]}"
        csistat=$key
        return
      fi
    fi
  elif ((char==117)); then
    if rex='^([0-9]*)(;[0-9]*)?$'; [[ $_ble_decode_csi_args =~ $rex ]]; then
      local rematch1=${BASH_REMATCH[1]}
      if [[ $rematch1 != 1 ]]; then
        local key=$rematch1 mods=${BASH_REMATCH:${#rematch1}+1}
        ble-decode-char/csi/.modify-key "$mods"
        csistat=$key
      fi
      return
    fi
  elif ((char==94||char==64)); then
    if rex='^[1-9][0-9]*$' && [[ $_ble_decode_csi_args =~ $rex ]]; then
      key=${_ble_decode_csimap_tilde[BASH_REMATCH[1]]}
      if [[ $key ]]; then
        ((key|=_ble_decode_Ctrl,
          char==64&&(key|=_ble_decode_Shft)))
        ble-decode-char/csi/.modify-key "${BASH_REMATCH[3]}"
        csistat=$key
        return
      fi
    fi
  elif ((char==99)); then # c
    if rex='^[?>]'; [[ $_ble_decode_csi_args =~ $rex ]]; then
      if [[ $_ble_decode_csi_args == '?'* ]]; then
        ble/term/DA1/notify "${_ble_decode_csi_args:1}"
      else
        ble/term/DA2/notify "${_ble_decode_csi_args:1}"
      fi
      csistat=$_ble_decode_KCODE_IGNORE
      return
    fi
  elif ((char==82||char==110)); then # R or n
    if rex='^([0-9]+);([0-9]+)$'; [[ $_ble_decode_csi_args =~ $rex ]]; then
      ble/term/CPR/notify $((10#${BASH_REMATCH[1]})) $((10#${BASH_REMATCH[2]}))
      csistat=$_ble_decode_KCODE_IGNORE
      return
    fi
  fi
  key=${_ble_decode_csimap_alpha[char]}
  if [[ $key ]]; then
    if rex='^(1?|1;([1-9][0-9]*))$' && [[ $_ble_decode_csi_args =~ $rex ]]; then
      ble-decode-char/csi/.modify-key "${BASH_REMATCH[2]}"
      csistat=$key
      return
    fi
  fi
  csistat=$_ble_decode_KCODE_ERROR
}
function ble-decode-char/csi/consume {
  csistat=
  ((_ble_decode_csi_mode==0&&$1!=27&&$1!=155)) && return 1
  local char=$1
  case "$_ble_decode_csi_mode" in
  (0)
    ((_ble_decode_csi_mode=$1==155?2:1))
    _ble_decode_csi_args=
    csistat=_ ;;
  (1)
    if ((char!=91)); then
      _ble_decode_csi_mode=0
      return 1
    else
      _ble_decode_csi_mode=2
      _ble_decode_csi_args=
      csistat=_
    fi ;;
  (2)
    if ((32<=char&&char<64)); then
      local ret; ble/util/c2s "$char"
      _ble_decode_csi_args=$_ble_decode_csi_args$ret
      csistat=_
    elif ((64<=char&&char<127)); then
      _ble_decode_csi_mode=0
      ble-decode-char/csi/.decode "$char"
    else
      _ble_decode_csi_mode=0
    fi ;;
  esac
}
_ble_decode_char_buffer=()
function ble-decode/has-input-for-char {
  ((_ble_decode_input_count)) ||
    ble/util/is-stdin-ready ||
    ble/encoding:"$bleopt_input_encoding"/is-intermediate
}
_ble_decode_char__hook=
_ble_decode_cmap_=()
_ble_decode_char2_seq=
_ble_decode_char2_reach=
_ble_decode_char2_modifier=
_ble_decode_char2_modkcode=
function ble-decode-char {
  if [[ $ble_decode_char_nest && ! $ble_decode_char_sync ]]; then
    ble/array#push _ble_decode_char_buffer "$@"
    return 148
  fi
  local ble_decode_char_nest=1
  local iloop=0
  local ble_decode_char_total=$#
  local ble_decode_char_rest=$#
  while
    if ((iloop++%50==0)); then
      ((iloop>50)) && ble-decode/.hook/show-progress
      if [[ ! $ble_decode_char_sync ]] && ble-decode/has-input-for-char; then
        ble/array#push _ble_decode_char_buffer "$@"
        return 148
      fi
    fi
    if ((${#_ble_decode_char_buffer[@]})); then
      ((ble_decode_char_total+=${#_ble_decode_char_buffer[@]}))
      set -- "${_ble_decode_char_buffer[@]}" "$@"
      _ble_decode_char_buffer=()
    fi
    (($#))
  do
    local char=$1; shift
    ble_decode_char_rest=$#
    ((_ble_keylogger_enabled)) && ble/array#push _ble_keylogger_chars "$char"
    if ((char&_ble_decode_Erro)); then
      ((char&=~_ble_decode_Erro))
      if [[ $bleopt_decode_error_char_vbell ]]; then
        local name; ble/util/sprintf name 'U+%04x' "$char"
        ble/term/visible-bell "received a misencoded char $name"
      fi
      [[ $bleopt_decode_error_char_abell ]] && ble/term/audible-bell
      [[ $bleopt_decode_error_char_discard ]] && continue
    fi
    if [[ $_ble_decode_char__hook ]]; then
      ((char==_ble_decode_IsolatedESC)) && char=27 # isolated ESC -> ESC
      local hook=$_ble_decode_char__hook
      _ble_decode_char__hook=
      ble-decode/widget/.call-async-read "$hook $char" "$char"
      continue
    fi
    local ent
    ble-decode-char/.getent
    if [[ ! $ent ]]; then
      if [[ $_ble_decode_char2_reach ]]; then
        local reach rest
        reach=($_ble_decode_char2_reach)
        rest=${_ble_decode_char2_seq:reach[1]}
        rest=(${rest//_/ } $char)
        _ble_decode_char2_reach=
        _ble_decode_char2_seq=
        ble-decode-char/csi/clear
        ble-decode-char/.send-modified-key "${reach[0]}"
        ((ble_decode_char_total+=${#rest[@]}))
        set -- "${rest[@]}" "$@"
      else
        ble-decode-char/.send-modified-key "$char"
      fi
    elif [[ $ent == *_ ]]; then
      _ble_decode_char2_seq=${_ble_decode_char2_seq}_$char
      if [[ ${ent%_} ]]; then
        _ble_decode_char2_reach="${ent%_} ${#_ble_decode_char2_seq}"
      elif [[ ! $_ble_decode_char2_reach ]]; then
        _ble_decode_char2_reach="$char ${#_ble_decode_char2_seq}"
      fi
    else
      _ble_decode_char2_seq=
      _ble_decode_char2_reach=
      ble-decode-char/csi/clear
      ble-decode-char/.send-modified-key "$ent"
    fi
  done
  return 0
}
function ble-decode-char/.getent {
  builtin eval "ent=\${_ble_decode_cmap_$_ble_decode_char2_seq[char]-}"
  local csistat=
  ble-decode-char/csi/consume "$char"
  if [[ $csistat && ! ${ent%_} ]]; then
    if ((csistat==_ble_decode_KCODE_ERROR)); then
      if [[ $bleopt_decode_error_cseq_vbell ]]; then
        local ret; ble-decode-unkbd ${_ble_decode_char2_seq//_/ } $char
        ble/term/visible-bell "unrecognized CSI sequence: $ret"
      fi
      [[ $bleopt_decode_error_cseq_abell ]] && ble/term/audible-bell
      if [[ $bleopt_decode_error_cseq_discard ]]; then
        csistat=$_ble_decode_KCODE_IGNORE
      else
        csistat=
      fi
    fi
    if [[ ! $ent ]]; then
      ent=$csistat
    else
      ent=${csistat%_}_
    fi
  fi
}
function ble-decode-char/.process-modifier {
  local mflag1=$1 mflag=$_ble_decode_char2_modifier
  if ((mflag1&mflag)); then
    return 1
  else
    ((_ble_decode_char2_modkcode=key|mflag,
      _ble_decode_char2_modifier=mflag1|mflag))
    return 0
  fi
}
function ble-decode-char/.send-modified-key {
  local key=$1
  ((key==_ble_decode_KCODE_IGNORE)) && return
  if ((0<=key&&key<32)); then
    ((key|=(key==0||key>26?64:96)|_ble_decode_Ctrl))
  fi
  if (($1==27)); then
    ble-decode-char/.process-modifier "$_ble_decode_Meta" && return
  elif (($1==_ble_decode_IsolatedESC)); then
    ((key=(_ble_decode_Ctrl|91)))
    if ! ble-decode/uses-isolated-esc; then
      ble-decode-char/.process-modifier "$_ble_decode_Meta" && return
    fi
  elif ((_ble_decode_KCODE_SHIFT<=$1&&$1<=_ble_decode_KCODE_HYPER)); then
    case "$1" in
    ($_ble_decode_KCODE_SHIFT)
      ble-decode-char/.process-modifier "$_ble_decode_Shft" && return ;;
    ($_ble_decode_KCODE_CONTROL)
      ble-decode-char/.process-modifier "$_ble_decode_Ctrl" && return ;;
    ($_ble_decode_KCODE_ALTER)
      ble-decode-char/.process-modifier "$_ble_decode_Altr" && return ;;
    ($_ble_decode_KCODE_META)
      ble-decode-char/.process-modifier "$_ble_decode_Meta" && return ;;
    ($_ble_decode_KCODE_SUPER)
      ble-decode-char/.process-modifier "$_ble_decode_Supr" && return ;;
    ($_ble_decode_KCODE_HYPER)
      ble-decode-char/.process-modifier "$_ble_decode_Hypr" && return ;;
    esac
  fi
  if [[ $_ble_decode_char2_modifier ]]; then
    local mflag=$_ble_decode_char2_modifier
    local mcode=$_ble_decode_char2_modkcode
    _ble_decode_char2_modifier=
    _ble_decode_char2_modkcode=
    if ((key&mflag)); then
      ble-decode-key "$mcode"
    else
      ((key|=mflag))
    fi
  fi
  ble-decode-key "$key"
}
function ble-decode-char/is-intermediate { [[ $_ble_decode_char2_seq ]]; }
function ble-decode-char/bind {
  local -a seq; ble/string#split-words seq "$1"
  local kc=$2
  local i iN=${#seq[@]} char tseq=
  for ((i=0;i<iN;i++)); do
    local char=${seq[i]}
    builtin eval "local okc=\${_ble_decode_cmap_$tseq[char]-}"
    if ((i+1==iN)); then
      if [[ ${okc//[0-9]} == _ ]]; then
        builtin eval "_ble_decode_cmap_$tseq[char]=\${kc}_"
      else
        builtin eval "_ble_decode_cmap_$tseq[char]=\${kc}"
      fi
    else
      if [[ ! $okc ]]; then
        builtin eval "_ble_decode_cmap_$tseq[char]=_"
      else
        builtin eval "_ble_decode_cmap_$tseq[char]=\${okc%_}_"
      fi
      tseq=${tseq}_$char
    fi
  done
}
function ble-decode-char/unbind {
  local -a seq; ble/string#split-words seq "$1"
  local tseq=
  local i iN=${#seq}
  for ((i=0;i<iN-1;i++)); do
    tseq=${tseq}_${seq[i]}
  done
  local char=${seq[iN-1]}
  local isfirst=1 ent=
  while
    builtin eval "ent=\${_ble_decode_cmap_$tseq[char]-}"
    if [[ $isfirst ]]; then
      isfirst=
      if [[ $ent == *_ ]]; then
        builtin eval "_ble_decode_cmap_$tseq[char]=_"
        break
      fi
    else
      if [[ $ent != _ ]]; then
        builtin eval "_ble_decode_cmap_$tseq[char]=${ent%_}"
        break
      fi
    fi
    unset -v "_ble_decode_cmap_$tseq[char]"
    builtin eval "((\${#_ble_decode_cmap_$tseq[@]}!=0))" && break
    [[ $tseq ]]
  do
    char=${tseq##*_}
    tseq=${tseq%_*}
  done
}
function ble-decode-char/dump {
  local tseq=$1 nseq ccode
  nseq=("${@:2}")
  builtin eval "local -a ccodes; ccodes=(\${!_ble_decode_cmap_$tseq[@]})"
  for ccode in "${ccodes[@]}"; do
    local ret; ble-decode-unkbd "$ccode"
    local cnames
    cnames=("${nseq[@]}" "$ret")
    builtin eval "local ent=\${_ble_decode_cmap_$tseq[ccode]}"
    if [[ ${ent%_} ]]; then
      local key=${ent%_} ret
      ble-decode-unkbd "$key"; local kspec=$ret
      builtin echo "ble-bind -k '${cnames[*]}' '$kspec'"
    fi
    if [[ ${ent//[0-9]} == _ ]]; then
      ble-decode-char/dump "${tseq}_$ccode" "${cnames[@]}"
    fi
  done
}
_ble_decode_kmaps=
function ble-decode/keymap/register {
  local kmap=$1
  if [[ $kmap && :$_ble_decode_kmaps: != *:"$kmap":* ]]; then
    _ble_decode_kmaps=$_ble_decode_kmaps:$kmap
  fi
}
function ble-decode/keymap/unregister {
  _ble_decode_kmaps=$_ble_decode_kmaps:
  _ble_decode_kmaps=${_ble_decode_kmaps//:"$1":/:}
  _ble_decode_kmaps=${_ble_decode_kmaps%:}
}
function ble-decode/keymap/is-registered {
  [[ :$_ble_decode_kmaps: == *:"$1":* ]]
}
function ble-decode/keymap/dump {
  if (($#)); then
    local kmap=$1 arrays
    builtin eval "arrays=(\"\${!_ble_decode_${kmap}_kmap_@}\")"
    builtin echo "ble-decode/keymap/register $kmap"
    ble/util/declare-print-definitions "${arrays[@]}"
  else
    local keymap_name
    for keymap_name in ${_ble_decode_kmaps//:/ }; do
      ble-decode/keymap/dump "$keymap_name"
    done
  fi
}
function ble-decode/DEFAULT_KEYMAP {
  [[ $1 == -v ]] || return 1
  builtin eval "$2=emacs"
}
function ble/widget/.SHELL_COMMAND { eval "$*"; }
function ble/widget/.EDIT_COMMAND { eval "$*"; }
function ble-decode-key/bind {
  local dicthead=_ble_decode_${kmap}_kmap_
  local -a seq; ble/string#split-words seq "$1"
  local cmd=$2
  local i iN=${#seq[@]} tseq=
  for ((i=0;i<iN;i++)); do
    local key=${seq[i]}
    builtin eval "local ocmd=\${$dicthead$tseq[key]}"
    if ((i+1==iN)); then
      if [[ ${ocmd::1} == _ ]]; then
        builtin eval "$dicthead$tseq[key]=_:\$cmd"
      else
        builtin eval "$dicthead$tseq[key]=1:\$cmd"
      fi
    else
      if [[ ! $ocmd ]]; then
        builtin eval "$dicthead$tseq[key]=_"
      elif [[ ${ocmd::1} == 1 ]]; then
        builtin eval "$dicthead$tseq[key]=_:\${ocmd#?:}"
      fi
      tseq=${tseq}_$key
    fi
  done
}
function ble-decode-key/unbind {
  local dicthead=_ble_decode_${kmap}_kmap_
  local -a seq; ble/string#split-words seq "$1"
  local i iN=${#seq[@]}
  local key=${seq[iN-1]}
  local tseq=
  for ((i=0;i<iN-1;i++)); do
    tseq=${tseq}_${seq[i]}
  done
  local isfirst=1 ent=
  while
    builtin eval "ent=\${$dicthead$tseq[key]}"
    if [[ $isfirst ]]; then
      isfirst=
      if [[ ${ent::1} == _ ]]; then
        builtin eval "$dicthead$tseq[key]=_"
        break
      fi
    else
      if [[ $ent != _ ]]; then
        builtin eval "$dicthead$tseq[key]=1:\${ent#?:}"
        break
      fi
    fi
    unset -v "$dicthead$tseq[key]"
    builtin eval "((\${#$dicthead$tseq[@]}!=0))" && break
    [[ $tseq ]]
  do
    key=${tseq##*_}
    tseq=${tseq%_*}
  done
}
function ble-decode-key/dump {
  local kmap
  if (($#==0)); then
    for kmap in ${_ble_decode_kmaps//:/ }; do
      echo "# keymap $kmap"
      ble-decode-key/dump "$kmap"
    done
    return
  fi
  local kmap=$1 tseq=$2 nseq=$3
  local dicthead=_ble_decode_${kmap}_kmap_
  local kmapopt=
  [[ $kmap ]] && kmapopt=" -m '$kmap'"
  local key keys
  builtin eval "keys=(\${!$dicthead$tseq[@]})"
  for key in "${keys[@]}"; do
    local ret; ble-decode-unkbd "$key"
    local knames=$nseq${nseq:+ }$ret
    builtin eval "local ent=\${$dicthead$tseq[key]}"
    if [[ ${ent:2} ]]; then
      local cmd=${ent:2} q=\' Q="'\''"
      case "$cmd" in
      ('ble/widget/.SHELL_COMMAND '*)
        echo "ble-bind$kmapopt -c '${knames//$q/$Q}' ${cmd#ble/widget/.SHELL_COMMAND }" ;;
      ('ble/widget/.EDIT_COMMAND '*)
        echo "ble-bind$kmapopt -x '${knames//$q/$Q}' ${cmd#ble/widget/.EDIT_COMMAND }" ;;
      ('ble/widget/.ble-decode-char '*)
        local ret; ble/util/chars2keyseq ${cmd#*' '}
        echo "ble-bind$kmapopt -s '${knames//$q/$Q}' '${ret//$q/$Q}'" ;;
      ('ble/widget/'*)
        echo "ble-bind$kmapopt -f '${knames//$q/$Q}' '${cmd#ble/widget/}'" ;;
      (*)
        echo "ble-bind$kmapopt -@ '${knames//$q/$Q}' '${cmd}'" ;;
      esac
    fi
    if [[ ${ent::1} == _ ]]; then
      ble-decode-key/dump "$kmap" "${tseq}_$key" "$knames"
    fi
  done
}
_ble_decode_keymap=emacs
_ble_decode_keymap_stack=()
_ble_decode_keymap_load=
function ble-decode/keymap/is-keymap {
  builtin eval -- "((\${#_ble_decode_${1}_kmap_[*]}))"
}
function ble-decode/keymap/load {
  ble-decode/keymap/is-keymap "$1" && return 0
  local init=ble-decode/keymap:$1/define
  if ble/is-function "$init"; then
    "$init" && ble-decode/keymap/is-keymap "$1"
  elif [[ $_ble_decode_keymap_load != *s* ]]; then
    ble/util/import "keymap/$1.sh" &&
      local _ble_decode_keymap_load=s &&
      ble-decode/keymap/load "$1" # 再試行
  else
    return 1
  fi
}
function ble-decode/keymap/push {
  if ble-decode/keymap/is-keymap "$1"; then
    ble/array#push _ble_decode_keymap_stack "$_ble_decode_keymap"
    _ble_decode_keymap=$1
  elif ble-decode/keymap/load "$1" && ble-decode/keymap/is-keymap "$1"; then
    ble-decode/keymap/push "$1" # 再実行
  else
    echo "[ble: keymap '$1' not found]" >&2
    return 1
  fi
}
function ble-decode/keymap/pop {
  local count=${#_ble_decode_keymap_stack[@]}
  local last=$((count-1))
  ble/util/assert '((last>=0))' || return
  _ble_decode_keymap=${_ble_decode_keymap_stack[last]}
  unset -v '_ble_decode_keymap_stack[last]'
}
_ble_decode_key__seq=
_ble_decode_key__hook=
function ble-decode-key/is-intermediate { [[ $_ble_decode_key__seq ]]; }
_ble_decode_key_batch=()
function ble-decode-key/batch/flush {
  ((${#_ble_decode_key_batch[@]})) || return
  eval "local command=\${${dicthead}[_ble_decode_KCODE_BATCH_CHAR]-}"
  command=${command:2}
  if [[ $command ]]; then
    local chars; chars=("${_ble_decode_key_batch[@]}")
    _ble_decode_key_batch=()
    ble-decode/widget/call-interactively "$command" "${chars[@]}"; local ext=$?
    ((ext!=125)) && return
  fi
  ble-decode/widget/call-interactively ble/widget/__batch_char__.default "${chars[@]}"; local ext=$?
  return "$ext"
}
function ble/widget/__batch_char__.default {
  builtin eval "local widget_defchar=\${${dicthead}[_ble_decode_KCODE_DEFCHAR]-}"
  widget_defchar=${widget_defchar:2}
  builtin eval "local widget_default=\${${dicthead}[_ble_decode_KCODE_DEFAULT]-}"
  widget_default=${widget_default:2}
  local -a unprocessed_chars=()
  local key command
  for key in "${KEYS[@]}"; do
    if [[ $widget_defchar ]]; then
      ble-decode/widget/call-interactively "$widget_defchar" "$key"; local ext=$?
      ((ext!=125)) && continue
    fi
    if [[ $widget_default ]]; then
      ble-decode/widget/call-interactively "$widget_default" "$key"; local ext=$?
      ((ext!=125)) && continue
    fi
    ble/array#push unprocessed_chars "$key"
  done
  if ((${#unprocessed_chars[@]})); then
    local ret; ble-decode-unkbd "${unprocessed_chars[@]}"
    [[ $bleopt_decode_error_kseq_vbell ]] && ble/term/visible-bell "unprocessed chars: $ret"
    [[ $bleopt_decode_error_kseq_abell ]] && ble/term/audible-bell
  fi
  return 0
}
function ble-decode-key {
  local key
  for key; do
    ((_ble_keylogger_enabled)) && ble/array#push _ble_keylogger_keys "$key"
    [[ $_ble_decode_keylog_enabled && $_ble_decode_keylog_depth == 0 ]] &&
      ble/array#push _ble_decode_keylog "$key"
    if [[ $_ble_decode_key__hook ]]; then
      local hook=$_ble_decode_key__hook
      _ble_decode_key__hook=
      ble-decode/widget/.call-async-read "$hook $key" "$key"
      continue
    fi
    local dicthead=_ble_decode_${_ble_decode_keymap}_kmap_
    builtin eval "local ent=\${$dicthead$_ble_decode_key__seq[key]-}"
    if [[ $ent == 1:* ]]; then
      local command=${ent:2}
      if [[ $command ]]; then
        ble-decode/widget/.call-keyseq
      else
        _ble_decode_key__seq=
      fi
    elif [[ $ent == _ || $ent == _:* ]]; then
      _ble_decode_key__seq=${_ble_decode_key__seq}_$key
    else
      ble-decode-key/.invoke-partial-match "$key" && continue
      local kseq=${_ble_decode_key__seq}_$key ret
      ble-decode-unkbd "${kseq//_/ }"
      local kspecs=$ret
      [[ $bleopt_decode_error_kseq_vbell ]] && ble/term/visible-bell "unbound keyseq: $kspecs"
      [[ $bleopt_decode_error_kseq_abell ]] && ble/term/audible-bell
      if [[ $_ble_decode_key__seq ]]; then
        if [[ $bleopt_decode_error_kseq_discard ]]; then
          _ble_decode_key__seq=
        else
          local -a keys=(${_ble_decode_key__seq//_/ } $key)
          _ble_decode_key__seq=
          ble-decode-key "${keys[@]:1}"
        fi
      fi
    fi
  done
  if ((${#_ble_decode_key_batch[@]})); then
    if ! ble-decode/has-input || ((${#_ble_decode_key_batch[@]}>=50)); then
      ble-decode-key/batch/flush
    fi
  fi
  return 0
}
function ble-decode-key/.invoke-partial-match {
  local dicthead=_ble_decode_${_ble_decode_keymap}_kmap_
  local next=$1
  if [[ $_ble_decode_key__seq ]]; then
    local last=${_ble_decode_key__seq##*_}
    _ble_decode_key__seq=${_ble_decode_key__seq%_*}
    builtin eval "local ent=\${$dicthead$_ble_decode_key__seq[last]-}"
    if [[ $ent == '_:'* ]]; then
      local command=${ent:2}
      if [[ $command ]]; then
        ble-decode/widget/.call-keyseq
      else
        _ble_decode_key__seq=
      fi
      ble-decode-key "$next"
      return 0
    else # ent = _
      if ble-decode-key/.invoke-partial-match "$last"; then
        ble-decode-key "$next"
        return 0
      else
        _ble_decode_key__seq=${_ble_decode_key__seq}_$last
        return 1
      fi
    fi
  else
    local key=$1
    if ble-decode-key/ischar "$key"; then
      if ble-decode/has-input && eval "[[ \${${dicthead}[_ble_decode_KCODE_BATCH_CHAR]-} ]]"; then
        ble/array#push _ble_decode_key_batch "$key"
        return 0
      fi
      builtin eval "local command=\${${dicthead}[_ble_decode_KCODE_DEFCHAR]-}"
      command=${command:2}
      if [[ $command ]]; then
        local seq_save=$_ble_decode_key__seq
        ble-decode/widget/.call-keyseq; local ext=$?
        ((ext!=125)) && return
        _ble_decode_key__seq=$seq_save # 125 の時はまた元に戻して次の試行を行う
      fi
    fi
    builtin eval "local command=\${${dicthead}[_ble_decode_KCODE_DEFAULT]-}"
    command=${command:2}
    ble-decode/widget/.call-keyseq; local ext=$?
    ((ext!=125)) && return
    return 1
  fi
}
function ble-decode-key/ischar {
  local key=$1
  (((key&_ble_decode_MaskFlag)==0&&32<=key&&key<_ble_decode_FunctionKeyBase))
}
_ble_decode_widget_last=
function ble-decode/widget/.invoke-hook {
  local key=$1
  local dicthead=_ble_decode_${_ble_decode_keymap}_kmap_
  builtin eval "local hook=\${$dicthead[key]-}"
  hook=${hook:2}
  [[ $hook ]] && builtin eval -- "$hook"
}
function ble-decode/widget/.call-keyseq {
  ble-decode-key/batch/flush
  [[ $command ]] || return 125
  local old_suppress=$_ble_decode_keylog_depth
  local _ble_decode_keylog_depth=$((old_suppress+1))
  local WIDGET=$command KEYMAP=$_ble_decode_keymap LASTWIDGET=$_ble_decode_widget_last
  local -a KEYS=(${_ble_decode_key__seq//_/ } $key)
  _ble_decode_widget_last=$WIDGET
  _ble_decode_key__seq=
  ble-decode/widget/.invoke-hook "$_ble_decode_KCODE_BEFORE_WIDGET"
  builtin eval -- "$WIDGET"; local ext=$?
  ble-decode/widget/.invoke-hook "$_ble_decode_KCODE_AFTER_WIDGET"
  return "$ext"
}
function ble-decode/widget/.call-async-read {
  local old_suppress=$_ble_decode_keylog_depth
  local _ble_decode_keylog_depth=$((old_suppress+1))
  local WIDGET=$1 KEYMAP=$_ble_decode_keymap LASTWIDGET=$_ble_decode_widget_last
  local -a KEYS=($2)
  builtin eval -- "$WIDGET"
}
function ble-decode/widget/call-interactively {
  local WIDGET=$1 KEYMAP=$_ble_decode_keymap LASTWIDGET=$_ble_decode_widget_last
  local -a KEYS; KEYS=("${@:2}")
  _ble_decode_widget_last=$WIDGET
  ble-decode/widget/.invoke-hook "$_ble_decode_KCODE_BEFORE_WIDGET"
  builtin eval -- "$WIDGET"; local ext=$?
  ble-decode/widget/.invoke-hook "$_ble_decode_KCODE_AFTER_WIDGET"
  return "$ext"
}
function ble-decode/widget/call {
  local WIDGET=$1 KEYMAP=$_ble_decode_keymap LASTWIDGET=$_ble_decode_widget_last
  local -a KEYS; KEYS=("${@:2}")
  _ble_decode_widget_last=$WIDGET
  builtin eval -- "$WIDGET"
}
function ble-decode/widget/suppress-widget {
  WIDGET=
}
function ble-decode/has-input {
  ((_ble_decode_input_count||ble_decode_char_rest)) ||
    ble/util/is-stdin-ready ||
    ble/encoding:"$bleopt_input_encoding"/is-intermediate ||
    ble-decode-char/is-intermediate
}
function ble/util/idle/IS_IDLE {
  ! ble-decode/has-input
}
_ble_keylogger_enabled=0
_ble_keylogger_bytes=()
_ble_keylogger_chars=()
_ble_keylogger_keys=()
function ble-decode/start-keylog {
  _ble_keylogger_enabled=1
}
function ble-decode/end-keylog {
  {
    echo '===== bytes ====='
    printf '%s\n' "${_ble_keylogger_bytes[*]}"
    echo
    echo '===== chars ====='
    local ret; ble-decode-unkbd "${_ble_keylogger_chars[@]}"
    ble/string#split ret ' ' "$ret"
    printf '%s\n' "${ret[*]}"
    echo
    echo '===== keys ====='
    local ret; ble-decode-unkbd "${_ble_keylogger_keys[@]}"
    ble/string#split ret ' ' "$ret"
    printf '%s\n' "${ret[*]}"
    echo
  } | fold -w 40
  _ble_keylogger_enabled=0
  _ble_keylogger_bytes=()
  _ble_keylogger_chars=()
  _ble_keylogger_keys=()
}
_ble_decode_keylog_enabled=
_ble_decode_keylog_depth=0
_ble_decode_keylog=()
function ble-decode/keylog/start {
  _ble_decode_keylog_enabled=1
  _ble_decode_keylog=()
}
function ble-decode/keylog/end {
  ret=("${_ble_decode_keylog[@]}")
  _ble_decode_keylog_enabled=
  _ble_decode_keylog=()
}
function ble-decode/keylog/pop {
  [[ $_ble_decode_keylog_enabled && $_ble_decode_keylog_depth == 1 ]] || return
  local new_size=$((${#_ble_decode_keylog[@]}-${#KEYS[@]}))
  _ble_decode_keylog=("${_ble_decode_keylog[@]::new_size}")
}
function ble-bind/load-keymap {
  local kmap=$1
  ble-decode/keymap/is-registered "$kmap" && return 0
  ble-decode/keymap/register "$kmap"
  ble-decode/keymap/load "$kmap" && return 0
  ble-decode/keymap/unregister "$kmap"
  echo "ble-bind: the keymap '$kmap' is not defined" >&2
  return 1
}
function ble-bind/option:help {
  ble/util/cat <<EOF
ble-bind --help
ble-bind -k cspecs [kspec]
ble-bind --csi PsFt kspec
ble-bind [-m keymap] -fxc@s kspecs command
ble-bind [-m keymap]... (-PD|--print|--dump)
ble-bind (-L|--list-widgets)
EOF
}
function ble-bind/check-argunment {
  if (($3<$2)); then
    if (($2==1)); then
      echo "ble-bind: the option \`$1' requires an argument." >&2
    else
      echo "ble-bind: the option \`$1' requires $2 arguments." >&2
    fi
    return 2
  fi
}
function ble-bind/option:csi {
  local ret key=
  if [[ $2 ]]; then
    ble-decode-kbd "$2"
    ble/string#split-words key "$ret"
    if ((${#key[@]}!=1)); then
      echo "ble-bind --csi: the second argument is not a single key!" >&2
      return 1
    elif ((key&~_ble_decode_MaskChar)); then
      echo "ble-bind --csi: the second argument should not have modifiers!" >&2
      return 1
    fi
  fi
  local rex
  if rex='^([1-9][0-9]*)~$' && [[ $1 =~ $rex ]]; then
    _ble_decode_csimap_tilde[BASH_REMATCH[1]]=$key
    local -a cseq
    cseq=(27 91)
    local ret i iN num="${BASH_REMATCH[1]}\$"
    for ((i=0,iN=${#num};i<iN;i++)); do
      ble/util/s2c "$num" "$i"
      ble/array#push cseq "$ret"
    done
    if [[ $key ]]; then
      ble-decode-char/bind "${cseq[*]}" $((key|_ble_decode_Shft))
    else
      ble-decode-char/unbind "${cseq[*]}"
    fi
  elif [[ $1 == [a-zA-Z] ]]; then
    local ret; ble/util/s2c "$1"
    _ble_decode_csimap_alpha[ret]=$key
  else
    echo "ble-bind --csi: not supported type of csi sequences: CSI \`$1'." >&2
    return 1
  fi
}
function ble-bind/option:list-widgets {
  declare -f | ble/bin/sed -n -r 's/^ble\/widget\/([[:alpha:]][^.[:space:]();&|]+)[[:space:]]*\(\)[[:space:]]*$/\1/p'
}
function ble-bind/option:dump {
  if (($#)); then
    local keymap
    for keymap; do
      ble-decode/keymap/dump "$keymap"
    done
  else
    ble/util/declare-print-definitions "${!_ble_decode_kbd__@}" "${!_ble_decode_cmap_@}" "${!_ble_decode_csimap_@}"
    ble-decode/keymap/dump
  fi
}
function ble-bind/option:print {
  local keymap
  ble-decode/DEFAULT_KEYMAP -v keymap # 初期化を強制する
  if (($#)); then
    for keymap; do
      ble-decode-key/dump "$keymap"
    done
  else
    ble-decode-char/csi/print
    ble-decode-char/dump
    ble-decode-key/dump
  fi
}
function ble-bind {
  local kmap=$ble_bind_keymap ret
  local -a keymaps; keymaps=()
  local arg c
  while (($#)); do
    local arg=$1; shift
    if [[ $arg == --?* ]]; then
      case "${arg:2}" in
      (help)
        ble-bind/option:help ;;
      (csi)
        ble-bind/check-argunment --csi 2 "$#" || return
        ble-bind/option:csi "$1" "$2"
        shift 2 ;;
      (list-widgets|list-functions)
        ble-bind/option:list-widgets ;;
      (dump) ble-bind/option:dump "${keymaps[@]}" ;;
      (print) ble-bind/option:print "${keymaps[@]}" ;;
      (*)
        echo "ble-bind: unrecognized long option $arg" >&2
        return 2 ;;
      esac
    elif [[ $arg == -?* ]]; then
      arg=${arg:1}
      while ((${#arg})); do
        c=${arg::1} arg=${arg:1}
        case $c in
        (k)
          if (($#<2)); then
            echo "ble-bind: the option \`-k' requires two arguments." >&2
            return 2
          fi
          ble-decode-kbd "$1"; local cseq=$ret
          if [[ $2 && $2 != - ]]; then
            ble-decode-kbd "$2"; local kc=$ret
            ble-decode-char/bind "$cseq" "$kc"
          else
            ble-decode-char/unbind "$cseq"
          fi
          shift 2 ;;
        (m)
          if (($#<1)); then
            echo "ble-bind: the option \`-m' requires an argument." >&2
            return 2
          elif ! ble-bind/load-keymap "$1"; then
            return 1
          fi
          kmap=$1
          ble/array#push keymaps "$1"
          shift ;;
        (D) ble-bind/option:dump "${keymaps[@]}" ;;
        ([Pd]) ble-bind/option:print "${keymaps[@]}" ;;
        (['fxc@s'])
          [[ $c != f && $arg == f* ]] && arg=${arg:1}
          if (($#<2)); then
            echo "ble-bind: the option \`-$c' requires two arguments." >&2
            return 2
          fi
          ble-decode-kbd "$1"; local kbd=$ret
          if [[ $2 && $2 != - ]]; then
            local command=$2
            case $c in
            (f)
              command=ble/widget/$command
              local arr; ble/string#split-words arr "$command"
              if ! ble/is-function "${arr[0]}"; then
                local message="ble-bind: Unknown ble edit function \`${arr[0]#'ble/widget/'}'."
                [[ $command == ble/widget/ble/widget/* ]] &&
                  message="$message Note: The prefix 'ble/widget/' is redundant"
                echo "$message" 1>&2
                return 1
              fi ;;
            (x) # 編集用の関数
              local q=\' Q="''\'"
              command="ble/widget/.EDIT_COMMAND '${command//$q/$Q}'" ;;
            (c) # コマンド実行
              local q=\' Q="''\'"
              command="ble/widget/.SHELL_COMMAND '${command//$q/$Q}'" ;;
            (s)
              local ret; ble/util/keyseq2chars "$command"
              command="ble/widget/.ble-decode-char ${ret[*]}" ;;
            ('@') ;; # 直接実行
            (*)
              echo "error: unsupported binding type \`-$c'." 1>&2
              return 1 ;;
            esac
            [[ $kmap ]] || ble-decode/DEFAULT_KEYMAP -v kmap
            ble-decode-key/bind "$kbd" "$command"
          else
            [[ $kmap ]] || ble-decode/DEFAULT_KEYMAP -v kmap
            ble-decode-key/unbind "$kbd"
          fi
          shift 2 ;;
        (L)
          ble-bind/option:list-widgets ;;
        (*)
          echo "ble-bind: unrecognized short option \`-$c'." >&2
          return 2 ;;
        esac
      done
    else
      echo "ble-bind: unrecognized argument \`$arg'." >&2
      return 2
    fi
  done
  return 0
}
function ble/widget/.ble-decode-char {
  ble-decode-char "$@"
}
_ble_decode_bind__uvwflag=
function ble-decode-bind/uvw {
  [[ $_ble_decode_bind__uvwflag ]] && return
  _ble_decode_bind__uvwflag=1
  builtin bind -x '"":ble-decode/.hook 21; builtin eval "$_ble_decode_bind_hook"'
  builtin bind -x '"":ble-decode/.hook 22; builtin eval "$_ble_decode_bind_hook"'
  builtin bind -x '"":ble-decode/.hook 23; builtin eval "$_ble_decode_bind_hook"'
  builtin bind -x '"":ble-decode/.hook 127; builtin eval "$_ble_decode_bind_hook"'
}
function ble/base/workaround-POSIXLY_CORRECT {
  [[ $_ble_decode_bind_state == none ]] && return
  builtin bind -x '"\C-i":ble-decode/.hook 9; builtin eval "$_ble_decode_bind_hook"'
}
_ble_decode_bind_hook=
function ble-decode-bind/c2dqs {
  local i=$1
  if ((0<=i&&i<32)); then
    if ((1<=i&&i<=26)); then
      ble/util/c2s $((i+96))
      ret="\\C-$ret"
    elif ((i==27)); then
      ret="\\e"
    else
      ble-decode-bind/c2dqs $((i+64))
      ret="\\C-$ret"
    fi
  elif ((32<=i&&i<127)); then
    ble/util/c2s "$i"
    if ((i==34||i==92)); then
      ret='\'"$ret"
    fi
  elif ((128<=i&&i<160)); then
    ble/util/sprintf ret '\\%03o' "$i"
  else
    ble/util/sprintf ret '\\%03o' "$i"
  fi
}
function ble-decode-bind/cmap/.generate-binder-template {
  local tseq=$1 qseq=$2 nseq=$3 depth=${4:-1} ccode
  local apos="'" escapos="'\\''"
  builtin eval "local -a ccodes; ccodes=(\${!_ble_decode_cmap_$tseq[@]})"
  for ccode in "${ccodes[@]}"; do
    local ret
    ble-decode-bind/c2dqs "$ccode"
    qseq1=$qseq$ret
    nseq1="$nseq $ccode"
    builtin eval "local ent=\${_ble_decode_cmap_$tseq[ccode]}"
    if [[ ${ent%_} ]]; then
      if ((depth>=3)); then
        echo "\$binder \"$qseq1\" \"${nseq1# }\""
      fi
    fi
    if [[ ${ent//[0-9]} == _ ]]; then
      ble-decode-bind/cmap/.generate-binder-template "${tseq}_$ccode" "$qseq1" "$nseq1" $((depth+1))
    fi
  done
}
function ble-decode-bind/cmap/.emit-bindx {
  local ap="'" eap="'\\''"
  echo "builtin bind -x '\"${1//$ap/$eap}\":ble-decode/.hook $2; builtin eval \"\$_ble_decode_bind_hook\"'"
}
function ble-decode-bind/cmap/.emit-bindr {
  echo "builtin bind -r \"$1\""
}
_ble_decode_cmap_initialized=
function ble-decode-bind/cmap/initialize {
  [[ $_ble_decode_cmap_initialized ]] && return
  _ble_decode_cmap_initialized=1
  [[ -d $_ble_base_cache ]] || ble/bin/mkdir -p "$_ble_base_cache"
  local init=$_ble_base/lib/init-cmap.sh
  local dump=$_ble_base_cache/cmap+default.$_ble_decode_kbd_ver.$TERM.dump
  if [[ $dump -nt $init ]]; then
    source "$dump"
  else
    ble-edit/info/immediate-show text 'ble.sh: generating "'"$dump"'"...'
    source "$init"
    ble-bind -D | ble/bin/sed '
      s/^declare \{1,\}\(-[aAfFgilrtux]\{1,\} \{1,\}\)\{0,1\}//
      s/^-- //
      s/["'"'"']//g
    ' >| "$dump"
  fi
  if ((_ble_bash>=40300)); then
    local fbinder=$_ble_base_cache/cmap+default.binder-source
    _ble_decode_bind_fbinder=$fbinder
    if ! [[ $_ble_decode_bind_fbinder -nt $init ]]; then
      ble-edit/info/immediate-show text  'ble.sh: initializing multichar sequence binders... '
      ble-decode-bind/cmap/.generate-binder-template >| "$fbinder"
      binder=ble-decode-bind/cmap/.emit-bindx source "$fbinder" >| "$fbinder.bind"
      binder=ble-decode-bind/cmap/.emit-bindr source "$fbinder" >| "$fbinder.unbind"
      ble-edit/info/immediate-show text  'ble.sh: initializing multichar sequence binders... done'
    fi
  fi
}
function ble-decode-bind/.generate-source-to-unbind-default {
  {
    if ((_ble_bash>=40300)); then
      echo '__BINDX__'
      builtin bind -X
    fi
    echo '__BINDP__'
    builtin bind -sp
  } | LC_ALL=C ble-decode-bind/.generate-source-to-unbind-default/.process
} 2>/dev/null
function ble-decode-bind/.generate-source-to-unbind-default/.process {
  local q=\' b=\\ Q="'\''"
  [[ $_ble_bin_awk_solaris_xpg4 == yes ]] && Q="'$b$b''"
  local QUOT_Q=\"${Q//"$b"/$b$b}\"
  ble/bin/awk -v q="$q" '
    BEGIN {
      Q = '"$QUOT_Q"';
      mode = 1;
    }
    function quote(text) {
      gsub(q, Q, text);
      return q text q;
    }
    function unescape_control_modifier(str, _, i, esc, chr) {
      for (i = 0; i < 32; i++) {
        if (i == 0 || i == 31)
          esc = sprintf("\\\\C-%c", i + 64);
        else if (27 <= i && i <= 30)
          esc = sprintf("\\\\C-\\%c", i + 64);
        else
          esc = sprintf("\\\\C-%c", i + 96);
        chr = sprintf("%c", i);
        gsub(esc, chr, str);
      }
      gsub(/\\C-\?/, sprintf("%c", 127), str);
      return str;
    }
    function unescape(str) {
      if (str ~ /\\C-/)
        str = unescape_control_modifier(str);
      gsub(/\\e/, sprintf("%c", 27), str);
      gsub(/\\"/, "\"", str);
      gsub(/\\\\/, "\\", str);
      return str;
    }
    function output_bindr(line0, _seq) {
      if (match(line0, /^"(([^"\\]|\\.)+)"/) > 0) {
        _seq = substr(line0, 2, RLENGTH - 2);
        gsub(/\\M-/, "\\e", _seq);
        print "builtin bind -r " quote(_seq);
      }
    }
    /^__BINDP__$/ { mode = 1; next; }
    /^__BINDX__$/ { mode = 2; next; }
    mode == 1 && $0 ~ /^"/ {
      sub(/^"\\C-\\\\\\"/, "\"\\C-\\\\\"");
      sub(/^"\\C-\\"/, "\"\\C-\\\\\"");
      output_bindr($0);
      print "builtin bind " quote($0) > "/dev/stderr";
    }
    mode == 2 && $0 ~ /^"/ {
      output_bindr($0);
      line = $0;
      if (line ~ /(^|[^[:alnum:]])ble-decode\/.hook($|[^[:alnum:]])/) next;
      if (match(line, /^("([^"\\]|\\.)*":) "(([^"\\]|\\.)*)"/) > 0) {
        rlen = RLENGTH;
        match(line, /^"([^"\\]|\\.)*":/);
        rlen1 = RLENGTH;
        rlen2 = rlen - rlen1 - 3;
        sequence = substr(line, 1        , rlen1);
        command  = substr(line, rlen1 + 3, rlen2);
        if (command ~ /\\/)
          command = unescape(command);
        line = sequence command;
      }
      print "builtin bind -x " quote(line) > "/dev/stderr";
    }
  ' 2>| "$_ble_base_run/$$.bind.save"
}
function ble-decode/bind {
  local file=$_ble_base_cache/ble-decode-bind.$_ble_bash.$bleopt_input_encoding.bind
  [[ $file -nt $_ble_base/lib/init-bind.sh ]] || source "$_ble_base/lib/init-bind.sh"
  ble/term/rl-convert-meta/enter
  source "$file"
  _ble_decode_bind__uvwflag=
}
function ble-decode/unbind {
  ble/function#try ble/encoding:"$bleopt_input_encoding"/clear
  source "$_ble_base_cache/ble-decode-bind.$_ble_bash.$bleopt_input_encoding.unbind"
}
function ble-decode/initialize {
  ble-decode-bind/cmap/initialize
}
_ble_decode_bind_state=none
function ble-decode/reset-default-keymap {
  ble-decode/DEFAULT_KEYMAP -v _ble_decode_keymap # 0ms
  ble-decode/widget/.invoke-hook "$_ble_decode_KCODE_ATTACH" # 7ms for vi-mode
}
function ble-decode/attach {
  [[ $_ble_decode_bind_state != none ]] && return
  ble/util/save-editing-mode _ble_decode_bind_state
  [[ $_ble_decode_bind_state == none ]] && return 1
  ble/term/initialize # 3ms
  ble/util/reset-keymap-of-editing-mode
  builtin eval -- "$(ble-decode-bind/.generate-source-to-unbind-default)" # 21ms
  ble-decode/bind # 20ms
  if ! ble/is-array "_ble_decode_${_ble_decode_keymap}_kmap_"; then
    echo "ble.sh: Failed to load the default keymap. keymap '$_ble_decode_keymap' is not defined." >&2
    ble-decode/detach
    return 1
  fi
  [[ $TERM == linux ]] ||
    ble/util/buffer $'\e[>c' # DA2 要求 (ble-decode-char/csi/.decode で受信)
}
function ble-decode/detach {
  [[ $_ble_decode_bind_state != none ]] || return
  local current_editing_mode=
  ble/util/save-editing-mode current_editing_mode
  [[ $_ble_decode_bind_state == "$current_editing_mode" ]] || ble/util/restore-editing-mode _ble_decode_bind_state
  ble/term/finalize
  ble-decode/unbind
  if [[ -s "$_ble_base_run/$$.bind.save" ]]; then
    source "$_ble_base_run/$$.bind.save"
    : >| "$_ble_base_run/$$.bind.save"
  fi
  [[ $_ble_decode_bind_state == "$current_editing_mode" ]] || ble/util/restore-editing-mode current_editing_mode
  _ble_decode_bind_state=none
}
function ble/decode/read-inputrc/test {
  local text=$1
  if [[ ! $text ]]; then
    echo "ble.sh (bind):\$if: test condition is not supplied." >&2
    return 1
  elif local rex=$'[ \t]*([<>]=?|[=!]?=)[ \t]*(.*)$'; [[ $text =~ $rex ]]; then
    local op=${BASH_REMATCH[1]}
    local rhs=${BASH_REMATCH[2]}
    local lhs=${text::${#text}-${#BASH_REMATCH}}
  else
    local lhs=application
    local rhs=$text
  fi
  case $lhs in
  (application)
    local ret; ble/string#tolower "$rhs"
    [[ $ret == bash || $ret == blesh ]]
    return ;;
  (mode)
    if [[ -o emacs ]]; then
      test emacs "$op" "$rhs"
    elif [[ -o vi ]]; then
      test vi "$op" "$rhs"
    else
      false
    fi
    return ;;
  (term)
    if [[ $op == '!=' ]]; then
      test "$TERM" "$op" "$rhs" && test "${TERM%%-*}" "$op" "$rhs"
    else
      test "$TERM" "$op" "$rhs" || test "${TERM%%-*}" "$op" "$rhs"
    fi
    return ;;
  (version)
    local lhs_major lhs_minor
    if ((_ble_bash<40400)); then
      ((lhs_major=2+_ble_bash/10000,
        lhs_minor=_ble_bash/100%100))
    else
      ((lhs_major=3+_ble_bash/10000,
        lhs_minor=0))
    fi
    local rhs_major rhs_minor
    if [[ $rhs == *.* ]]; then
      local version
      ble/string#split version . "$rhs"
      rhs_major=${version[0]}
      rhs_minor=${version[1]}
    else
      ((rhs_major=rhs,rhs_minor=0))
    fi
    local lhs_ver=$((lhs_major*10000+lhs_minor))
    local rhs_ver=$((rhs_major*10000+rhs_minor))
    [[ $op == '=' ]] && op='=='
    let "$lhs_ver$op$rhs_ver"
    return ;;
  (*)
    if local ret; ble/util/read-rl-variable "$lhs"; then
      test "$ret" "$op" "$rhs"
      return
    else
      echo "ble.sh (bind):\$if: unknown readline variable '${lhs//$q/$Q}'." >&2
      return 1
    fi ;;
  esac
}
function ble/decode/read-inputrc {
  local file=$1 ref=$2 q=\' Q="''\'"
  if [[ -f $ref && $ref == */* && $file != /* ]]; then
    local relative_file=${ref%/*}/$file
    [[ -f $relative_file ]] && file=$relative_file
  fi
  if [[ ! -f $file ]]; then
    echo "ble.sh (bind):\$include: the file '${1//$q/$Q}' not found." >&2
    return 1
  fi
  local -a script=()
  local ret line= iline=0
  while builtin read -r line || [[ $line ]]; do
    ((++iline))
    ble/string#trim "$line"; line=$ret
    [[ ! $line || $line == '#'* ]] && continue
    if [[ $line == '$'* ]]; then
      local directive=${line%%[$IFS]*}
      case $directive in
      ('$if')
        local args=${line#'$if'}
        ble/string#trim "$args"; args=$ret
        ble/array#push script "if ble/decode/read-inputrc/test '${args//$q/$Q}'; then :" ;;
      ('$else')  ble/array#push script 'else :' ;;
      ('$endif') ble/array#push script 'fi' ;;
      ('$include')
        local args=${line#'$include'}
        ble/string#trim "$args"; args=$ret
        ble/array#push script "ble/decode/read-inputrc '${args//$q/$Q}' '${file//$q/$Q}'" ;;
      (*)
        echo "ble.sh (bind):$file:$iline: unrecognized directive '$directive'." >&2 ;;
      esac
    else
      ble/array#push script "ble/builtin/bind/.process '${line//$q/$Q}'"
    fi
  done < "$file"
  IFS=$'\n' eval 'script="${script[*]}"'
  builtin eval "$script"
}
function ble/builtin/bind/option:m {
  local name=$1
  local ret; ble/string#tolower "$name"; local keymap=$ret
  case $keymap in
  (emacs|emacs-standard|emacs-meta|emacs-ctlx) ;;
  (vi|vi-command|vi-move|vi-insert) ;;
  (*) keymap= ;;
  esac
  if [[ ! $keymap ]]; then
    echo "ble.sh (bind): unrecognized keymap name '$name'" >&2
    flags=e$flags
  else
    opt_keymap=$keymap
  fi
}
function ble/builtin/bind/.decompose-pair {
  local ret; ble/string#trim "$1"
  local spec=$ret ifs=$' \t\n' q=\' Q="'\''"
  keyseq= value=
  [[ ! $spec || $spec == 'set'["$ifs"]* ]] && return 3  # bind ''
  local rex='^(("([^\"]|\\.)*"|[^":'$ifs'])*("([^\"]|\\.)*)?)['$ifs']*(:['$ifs']*)?'
  [[ $spec =~ $rex ]]
  keyseq=${BASH_REMATCH[1]} value=${spec:${#BASH_REMATCH}}
  if [[ $keyseq == '$'* ]]; then
    return 3
  elif [[ ! $keyseq ]]; then
    echo "ble.sh (bind): empty keyseq in spec:'${spec//$q/$Q}'" >&2
    flags=e$flags
    return 1
  elif rex='^"([^\"]|\\.)*$'; [[ $keyseq =~ $rex ]]; then
    echo "ble.sh (bind): no closing '\"' in keyseq:'${keyseq//$q/$Q}'" >&2
    flags=e$flags
    return 1
  elif rex='^"([^\"]|\\.)*"'; [[ $keyseq =~ $rex ]]; then
    local rematch=${BASH_REMATCH[0]}
    if ((${#rematch}<${#keyseq})); then
      local fragment=${keyseq:${#rematch}}
      echo "ble.sh (bind): warning: unprocessed fragments in keyseq '${fragment//$q/$Q}'" >&2
    fi
    keyseq=$rematch
    return 0
  else
    return 0
  fi
}
function ble/builtin/bind/.parse-keyname {
  local value=$1
  local ret rex='^(control-|c-|ctrl-|meta|m-)-*' mflags=
  while ble/string#tolower "$value"; [[ $ret =~ $rex ]]; do
    value=${value:${#BASH_REMATCH}}
    mflags=${BASH_REMATCH::1}$mflags
  done
  local ch=
  case $ret in
  (rubout|del) ch=$'\177' ;;
  (escape|esc) ch=$'\033' ;;
  (newline|lfd) ch=$'\n' ;;
  (return|ret) ch=$'\r' ;;
  (space|spc) ch=' ' ;;
  (tab) ch=$'\t' ;;
  (*) LC_ALL=C eval 'local ch=${value::1}' ;;
  esac
  ble/util/s2c "$c"; local key=$ret
  [[ $mflags == *c* ]] && ((key&=0x1F))
  [[ $mflags == *m* ]] && ((key|=0x80))
  chars=("$key")
}
function ble/builtin/bind/.decode-chars.hook {
  ble/array#push ble_decode_bind_keys "$1"
  _ble_decode_key__hook=ble/builtin/bind/.decode-chars.hook
}
function ble/builtin/bind/.decode-chars {
  local _ble_decode_csi_mode=0
  local _ble_decode_csi_args=
  local _ble_decode_char2_seq=
  local _ble_decode_char2_reach=
  local _ble_decode_char2_modifier=
  local _ble_decode_char2_modkcode=
  local _ble_decode_char__hook=
  local _ble_keylogger_enabled=
  local _ble_decode_keylog_enabled=
  local -a ble_decode_bind_keys=()
  local _ble_decode_key__hook=ble/builtin/bind/.decode-chars.hook
  local ble_decode_char_sync=1 # ユーザ入力があっても中断しない
  ble-decode-char "$@"
  keys=("${ble_decode_bind_keys[@]}")
}
function ble/builtin/bind/.initialize-kmap {
  local keymap=$1
  kmap=
  case $keymap in
  (emacs|emacs-standard) kmap=emacs ;;
  (emacs-ctlx) kmap=emacs; keys=(24 "${keys[@]}") ;;
  (emacs-meta) kmap=emacs; keys=(27 "${keys[@]}") ;;
  (vi-insert) kmap=vi_imap ;;
  (vi|vi-command|vi-move) kmap=vi_nmap ;;
  (*) ble-decode/DEFAULT_KEYMAP -v kmap ;;
  esac
  ble-bind/load-keymap "$kmap" || return 1
  return 0
}
function ble/builtin/bind/.initialize-keys-and-value {
  local spec=$1 opts=$2
  keys= value=
  local keyseq
  ble/builtin/bind/.decompose-pair "$spec" || return
  local chars
  if [[ $keyseq == \"*\" ]]; then
    local ret; ble/util/keyseq2chars "${keyseq:1:${#keyseq}-2}"
    chars=("${ret[@]}")
    ((${#chars[@]})) || echo "ble.sh (bind): warning: empty keyseq" >&2
  else
    [[ :$opts: == *:nokeyname:* ]] &&
      echo "ble.sh (bind): warning: readline \"bind -x\" does not support \"keyname\" spec" >&2
    ble/builtin/bind/.parse-keyname "$keyseq"
  fi
  ble/builtin/bind/.decode-chars "${chars[@]}"
}
function ble/builtin/bind/option:x {
  local q=\' Q="''\'"
  local keys value kmap
  if ! ble/builtin/bind/.initialize-keys-and-value "$1" nokeyname; then
    echo "ble.sh (bind): unrecognized readline command '${1//$q/$Q}'." >&2
    flags=e$flags
    return 1
  elif ! ble/builtin/bind/.initialize-kmap "$opt_keymap"; then
    echo "ble.sh (bind): sorry, failed to initialize keymap:'$opt_keymap'." >&2
    flags=e$flags
    return 1
  fi
  if [[ $value == \"* ]]; then
    local ifs=$' \t\n'
    local rex='^"(([^\"]|\\.)*)"'
    if ! [[ $value =~ $rex ]]; then
      echo "ble.sh (bind): no closing '\"' in spec:'${1//$q/$Q}'" >&2
      flags=e$flags
      return 1
    fi
    if ((${#BASH_REMATCH}<${#value})); then
      local fragment=${value:${#BASH_REMATCH}}
      echo "ble.sh (bind): warning: unprocessed fragments:'${fragment//$q/$Q}' in spec:'${1//$q/$Q}'" >&2
    fi
    value=${BASH_REMATCH[1]}
  fi
  [[ $value == \"*\" ]] && value=${value:1:${#value}-2}
  local command="ble/widget/.EDIT_COMMAND '${value//$q/$Q}'"
  ble-decode-key/bind "${keys[*]}" "$command"
}
function ble/builtin/bind/option:r {
  local keyseq=$1
  local ret chars keys
  ble/util/keyseq2chars "$keyseq"; chars=("${ret[@]}")
  ble/builtin/bind/.decode-chars "${chars[@]}"
  local kmap
  ble/builtin/bind/.initialize-kmap "$opt_keymap" || return
  ble-decode-key/unbind "${keys[*]}"
}
function ble/builtin/bind/rlfunc2widget {
  local kmap=$1 rlfunc=$2
  local rlfunc_dict=
  case $kmap in
  (emacs)   rlfunc_dict=$_ble_base/keymap/emacs.rlfunc.txt ;;
  (vi_imap) rlfunc_dict=$_ble_base/keymap/vi_imap.rlfunc.txt ;;
  (vi_nmap) rlfunc_dict=$_ble_base/keymap/vi_nmap.rlfunc.txt ;;
  esac
  if [[ $rlfunc_dict && -s $rlfunc_dict ]]; then
    local awk_script='$1 == ENVIRON["RLFUNC"] { $1=""; print; exit; }'
    ble/util/assign ret 'RLFUNC=$rlfunc ble/bin/awk "$awk_script" "$rlfunc_dict"'
    ble/string#trim "$ret"
    ret=ble/widget/$ret
    return 0
  else
    return 1
  fi
}
function ble/builtin/bind/option:u {
  local rlfunc=$1
  local kmap
  if ! ble/builtin/bind/.initialize-kmap "$opt_keymap"; then
    echo "ble.sh (bind): sorry, failed to initialize keymap:'$opt_keymap'." >&2
    flags=e$flags
    return 1
  fi
  local ret
  ble/builtin/bind/rlfunc2widget "$kmap" "$rlfunc" || return 0
  local command=$ret
  local -a unbind_keys_list=()
  ble/builtin/bind/option:u/search-recursive "$kmap"
  local keys
  for keys in "${unbind_keys_list[@]}"; do
    ble-decode-key/unbind "$keys"
  done
}
function ble/builtin/bind/option:u/search-recursive {
  local kmap=$1 tseq=$2
  local dicthead=_ble_decode_${kmap}_kmap_
  local key keys
  builtin eval "keys=(\${!$dicthead$tseq[@]})"
  for key in "${keys[@]}"; do
    builtin eval "local ent=\${$dicthead$tseq[key]}"
    if [[ ${ent:2} == "$command" ]]; then
      ble/array#push unbind_keys_list "${tseq//_/ } $key"
    fi
    if [[ ${ent::1} == _ ]]; then
      ble/builtin/bind/option:u/search-recursive "$kmap" "${tseq}_$key"
    fi
  done
}
function ble/builtin/bind/option:- {
  local ret; ble/string#trim "$1"; local arg=$ret
  local ifs=$' \t\n'
  if [[ $arg == 'set'["$ifs"]* ]]; then
    [[ $_ble_decode_bind_state != none ]] && builtin bind "$arg"
    return
  fi
  local keys value kmap
  if ! ble/builtin/bind/.initialize-keys-and-value "$arg"; then
    local q=\' Q="''\'"
    echo "ble.sh (bind): unrecognized readline command '${arg//$q/$Q}'." >&2
    flags=e$flags
    return 1
  elif ! ble/builtin/bind/.initialize-kmap "$opt_keymap"; then
    echo "ble.sh (bind): sorry, failed to initialize keymap:'$opt_keymap'." >&2
    flags=e$flags
    return 1
  fi
  if [[ $value == \"* ]]; then
    value=${value#\"} value=${value%\"}
    local ret chars; ble/util/keyseq2chars "$value"; chars=("${ret[@]}")
    local command="ble/widget/.ble-decode-char ${chars[*]}"
    ble-decode-key/bind "${keys[*]}" "$command"
  elif [[ $value ]]; then
    if local ret; ble/builtin/bind/rlfunc2widget "$kmap" "$value"; then
      local command=$ret
      local arr; ble/string#split-words arr "$command"
      if ble/is-function "${arr[0]}"; then
        ble-decode-key/bind "${keys[*]}" "$command"
        return
      fi
    fi
    echo "ble.sh (bind): unsupported readline function '${value//$q/$Q}'." >&2
    flags=e$flags
    return 1
  else
    echo "ble.sh (bind): readline function name is not specified ($arg)." >&2
    return 1
  fi
}
function ble/builtin/bind/.process {
  flags=
  local opt_literal= opt_keymap= opt_print=
  local -a opt_queries=()
  while (($#)); do
    local arg=$1; shift
    if [[ ! $opt_literal ]]; then
      case $arg in
      (--) opt_literal=1
           continue ;;
      (--help)
        if ((_ble_bash<40400)); then
          echo "ble.sh (bind): unrecognized option $arg" >&2
          flags=e$flags
        else
          [[ $_ble_decode_bind_state != none ]] &&
            (builtin bind --help)
        fi
        continue ;;
      (--*)
        echo "ble.sh (bind): unrecognized option $arg" >&2
        flags=e$flags
        continue ;;
      (-*)
        local i n=${#arg} c
        for ((i=1;i<n;i++)); do
          c=${arg:i:1}
          case $c in
          ([lpPsSvVX])
            opt_print=$opt_print$c ;;
          ([mqurfx])
            if ((!$#)); then
              echo "ble.sh (bind): missing option argument for -$c" >&2
              flags=e$flags
            else
              local optarg=$1; shift
              case $c in
              (m) ble/builtin/bind/option:m "$optarg" ;;
              (x) ble/builtin/bind/option:x "$optarg" ;;
              (r) ble/builtin/bind/option:r "$optarg" ;;
              (u) ble/builtin/bind/option:u "$optarg" ;;
              (q) ble/array#push opt_queries "$optarg" ;;
              (f) ble/decode/read-inputrc "$optarg" ;;
              (*)
                echo "ble.sh (bind): unsupported option -$c $optarg" >&2
                flags=e$flags ;;
              esac
            fi ;;
          (*)
            echo "ble.sh (bind): unrecognized option -$c" >&2
            flags=e$flags ;;
          esac
        done
        continue ;;
      esac
    fi
    ble/builtin/bind/option:- "$arg"
    opt_literal=1
  done
  if [[ $_ble_decode_bind_state != none ]]; then
    if [[ $opt_print == *[pPsSX]* ]] || ((${#opt_queries[@]})); then
      ( ble-decode/unbind
        [[ -s "$_ble_base_run/$$.bind.save" ]] &&
          source "$_ble_base_run/$$.bind.save"
        [[ $opt_print ]] &&
          builtin bind ${opt_keymap:+-m $opt_keymap} -$opt_print
        declare rlfunc
        for rlfunc in "${opt_queries[@]}"; do
          builtin bind ${opt_keymap:+-m $opt_keymap} -q "$rlfunc"
        done )
    elif [[ $opt_print ]]; then
      builtin bind ${opt_keymap:+-m $opt_keymap} -$opt_print
    fi
  fi
  return 0
}
function ble/builtin/bind {
  local flags=
  ble/builtin/bind/.process "$@"
  if [[ $_ble_decode_bind_state == none ]]; then
    builtin bind "$@"
  else
    [[ $flags != *e* ]]
  fi
}
function bind { ble/builtin/bind "$@"; }
function ble/encoding:UTF-8/generate-binder { :; }
_ble_decode_byte__utf_8__mode=0
_ble_decode_byte__utf_8__code=0
function ble/encoding:UTF-8/clear {
  _ble_decode_byte__utf_8__mode=0
  _ble_decode_byte__utf_8__code=0
}
function ble/encoding:UTF-8/is-intermediate {
  ((_ble_decode_byte__utf_8__mode))
}
function ble/encoding:UTF-8/decode {
  local code=$_ble_decode_byte__utf_8__code
  local mode=$_ble_decode_byte__utf_8__mode
  local byte=$1
  local cha0= char=
  ((
    byte&=0xFF,
    (mode!=0&&(byte&0xC0)!=0x80)&&(
      cha0=_ble_decode_Erro|code,mode=0
    ),
    byte<0xF0?(
      byte<0xC0?(
        byte<0x80?(
          char=byte
        ):(
          mode==0?(
            char=_ble_decode_Erro|byte
          ):(
            code=code<<6|byte&0x3F,
            --mode==0&&(char=code)
          )
        )
      ):(
        byte<0xE0?(
          code=byte&0x1F,mode=1
        ):(
          code=byte&0x0F,mode=2
        )
      )
    ):(
      byte<0xFC?(
        byte<0xF8?(
          code=byte&0x07,mode=3
        ):(
          code=byte&0x03,mode=4
        )
      ):(
        byte<0xFE?(
          code=byte&0x01,mode=5
        ):(
          char=_ble_decode_Erro|byte
        )
      )
    )
  ))
  _ble_decode_byte__utf_8__code=$code
  _ble_decode_byte__utf_8__mode=$mode
  local -a CHARS=($cha0 $char)
  ((${#CHARS[*]})) && ble-decode-char "${CHARS[@]}"
}
function ble/encoding:UTF-8/c2bc {
  local code=$1
  ((ret=code<0x80?1:
    (code<0x800?2:
    (code<0x10000?3:
    (code<0x200000?4:5)))))
}
function ble/encoding:C/generate-binder {
  ble/init:bind/bind-s '"\C-@":"\x9B\x80"'
  ble/init:bind/bind-s '"\e":"\x9B\x8B"' # isolated ESC (U+07FF)
  local i ret
  for i in {0..255}; do
    ble-decode-bind/c2dqs "$i"
    ble/init:bind/bind-s "\"\e$ret\": \"\x9B\x9B$ret\""
  done
}
_ble_encoding_c_csi=
function ble/encoding:C/clear {
  _ble_encoding_c_csi=
}
function ble/encoding:C/is-intermediate {
  [[ $_ble_encoding_c_csi ]]
}
function ble/encoding:C/decode {
  if [[ $_ble_encoding_c_csi ]]; then
    _ble_encoding_c_csi=
    case $1 in
    (155) ble-decode-char 27 # ESC
          return ;;
    (139) ble-decode-char 2047 # isolated ESC
          return ;;
    (128) ble-decode-char 0 # C-@
          return ;;
    esac
    ble-decode-char 155
  fi
  if (($1==155)); then
    _ble_encoding_c_csi=1
  else
    ble-decode-char "$1"
  fi
}
function ble/encoding:C/c2bc {
  ret=1
}
_ble_color_gflags_Bold=0x01
_ble_color_gflags_Italic=0x02
_ble_color_gflags_Underline=0x04
_ble_color_gflags_Revert=0x08
_ble_color_gflags_Invisible=0x10
_ble_color_gflags_Strike=0x20
_ble_color_gflags_Blink=0x40
_ble_color_gflags_MaskFg=0x0000FF00
_ble_color_gflags_MaskBg=0x00FF0000
_ble_color_gflags_ShiftFg=8
_ble_color_gflags_ShiftBg=16
_ble_color_gflags_ForeColor=0x1000000
_ble_color_gflags_BackColor=0x2000000
if [[ ! ${bleopt_term_index_colors+set} ]]; then
  if [[ $TERM == xterm* || $TERM == *-256color || $TERM == kterm* ]]; then
    bleopt_term_index_colors=256
  elif [[ $TERM == *-88color ]]; then
    bleopt_term_index_colors=88
  else
    bleopt_term_index_colors=0
  fi
fi
function ble-color-show {
  if (($#)); then
    ble/base/print-usage-for-no-argument-command 'Update and reload ble.sh.' "$@"
    return
  fi
  local cols=16
  local bg bg0 bgN ret gflags=$((_ble_color_gflags_BackColor|_ble_color_gflags_ForeColor))
  for ((bg0=0;bg0<256;bg0+=cols)); do
    ((bgN=bg0+cols,bgN<256||(bgN=256)))
    for ((bg=bg0;bg<bgN;bg++)); do
      ble/color/g2sgr $((gflags|bg<<16))
      printf '%s%03d ' "$ret" "$bg"
    done
    printf '%s\n' "$_ble_term_sgr0"
    for ((bg=bg0;bg<bgN;bg++)); do
      ble/color/g2sgr $((gflags|bg<<16|15<<8))
      printf '%s%03d ' "$ret" "$bg"
    done
    printf '%s\n' "$_ble_term_sgr0"
  done
}
_ble_color_g2sgr=()
function ble/color/g2sgr/.impl {
  local -i g=$1
  local fg=$((g>> 8&0xFF))
  local bg=$((g>>16&0xFF))
  local sgr=0
  ((g&_ble_color_gflags_Bold))      && sgr="$sgr;${_ble_term_sgr_bold:-1}"
  ((g&_ble_color_gflags_Italic))    && sgr="$sgr;${_ble_term_sgr_sitm:-3}"
  ((g&_ble_color_gflags_Underline)) && sgr="$sgr;${_ble_term_sgr_smul:-4}"
  ((g&_ble_color_gflags_Blink))     && sgr="$sgr;${_ble_term_sgr_blink:-5}"
  ((g&_ble_color_gflags_Revert))    && sgr="$sgr;${_ble_term_sgr_rev:-7}"
  ((g&_ble_color_gflags_Invisible)) && sgr="$sgr;${_ble_term_sgr_invis:-8}"
  ((g&_ble_color_gflags_Strike))    && sgr="$sgr;${_ble_term_sgr_strike:-9}"
  if ((g&_ble_color_gflags_ForeColor)); then
    ble/color/.color2sgrfg "$fg"
    sgr="$sgr;$ret"
  fi
  if ((g&_ble_color_gflags_BackColor)); then
    ble/color/.color2sgrbg "$bg"
    sgr="$sgr;$ret"
  fi
  ret="[${sgr}m"
  _ble_color_g2sgr[$1]=$ret
}
function ble/color/g2sgr {
  ret=${_ble_color_g2sgr[$1]}
  [[ $ret ]] || ble/color/g2sgr/.impl "$1"
}
function ble/color/gspec2g {
  local g=0 entry
  for entry in ${1//,/ }; do
    case "$entry" in
    (bold)      ((g|=_ble_color_gflags_Bold)) ;;
    (underline) ((g|=_ble_color_gflags_Underline)) ;;
    (blink)     ((g|=_ble_color_gflags_Blink)) ;;
    (invis)     ((g|=_ble_color_gflags_Invisible)) ;;
    (reverse)   ((g|=_ble_color_gflags_Revert)) ;;
    (strike)    ((g|=_ble_color_gflags_Strike)) ;;
    (italic)    ((g|=_ble_color_gflags_Italic)) ;;
    (standout)  ((g|=_ble_color_gflags_Revert|_ble_color_gflags_Bold)) ;;
    (fg=*)
      ble/color/.name2color "${entry:3}"
      if ((ret<0)); then
        ((g&=~(_ble_color_gflags_ForeColor|_ble_color_gflags_MaskFg)))
      else
        ((g|=ret<<8|_ble_color_gflags_ForeColor))
      fi ;;
    (bg=*)
      ble/color/.name2color "${entry:3}"
      if ((ret<0)); then
        ((g&=~(_ble_color_gflags_BackColor|_ble_color_gflags_MaskBg)))
      else
        ((g|=ret<<16|_ble_color_gflags_BackColor))
      fi ;;
    (none)
      g=0 ;;
    esac
  done
  ret=$g
}
function ble/color/g2gspec {
  local g=$1 gspec=
  if ((g&_ble_color_gflags_ForeColor)); then
    local fg=$(((g&_ble_color_gflags_MaskFg)>>_ble_color_gflags_ShiftFg))
    ble/color/.color2name "$fg"
    gspec=$gspec,fg=$ret
  fi
  if ((g&_ble_color_gflags_BackColor)); then
    local bg=$(((g&_ble_color_gflags_MaskBg)>>_ble_color_gflags_ShiftBg))
    ble/color/.color2name "$bg"
    gspec=$gspec,bg=$ret
  fi
  ((g&_ble_color_gflags_Bold))      && gspec=$gspec,bold
  ((g&_ble_color_gflags_Underline)) && gspec=$gspec,underline
  ((g&_ble_color_gflags_Blink))     && gspec=$gspec,blink
  ((g&_ble_color_gflags_Invisible)) && gspec=$gspec,invis
  ((g&_ble_color_gflags_Revert))    && gspec=$gspec,reverse
  ((g&_ble_color_gflags_Strike))    && gspec=$gspec,strike
  ((g&_ble_color_gflags_Italic))    && gspec=$gspec,italic
  gspec=${gspec#,}
  ret=${gspec:-none}
}
function ble/color/gspec2sgr {
  local sgr=0 entry
  for entry in ${1//,/ }; do
    case "$entry" in
    (bold)      sgr="$sgr;${_ble_term_sgr_bold:-1}" ;;
    (underline) sgr="$sgr;${_ble_term_sgr_smul:-4}" ;;
    (blink)     sgr="$sgr;${_ble_term_sgr_blink:-5}" ;;
    (invis)     sgr="$sgr;${_ble_term_sgr_invis:-8}" ;;
    (reverse)   sgr="$sgr;${_ble_term_sgr_rev:-7}" ;;
    (strike)    sgr="$sgr;${_ble_term_sgr_strike:-9}" ;;
    (italic)    sgr="$sgr;${_ble_term_sgr_sitm:-3}" ;;
    (standout)  sgr="$sgr;${_ble_term_sgr_bold:-1};${_ble_term_sgr_rev:-7}" ;;
    (fg=*)
      ble/color/.name2color "${entry:3}"
      ble/color/.color2sgrfg "$ret"
      sgr="$sgr;$ret" ;;
    (bg=*)
      ble/color/.name2color "${entry:3}"
      ble/color/.color2sgrbg "$ret"
      sgr="$sgr;$ret" ;;
    (none)
      sgr=0 ;;
    esac
  done
  ret="[${sgr}m"
}
function ble/color/.name2color {
  local colorName=$1
  if [[ ! ${colorName//[0-9]} ]]; then
    ((ret=10#$colorName&255))
  else
    case "$colorName" in
    (black)   ret=0 ;;
    (brown)   ret=1 ;;
    (green)   ret=2 ;;
    (olive)   ret=3 ;;
    (navy)    ret=4 ;;
    (purple)  ret=5 ;;
    (teal)    ret=6 ;;
    (silver)  ret=7 ;;
    (gray)    ret=8 ;;
    (red)     ret=9 ;;
    (lime)    ret=10 ;;
    (yellow)  ret=11 ;;
    (blue)    ret=12 ;;
    (magenta) ret=13 ;;
    (cyan)    ret=14 ;;
    (white)   ret=15 ;;
    (orange)  ret=202 ;;
    (transparent) ret=-1 ;;
    (*)       ret=-1 ;;
    esac
  fi
}
function ble/color/.color2name {
  ((ret=(10#$1&255)))
  case $ret in
  (0)  ret=black   ;;
  (1)  ret=brown   ;;
  (2)  ret=green   ;;
  (3)  ret=olive   ;;
  (4)  ret=navy    ;;
  (5)  ret=purple  ;;
  (6)  ret=teal    ;;
  (7)  ret=silver  ;;
  (8)  ret=gray    ;;
  (9)  ret=red     ;;
  (10) ret=lime    ;;
  (11) ret=yellow  ;;
  (12) ret=blue    ;;
  (13) ret=magenta ;;
  (14) ret=cyan    ;;
  (15) ret=white   ;;
  (202) ret=orange ;;
  esac
}
function ble/color/convert-color88-to-color256 {
  local color=$1
  if ((color>=16)); then
    if ((color>=80)); then
      local L=$((((color-80+1)*25+4)/9))
      ((color=L==0?16:(L==25?231:232+(L-1))))
    else
      ((color-=16))
      local R=$((color/16)) G=$((color/4%4)) B=$((color%4))
      ((R=(R*5+1)/3,G=(G*5+1)/3,B=(B*5+1)/3,
        color=16+R*36+G*6+B))
    fi
  fi
  ret=$color
}
function ble/color/convert-color256-to-color88 {
  local color=$1
  if ((color>=16)); then
    if ((color>=232)); then
      local L=$((((color-232+1)*9+12)/25))
      ((color=L==0?16:(L==9?79:80+(L-1))))
    else
      ((color-=16))
      local R=$((color/36)) G=$((color/6%6)) B=$((color%6))
      ((R=(R*3+2)/5,G=(G*3+2)/5,B=(B*3+2)/5,
        color=16+R*16+G*4+B))
    fi
  fi
  ret=$color
}
function ble/color/.color2sgr-impl {
  local ccode=$1 prefix=$2 # 3 for fg, 4 for bg
  if ((ccode<0)); then
    ret=${prefix}9
  elif ((ccode<16&&ccode<_ble_term_colors)); then
    if ((prefix==4)); then
      ret=${_ble_term_sgr_ab[ccode]}
    else
      ret=${_ble_term_sgr_af[ccode]}
    fi
  elif ((ccode<256)); then
    if ((ccode<_ble_term_colors||bleopt_term_index_colors==256)); then
      ret="${prefix}8;5;$ccode"
    elif ((bleopt_term_index_colors==88)); then
      ble/color/convert-color256-to-color88 "$ccode"
      ret="${prefix}8;5;$ret"
    elif ((ccode<bleopt_term_index_colors)); then
      ret="${prefix}8;5;$ccode"
    elif ((_ble_term_colors>=16||_ble_term_colors==8)); then
      if ((ccode>=16)); then
        if ((ccode>=232)); then
          local L=$((((ccode-232+1)*3+12)/25))
          ((ccode=L==0?0:(L==1?8:(L==2?7:15))))
        else
          ((ccode-=16))
          local R=$((ccode/36)) G=$((ccode/6%6)) B=$((ccode%6))
          if ((R==G&&G==B)); then
            local L=$(((R*3+2)/5))
            ((ccode=L==0?0:(L==1?8:(L==2?7:15))))
          else
            local min max
            ((R<G?(min=R,max=G):(min=G,max=R),
              B<min?(min=B):(B>max&&(max=B))))
            local Range=$((max-min))
            ((R=(R-min+Range/2)/Range,
              G=(G-min+Range/2)/Range,
              B=(B-min+Range/2)/Range,
              ccode=R+G*2+B*4+(min+max>=5?8:0)))
          fi
        fi
      fi
      ((_ble_term_colors==8&&ccode>=8&&(ccode-=8)))
      if ((prefix==4)); then
        ret=${_ble_term_sgr_ab[ccode]}
      else
        ret=${_ble_term_sgr_af[ccode]}
      fi
    else
      ret=${prefix}9
    fi
  fi
}
function ble/color/.color2sgrfg {
  ble/color/.color2sgr-impl "$1" 3
}
function ble/color/.color2sgrbg {
  ble/color/.color2sgr-impl "$1" 4
}
function ble/color/read-sgrspec/.arg-next {
  local _var=arg _ret
  if [[ $1 == -v ]]; then
    _var=$2
    shift 2
  fi
  if ((j<${#fields[*]})); then
    ((_ret=10#${fields[j++]}))
  else
    ((i++))
    ((_ret=10#${specs[i]%%:*}))
  fi
  (($_var=_ret))
}
function ble/color/read-sgrspec {
  local specs i iN
  ble/string#split specs \; "$1"
  for ((i=0,iN=${#specs[@]};i<iN;i++)); do
    local spec=${specs[i]} fields
    ble/string#split fields : "$spec"
    local arg=$((10#${fields[0]}))
    if ((arg==0)); then
      g=0
      continue
    elif [[ :$opts: != *:ansi:* ]]; then
      [[ ${_ble_term_sgr_term2ansi[arg]} ]] &&
        arg=${_ble_term_sgr_term2ansi[arg]}
    fi
    if ((30<=arg&&arg<50)); then
      if ((30<=arg&&arg<38)); then
        local color=$((arg-30))
        ((g=g&~_ble_color_gflags_MaskFg|_ble_color_gflags_ForeColor|color<<8))
      elif ((40<=arg&&arg<48)); then
        local color=$((arg-40))
        ((g=g&~_ble_color_gflags_MaskBg|_ble_color_gflags_BackColor|color<<16))
      elif ((arg==38)); then
        local j=1 color cspace
        ble/color/read-sgrspec/.arg-next -v cspace
        if ((cspace==5)); then
          ble/color/read-sgrspec/.arg-next -v color
          if [[ :$opts: != *:ansi:* ]] && ((bleopt_term_index_colors==88)); then
            local ret; ble/color/convert-color88-to-color256 "$color"; color=$ret
          fi
          ((g=g&~_ble_color_gflags_MaskFg|_ble_color_gflags_ForeColor|color<<8))
        fi
      elif ((arg==48)); then
        local j=1 color cspace
        ble/color/read-sgrspec/.arg-next -v cspace
        if ((cspace==5)); then
          ble/color/read-sgrspec/.arg-next -v color
          if [[ :$opts: != *:ansi:* ]] && ((bleopt_term_index_colors==88)); then
            local ret; ble/color/convert-color88-to-color256 "$color"; color=$ret
          fi
          ((g=g&~_ble_color_gflags_MaskBg|_ble_color_gflags_BackColor|color<<16))
        fi
      elif ((arg==39)); then
        ((g&=~(_ble_color_gflags_MaskFg|_ble_color_gflags_ForeColor)))
      elif ((arg==49)); then
        ((g&=~(_ble_color_gflags_MaskBg|_ble_color_gflags_BackColor)))
      fi
    elif ((90<=arg&&arg<98)); then
      local color=$((arg-90+8))
      ((g=g&~_ble_color_gflags_MaskFg|_ble_color_gflags_ForeColor|color<<8))
    elif ((100<=arg&&arg<108)); then
      local color=$((arg-100+8))
      ((g=g&~_ble_color_gflags_MaskBg|_ble_color_gflags_BackColor|color<<16))
    elif ((arg==1)); then
      ((g|=_ble_color_gflags_Bold))
    elif ((arg==22)); then
      ((g&=~_ble_color_gflags_Bold))
    elif ((arg==4)); then
      ((g|=_ble_color_gflags_Underline))
    elif ((arg==24)); then
      ((g&=~_ble_color_gflags_Underline))
    elif ((arg==7)); then
      ((g|=_ble_color_gflags_Revert))
    elif ((arg==27)); then
      ((g&=~_ble_color_gflags_Revert))
    elif ((arg==3)); then
      ((g|=_ble_color_gflags_Italic))
    elif ((arg==23)); then
      ((g&=~_ble_color_gflags_Italic))
    elif ((arg==5)); then
      ((g|=_ble_color_gflags_Blink))
    elif ((arg==25)); then
      ((g&=~_ble_color_gflags_Blink))
    elif ((arg==8)); then
      ((g|=_ble_color_gflags_Invisible))
    elif ((arg==28)); then
      ((g&=~_ble_color_gflags_Invisible))
    elif ((arg==9)); then
      ((g|=_ble_color_gflags_Strike))
    elif ((arg==29)); then
      ((g&=~_ble_color_gflags_Strike))
    fi
  done
}
function ble/color/sgrspec2g {
  local g=0
  ble/color/read-sgrspec "$1"
  ret=$g
}
function ble/color/ansi2g {
  local x=0 y=0 g=0
  ble/function#try ble/canvas/trace "$1" # -> ret
  ret=$g
}
if [[ ! $_ble_faces_count ]]; then # reload #D0875
  _ble_faces_count=0
  _ble_faces=()
  _ble_faces_sgr=()
fi
function ble/color/setface/.check-argument {
  local rex='^[a-zA-Z0-9_]+$'
  [[ $# == 2 && $1 =~ $rex && $2 ]] && return 0
  local name=${FUNCNAME[1]}
  printf '%s\n' "usage: $name FACE_NAME [TYPE:]SPEC" '' \
         'TYPE' \
         '  Specifies the format of SPEC. The following values are available.' \
         '' \
         '  gspec   Comma separated graphic attribute list' \
         '  g       Integer value' \
         '  face    Face name' \
         '  iface   Face id' \
         '  sgrspec Parameters to the control function SGR' \
         '  ansi    ANSI Sequences'
  ext=2; [[ $# == 1 && $1 == --help ]] && ext=0
  return 1
} >&2
function ble-color-defface {
  local ext; ble/color/setface/.check-argument "$@" || return "$ext"
  ble/color/defface "$@"
}
function ble-color-setface {
  local ext; ble/color/setface/.check-argument "$@" || return "$ext"
  ble/color/setface "$@"
}
function ble/color/defface   { local q=\' Q="'\''"; ble/array#push _ble_color_faces_defface_hook "ble-color-defface '${1//$q/$Q}' '${2//$q/$Q}'"; }
function ble/color/setface   { local q=\' Q="'\''"; ble/array#push _ble_color_faces_setface_hook "ble-color-setface '${1//$q/$Q}' '${2//$q/$Q}'"; }
function ble/color/face2g    { ble/color/initialize-faces && ble/color/face2g    "$@"; }
function ble/color/face2sgr  { ble/color/initialize-faces && ble/color/face2sgr  "$@"; }
function ble/color/iface2g   { ble/color/initialize-faces && ble/color/iface2g   "$@"; }
function ble/color/iface2sgr { ble/color/initialize-faces && ble/color/iface2sgr "$@"; }
function ble/color/initialize-faces {
  local _ble_color_faces_initializing=1
  local -a _ble_color_faces_errors=()
  function ble/color/face2g {
    ((g=_ble_faces[_ble_faces__$1]))
  }
  function ble/color/face2sgr {
    builtin eval "sgr=\"\${_ble_faces_sgr[_ble_faces__$1]}\""
  }
  function ble/color/iface2g {
    ((g=_ble_faces[$1]))
  }
  function ble/color/iface2sgr {
    sgr=${_ble_faces_sgr[$1]}
  }
  function ble/color/setface/.spec2g {
    local spec=$1
    case $spec in
    (gspec:*)   ble/color/gspec2g "${spec#*:}" ;;
    (g:*)       ret=$((${spec#*:})) ;;
    (face:*)    local g; ble/color/face2g "${spec#*:}" ; ret=$g ;;
    (iface:*)   local g; ble/color/iface2g "${spec#*:}"; ret=$g ;;
    (sgrspec:*) ble/color/sgrspec2g "${spec#*:}" ;;
    (ansi:*)    ble/color/ansi2g "${spec#*:}" ;;
    (*)         ble/color/gspec2g "$spec" ;;
    esac
  }
  function ble/color/defface {
    local name=_ble_faces__$1 spec=$2 ret
    (($name)) && return
    (($name=++_ble_faces_count))
    ble/color/setface/.spec2g "$spec"; _ble_faces[$name]=$ret
    ble/color/g2sgr "$ret"; _ble_faces_sgr[$name]=$ret
  }
  function ble/color/setface {
    local name=_ble_faces__$1 spec=$2 ret
    if [[ ${!name} ]]; then
      ble/color/setface/.spec2g "$spec"; _ble_faces[$name]=$ret
      ble/color/g2sgr "$ret"; _ble_faces_sgr[$name]=$ret
    else
      local message="ble.sh: the specified face \`$1' is not defined."
      if [[ $_ble_color_faces_initializing ]]; then
        ble/array#push _ble_color_faces_errors "$message"
      else
        builtin echo "$message" >&2
      fi
      return 1
    fi
  }
  ble/util/invoke-hook _ble_color_faces_defface_hook
  ble/util/invoke-hook _ble_color_faces_setface_hook
  if ((${#_ble_color_faces_errors[@]})); then
    if ((_ble_edit_attached)) && [[ ! $_ble_textarea_invalidated && $_ble_term_state == internal ]]; then
      IFS=$'\n' eval 'local message="${_ble_color_faces_errors[@]}"'
      ble/widget/print "$message"
    else
      printf '%s\n' "${_ble_color_faces_errors[@]}" >&2
    fi
    return 1
  else
    return 0
  fi
}
function ble/color/list-faces {
  local key g ret sgr
  for key in "${!_ble_faces__@}"; do
    local name=${key#_ble_faces__}
    ble/color/iface2sgr $((key))
    ble/color/g2gspec $((_ble_faces[key]))
    ret=$sgr$ret$_ble_term_sgr0
    printf 'ble-color-setface %s %s\n' "$name" "$ret"
  done
}
_ble_highlight_layer__list=(plain)
function ble/highlight/layer/update {
  local text=$1
  local -i DMIN=$((BLELINE_RANGE_UPDATE[0]))
  local -i DMAX=$((BLELINE_RANGE_UPDATE[1]))
  local -i DMAX0=$((BLELINE_RANGE_UPDATE[2]))
  local PREV_BUFF=_ble_highlight_layer_plain_buff
  local PREV_UMIN=-1
  local PREV_UMAX=-1
  local layer player=plain LEVEL
  local nlevel=${#_ble_highlight_layer__list[@]}
  for ((LEVEL=0;LEVEL<nlevel;LEVEL++)); do
    layer=${_ble_highlight_layer__list[LEVEL]}
    "ble/highlight/layer:$layer/update" "$text" "$player"
    player=$layer
  done
  HIGHLIGHT_BUFF=$PREV_BUFF
  HIGHLIGHT_UMIN=$PREV_UMIN
  HIGHLIGHT_UMAX=$PREV_UMAX
}
function ble/highlight/layer/update/add-urange {
  local umin=$1 umax=$2
  (((PREV_UMIN<0||PREV_UMIN>umin)&&(PREV_UMIN=umin),
    (PREV_UMAX<0||PREV_UMAX<umax)&&(PREV_UMAX=umax)))
}
function ble/highlight/layer/update/shift {
  local __dstArray=$1
  local __srcArray=${2:-$__dstArray}
  if ((DMIN>=0)); then
    ble/array#reserve-prototype $((DMAX-DMIN))
    builtin eval "
    $__dstArray=(
      \"\${$__srcArray[@]::DMIN}\"
      \"\${_ble_array_prototype[@]::DMAX-DMIN}\"
      \"\${$__srcArray[@]:DMAX0}\")"
  else
    [[ $__dstArray != "$__srcArray" ]] && builtin eval "$__dstArray=(\"\${$__srcArray[@]}\")"
  fi
}
function ble/highlight/layer/update/getg {
  g=
  local LEVEL=$LEVEL
  while ((--LEVEL>=0)); do
    "ble/highlight/layer:${_ble_highlight_layer__list[LEVEL]}/getg" "$1"
    [[ $g ]] && return
  done
  g=0
}
function ble/highlight/layer/getg {
  LEVEL=${#_ble_highlight_layer__list[*]} ble/highlight/layer/update/getg "$1"
}
_ble_highlight_layer_plain_buff=()
function ble/highlight/layer:plain/update/.getch {
  [[ $ch == [' '-'~'] ]] && return
  if [[ $ch == [-] ]]; then
    if [[ $ch == $'\t' ]]; then
      ch=${_ble_string_prototype::it}
    elif [[ $ch == $'\n' ]]; then
      ch=$_ble_term_el$_ble_term_nl
    elif [[ $ch == '' ]]; then
      ch='^?'
    else
      local ret
      ble/util/s2c "$ch" 0
      ble/util/c2s $((ret+64))
      ch="^$ret"
    fi
  else
    local ret; ble/util/s2c "$ch"
    if ((0x80<=ret&&ret<=0x9F)); then
      ble/util/c2s $((ret-64))
      ch="M-^$ret"
    fi
  fi
}
function ble/highlight/layer:plain/update {
  if ((DMIN>=0)); then
    ble/highlight/layer/update/shift _ble_highlight_layer_plain_buff
    local i text=$1 ch
    local it=$_ble_term_it
    for ((i=DMIN;i<DMAX;i++)); do
      ch=${text:i:1}
      LC_COLLATE=C ble/highlight/layer:plain/update/.getch
      _ble_highlight_layer_plain_buff[i]=$ch
    done &>/dev/null # Note: suppress LC_COLLATE errors #D1205
  fi
  PREV_BUFF=_ble_highlight_layer_plain_buff
  ((PREV_UMIN=DMIN,PREV_UMAX=DMAX))
}
function ble/highlight/layer:plain/getg {
  g=0
}
function ble/color/faces-defface-hook {
  ble/color/defface region         bg=60,fg=white
  ble/color/defface region_target  bg=153,fg=black
  ble/color/defface region_match   bg=55,fg=white
  ble/color/defface disabled       fg=242
  ble/color/defface overwrite_mode fg=black,bg=51
}
ble/array#push _ble_color_faces_defface_hook ble/color/faces-defface-hook
_ble_highlight_layer_region_buff=()
_ble_highlight_layer_region_osel=()
_ble_highlight_layer_region_osgr=
function ble/highlight/layer:region/.update-dirty-range {
  local a=$1 b=$2 p q
  ((a==b)) && return
  (((a<b?(p=a,q=b):(p=b,q=a)),
    (umin<0||umin>p)&&(umin=p),
    (umax<0||umax<q)&&(umax=q)))
}
function ble/highlight/layer:region/update {
  local omin=-1 omax=-1 osgr= olen=${#_ble_highlight_layer_region_osel[@]}
  if ((olen)); then
    omin=${_ble_highlight_layer_region_osel[0]}
    omax=${_ble_highlight_layer_region_osel[olen-1]}
    osgr=$_ble_highlight_layer_region_osgr
  fi
  if ((DMIN>=0)); then
    ((DMAX0<=omin?(omin+=DMAX-DMAX0):(DMIN<omin&&(omin=DMIN)),
      DMAX0<=omax?(omax+=DMAX-DMAX0):(DMIN<omax&&(omax=DMIN))))
  fi
  local sgr=
  local -a selection=()
  if [[ $_ble_edit_mark_active ]]; then
    if ! ble/function#try ble/highlight/layer:region/mark:"$_ble_edit_mark_active"/get-selection; then
      if ((_ble_edit_mark>_ble_edit_ind)); then
        selection=("$_ble_edit_ind" "$_ble_edit_mark")
      elif ((_ble_edit_mark<_ble_edit_ind)); then
        selection=("$_ble_edit_mark" "$_ble_edit_ind")
      fi
    fi
    local face=region
    ble/function#try ble/highlight/layer:region/mark:"$_ble_edit_mark_active"/get-face
    ble/color/face2sgr "$face"
  fi
  local rlen=${#selection[@]}
  if ((DMIN<0)); then
    if [[ $sgr == "$osgr" && ${selection[*]} == "${_ble_highlight_layer_region_osel[*]}" ]]; then
      [[ ${selection[*]} ]] && PREV_BUFF=_ble_highlight_layer_region_buff
      return 0
    fi
  else
    [[ ! ${selection[*]} && ! ${_ble_highlight_layer_region_osel[*]} ]] && return 0
  fi
  local umin=-1 umax=-1
  if ((rlen)); then
    local rmin=${selection[0]}
    local rmax=${selection[rlen-1]}
    local -a buff=()
    local g ret
    local k=0 inext iprev=0
    for inext in "${selection[@]}"; do
      if ((k==0)); then
        ble/array#push buff "\"\${$PREV_BUFF[@]::$inext}\""
      elif ((k%2)); then
        ble/array#push buff "\"$sgr\${_ble_highlight_layer_plain_buff[@]:$iprev:$((inext-iprev))}\""
      else
        ble/highlight/layer/update/getg "$iprev"
        ble/color/g2sgr "$g"
        ble/array#push buff "\"$ret\${$PREV_BUFF[@]:$iprev:$((inext-iprev))}\""
      fi
      ((iprev=inext,k++))
    done
    ble/highlight/layer/update/getg "$iprev"
    ble/color/g2sgr "$g"
    ble/array#push buff "\"$ret\${$PREV_BUFF[@]:$iprev}\""
    builtin eval "_ble_highlight_layer_region_buff=(${buff[*]})"
    PREV_BUFF=_ble_highlight_layer_region_buff
    if ((DMIN>=0)); then
      ble/highlight/layer:region/.update-dirty-range "$DMIN" "$DMAX"
    fi
    if ((omin>=0)); then
      if [[ $osgr != "$sgr" ]]; then
        ble/highlight/layer:region/.update-dirty-range "$omin" "$omax"
        ble/highlight/layer:region/.update-dirty-range "$rmin" "$rmax"
      else
        ble/highlight/layer:region/.update-dirty-range "$omin" "$rmin"
        ble/highlight/layer:region/.update-dirty-range "$omax" "$rmax"
        if ((olen>1||rlen>1)); then
          ble/highlight/layer:region/.update-dirty-range "$rmin" "$rmax"
        fi
      fi
    else
      ble/highlight/layer:region/.update-dirty-range "$rmin" "$rmax"
    fi
    local pmin=$PREV_UMIN pmax=$PREV_UMAX
    if ((rlen==2)); then
      ((rmin<=pmin&&pmin<rmax&&(pmin=rmax),
        rmin<pmax&&pmax<=rmax&&(pmax=rmin)))
    fi
    ble/highlight/layer:region/.update-dirty-range "$pmin" "$pmax"
  else
    umin=$PREV_UMIN umax=$PREV_UMAX
    ble/highlight/layer:region/.update-dirty-range "$omin" "$omax"
  fi
  _ble_highlight_layer_region_osel=("${selection[@]}")
  _ble_highlight_layer_region_osgr=$sgr
  ((PREV_UMIN=umin,
    PREV_UMAX=umax))
}
function ble/highlight/layer:region/getg {
  if [[ $_ble_edit_mark_active ]]; then
    local index=$1 olen=${#_ble_highlight_layer_region_osel[@]}
    ((olen)) || return
    ((_ble_highlight_layer_region_osel[0]<=index&&index<_ble_highlight_layer_region_osel[olen-1])) || return
    local flag_region=
    if ((olen>=4)); then
      local l=0 u=$((olen-1)) m
      while ((l+1<u)); do
        ((_ble_highlight_layer_region_osel[m=(l+u)/2]<=index?(l=m):(u=m)))
      done
      ((l%2==0)) && flag_region=1
    else
      flag_region=1
    fi
    if [[ $flag_region ]]; then
      local face=region
      ble/function#try ble/highlight/layer:region/mark:"$_ble_edit_mark_active"/get-face
      ble/color/face2g "$face"
    fi
  fi
}
_ble_highlight_layer_disabled_prev=
_ble_highlight_layer_disabled_buff=()
function ble/highlight/layer:disabled/update {
  if [[ $_ble_edit_line_disabled ]]; then
    if ((DMIN>=0)) || [[ ! $_ble_highlight_layer_disabled_prev ]]; then
      local sgr
      ble/color/face2sgr disabled
      _ble_highlight_layer_disabled_buff=("$sgr""${_ble_highlight_layer_plain_buff[@]}")
    fi
    PREV_BUFF=_ble_highlight_layer_disabled_buff
    if [[ $_ble_highlight_layer_disabled_prev ]]; then
      PREV_UMIN=$DMIN PREV_UMAX=$DMAX
    else
      PREV_UMIN=0 PREV_UMAX=${#1}
    fi
  else
    if [[ $_ble_highlight_layer_disabled_prev ]]; then
      PREV_UMIN=0 PREV_UMAX=${#1}
    fi
  fi
  _ble_highlight_layer_disabled_prev=$_ble_edit_line_disabled
}
function ble/highlight/layer:disabled/getg {
  if [[ $_ble_highlight_layer_disabled_prev ]]; then
    ble/color/face2g disabled
  fi
}
_ble_highlight_layer_overwrite_mode_index=-1
_ble_highlight_layer_overwrite_mode_buff=()
function ble/highlight/layer:overwrite_mode/update {
  local oindex=$_ble_highlight_layer_overwrite_mode_index
  if ((DMIN>=0)); then
    if ((oindex>=DMAX0)); then
      ((oindex+=DMAX-DMAX0))
    elif ((oindex>=DMIN)); then
      oindex=-1
    fi
  fi
  local index=-1
  if [[ $_ble_edit_overwrite_mode && ! $_ble_edit_mark_active ]]; then
    local next=${_ble_edit_str:_ble_edit_ind:1}
    if [[ $next && $next != [$'\n\t'] ]]; then
      index=$_ble_edit_ind
      local g ret
      if ((PREV_UMIN<0&&oindex>=0)); then
        ble/highlight/layer/update/getg "$oindex"
        ble/color/g2sgr "$g"
        _ble_highlight_layer_overwrite_mode_buff[oindex]=$ret${_ble_highlight_layer_plain_buff[oindex]}
      else
        builtin eval "_ble_highlight_layer_overwrite_mode_buff=(\"\${$PREV_BUFF[@]}\")"
      fi
      PREV_BUFF=_ble_highlight_layer_overwrite_mode_buff
      ble/color/face2g overwrite_mode
      ble/color/g2sgr "$g"
      _ble_highlight_layer_overwrite_mode_buff[index]=$ret${_ble_highlight_layer_plain_buff[index]}
      if ((index+1<${#1})); then
        ble/highlight/layer/update/getg $((index+1))
        ble/color/g2sgr "$g"
        _ble_highlight_layer_overwrite_mode_buff[index+1]=$ret${_ble_highlight_layer_plain_buff[index+1]}
      fi
    fi
  fi
  if ((index>=0)); then
    ble/term/cursor-state/hide
  else
    ble/term/cursor-state/reveal
  fi
  if ((index!=oindex)); then
    ((oindex>=0)) && ble/highlight/layer/update/add-urange "$oindex" $((oindex+1))
    ((index>=0)) && ble/highlight/layer/update/add-urange "$index" $((index+1))
  fi
  _ble_highlight_layer_overwrite_mode_index=$index
}
function ble/highlight/layer:overwrite_mode/getg {
  local index=$_ble_highlight_layer_overwrite_mode_index
  if ((index>=0&&index==$1)); then
    ble/color/face2g overwrite_mode
  fi
}
_ble_highlight_layer_RandomColor_buff=()
function ble/highlight/layer:RandomColor/update {
  local text=$1 ret i
  _ble_highlight_layer_RandomColor_buff=()
  for ((i=0;i<${#text};i++)); do
    ble/color/gspec2sgr "fg=$((RANDOM%256))"
    _ble_highlight_layer_RandomColor_buff[i]=$ret${_ble_highlight_layer_plain_buff[i]}
  done
  PREV_BUFF=_ble_highlight_layer_RandomColor_buff
  ((PREV_UMIN=0,PREV_UMAX=${#text}))
}
function ble/highlight/layer:RandomColor/getg {
  local ret; ble/color/gspec2g "fg=$((RANDOM%256))"; g=$ret
}
_ble_highlight_layer_RandomColor2_buff=()
function ble/highlight/layer:RandomColor2/update {
  local text=$1 ret i x
  ble/highlight/layer/update/shift _ble_highlight_layer_RandomColor2_buff
  for ((i=DMIN;i<DMAX;i++)); do
    ble/color/gspec2sgr "fg=$((16+(x=RANDOM%27)*4-x%9*2-x%3))"
    _ble_highlight_layer_RandomColor2_buff[i]=$ret${_ble_highlight_layer_plain_buff[i]}
  done
  PREV_BUFF=_ble_highlight_layer_RandomColor2_buff
  ((PREV_UMIN=0,PREV_UMAX=${#text}))
}
function ble/highlight/layer:RandomColor2/getg {
  local x ret
  ble/color/gspec2g "fg=$((16+(x=RANDOM%27)*4-x%9*2-x%3))"; g=$ret
}
_ble_highlight_layer__list=(plain syntax region overwrite_mode disabled)
bleopt/declare -v tab_width ''
function bleopt/check:tab_width {
  if [[ $value ]] && (((value=value)<=0)); then
    echo "bleopt: an empty string or a positive value is required for tab_width." >&2
    return 1
  fi
}
function ble/arithmetic/sum {
  IFS=+ eval 'let "ret=$*+0"'
}
bleopt/declare -n char_width_mode auto
bleopt/declare -n emoji_width 2
function bleopt/check:char_width_mode {
  if ! ble/is-function "ble/util/c2w+$value"; then
    echo "bleopt: Invalid value char_width_mode='$value'. A function 'ble/util/c2w+$value' is not defined." >&2
    return 1
  fi
  if [[ $_ble_attached && $value == auto ]]; then
    ble/util/c2w+auto/update.buff first-line
    ble/util/buffer.flush >&2
  fi
}
_ble_util_c2w_table=()
function ble/util/c2w {
  "ble/util/c2w+$bleopt_char_width_mode" "$1"
}
function ble/util/c2w-edit {
  if (($1<32||127<=$1&&$1<160)); then
    ret=2
    ((128<=$1&&(ret=4)))
  else
    ble/util/c2w "$1"
  fi
}
_ble_util_c2w_non_zenkaku=(
  [0x303F]=1 # 半角スペース
  [0x3030]=-2 [0x303d]=-2 [0x3297]=-2 [0x3299]=-2 # 絵文字
)
function ble/util/c2w/.determine-unambiguous {
  local code=$1
  if ((code<0xA0)); then
    ret=1
    return
  fi
  ret=-1
  if ((code<0xFB00)); then
    ((0x2E80<=code&&code<0xA4D0&&!_ble_util_c2w_non_zenkaku[code]||
      0xAC00<=code&&code<0xD7A4||
      0xF900<=code||
      0x1100<=code&&code<0x1160||
      code==0x2329||code==0x232A)) && ret=2
  elif ((code<0x10000)); then
    ((0xFF00<=code&&code<0xFF61||
      0xFE30<=code&&code<0xFE70||
      0xFFE0<=code&&code<0xFFE7)) && ret=2
  else
    ((0x20000<=code&&code<0x2FFFE||
      0x30000<=code&&code<0x3FFFE)) && ret=2
  fi
}
_ble_util_c2w_emoji_wranges=(
  8252 8253 8265 8266 8482 8483 8505 8506 8596 8602 8617 8619 8986 8988
  9000 9001 9167 9168 9193 9204 9208 9211 9410 9411 9642 9644 9654 9655
  9664 9665 9723 9727 9728 9733 9742 9743 9745 9746 9748 9750 9752 9753
  9757 9758 9760 9761 9762 9764 9766 9767 9770 9771 9774 9776 9784 9787
  9792 9793 9794 9795 9800 9812 9824 9825 9827 9828 9829 9831 9832 9833
  9851 9852 9855 9856 9874 9880 9881 9882 9883 9885 9888 9890 9898 9900
  9904 9906 9917 9919 9924 9926 9928 9929 9934 9936 9937 9938 9939 9941
  9961 9963 9968 9974 9975 9979 9981 9982 9986 9987 9989 9990 9992 9998
  9999 10000 10002 10003 10004 10005 10006 10007 10013 10014 10017 10018
  10024 10025 10035 10037 10052 10053 10055 10056 10060 10061 10062 10063
  10067 10070 10071 10072 10083 10085 10133 10136 10145 10146 10160 10161
  10175 10176 10548 10550 11013 11016 11035 11037 11088 11089 11093 11094
  126980 126981
  127183 127184 127344 127346 127358 127360 127374 127375 127377 127387
  127462 127488 127489 127491 127514 127515 127535 127536 127538 127547
  127568 127570 127744 127778 127780 127892 127894 127896 127897 127900
  127902 127985 127987 127990 127991 128254 128255 128318 128329 128335
  128336 128360 128367 128369 128371 128379 128391 128392 128394 128398
  128400 128401 128405 128407 128420 128422 128424 128425 128433 128435
  128444 128445 128450 128453 128465 128468 128476 128479 128481 128482
  128483 128484 128488 128489 128495 128496 128499 128500 128506 128592
  128640 128710 128715 128723 128736 128742 128745 128746 128747 128749
  128752 128753 128755 128761 129296 129339 129340 129343 129344 129350
  129351 129357 129360 129388 129408 129432 129472 129473 129488 129511)
function ble/util/c2w/is-emoji {
  local code=$1
  ((8252<=code&&code<=0x2b55||0x1f004<code&&code<=0x1f9e6)) || return 1
  ((0x3030<=code&&code<=0x3299&&_ble_util_c2w_non_zenkaku[code]!=-2)) && return 1
  local l=0 u=${#_ble_util_c2w_emoji_wranges[@]} m
  while ((l+1<u)); do
    ((_ble_util_c2w_emoji_wranges[m=(l+u)/2]<=code?(l=m):(u=m)))
  done
  (((l&1)==0)); return
}
_ble_util_c2w_emacs_wranges=(
 162 164 167 169 172 173 176 178 180 181 182 183 215 216 247 248 272 273 276 279
 280 282 284 286 288 290 293 295 304 305 306 308 315 316 515 516 534 535 545 546
 555 556 608 618 656 660 722 723 724 725 768 769 770 772 775 777 779 780 785 787
 794 795 797 801 805 806 807 813 814 815 820 822 829 830 850 851 864 866 870 872
 874 876 898 900 902 904 933 934 959 960 1042 1043 1065 1067 1376 1396 1536 1540 1548 1549
 1551 1553 1555 1557 1559 1561 1563 1566 1568 1569 1571 1574 1576 1577 1579 1581 1583 1585 1587 1589
 1591 1593 1595 1597 1599 1600 1602 1603 1611 1612 1696 1698 1714 1716 1724 1726 1734 1736 1739 1740
 1742 1744 1775 1776 1797 1799 1856 1857 1858 1859 1898 1899 1901 1902 1903 1904)
function ble/util/c2w+emacs {
  local code=$1 al=0 ah=0 tIndex=
  ret=1
  ((code<0xA0)) && return
  if [[ $bleopt_emoji_width ]] && ble/util/c2w/is-emoji "$1"; then
    ((ret=bleopt_emoji_width))
    return
  fi
  ((
    0x3100<=code&&code<0xA4D0||0xAC00<=code&&code<0xD7A4?(
      ret=2
    ):(0x2000<=code&&code<0x2700?(
      tIndex=0x0100+code-0x2000
    ):(
      al=code&0xFF,
      ah=code/256,
      ah==0x00?(
        tIndex=al
      ):(ah==0x03?(
        ret=0xFF&((al-0x91)&~0x20),
        ret=ret<25&&ret!=17?2:1
      ):(ah==0x04?(
        ret=al==1||0x10<=al&&al<=0x50||al==0x51?2:1
      ):(ah==0x11?(
        ret=al<0x60?2:1
      ):(ah==0x2e?(
        ret=al>=0x80?2:1
      ):(ah==0x2f?(
        ret=2
      ):(ah==0x30?(
        ret=al!=0x3f?2:1
      ):(ah==0xf9||ah==0xfa?(
        ret=2
      ):(ah==0xfe?(
        ret=0x30<=al&&al<0x70?2:1
      ):(ah==0xff?(
        ret=0x01<=al&&al<0x61||0xE0<=al&&al<=0xE7?2:1
      ):(ret=1))))))))))
    ))
  ))
  [[ $tIndex ]] || return 0
  if ((tIndex<_ble_util_c2w_emacs_wranges[0])); then
    ret=1
    return
  fi
  local l=0 u=${#_ble_util_c2w_emacs_wranges[@]} m
  while ((l+1<u)); do
    ((_ble_util_c2w_emacs_wranges[m=(l+u)/2]<=tIndex?(l=m):(u=m)))
  done
  ((ret=((l&1)==0)?2:1))
  return 0
}
function ble/util/c2w+west {
  ble/util/c2w/.determine-unambiguous "$1"
  if ((ret<0)); then
    if [[ $bleopt_emoji_width ]] && ble/util/c2w/is-emoji "$1"; then
      ((ret=bleopt_emoji_width))
    else
      ((ret=1))
    fi
  fi
}
_ble_util_c2w_east_wranges=(
 161 162 164 165 167 169 170 171 174 175 176 181 182 187 188 192 198 199 208 209
 215 217 222 226 230 231 232 235 236 238 240 241 242 244 247 251 252 253 254 255
 257 258 273 274 275 276 283 284 294 296 299 300 305 308 312 313 319 323 324 325
 328 332 333 334 338 340 358 360 363 364 462 463 464 465 466 467 468 469 470 471
 472 473 474 475 476 477 593 594 609 610 708 709 711 712 713 716 717 718 720 721
 728 732 733 734 735 736 913 930 931 938 945 962 963 970 1025 1026 1040 1104 1105 1106
 8208 8209 8211 8215 8216 8218 8220 8222 8224 8227 8228 8232 8240 8241 8242 8244 8245 8246 8251 8252
 8254 8255 8308 8309 8319 8320 8321 8325 8364 8365 8451 8452 8453 8454 8457 8458 8467 8468 8470 8471
 8481 8483 8486 8487 8491 8492 8531 8533 8539 8543 8544 8556 8560 8570 8592 8602 8632 8634 8658 8659
 8660 8661 8679 8680 8704 8705 8706 8708 8711 8713 8715 8716 8719 8720 8721 8722 8725 8726 8730 8731
 8733 8737 8739 8740 8741 8742 8743 8749 8750 8751 8756 8760 8764 8766 8776 8777 8780 8781 8786 8787
 8800 8802 8804 8808 8810 8812 8814 8816 8834 8836 8838 8840 8853 8854 8857 8858 8869 8870 8895 8896
 8978 8979 9312 9450 9451 9548 9552 9588 9600 9616 9618 9622 9632 9634 9635 9642 9650 9652 9654 9656
 9660 9662 9664 9666 9670 9673 9675 9676 9678 9682 9698 9702 9711 9712 9733 9735 9737 9738 9742 9744
 9748 9750 9756 9757 9758 9759 9792 9793 9794 9795 9824 9826 9827 9830 9831 9835 9836 9838 9839 9840
 10045 10046 10102 10112 57344 63744 65533 65534 983040 1048574 1048576 1114110)
function ble/util/c2w+east {
  ble/util/c2w/.determine-unambiguous "$1"
  ((ret>=0)) && return
  if [[ $bleopt_emoji_width ]] && ble/util/c2w/is-emoji "$1"; then
    ((ret=bleopt_emoji_width))
    return
  fi
  local code=$1
  if ((code<_ble_util_c2w_east_wranges[0])); then
    ret=1
    return
  fi
  local l=0 u=${#_ble_util_c2w_east_wranges[@]} m
  while ((l+1<u)); do
    ((_ble_util_c2w_east_wranges[m=(l+u)/2]<=code?(l=m):(u=m)))
  done
  ((ret=((l&1)==0)?2:1))
}
_ble_util_c2w_auto_width=1
_ble_util_c2w_auto_update_x0=0
function ble/util/c2w+auto {
  ble/util/c2w/.determine-unambiguous "$1"
  ((ret>=0)) && return
  if ((_ble_util_c2w_auto_width==1)); then
    ble/util/c2w+west "$1"
  else
    ble/util/c2w+east "$1"
    ((ret==2&&(ret=_ble_util_c2w_auto_width)))
  fi
}
function ble/util/c2w+auto/update.buff {
  local opts=$1
  if ble/util/is-unicode-output; then
    local achar='▽'
    if [[ :$opts: == *:first-line:* ]]; then
      local cols=${COLUMNS:-80}
      local x0=$((cols-4)); ((x0<0)) && x0=0
      _ble_util_c2w_auto_update_x0=$x0
      local -a DRAW_BUFF=()
      ble/canvas/put.draw "$_ble_term_sc"
      ble/canvas/put-cup.draw 1 $((x0+1))
      ble/canvas/put.draw "$achar"
      ble/term/CPR/request.draw ble/util/c2w+auto/update.hook
      ble/canvas/put-cup.draw 1 $((x0+1))
      ble/canvas/put.draw "$_ble_term_el"
      ble/canvas/put.draw "$_ble_term_rc"
      ble/canvas/bflush.draw
    else
      _ble_util_c2w_auto_update_x0=0
      ble/util/buffer "$_ble_term_sc$_ble_term_cr$achar"
      ble/term/CPR/request.buff ble/util/c2w+auto/update.hook
      ble/util/buffer "$_ble_term_rc"
    fi
  fi
}
function ble/util/c2w+auto/update.hook {
  local l=$1 c=$2
  local w=$((c-1-_ble_util_c2w_auto_update_x0))
  ((_ble_util_c2w_auto_width=w==1?1:2))
}
function ble/canvas/attach {
  [[ $bleopt_char_width_mode == auto ]] &&
    ble/util/c2w+auto/update.buff
}
function ble/canvas/put.draw {
  DRAW_BUFF[${#DRAW_BUFF[*]}]="$*"
}
function ble/canvas/put-ind.draw {
  local count=${1-1}
  local ret; ble/string#repeat "${_ble_term_ind}" "$count"
  DRAW_BUFF[${#DRAW_BUFF[*]}]=$ret
}
function ble/canvas/put-il.draw {
  local value=${1-1}
  ((value>0)) || return 0
  DRAW_BUFF[${#DRAW_BUFF[*]}]=${_ble_term_il//'%d'/$value}
  DRAW_BUFF[${#DRAW_BUFF[*]}]=$_ble_term_el2 # Note #D1214: 最終行対策 cygwin, linux
}
function ble/canvas/put-dl.draw {
  local value=${1-1}
  ((value>0)) || return 0
  DRAW_BUFF[${#DRAW_BUFF[*]}]=$_ble_term_el2 # Note #D1214: 最終行対策 cygwin, linux
  DRAW_BUFF[${#DRAW_BUFF[*]}]=${_ble_term_dl//'%d'/$value}
}
function ble/canvas/put-cuu.draw {
  local value=${1-1}
  DRAW_BUFF[${#DRAW_BUFF[*]}]=${_ble_term_cuu//'%d'/$value}
}
function ble/canvas/put-cud.draw {
  local value=${1-1}
  DRAW_BUFF[${#DRAW_BUFF[*]}]=${_ble_term_cud//'%d'/$value}
}
function ble/canvas/put-cuf.draw {
  local value=${1-1}
  DRAW_BUFF[${#DRAW_BUFF[*]}]=${_ble_term_cuf//'%d'/$value}
}
function ble/canvas/put-cub.draw {
  local value=${1-1}
  DRAW_BUFF[${#DRAW_BUFF[*]}]=${_ble_term_cub//'%d'/$value}
}
function ble/canvas/put-cup.draw {
  local l=${1-1} c=${2-1}
  local out=$_ble_term_cup
  out=${out//'%l'/$l}
  out=${out//'%c'/$c}
  out=${out//'%y'/$((l-1))}
  out=${out//'%x'/$((c-1))}
  DRAW_BUFF[${#DRAW_BUFF[*]}]=$out
}
function ble/canvas/put-hpa.draw {
  local c=${1-1}
  local out=$_ble_term_hpa
  out=${out//'%c'/$c}
  out=${out//'%x'/$((c-1))}
  DRAW_BUFF[${#DRAW_BUFF[*]}]=$out
}
function ble/canvas/put-vpa.draw {
  local l=${1-1}
  local out=$_ble_term_vpa
  out=${out//'%l'/$l}
  out=${out//'%y'/$((l-1))}
  DRAW_BUFF[${#DRAW_BUFF[*]}]=$out
}
function ble/canvas/put-ech.draw {
  local value=${1:-1} esc
  if [[ $_ble_term_ech ]]; then
    esc=${_ble_term_ech/'%d'/$value}
  else
    ble/string#reserve-prototype "$value"
    esc=${_ble_string_prototype::value}${_ble_term_cub/'%d'/$value}
  fi
  DRAW_BUFF[${#DRAW_BUFF[*]}]=$esc
}
function ble/canvas/put-spaces.draw {
  local value=${1:-1}
  ble/string#reserve-prototype "$value"
  DRAW_BUFF[${#DRAW_BUFF[*]}]=${_ble_string_prototype::value}
}
function ble/canvas/put-move-x.draw {
  local dx=$1
  ((dx)) || return 1
  if ((dx>0)); then
    ble/canvas/put-cuf.draw "$dx"
  else
    ble/canvas/put-cub.draw $((-dx))
  fi
}
function ble/canvas/put-move-y.draw {
  local dy=$1
  ((dy)) || return 1
  if ((dy>0)); then
    ble/canvas/put-cud.draw "$dy"
  else
    ble/canvas/put-cuu.draw $((-dy))
  fi
}
function ble/canvas/put-move.draw {
  ble/canvas/put-move-x.draw "$1"
  ble/canvas/put-move-y.draw "$2"
}
function ble/canvas/flush.draw {
  IFS= builtin eval 'builtin echo -n "${DRAW_BUFF[*]}"'
  DRAW_BUFF=()
}
function ble/canvas/sflush.draw {
  local _var=ret
  [[ $1 == -v ]] && _var=$2
  IFS= builtin eval "$_var=\"\${DRAW_BUFF[*]}\""
  DRAW_BUFF=()
}
function ble/canvas/bflush.draw {
  IFS= builtin eval 'ble/util/buffer "${DRAW_BUFF[*]}"'
  DRAW_BUFF=()
}
function ble/canvas/trace/.goto {
  local x1=$1 y1=$2
  if [[ $opt_relative ]]; then
    ble/canvas/put-move.draw $((x1-x)) $((y1-y))
  else
    ble/canvas/put-cup.draw $((y1+1)) $((x1+1))
  fi
  ((x=x1,y=y1))
}
function ble/canvas/trace/.process-overflow {
  [[ :$opts: == *:truncate:* ]] && i=$iN # stop
  if [[ :$opts: == *:ellipsis:* ]]; then
    if ble/util/is-unicode-output; then
      local ellipsis='…' ret
      ble/util/s2c "$ellipsis"; ble/util/c2w "$ret"; local w=$ret
    else
      local ellipsis=... w=3
    fi
    local x0=$x y0=$y
    ble/canvas/trace/.goto $((cols-w)) $((lines-1))
    ble/canvas/put.draw "$ellipsis"
    ((x+=w,x>=cols&&!opt_relative&&!xenl)) && ((x=0,y++))
    ble/canvas/trace/.goto "$x0" "$y0"
    if [[ $opt_measure ]]; then
      ((x2<cols&&(x2=cols)))
      ((y2<lines-1&&(y2=lines-1)))
    fi
  fi
}
function ble/canvas/trace/.SC {
  trace_scosc=("$x" "$y" "$g" "$lc" "$lg")
  ble/canvas/put.draw "$_ble_term_sc"
}
function ble/canvas/trace/.RC {
  x=${trace_scosc[0]}
  y=${trace_scosc[1]}
  g=${trace_scosc[2]}
  lc=${trace_scosc[3]}
  lg=${trace_scosc[4]}
  ble/canvas/put.draw "$_ble_term_rc"
}
function ble/canvas/trace/.NEL {
  if [[ $opt_nooverflow ]] && ((y+1>=lines)); then
    ble/canvas/trace/.process-overflow
    return 1
  fi
  if [[ $opt_relative ]]; then
    ((x)) && ble/canvas/put-cub.draw "$x"
    ble/canvas/put-cud.draw 1
  else
    ble/canvas/put.draw "$_ble_term_cr"
    ble/canvas/put.draw "$_ble_term_nl"
  fi
  ((y++,x=0,lc=32,lg=0))
  return 0
}
function ble/canvas/trace/.SGR/arg_next {
  local _var=arg _ret
  if [[ $1 == -v ]]; then
    _var=$2
    shift 2
  fi
  if ((j<${#f[*]})); then
    _ret=${f[j++]}
  else
    ((i++))
    _ret=${specs[i]%%:*}
  fi
  (($_var=_ret))
}
function ble/canvas/trace/.SGR {
  local param=$1 seq=$2 specs i iN
  if [[ ! $param ]]; then
    g=0
    ble/canvas/put.draw "$_ble_term_sgr0"
    return
  fi
  if [[ $opt_terminfo ]]; then
    ble/color/read-sgrspec "$param"
  else
    ble/color/read-sgrspec "$param" ansi
  fi
  local ret
  ble/color/g2sgr "$g"
  ble/canvas/put.draw "$ret"
}
function ble/canvas/trace/.process-csi-sequence {
  local seq=$1 seq1=${1:2} rex
  local char=${seq1:${#seq1}-1:1} param=${seq1::${#seq1}-1}
  if [[ ! ${param//[0-9:;]} ]]; then
    case "$char" in
    (m) # SGR
      ble/canvas/trace/.SGR "$param" "$seq"
      return ;;
    ([ABCDEFGIZ\`ade])
      local arg=0
      [[ $param =~ ^[0-9]+$ ]] && arg=$param
      ((arg==0&&(arg=1)))
      local x0=$x y0=$y
      if [[ $char == A ]]; then
        ((y-=arg,y<0&&(y=0)))
        ((y<y0)) && ble/canvas/put-cuu.draw $((y0-y))
      elif [[ $char == [Be] ]]; then
        ((y+=arg,y>=lines&&(y=lines-1)))
        ((y>y0)) && ble/canvas/put-cud.draw $((y-y0))
      elif [[ $char == [Ca] ]]; then
        ((x+=arg,x>=cols&&(x=cols-1)))
        ((x>x0)) && ble/canvas/put-cuf.draw $((x-x0))
      elif [[ $char == D ]]; then
        ((x-=arg,x<0&&(x=0)))
        ((x<x0)) && ble/canvas/put-cub.draw $((x0-x))
      elif [[ $char == E ]]; then
        ((y+=arg,y>=lines&&(y=lines-1),x=0))
        ((y>y0)) && ble/canvas/put-cud.draw $((y-y0))
        ble/canvas/put.draw "$_ble_term_cr"
      elif [[ $char == F ]]; then
        ((y-=arg,y<0&&(y=0),x=0))
        ((y<y0)) && ble/canvas/put-cuu.draw $((y0-y))
        ble/canvas/put.draw "$_ble_term_cr"
      elif [[ $char == [G\`] ]]; then
        ((x=arg-1,x<0&&(x=0),x>=cols&&(x=cols-1)))
        if [[ $opt_relative ]]; then
          ble/canvas/put-move-x.draw $((x-x0))
        else
          ble/canvas/put-hpa.draw $((x+1))
        fi
      elif [[ $char == d ]]; then
        ((y=arg-1,y<0&&(y=0),y>=lines&&(y=lines-1)))
        if [[ $opt_relative ]]; then
          ble/canvas/put-move-y.draw $((y-y0))
        else
          ble/canvas/put-vpa.draw $((y+1))
        fi
      elif [[ $char == I ]]; then
        local _x
        ((_x=(x/it+arg)*it,
          _x>=cols&&(_x=cols-1)))
        if ((_x>x)); then
          ble/canvas/put-cuf.draw $((_x-x))
          ((x=_x))
        fi
      elif [[ $char == Z ]]; then
        local _x
        ((_x=((x+it-1)/it-arg)*it,
          _x<0&&(_x=0)))
        if ((_x<x)); then
          ble/canvas/put-cub.draw $((x-_x))
          ((x=_x))
        fi
      fi
      lc=-1 lg=0
      return ;;
    ([Hf])
      local -a params
      params=(${param//[^0-9]/ })
      local x1 y1
      ((x1=params[1]-1))
      ((y1=params[0]-1))
      ((x1<0&&(x1=0),x1>=cols&&(x1=cols-1),
        y1<0&&(y1=0),y1>=lines&&(y1=lines-1)))
      ble/canvas/trace/.goto "$x1" "$y1"
      lc=-1 lg=0
      return ;;
    ([su]) # SCOSC SCORC
      if [[ $param == 99 ]]; then
        if [[ $char == s ]]; then
          trace_brack[${#trace_brack[*]}]="$x $y"
        else
          local lastIndex=$((${#trace_brack[*]}-1))
          if ((lastIndex>=0)); then
            local -a scosc
            scosc=(${trace_brack[lastIndex]})
            ((x=scosc[0]))
            ((y=scosc[1]))
            unset -v "trace_brack[$lastIndex]"
          fi
        fi
        return
      else
        if [[ $char == s ]]; then
          ble/canvas/trace/.SC
        else
          ble/canvas/trace/.RC
        fi
        return
      fi ;;
    esac
  fi
  ble/canvas/put.draw "$seq"
}
function ble/canvas/trace/.process-esc-sequence {
  local seq=$1 char=${1:1}
  case "$char" in
  (7) # DECSC
    ble/canvas/trace/.SC
    return ;;
  (8) # DECRC
    ble/canvas/trace/.RC
    return ;;
  (D) # IND
    [[ $opt_nooverflow ]] && ((y+1>=lines)) && return
    if [[ $opt_relative ]]; then
      ((y+1>=lines)) && return
      ((y++))
      ble/canvas/put-cud.draw 1
    else
      ((y++))
      ble/canvas/put.draw "$_ble_term_ind"
      [[ $_ble_term_ind != $'\eD' ]] &&
        ble/canvas/put-hpa.draw $((x+1)) # tput ind が唯の改行の時がある
    fi
    lc=-1 lg=0
    return ;;
  (M) # RI
    [[ $opt_nooverflow ]] && ((y==0)) && return
    if [[ $opt_relative ]]; then
      ((y==0)) && return
      ((y--))
      ble/canvas/put-cuu.draw 1
    else
      ((y--,y<0&&(y=0)))
      ble/canvas/put.draw "$_ble_term_ri"
    fi
    lc=-1 lg=0
    return ;;
  (E) # NEL
    ble/canvas/trace/.NEL
    return ;;
  esac
  ble/canvas/put.draw "$seq"
}
function ble/canvas/trace/.impl {
  local text=$1 opts=$2
  local ret
  ble/util/c2s 156; local st=$ret #  (ST)
  ((${#st}>=2)) && st=
  local opt_nooverflow=; [[ :$opts: == *:truncate:* || :$opts: == *:confine:* ]] && opt_nooverflow=1
  local opt_relative=; [[ :$opts: == *:relative:* ]] && opt_relative=1
  local opt_measure=; [[ :$opts: == *:measure-bbox:* ]] && opt_measure=1
  [[ :$opts: != *:left-char:* ]] && local lc=32 lg=0
  local opt_terminfo=; [[ :$opts: == *:terminfo:* ]] && opt_terminfo=1
  local cols=${COLUMNS:-80} lines=${LINES:-25}
  local it=${bleopt_tab_width:-$_ble_term_it} xenl=$_ble_term_xenl
  ble/string#reserve-prototype "$it"
  local rex_csi='^\[[ -?]*[@-~]'
  local rex_osc='^([]PX^_k])([^'$st']|+[^\'$st'])*(\\|'${st:+'|'}$st'|$)'
  local rex_2022='^[ -/]+[@-~]'
  local rex_esc='^[ -~]'
  local -a trace_brack=()
  local -a trace_scosc=()
  [[ $opt_measure ]] && ((x1=x2=x,y1=y2=y))
  local i=0 iN=${#text}
  while ((i<iN)); do
    local tail=${text:i}
    local w=0 is_overflow=
    if [[ $tail == [-]* ]]; then
      local s=${tail::1}
      ((i++))
      case "$s" in
      ('')
        if [[ $tail =~ $rex_osc ]]; then
          s=$BASH_REMATCH
          [[ ${BASH_REMATCH[3]} ]] || s="$s\\" # 終端の追加
          ((i+=${#BASH_REMATCH}-1))
        elif [[ $tail =~ $rex_csi ]]; then
          s=
          ((i+=${#BASH_REMATCH}-1))
          ble/canvas/trace/.process-csi-sequence "$BASH_REMATCH"
        elif [[ $tail =~ $rex_2022 ]]; then
          s=$BASH_REMATCH
          ((i+=${#BASH_REMATCH}-1))
        elif [[ $tail =~ $rex_esc ]]; then
          s=
          ((i+=${#BASH_REMATCH}-1))
          ble/canvas/trace/.process-esc-sequence "$BASH_REMATCH"
        fi ;;
      ('') # BS
        if ((x>0)); then
          ((x--,lc=32,lg=g))
        else
          s=
        fi ;;
      ($'\t') # HT
        local _x
        ((_x=(x+it)/it*it,
          _x>=cols&&(_x=cols-1)))
        if ((x<_x)); then
          s=${_ble_string_prototype::_x-x}
          ((x=_x,lc=32,lg=g))
        else
          s=
        fi ;;
      ($'\n') # LF = CR+LF
        s=
        ble/canvas/trace/.NEL ;;
      ('') # VT
        s=
        if ((y+1<lines||!opt_nooverflow)); then
          if [[ $opt_relative ]]; then
            if ((y+1<lines)); then
              ble/canvas/put-cud.draw 1
              ((y++,lc=32,lg=0))
            fi
          else
            ble/canvas/put.draw "$_ble_term_cr"
            ble/canvas/put.draw "$_ble_term_nl"
            ((x)) && ble/canvas/put-cuf.draw "$x"
            ((y++,lc=32,lg=0))
          fi
        fi ;;
      ($'\r') # CR ^M
        if [[ $opt_relative ]]; then
          s=
          ble/canvas/put-cub.draw "$x"
        else
          s=$_ble_term_cr
        fi
        ((x=0,lc=-1,lg=0)) ;;
      esac
      [[ $s ]] && ble/canvas/put.draw "$s"
    elif ble/util/isprint+ "$tail"; then
      local s=$BASH_REMATCH
      w=${#s}
      if [[ $opt_nooverflow ]]; then
        local wmax=$((lines*cols-(y*cols+x)))
        ((w>wmax)) && w=$wmax is_overflow=1
      fi
      if [[ $opt_relative ]]; then
        local t=${s::w} tlen=$w len=$((cols-x))
        if [[ $opt_measure ]]; then
          if ((tlen>len)); then
            ((x1>0&&(x1=0)))
            ((x2<cols&&(x2=cols)))
          fi
        fi
        while ((tlen>len)); do
          ble/canvas/put.draw "${t::len}"
          t=${t:len}
          ((x=cols,tlen-=len,len=cols))
          ble/canvas/trace/.NEL
        done
        w=${#t}
        ble/canvas/put.draw "$t"
      else
        ble/canvas/put.draw "${tail::w}"
      fi
      ((i+=${#s}))
      if [[ ! $bleopt_internal_suppress_bash_output ]]; then
        local ret
        ble/util/s2c "$s" $((w-1))
        lc=$ret lg=$g
      fi
    else
      local ret
      ble/util/s2c "$tail" 0; local c=$ret
      ble/util/c2w "$c"; local w=$ret
      if [[ $opt_nooverflow ]] && ! ((x+w<=cols||y+1<lines&&w<=cols)); then
        w=0 is_overflow=1
      else
        lc=$c lg=$g
        if ((x+w>cols)); then
          if [[ $opt_relative ]]; then
            ble/canvas/trace/.NEL
          else
            ble/canvas/put.draw "${_ble_string_prototype::x+w-cols}"
            ((x=cols))
          fi
          if [[ $opt_measure ]]; then
            ((x1>0&&(x1=0)))
            [[ $opt_relative ]] ||
              ((x2<cols&&(x2=cols)))
          fi
        fi
        ble/canvas/put.draw "${tail::1}"
      fi
      ((i++))
    fi
    if ((w>0)); then
      if [[ $opt_measure ]]; then
        if ((x+w>cols)); then
          ((x1>0&&(x1=0)))
          ((x2<cols&&(x2=cols)))
        fi
      fi
      ((x+=w,y+=x/cols,x%=cols,
        (opt_relative||xenl)&&x==0&&(y--,x=cols)))
      ((x==0&&(lc=32,lg=0)))
    fi
    if [[ $opt_measure ]]; then
      ((x<x1?(x1=x):(x>x2?(x2=x):1)))
      ((y<y1?(y1=y):(y>y2?(y2=y):1)))
    fi
    [[ $is_overflow ]] && ble/canvas/trace/.process-overflow
  done
  [[ $opt_measure ]] && ((y2++))
}
function ble/canvas/trace.draw {
  LC_COLLATE=C ble/canvas/trace/.impl "$@"
} &>/dev/null # Note: suppress LC_COLLATE errors #D1205
function ble/canvas/trace {
  local -a DRAW_BUFF=()
  LC_COLLATE=C ble/canvas/trace/.impl "$@"
  ble/canvas/sflush.draw # -> ret
} &>/dev/null # Note: suppress LC_COLLATE errors #D1205
function ble/canvas/trace-text/.put-simple {
  local nchar=$1
  if ((y+(x+nchar)/cols<lines)); then
    out=$out$2
    ((x+=nchar%cols,
      y+=nchar/cols,
      (_ble_term_xenl?x>cols:x>=cols)&&(y++,x-=cols)))
  else
    flag_overflow=1
    out=$out${2::lines*cols-(y*cols+x)}
    ((x=cols,y=lines-1))
    ble/canvas/trace-text/.put-nl-if-eol
  fi
}
function ble/canvas/trace-text/.put-atomic {
  local w=$1 c=$2
  if ((x<cols&&cols<x+w)); then
    if ((y+1>=lines)); then
      flag_overflow=1
      if [[ :$opts: == *:nonewline:* ]]; then
        ble/string#reserve-prototype $((cols-x))
        out=$out${_ble_string_prototype::cols-x}
        ((x=cols))
      else
        out=$out$'\n'
        ((y++,x=0))
      fi
      return
    fi
    ble/string#reserve-prototype $((cols-x))
    out=$out${_ble_string_prototype::cols-x}
    ((x=cols))
  fi
  out=$out$c
  if ((w>0)); then
    ((x+=w))
    while ((_ble_term_xenl?x>cols:x>=cols)); do
      ((y++,x-=cols))
    done
  fi
}
function ble/canvas/trace-text/.put-nl-if-eol {
  if ((x==cols)); then
    [[ :$opts: == *:nonewline:* ]] && return
    ((_ble_term_xenl)) && out=$out$'\n'
    ((y++,x=0))
  fi
}
function ble/canvas/trace-text {
  local out= LC_ALL= LC_COLLATE=C glob='*[! -~]*'
  local opts=$2 flag_overflow=
  [[ :$opts: == *:external-sgr:* ]] ||
    local sgr0=$_ble_term_sgr0 sgr1=$_ble_term_rev
  if [[ $1 != $glob ]]; then
    ble/canvas/trace-text/.put-simple "${#1}" "$1"
  else
    local glob='[ -~]*' globx='[! -~]*'
    local i iN=${#1} text=$1
    for ((i=0;i<iN;)); do
      local tail=${text:i}
      if [[ $tail == $glob ]]; then
        local span=${tail%%$globx}
        ble/canvas/trace-text/.put-simple "${#span}" "$span"
        ((i+=${#span}))
      else
        ble/util/s2c "$text" "$i"
        local code=$ret w=0
        if ((code<32)); then
          ble/util/c2s $((code+64))
          ble/canvas/trace-text/.put-atomic 2 "$sgr1^$ret$sgr0"
        elif ((code==127)); then
          ble/canvas/trace-text/.put-atomic 2 '$sgr1^?$sgr0'
        elif ((128<=code&&code<160)); then
          ble/util/c2s $((code-64))
          ble/canvas/trace-text/.put-atomic 4 "${sgr1}M-^$ret$sgr0"
        else
          ble/util/c2w "$code"
          ble/canvas/trace-text/.put-atomic "$ret" "${text:i:1}"
        fi
        ((i++))
      fi
      ((y*cols+x>=lines*cols)) && break
    done
  fi
  ble/canvas/trace-text/.put-nl-if-eol
  ret=$out
  ((y>=lines)) && flag_overflow=1
  [[ ! $flag_overflow ]]
} &>/dev/null # Note: suppress LC_COLLATE errors #D1205
_ble_textmap_VARNAMES=(
  _ble_textmap_cols
  _ble_textmap_length
  _ble_textmap_begx
  _ble_textmap_begy
  _ble_textmap_endx
  _ble_textmap_endy
  _ble_textmap_dbeg
  _ble_textmap_dend
  _ble_textmap_dend0
  _ble_textmap_umin
  _ble_textmap_umax)
_ble_textmap_ARRNAMES=(
  _ble_textmap_pos
  _ble_textmap_glyph
  _ble_textmap_ichg)
_ble_textmap_cols=80
_ble_textmap_length=
_ble_textmap_begx=0
_ble_textmap_begy=0
_ble_textmap_endx=0
_ble_textmap_endy=0
_ble_textmap_pos=()
_ble_textmap_glyph=()
_ble_textmap_ichg=()
_ble_textmap_dbeg=-1
_ble_textmap_dend=-1
_ble_textmap_dend0=-1
_ble_textmap_umin=-1
_ble_textmap_umax=-1
function ble/textmap#update-dirty-range {
  ble/dirty-range#update --prefix=_ble_textmap_d "$@"
}
function ble/textmap#save {
  local name prefix=$1
  ble/util/save-vars "$prefix" "${_ble_textmap_VARNAMES[@]}"
  ble/util/save-arrs "$prefix" "${_ble_textmap_ARRNAMES[@]}"
}
function ble/textmap#restore {
  local name prefix=$1
  ble/util/restore-vars "$prefix" "${_ble_textmap_VARNAMES[@]}"
  ble/util/restore-arrs "$prefix" "${_ble_textmap_ARRNAMES[@]}"
}
function ble/textmap#update/.wrap {
  if [[ :$opts: == *:relative:* ]]; then
    ((x)) && cs=$cs${_ble_term_cub//'%d'/$x}
    cs=$cs${_ble_term_cud//'%d'/1}
    changed=1
  elif ((xenl)); then
    cs=$cs$_ble_term_nl
    changed=1
  fi
  ((y++,x=0))
}
function ble/textmap#update {
  local IFS=$' \t\n'
  local dbeg dend dend0
  ((dbeg=_ble_textmap_dbeg,
    dend=_ble_textmap_dend,
    dend0=_ble_textmap_dend0))
  ble/dirty-range#clear --prefix=_ble_textmap_d
  local text=$1 opts=$2
  local iN=${#text}
  local _pos="$x $y"
  _ble_textmap_begx=$x
  _ble_textmap_begy=$y
  local cols=${COLUMNS-80} xenl=$_ble_term_xenl
  ((COLUMNS&&cols<COLUMNS&&(xenl=1)))
  ble/string#reserve-prototype "$cols"
  local it=${bleopt_tab_width:-$_ble_term_it}
  ble/string#reserve-prototype "$it"
  if ((cols!=_ble_textmap_cols)); then
    ((dbeg=0,dend0=_ble_textmap_length,dend=iN))
    _ble_textmap_pos[0]=$_pos
  elif [[ ${_ble_textmap_pos[0]} != "$_pos" ]]; then
    ((dbeg<0&&(dend=dend0=0),
      dbeg=0))
    _ble_textmap_pos[0]=$_pos
  else
    if ((dbeg<0)); then
      local -a pos
      pos=(${_ble_textmap_pos[iN]})
      ((x=pos[0]))
      ((y=pos[1]))
      _ble_textmap_endx=$x
      _ble_textmap_endy=$y
      return
    elif ((dbeg>0)); then
      local -a pos
      pos=(${_ble_textmap_pos[dbeg]})
      ((x=pos[0]))
      ((y=pos[1]))
    fi
  fi
  _ble_textmap_cols=$cols
  _ble_textmap_length=$iN
  ble/array#reserve-prototype "$iN"
  local -a old_pos old_ichg
  old_pos=("${_ble_textmap_pos[@]:dend0:iN-dend+1}")
  old_ichg=("${_ble_textmap_ichg[@]}")
  _ble_textmap_pos=(
    "${_ble_textmap_pos[@]::dbeg+1}"
    "${_ble_array_prototype[@]::dend-dbeg}"
    "${_ble_textmap_pos[@]:dend0+1:iN-dend}")
  _ble_textmap_glyph=(
    "${_ble_textmap_glyph[@]::dbeg}"
    "${_ble_array_prototype[@]::dend-dbeg}"
    "${_ble_textmap_glyph[@]:dend0:iN-dend}")
  _ble_textmap_ichg=()
  ble/urange#shift --prefix=_ble_textmap_ "$dbeg" "$dend" "$dend0"
  local i
  for ((i=dbeg;i<iN;)); do
    if ble/util/isprint+ "${text:i}"; then
      local w=${#BASH_REMATCH}
      local n
      for ((n=i+w;i<n;i++)); do
        local cs=${text:i:1}
        if ((++x==cols)); then
          local changed=0
          ble/textmap#update/.wrap
          ((changed)) && ble/array#push _ble_textmap_ichg "$i"
        fi
        _ble_textmap_glyph[i]=$cs
        _ble_textmap_pos[i+1]="$x $y 0"
      done
    else
      local ret
      ble/util/s2c "$text" "$i"
      local code=$ret
      local w=0 cs= changed=0
      if ((code<32)); then
        if ((code==9)); then
          if ((x+1>=cols)); then
            cs=' '
            ble/textmap#update/.wrap
            changed=1
          else
            local x2
            ((x2=(x/it+1)*it,
              x2>=cols&&(x2=cols-1),
              w=x2-x,
              w!=it&&(changed=1)))
            cs=${_ble_string_prototype::w}
          fi
        elif ((code==10)); then
          if [[ :$opts: == *:relative:* ]]; then
            local pad=$((cols-x)) eraser=
            if ((pad)); then
              if [[ $_ble_term_ech ]]; then
                eraser=${_ble_term_ech//'%d'/$pad}
              else
                eraser=${_ble_string_prototype::cols-x}
                ((x=cols))
              fi
            fi
            local move=${_ble_term_cub//'%d'/$x}${_ble_term_cud//'%d'/1}
            cs=$eraser$move
            changed=1
          else
            cs=$_ble_term_el$_ble_term_nl
          fi
          ((y++,x=0))
        else
          ((w=2))
          ble/util/c2s $((code+64))
          cs="^$ret"
        fi
      elif ((code==127)); then
        w=2 cs="^?"
      elif ((128<=code&&code<160)); then
        ble/util/c2s $((code-64))
        w=4 cs="M-^$ret"
      else
        ble/util/c2w "$code"
        w=$ret cs=${text:i:1}
      fi
      local wrapping=0
      if ((w>0)); then
        if ((x<cols&&cols<x+w)); then
          if [[ :$opts: == *:relative:* ]]; then
            cs=${_ble_term_cub//'%d'/$cols}${_ble_term_cud//'%d'/1}$cs
          elif ((xenl)); then
            cs=$_ble_term_nl$cs
          fi
          cs=${_ble_string_prototype::cols-x}$cs
          ((x=cols,changed=1,wrapping=1))
        fi
        ((x+=w))
        while ((x>cols)); do
          ((y++,x-=cols))
        done
        if ((x==cols)); then
          ble/textmap#update/.wrap
        fi
      fi
      _ble_textmap_glyph[i]=$cs
      ((changed)) && ble/array#push _ble_textmap_ichg "$i"
      _ble_textmap_pos[i+1]="$x $y $wrapping"
      ((i++))
    fi
    if ((i>=dend)); then
      [[ ${old_pos[i-dend]} == "${_ble_textmap_pos[i]}" ]] && break
      if [[ ${old_pos[i-dend]%%[$IFS]*} == "${_ble_textmap_pos[i]%%[$IFS]*}" ]]; then
        local -a opos npos pos
        opos=(${old_pos[i-dend]})
        npos=(${_ble_textmap_pos[i]})
        local ydelta=$((npos[1]-opos[1]))
        while ((i<iN)); do
          ((i++))
          pos=(${_ble_textmap_pos[i]})
          ((pos[1]+=ydelta))
          _ble_textmap_pos[i]="${pos[*]}"
        done
        pos=(${_ble_textmap_pos[iN]})
        x=${pos[0]} y=${pos[1]}
        break
      fi
    fi
  done
  if ((i<iN)); then
    local -a pos
    pos=(${_ble_textmap_pos[iN]})
    x=${pos[0]} y=${pos[1]}
  fi
  local j jN ichg
  for ((j=0,jN=${#old_ichg[@]};j<jN;j++)); do
    if ((ichg=old_ichg[j],
         (ichg>=dend0)&&(ichg+=dend-dend0),
         (0<=ichg&&ichg<dbeg||dend<=i&&ichg<iN)))
    then
      ble/array#push _ble_textmap_ichg "$ichg"
    fi
  done
  ((dbeg<i)) && ble/urange#update --prefix=_ble_textmap_ "$dbeg" "$i"
  _ble_textmap_endx=$x
  _ble_textmap_endy=$y
}
function ble/textmap#is-up-to-date {
  ((_ble_textmap_dbeg==-1))
}
function ble/textmap#assert-up-to-date {
  ble/util/assert 'ble/textmap#is-up-to-date' 'dirty text positions'
}
function ble/textmap#getxy.out {
  ble/textmap#assert-up-to-date
  local _prefix=
  if [[ $1 == --prefix=* ]]; then
    _prefix=${1#--prefix=}
    shift
  fi
  local -a _pos
  _pos=(${_ble_textmap_pos[$1]})
  ((${_prefix}x=_pos[0]))
  ((${_prefix}y=_pos[1]))
}
function ble/textmap#getxy.cur {
  ble/textmap#assert-up-to-date
  local _prefix=
  if [[ $1 == --prefix=* ]]; then
    _prefix=${1#--prefix=}
    shift
  fi
  local -a _pos
  _pos=(${_ble_textmap_pos[$1]})
  if (($1<_ble_textmap_length)); then
    local -a _eoc
    _eoc=(${_ble_textmap_pos[$1+1]})
    ((_eoc[2])) && ((_pos[0]=0,_pos[1]++))
  fi
  ((${_prefix}x=_pos[0]))
  ((${_prefix}y=_pos[1]))
}
function ble/textmap#get-index-at {
  ble/textmap#assert-up-to-date
  local _var=index
  if [[ $1 == -v ]]; then
    _var=$2
    shift 2
  fi
  local _x=$1 _y=$2
  if ((_y>_ble_textmap_endy)); then
    (($_var=_ble_textmap_length))
  elif ((_y<_ble_textmap_begy)); then
    (($_var=0))
  else
    local _l=0 _u=$((_ble_textmap_length+1)) _m
    local _mx _my
    while ((_l+1<_u)); do
      ble/textmap#getxy.cur --prefix=_m $((_m=(_l+_u)/2))
      (((_y<_my||_y==_my&&_x<_mx)?(_u=_m):(_l=_m)))
    done
    (($_var=_l))
  fi
}
function ble/textmap#hit/.getxy.out {
  set -- ${_ble_textmap_pos[$1]}
  x=$1 y=$2
}
function ble/textmap#hit/.getxy.cur {
  local index=$1
  set -- ${_ble_textmap_pos[index]}
  x=$1 y=$2
  if ((index<_ble_textmap_length)); then
    set -- ${_ble_textmap_pos[index+1]}
    (($3)) && ((x=0,y++))
  fi
}
function ble/textmap#hit {
  ble/textmap#assert-up-to-date
  local getxy=ble/textmap#hit/.getxy.$1
  local xh=$2 yh=$3 beg=${4:-0} end=${5:-$_ble_textmap_length}
  local -a pos
  if "$getxy" "$end"; ((yh>y||yh==y&&xh>x)); then
    index=$end
    lx=$x ly=$y
    rx=$x ry=$y
  elif "$getxy" "$beg"; ((yh<y||yh==y&&xh<x)); then
    index=$beg
    lx=$x ly=$y
    rx=$x ry=$y
  else
    local l=0 u=$((end+1)) m
    while ((l+1<u)); do
      "$getxy" $((m=(l+u)/2))
      (((yh<y||yh==y&&xh<x)?(u=m):(l=m)))
    done
    "$getxy" $((index=l))
    lx=$x ly=$y
    (((ly<yh||ly==yh&&lx<xh)&&index<end)) && "$getxy" $((index+1))
    rx=$x ry=$y
  fi
}
_ble_canvas_x=0 _ble_canvas_y=0
function ble/canvas/goto.draw {
  local x=$1 y=$2
  ble/canvas/put.draw "$_ble_term_sgr0"
  ble/canvas/put-move-y.draw $((y-_ble_canvas_y))
  local dx=$((x-_ble_canvas_x))
  if ((dx!=0)); then
    if ((x==0)); then
      ble/canvas/put.draw "$_ble_term_cr"
    else
      ble/canvas/put-move-x.draw "$dx"
    fi
  fi
  _ble_canvas_x=$x _ble_canvas_y=$y
}
_ble_canvas_panel_type=(ble/textarea/panel ble/textarea/panel ble-edit/info)
_ble_canvas_panel_height=(1 0 0)
function ble/canvas/panel/layout/.extract-heights {
  local i n=${#_ble_canvas_panel_type[@]}
  for ((i=0;i<n;i++)); do
    local height
    "${_ble_canvas_panel_type[i]}#get-height" "$i"
    mins[i]=${height%:*}
    maxs[i]=${height#*:}
  done
}
function ble/canvas/panel/layout/.determine-heights {
  local i n=${#_ble_canvas_panel_type[@]} ret
  ble/arithmetic/sum "${mins[@]}"; local min=$ret
  ble/arithmetic/sum "${maxs[@]}"; local max=$ret
  if ((max<=lines)); then
    heights=("${maxs[@]}")
  elif ((min<=lines)); then
    local room=$((lines-min))
    heights=("${mins[@]}")
    while ((room)); do
      local count=0 min_delta=-1 delta
      for ((i=0;i<n;i++)); do
        ((delta=maxs[i]-heights[i],delta>0)) || continue
        ((count++))
        ((min_delta<0||min_delta>delta)) && min_delta=$delta
      done
      ((count==0)) && break
      if ((count*min_delta<=room)); then
        for ((i=0;i<n;i++)); do
          ((maxs[i]-heights[i]>0)) || continue
          ((heights[i]+=min_delta))
        done
        ((room-=count*min_delta))
      else
        local delta=$((room/count)) rem=$((room%count)) count=0
        for ((i=0;i<n;i++)); do
          ((maxs[i]-heights[i]>0)) || continue
          ((heights[i]+=delta))
          ((count++<rem)) && ((heights[i]++))
        done
        ((room=0))
      fi
    done
  else
    heights=("${mins[@]}")
    local excess=$((min-lines))
    for ((i=n-1;i>=0;i--)); do
      local sub=$((heights[i]-heights[i]*lines/min))
      if ((sub<excess)); then
        ((excess-=sub))
        ((heights[i]-=sub))
      else
        ((heights[i]-=excess))
        break
      fi
    done
  fi
}
function ble/canvas/panel/layout/.get-available-height {
  local index=$1
  local lines=$((${LINES:-25}-1)) # Note: bell の為に一行余裕を入れる
  local -a mins=() maxs=()
  ble/canvas/panel/layout/.extract-heights
  maxs[index]=${LINES:-25}
  local -a heights=()
  ble/canvas/panel/layout/.determine-heights
  ret=${heights[index]}
}
function ble/canvas/panel#reallocate-height.draw {
  local lines=$((${LINES:-25}-1)) # Note: bell の為に一行余裕を入れる
  local i n=${#_ble_canvas_panel_type[@]}
  local -a mins=() maxs=()
  ble/canvas/panel/layout/.extract-heights
  local -a heights=()
  ble/canvas/panel/layout/.determine-heights
  for ((i=0;i<n;i++)); do
    ((heights[i]<_ble_canvas_panel_height[i])) &&
      ble/canvas/panel#set-height.draw "$i" "${heights[i]}"
  done
  for ((i=0;i<n;i++)); do
    ((heights[i]>_ble_canvas_panel_height[i])) &&
      ble/canvas/panel#set-height.draw "$i" "${heights[i]}"
  done
}
function ble/canvas/panel#get-origin {
  local ret index=$1 prefix=
  [[ $2 == --prefix=* ]] && prefix=${2#*=}
  ble/arithmetic/sum "${_ble_canvas_panel_height[@]::index}"
  ((${prefix}x=0,${prefix}y=ret))
}
function ble/canvas/panel#goto.draw {
  local index=$1 x=${2-0} y=${3-0} ret
  ble/arithmetic/sum "${_ble_canvas_panel_height[@]::index}"
  ble/canvas/goto.draw "$x" $((ret+y))
}
function ble/canvas/panel#put.draw {
  ble/canvas/put.draw "$2"
  ble/canvas/panel#report-cursor-position "$1" "$3" "$4"
}
function ble/canvas/panel#report-cursor-position {
  local index=$1 x=${2-0} y=${3-0} ret
  ble/arithmetic/sum "${_ble_canvas_panel_height[@]::index}"
  ((_ble_canvas_x=x,_ble_canvas_y=ret+y))
}
function ble/canvas/panel#increase-total-height.draw {
  local delta=$1
  ((delta>0)) || return
  local ret
  ble/arithmetic/sum "${_ble_canvas_panel_height[@]}"; local old_total_height=$ret
  if ((old_total_height>0)); then
    ble/canvas/goto.draw 0 $((old_total_height-1))
    ble/canvas/put-ind.draw "$delta"; ((_ble_canvas_y+=delta))
  else
    ble/canvas/goto.draw 0 0
    ble/canvas/put-ind.draw $((delta-1)); ((_ble_canvas_y+=delta-1))
  fi
}
function ble/canvas/panel#set-height.draw {
  local index=$1 new_height=$2
  local delta=$((new_height-_ble_canvas_panel_height[index]))
  ((delta)) || return
  local ret
  if ((delta>0)); then
    ble/canvas/panel#increase-total-height.draw "$delta"
    ble/arithmetic/sum "${_ble_canvas_panel_height[@]::index+1}"; local ins_offset=$ret
    ble/canvas/goto.draw 0 "$ins_offset"
    ble/canvas/put-il.draw "$delta"
  else
    ble/arithmetic/sum "${_ble_canvas_panel_height[@]::index+1}"; local ins_offset=$ret
    ble/canvas/goto.draw 0 $((ins_offset+delta))
    ble/canvas/put-dl.draw $((-delta))
  fi
  ((_ble_canvas_panel_height[index]=new_height))
  ble/function#try "${_ble_canvas_panel_type[index]}#on-height-change" "$index"
  return 0
}
function ble/canvas/panel#increase-height.draw {
  local index=$1 delta=$2
  ble/canvas/panel#set-height.draw "$index" $((_ble_canvas_panel_height[index]+delta))
}
function ble/canvas/panel#set-height-and-clear.draw {
  local index=$1 new_height=$2
  local old_height=${_ble_canvas_panel_height[index]}
  ((old_height||new_height)) || return
  local ret
  ble/canvas/panel#increase-total-height.draw $((new_height-old_height))
  ble/arithmetic/sum "${_ble_canvas_panel_height[@]::index}"; local ins_offset=$ret
  ble/canvas/goto.draw 0 "$ins_offset"
  ((old_height)) && ble/canvas/put-dl.draw "$old_height"
  ((new_height)) && ble/canvas/put-il.draw "$new_height"
  ((_ble_canvas_panel_height[index]=new_height))
}
function ble/canvas/panel#clear.draw {
  local index=$1
  local height=${_ble_canvas_panel_height[index]}
  if ((height)); then
    local ret
    ble/arithmetic/sum "${_ble_canvas_panel_height[@]::index}"; local ins_offset=$ret
    ble/canvas/goto.draw 0 "$ins_offset"
    if ((height==1)); then
      ble/canvas/put.draw "$_ble_term_el2"
    else
      ble/canvas/put-dl.draw "$height"
      ble/canvas/put-il.draw "$height"
    fi
  fi
}
function ble/canvas/panel#clear-after.draw {
  local index=$1 x=$2 y=$3
  local height=${_ble_canvas_panel_height[index]}
  ((y<height)) || return
  ble/canvas/panel#goto.draw "$index" "$x" "$y"
  ble/canvas/put.draw "$_ble_term_el"
  local rest_lines=$((height-(y+1)))
  if ((rest_lines)); then
    ble/canvas/put.draw "$_ble_term_ind"
    ble/canvas/put-dl.draw "$rest_lines"
    ble/canvas/put-il.draw "$rest_lines"
    ble/canvas/put.draw "$_ble_term_ri"
  fi
}
bleopt/declare -v edit_vbell ''
bleopt/declare -v edit_abell 1
bleopt/declare -v history_lazyload 1
bleopt/declare -v delete_selection_mode 1
bleopt/declare -n indent_offset 4
bleopt/declare -n indent_tabs 1
bleopt/declare -v undo_point end
bleopt/declare -n edit_forced_textmap 1
function ble/edit/use-textmap {
  ble/textmap#is-up-to-date && return 0
  ((bleopt_edit_forced_textmap)) || return 1
  ble/widget/.update-textmap
  return 0
}
bleopt/declare -v rps1 ''
bleopt/declare -v rps1_transient ''
bleopt/declare -v prompt_eol_mark $'\e[94m[ble: EOF]\e[m'
bleopt/declare -n internal_exec_type gexec
function bleopt/check:internal_exec_type {
  if ! ble/is-function "ble-edit/exec:$value/process"; then
    echo "bleopt: Invalid value internal_exec_type='$value'. A function 'ble-edit/exec:$value/process' is not defined." >&2
    return 1
  fi
}
bleopt/declare -v internal_suppress_bash_output 1
bleopt/declare -n internal_ignoreeof_trap 'Use "exit" to leave the shell.'
bleopt/declare -v allow_exit_with_jobs ''
function ble-edit/prompt/initialize {
  _ble_edit_prompt__string_H=${HOSTNAME}
  if local rex='^[0-9]+(\.[0-9]){3}$'; [[ $HOSTNAME =~ $rex ]]; then
    _ble_edit_prompt__string_h=$HOSTNAME
  else
    _ble_edit_prompt__string_h=${HOSTNAME%%.*}
  fi
  local tmp; ble/util/assign tmp 'tty 2>/dev/null'
  _ble_edit_prompt__string_l=${tmp##*/}
  _ble_edit_prompt__string_s=${0##*/}
  _ble_edit_prompt__string_u=${USER}
  ble/util/sprintf _ble_edit_prompt__string_v '%d.%d' "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}"
  ble/util/sprintf _ble_edit_prompt__string_V '%d.%d.%d' "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}" "${BASH_VERSINFO[2]}"
  if [[ $EUID -eq 0 ]]; then
    _ble_edit_prompt__string_root='#'
  else
    _ble_edit_prompt__string_root='$'
  fi
  if [[ $OSTYPE == cygwin* ]]; then
    local windir=/cygdrive/c/Windows
    if [[ $WINDIR == [A-Za-z]:\\* ]]; then
      local bsl='\' sl=/
      local c=${WINDIR::1} path=${WINDIR:3}
      if [[ $c == [A-Z] ]]; then
        if ((_ble_bash>=40000)); then
          c=${c,?}
        else
          local ret
          ble/util/s2c "$c"
          ble/util/c2s $((ret+32))
          c=$ret
        fi
      fi
      windir=/cygdrive/$c/${path//$bsl/$sl}
    fi
    if [[ -e $windir && -w $windir ]]; then
      _ble_edit_prompt__string_root='#'
    fi
  fi
}
_ble_edit_prompt=("" 0 0 0 32 0 "" "")
function ble-edit/prompt/.load {
  x=${_ble_edit_prompt[1]}
  y=${_ble_edit_prompt[2]}
  g=${_ble_edit_prompt[3]}
  lc=${_ble_edit_prompt[4]}
  lg=${_ble_edit_prompt[5]}
  ret=${_ble_edit_prompt[6]}
}
function ble-edit/prompt/print {
  local text=$1 a b
  if [[ $text == *['$\"`']* ]]; then
    a='\' b='\\' text=${text//"$a"/$b}
    a='$' b='\$' text=${text//"$a"/$b}
    a='"' b='\"' text=${text//"$a"/$b}
    a='`' b='\`' text=${text//"$a"/$b}
  fi
  ble/canvas/put.draw "$text"
}
function ble-edit/prompt/process-prompt-string {
  local ps1=$1
  local i=0 iN=${#ps1}
  local rex_letters='^[^\]+|\\$'
  while ((i<iN)); do
    local tail=${ps1:i}
    if [[ $tail == '\'?* ]]; then
      ble-edit/prompt/.process-backslash
    elif [[ $tail =~ $rex_letters ]]; then
      ble/canvas/put.draw "$BASH_REMATCH"
      ((i+=${#BASH_REMATCH}))
    else
      ble/canvas/put.draw "${tail::1}"
      ((i++))
    fi
  done
}
function ble-edit/prompt/.process-backslash {
  ((i+=2))
  local c=${tail:1:1} pat='[]#!$\'
  if [[ ! ${pat##*"$c"*} ]]; then
    case "$c" in
    (\[) ble/canvas/put.draw $'\e[99s' ;; # \[ \] は後処理の為、適当な識別用の文字列を出力する。
    (\]) ble/canvas/put.draw $'\e[99u' ;;
    ('#') # コマンド番号 (本当は history に入らない物もある…)
      ble/canvas/put.draw "$_ble_edit_CMD" ;;
    (\!) # 編集行の履歴番号
      local count
      ble-edit/history/get-count -v count
      ble/canvas/put.draw $((count+1)) ;;
    ('$') # # or $
      ble-edit/prompt/print "$_ble_edit_prompt__string_root" ;;
    (\\)
      ble/canvas/put.draw '\' ;;
    esac
  elif ! ble/function#try ble-edit/prompt/backslash:"$c"; then
    ble/canvas/put.draw "\\$c"
  fi
}
function ble-edit/prompt/backslash:0 { # 8進表現
  local rex='^\\[0-7]{1,3}'
  if [[ $tail =~ $rex ]]; then
    local seq=${BASH_REMATCH[0]}
    ((i+=${#seq}-2))
    builtin eval "c=\$'$seq'"
  fi
  ble-edit/prompt/print "$c"
  return 0
}
function ble-edit/prompt/backslash:1 { ble-edit/prompt/backslash:0; }
function ble-edit/prompt/backslash:2 { ble-edit/prompt/backslash:0; }
function ble-edit/prompt/backslash:3 { ble-edit/prompt/backslash:0; }
function ble-edit/prompt/backslash:4 { ble-edit/prompt/backslash:0; }
function ble-edit/prompt/backslash:5 { ble-edit/prompt/backslash:0; }
function ble-edit/prompt/backslash:6 { ble-edit/prompt/backslash:0; }
function ble-edit/prompt/backslash:7 { ble-edit/prompt/backslash:0; }
function ble-edit/prompt/backslash:a { # 0 BEL
  ble/canvas/put.draw ""
  return 0
}
function ble-edit/prompt/backslash:d { # ? 日付
  [[ $cache_d ]] || ble/util/strftime -v cache_d '%a %b %d'
  ble-edit/prompt/print "$cache_d"
  return 0
}
function ble-edit/prompt/backslash:t { # 8 時刻
  [[ $cache_t ]] || ble/util/strftime -v cache_t '%H:%M:%S'
  ble-edit/prompt/print "$cache_t"
  return 0
}
function ble-edit/prompt/backslash:A { # 5 時刻
  [[ $cache_A ]] || ble/util/strftime -v cache_A '%H:%M'
  ble-edit/prompt/print "$cache_A"
  return 0
}
function ble-edit/prompt/backslash:T { # 8 時刻
  [[ $cache_T ]] || ble/util/strftime -v cache_T '%I:%M:%S'
  ble-edit/prompt/print "$cache_T"
  return 0
}
function ble-edit/prompt/backslash:@ { # ? 時刻
  [[ $cache_at ]] || ble/util/strftime -v cache_at '%I:%M %p'
  ble-edit/prompt/print "$cache_at"
  return 0
}
function ble-edit/prompt/backslash:D {
  local rex='^\\D\{([^{}]*)\}' cache_D
  if [[ $tail =~ $rex ]]; then
    ble/util/strftime -v cache_D "${BASH_REMATCH[1]}"
    ble-edit/prompt/print "$cache_D"
    ((i+=${#BASH_REMATCH}-2))
  else
    ble-edit/prompt/print "\\$c"
  fi
  return 0
}
function ble-edit/prompt/backslash:e {
  ble/canvas/put.draw $'\e'
  return 0
}
function ble-edit/prompt/backslash:h { # = ホスト名
  ble-edit/prompt/print "$_ble_edit_prompt__string_h"
  return 0
}
function ble-edit/prompt/backslash:H { # = ホスト名
  ble-edit/prompt/print "$_ble_edit_prompt__string_H"
  return 0
}
function ble-edit/prompt/backslash:j { #   ジョブの数
  if [[ ! $cache_j ]]; then
    local joblist
    ble/util/joblist
    cache_j=${#joblist[@]}
  fi
  ble/canvas/put.draw "$cache_j"
  return 0
}
function ble-edit/prompt/backslash:l { #   tty basename
  ble-edit/prompt/print "$_ble_edit_prompt__string_l"
  return 0
}
function ble-edit/prompt/backslash:n {
  ble/canvas/put.draw $'\n'
  return 0
}
function ble-edit/prompt/backslash:r {
  ble/canvas/put.draw "$_ble_term_cr"
  return 0
}
function ble-edit/prompt/backslash:s { # 4 "bash"
  ble-edit/prompt/print "$_ble_edit_prompt__string_s"
  return 0
}
function ble-edit/prompt/backslash:u { # = ユーザ名
  ble-edit/prompt/print "$_ble_edit_prompt__string_u"
  return 0
}
function ble-edit/prompt/backslash:v { # = bash version %d.%d
  ble-edit/prompt/print "$_ble_edit_prompt__string_v"
  return 0
}
function ble-edit/prompt/backslash:V { # = bash version %d.%d.%d
  ble-edit/prompt/print "$_ble_edit_prompt__string_V"
  return 0
}
function ble-edit/prompt/backslash:w { # PWD
  ble-edit/prompt/.update-working-directory
  ble-edit/prompt/print "$cache_wd"
  return 0
}
function ble-edit/prompt/backslash:W { # PWD短縮
  if [[ ! ${PWD//'/'} ]]; then
    ble-edit/prompt/print "$PWD"
  else
    ble-edit/prompt/.update-working-directory
    ble-edit/prompt/print "${cache_wd##*/}"
  fi
  return 0
}
function ble-edit/prompt/.update-working-directory {
  [[ $cache_wd ]] && return
  if [[ ! ${PWD//'/'} ]]; then
    cache_wd=$PWD
    return
  fi
  local head= body=${PWD%/}
  if [[ $body == "$HOME" ]]; then
    cache_wd='~'
    return
  elif [[ $body == "$HOME"/* ]]; then
    head='~/'
    body=${body#"$HOME"/}
  fi
  if [[ $PROMPT_DIRTRIM ]]; then
    local dirtrim=$((PROMPT_DIRTRIM))
    local pat='[^/]'
    local count=${body//$pat}
    if ((${#count}>=dirtrim)); then
      local ret
      ble/string#repeat '/*' "$dirtrim"
      local omit=${body%$ret}
      ((${#omit}>3)) &&
        body=...${body:${#omit}}
    fi
  fi
  cache_wd=$head$body
}
function ble-edit/prompt/.escape/check-double-quotation {
  if [[ $tail == '"'* ]]; then
    if [[ ! $nest ]]; then
      out=$out'\"'
      tail=${tail:1}
    else
      out=$out'"'
      tail=${tail:1}
      nest=\"$nest
      ble-edit/prompt/.escape/update-rex_skip
    fi
    return 0
  else
    return 1
  fi
}
function ble-edit/prompt/.escape/check-command-substitution {
  if [[ $tail == '$('* ]]; then
    out=$out'$('
    tail=${tail:2}
    nest=')'$nest
    ble-edit/prompt/.escape/update-rex_skip
    return 0
  else
    return 1
  fi
}
function ble-edit/prompt/.escape/check-parameter-expansion {
  if [[ $tail == '${'* ]]; then
    out=$out'${'
    tail=${tail:2}
    nest='}'$nest
    ble-edit/prompt/.escape/update-rex_skip
    return 0
  else
    return 1
  fi
}
function ble-edit/prompt/.escape/check-incomplete-quotation {
  if [[ $tail == '`'* ]]; then
    local rex='^`([^\`]|\\.)*\\$'
    [[ $tail =~ $rex ]] && tail=$tail'\'
    out=$out$tail'`'
    tail=
    return 0
  elif [[ $nest == ['})']* && $tail == \'* ]]; then
    out=$out$tail$q
    tail=
    return 0
  elif [[ $nest == ['})']* && $tail == \$\'* ]]; then
    local rex='^\$'$q'([^\'$q']|\\.)*\\$'
    [[ $tail =~ $rex ]] && tail=$tail'\'
    out=$out$tail$q
    tail=
    return 0
  elif [[ $tail == '\' ]]; then
    out=$out'\\'
    tail=
    return 0
  else
    return 1
  fi
}
function ble-edit/prompt/.escape/update-rex_skip {
  if [[ $nest == \)* ]]; then
    rex_skip=$rex_skip_paren
  elif [[ $nest == \}* ]]; then
    rex_skip=$rex_skip_brace
  else
    rex_skip=$rex_skip_dquot
  fi
}
function ble-edit/prompt/.escape {
  local tail=$1 out= nest=
  local q=\'
  local rex_bq='`([^\`]|\\.)*`'
  local rex_sq=$q'[^'$q']*'$q'|\$'$q'([^\'$q']|\\.)*'$q
  local rex_skip
  local rex_skip_dquot='^([^\"$`]|'$rex_bq'|\\.)+'
  local rex_skip_brace='^([^\"$`'$q'}]|'$rex_bq'|'$rex_sq'|\\.)+'
  local rex_skip_paren='^([^\"$`'$q'()]|'$rex_bq'|'$rex_sq'|\\.)+'
  ble-edit/prompt/.escape/update-rex_skip
  while [[ $tail ]]; do
    if [[ $tail =~ $rex_skip ]]; then
      out=$out$BASH_REMATCH
      tail=${tail:${#BASH_REMATCH}}
    elif [[ $nest == ['})"']* && $tail == "${nest::1}"* ]]; then
      out=$out${nest::1}
      tail=${tail:1}
      nest=${nest:1}
      ble-edit/prompt/.escape/update-rex_skip
    elif [[ $nest == \)* && $tail == \(* ]]; then
      out=$out'('
      tail=${tail:1}
      nest=')'$nest
    elif ble-edit/prompt/.escape/check-double-quotation; then
      continue
    elif ble-edit/prompt/.escape/check-command-substitution; then
      continue
    elif ble-edit/prompt/.escape/check-parameter-expansion; then
      continue
    elif ble-edit/prompt/.escape/check-incomplete-quotation; then
      continue
    else
      out=$out${tail::1}
      tail=${tail:1}
    fi
  done
  ret=$out$nest
}
function ble-edit/prompt/.instantiate {
  trace_hash= esc= x=0 y=0 g=0 lc=32 lg=0
  local ps=$1 opts=$2 x0=$3 y0=$4 g0=$5 lc0=$6 lg0=$7 esc0=$8 trace_hash0=$9
  [[ ! $ps ]] && return 0
  local -a DRAW_BUFF=()
  ble-edit/prompt/process-prompt-string "$ps"
  local processed; ble/canvas/sflush.draw -v processed
  local ret
  ble-edit/prompt/.escape "$processed"; local escaped=$ret
  local expanded=${trace_hash0#*:} # Note: これは次行が失敗した時の既定値
  builtin eval "expanded=\"$escaped\""
  trace_hash=$COLUMNS:$expanded
  if [[ $trace_hash != "$trace_hash0" ]]; then
    x=0 y=0 g=0 lc=32 lg=0
    ble/canvas/trace "$expanded" "$opts:left-char"; local traced=$ret
    ((lc<0&&(lc=0)))
    esc=$traced
    return 0
  else
    x=$x0 y=$y0 g=$g0 lc=$lc0 lg=$lg0
    esc=$esc0
    return 2
  fi
}
function ble-edit/prompt/update/.eval-prompt_command {
  eval "$PROMPT_COMMAND"
}
function ble-edit/prompt/update {
  local version=$COLUMNS:$_ble_edit_LINENO
  if [[ ${_ble_edit_prompt[0]} == "$version" ]]; then
    ble-edit/prompt/.load
    return
  fi
  local cache_d= cache_t= cache_A= cache_T= cache_at= cache_j= cache_wd=
  if [[ $PROMPT_COMMAND ]]; then
    ble-edit/restore-PS1
    ble-edit/prompt/update/.eval-prompt_command
    ble-edit/adjust-PS1
  fi
  local trace_hash esc
  ble-edit/prompt/.instantiate "$_ble_edit_PS1" '' "${_ble_edit_prompt[@]:1}"
  _ble_edit_prompt=("$version" "$x" "$y" "$g" "$lc" "$lg" "$esc" "$trace_hash")
  ret=$esc
  if [[ $bleopt_rps1 ]]; then
    local ps1_height=$((y+1))
    local trace_hash esc x y g lc lg # Note: これ以降は local の x y g lc lg
    local x1=${_ble_edit_rprompt_bbox[0]}
    local y1=${_ble_edit_rprompt_bbox[1]}
    local x2=${_ble_edit_rprompt_bbox[2]}
    local y2=${_ble_edit_rprompt_bbox[3]}
    LINES=$ps1_height ble-edit/prompt/.instantiate "$bleopt_rps1" confine:relative:measure-bbox "${_ble_edit_rprompt[@]:1}"
    _ble_edit_rprompt=("$version" "$x" "$y" "$g" "$lc" "$lg" "$esc" "$trace_hash")
    _ble_edit_rprompt_bbox=("$x1" "$y1" "$x2" "$y2")
  fi
}
function ble-edit/info/.initialize-size {
  local ret
  ble/canvas/panel/layout/.get-available-height "$_ble_edit_info_panel"
  cols=${COLUMNS-80} lines=$ret
}
_ble_edit_info_panel=2
_ble_edit_info=(0 0 "")
function ble-edit/info#get-height {
  if [[ ${_ble_edit_info[2]} ]]; then
    height=1:$((_ble_edit_info[1]+1))
  else
    height=0:0
  fi
}
function ble-edit/info/.construct-content {
  local cols lines
  ble-edit/info/.initialize-size
  x=0 y=0 content=
  local type=$1 text=$2
  case "$1" in
  (ansi|esc)
    local trace_opts=truncate
    [[ $1 == esc ]] && trace_opts=$trace_opts:terminfo
    local ret= g=0
    LINES=$lines ble/canvas/trace "$text" "$trace_opts"
    content=$ret ;;
  (text)
    local ret
    ble/canvas/trace-text "$text"
    content=$ret ;;
  (store)
    x=$2 y=$3 content=$4
    ((y<lines)) || ble-edit/info/.construct-content esc "$content" ;;
  (*)
    echo "usage: ble-edit/info/.construct-content type text" >&2 ;;
  esac
}
function ble-edit/info/.clear-content {
  [[ ${_ble_edit_info[2]} ]] || return
  local -a DRAW_BUFF=()
  ble/canvas/panel#set-height.draw "$_ble_edit_info_panel" 0
  ble/canvas/bflush.draw
  _ble_edit_info=(0 0 "")
}
function ble-edit/info/.render-content {
  local x=$1 y=$2 content=$3
  [[ $content == "${_ble_edit_info[2]}" ]] && return
  if [[ ! $content ]]; then
    ble-edit/info/.clear-content
    return
  fi
  _ble_edit_info=("$x" "$y" "$content")
  local -a DRAW_BUFF=()
  ble/canvas/panel#reallocate-height.draw
  ble/canvas/panel#clear.draw "$_ble_edit_info_panel"
  ble/canvas/panel#goto.draw "$_ble_edit_info_panel"
  ble/canvas/put.draw "$content"
  ble/canvas/bflush.draw
  ((_ble_canvas_y+=y,_ble_canvas_x=x))
}
_ble_edit_info_default=(0 0 "")
_ble_edit_info_scene=default
function ble-edit/info/show {
  local type=$1 text=$2
  if [[ $text ]]; then
    local x y content=
    ble-edit/info/.construct-content "$@"
    ble-edit/info/.render-content "$x" "$y" "$content"
    ble/util/buffer.flush >&2
    _ble_edit_info_scene=show
  else
    ble-edit/info/default
  fi
}
function ble-edit/info/set-default {
  local type=$1 text=$2
  local x y content
  ble-edit/info/.construct-content "$type" "$text"
  _ble_edit_info_default=("$x" "$y" "$content")
}
function ble-edit/info/default {
  _ble_edit_info_scene=default
  (($#)) && ble-edit/info/set-default "$@"
  return 0
}
function ble-edit/info/clear {
  ble-edit/info/default
}
function ble-edit/info/hide {
  ble-edit/info/.clear-content
}
function ble-edit/info/reveal {
  if [[ $_ble_edit_info_scene == default ]]; then
    ble-edit/info/.render-content "${_ble_edit_info_default[@]}"
  fi
}
function ble-edit/info/immediate-show {
  local x=$_ble_canvas_x y=$_ble_canvas_y
  ble-edit/info/show "$@"
  local -a DRAW_BUFF=()
  ble/canvas/goto.draw "$x" "$y"
  ble/canvas/bflush.draw
  ble/util/buffer.flush >&2
}
function ble-edit/info/immediate-clear {
  local x=$_ble_canvas_x y=$_ble_canvas_y
  ble-edit/info/clear
  ble-edit/info/reveal
  local -a DRAW_BUFF=()
  ble/canvas/goto.draw "$x" "$y"
  ble/canvas/bflush.draw
  ble/util/buffer.flush >&2
}
_ble_edit_VARNAMES=(
  _ble_edit_str
  _ble_edit_ind
  _ble_edit_mark
  _ble_edit_mark_active
  _ble_edit_overwrite_mode
  _ble_edit_line_disabled
  _ble_edit_arg
  _ble_edit_dirty_draw_beg
  _ble_edit_dirty_draw_end
  _ble_edit_dirty_draw_end0
  _ble_edit_dirty_syntax_beg
  _ble_edit_dirty_syntax_end
  _ble_edit_dirty_syntax_end0
  _ble_edit_kill_ring
  _ble_edit_kill_type
  _ble_edit_dirty_observer)
_ble_edit_ARRNAMES=()
_ble_edit_str=
_ble_edit_ind=0
_ble_edit_mark=0
_ble_edit_mark_active=
_ble_edit_overwrite_mode=
_ble_edit_line_disabled=
_ble_edit_arg=
_ble_edit_kill_ring=
_ble_edit_kill_type=
function ble-edit/content/replace {
  local beg=$1 end=$2
  local ins=$3 reason=${4:-edit}
  _ble_edit_str="${_ble_edit_str::beg}""$ins""${_ble_edit_str:end}"
  ble-edit/content/.update-dirty-range "$beg" $((beg+${#ins})) "$end" "$reason"
}
function ble-edit/content/reset {
  local str=$1 reason=${2:-edit}
  local beg=0 end=${#str} end0=${#_ble_edit_str}
  _ble_edit_str=$str
  ble-edit/content/.update-dirty-range "$beg" "$end" "$end0" "$reason"
}
function ble-edit/content/reset-and-check-dirty {
  local str=$1 reason=${2:-edit}
  [[ $_ble_edit_str == "$str" ]] && return
  local ret pref suff
  ble/string#common-prefix "$_ble_edit_str" "$str"; pref=$ret
  local dmin=${#pref}
  ble/string#common-suffix "${_ble_edit_str:dmin}" "${str:dmin}"; suff=$ret
  local dmax0=$((${#_ble_edit_str}-${#suff})) dmax=$((${#str}-${#suff}))
  _ble_edit_str=$str
  ble-edit/content/.update-dirty-range "$dmin" "$dmax" "$dmax0" "$reason"
}
_ble_edit_dirty_draw_beg=-1
_ble_edit_dirty_draw_end=-1
_ble_edit_dirty_draw_end0=-1
_ble_edit_dirty_syntax_beg=0
_ble_edit_dirty_syntax_end=0
_ble_edit_dirty_syntax_end0=1
_ble_edit_dirty_observer=()
function ble-edit/content/.update-dirty-range {
  ble/dirty-range#update --prefix=_ble_edit_dirty_draw_ "${@:1:3}"
  ble/dirty-range#update --prefix=_ble_edit_dirty_syntax_ "${@:1:3}"
  ble/textmap#update-dirty-range "${@:1:3}"
  local obs
  for obs in "${_ble_edit_dirty_observer[@]}"; do "$obs" "$@"; done
}
function ble-edit/content/update-syntax {
  if ble/is-function ble/syntax/parse; then
    local beg end end0
    ble/dirty-range#load --prefix=_ble_edit_dirty_syntax_
    if ((beg>=0)); then
      ble/dirty-range#clear --prefix=_ble_edit_dirty_syntax_
      ble/syntax/parse "$_ble_edit_str" "$beg" "$end" "$end0"
    fi
  fi
}
function ble-edit/content/eolp {
  local pos=${1:-$_ble_edit_ind}
  ((pos==${#_ble_edit_str})) || [[ ${_ble_edit_str:pos:1} == $'\n' ]]
}
function ble-edit/content/bolp {
  local pos=${1:-$_ble_edit_ind}
  ((pos<=0)) || [[ ${_ble_edit_str:pos-1:1} == $'\n' ]]
}
function ble-edit/content/find-logical-eol {
  local index=${1:-$_ble_edit_ind} offset=${2:-0}
  if ((offset>0)); then
    local text=${_ble_edit_str:index}
    local rex=$'^([^\n]*\n){0,'$((offset-1))$'}([^\n]*\n)?[^\n]*'
    [[ $text =~ $rex ]]
    ((ret=index+${#BASH_REMATCH}))
    [[ ${BASH_REMATCH[2]} ]]
  elif ((offset<0)); then
    local text=${_ble_edit_str::index}
    local rex=$'(\n[^\n]*){0,'$((-offset-1))$'}(\n[^\n]*)?$'
    [[ $text =~ $rex ]]
    if [[ $BASH_REMATCH ]]; then
      ((ret=index-${#BASH_REMATCH}))
      [[ ${BASH_REMATCH[2]} ]]
    else
      ble-edit/content/find-logical-eol "$index" 0
      return 1
    fi
  else
    local text=${_ble_edit_str:index}
    text=${text%%$'\n'*}
    ((ret=index+${#text}))
    return 0
  fi
}
function ble-edit/content/find-logical-bol {
  local index=${1:-$_ble_edit_ind} offset=${2:-0}
  if ((offset>0)); then
    local rex=$'^([^\n]*\n){0,'$((offset-1))$'}([^\n]*\n)?'
    [[ ${_ble_edit_str:index} =~ $rex ]]
    if [[ $BASH_REMATCH ]]; then
      ((ret=index+${#BASH_REMATCH}))
      [[ ${BASH_REMATCH[2]} ]]
    else
      ble-edit/content/find-logical-bol "$index" 0
      return 1
    fi
  elif ((offset<0)); then
    ble-edit/content/find-logical-eol "$index" "$offset"; local ext=$?
    ble-edit/content/find-logical-bol "$ret" 0
    return "$ext"
  else
    local text=${_ble_edit_str::index}
    text=${text##*$'\n'}
    ((ret=index-${#text}))
    return 0
  fi
}
function ble-edit/content/find-non-space {
  local bol=$1
  local rex=$'^[ \t]*'; [[ ${_ble_edit_str:bol} =~ $rex ]]
  ret=$((bol+${#BASH_REMATCH}))
}
function ble-edit/content/is-single-line {
  [[ $_ble_edit_str != *$'\n'* ]]
}
function ble-edit/content/get-arg {
  local default_value=$1
  if [[ $_ble_edit_arg == -* ]]; then
    if [[ $_ble_edit_arg == - ]]; then
      arg=-1
    else
      arg=$((-10#${_ble_edit_arg#-}))
    fi
  else
    if [[ $_ble_edit_arg ]]; then
      arg=$((10#$_ble_edit_arg))
    else
      arg=$default_value
    fi
  fi
  _ble_edit_arg=
}
function ble-edit/content/clear-arg {
  _ble_edit_arg=
}
_ble_edit_PS1_adjusted=
_ble_edit_PS1=
function ble-edit/adjust-PS1 {
  [[ $_ble_edit_PS1_adjusted ]] && return
  _ble_edit_PS1_adjusted=1
  _ble_edit_PS1=$PS1
  PS1=
}
function ble-edit/restore-PS1 {
  [[ $_ble_edit_PS1_adjusted ]] || return
  _ble_edit_PS1_adjusted=
  PS1=$_ble_edit_PS1
}
_ble_edit_IGNOREEOF_adjusted=
_ble_edit_IGNOREEOF=
function ble-edit/adjust-IGNOREEOF {
  [[ $_ble_edit_IGNOREEOF_adjusted ]] && return
  _ble_edit_IGNOREEOF_adjusted=1
  if [[ ${IGNOREEOF+set} ]]; then
    _ble_edit_IGNOREEOF=$IGNOREEOF
  else
    unset -v _ble_edit_IGNOREEOF
  fi
  if ((_ble_bash>=40000)); then
    unset -v IGNOREEOF
  else
    IGNOREEOF=9999
  fi
}
function ble-edit/restore-IGNOREEOF {
  [[ $_ble_edit_IGNOREEOF_adjusted ]] || return
  _ble_edit_IGNOREEOF_adjusted=
  if [[ ${_ble_edit_IGNOREEOF+set} ]]; then
    IGNOREEOF=$_ble_edit_IGNOREEOF
  else
    unset -v IGNOREEOF
  fi
}
function ble-edit/eval-IGNOREEOF {
  local value=
  if [[ $_ble_edit_IGNOREEOF_adjusted ]]; then
    value=${_ble_edit_IGNOREEOF-0}
  else
    value=${IGNOREEOF-0}
  fi
  if [[ $value && ! ${value//[0-9]} ]]; then
    ret=$((10#$value))
  else
    ret=10
  fi
}
function ble-edit/attach/TRAPWINCH {
  local IFS=$' \t\n'
  if ((_ble_edit_attached)); then
    if [[ ! $_ble_textarea_invalidated && $_ble_term_state == internal ]]; then
      _ble_textmap_pos=()
      ble-edit/bind/stdout.on
      ble-edit/info/hide
      ble/util/buffer "$_ble_term_ed"
      ble-edit/info/reveal
      ble/textarea#redraw
      ble-edit/bind/stdout.off
    fi
  fi
}
_ble_edit_attached=0
function ble-edit/attach/.attach {
  ((_ble_edit_attached)) && return
  _ble_edit_attached=1
  if [[ ! ${_ble_edit_LINENO+set} ]]; then
    _ble_edit_LINENO="${BASH_LINENO[*]: -1}"
    ((_ble_edit_LINENO<0)) && _ble_edit_LINENO=0
    unset -v LINENO; LINENO=$_ble_edit_LINENO
    _ble_edit_CMD=$_ble_edit_LINENO
  fi
  trap ble-edit/attach/TRAPWINCH WINCH
  ble-edit/adjust-PS1
  ble-edit/adjust-IGNOREEOF
  [[ $bleopt_internal_exec_type == exec ]] && _ble_edit_IFS=$IFS
}
function ble-edit/attach/.detach {
  ((!_ble_edit_attached)) && return
  ble-edit/restore-PS1
  ble-edit/restore-IGNOREEOF
  [[ $bleopt_internal_exec_type == exec ]] && IFS=$_ble_edit_IFS
  _ble_edit_attached=0
}
_ble_textarea_VARNAMES=(
  _ble_textarea_bufferName
  _ble_textarea_scroll
  _ble_textarea_gendx
  _ble_textarea_gendy
  _ble_textarea_invalidated
  _ble_textarea_version
  _ble_textarea_caret_state
  _ble_textarea_panel)
_ble_textarea_ARRNAMES=(
  _ble_textarea_buffer
  _ble_textarea_cur
  _ble_textarea_cache)
function ble/textarea/panel#get-height {
  if [[ $1 == "$_ble_textarea_panel" ]]; then
    local min=$((_ble_edit_prompt[2]+1)) max=$((_ble_textmap_endy+1))
    ((min<max&&min++))
    height=$min:$max
  else
    height=0:${_ble_canvas_panel_height[$1]}
  fi
}
function ble/textarea/panel#on-height-change {
  [[ $1 == "$_ble_textarea_panel" ]] || return
  if [[ ! $ble_textarea_render_flag ]]; then
    ble/textarea#invalidate
  fi
}
_ble_textarea_buffer=()
_ble_textarea_bufferName=
function ble/textarea#update-text-buffer {
  local iN=${#text}
  local HIGHLIGHT_BUFF HIGHLIGHT_UMIN HIGHLIGHT_UMAX
  ble/highlight/layer/update "$text"
  ble/urange#update "$HIGHLIGHT_UMIN" "$HIGHLIGHT_UMAX"
  if ((${#_ble_textmap_ichg[@]})); then
    local ichg g ret
    builtin eval "_ble_textarea_buffer=(\"\${$HIGHLIGHT_BUFF[@]}\")"
    HIGHLIGHT_BUFF=_ble_textarea_buffer
    for ichg in "${_ble_textmap_ichg[@]}"; do
      ble/highlight/layer/getg "$ichg"
      ble/color/g2sgr "$g"
      _ble_textarea_buffer[ichg]=$ret${_ble_textmap_glyph[ichg]}
    done
  fi
  _ble_textarea_bufferName=$HIGHLIGHT_BUFF
  if [[ $bleopt_internal_suppress_bash_output ]]; then
    lc=32 lg=0
  else
    if ((index>0)); then
      local cx cy
      ble/textmap#getxy.cur --prefix=c "$index"
      local lcs ret
      if ((cx==0)); then
        if ((index==iN)); then
          ret=32
        else
          lcs=${_ble_textmap_glyph[index]}
          ble/util/s2c "$lcs" 0
        fi
        local g; ble/highlight/layer/getg "$index"; lg=$g
        ((lc=ret==10?32:ret))
      else
        lcs=${_ble_textmap_glyph[index-1]}
        ble/util/s2c "$lcs" $((${#lcs}-1))
        local g; ble/highlight/layer/getg $((index-1)); lg=$g
        ((lc=ret))
      fi
    fi
  fi
}
function ble/textarea#slice-text-buffer {
  ble/textmap#assert-up-to-date
  local iN=$_ble_textmap_length
  local i1=${1:-0} i2=${2:-$iN}
  ((i1<0&&(i1+=iN,i1<0&&(i1=0)),
    i2<0&&(i2+=iN)))
  if ((i1<i2&&i1<iN)); then
    local g
    ble/highlight/layer/getg "$i1"
    ble/color/g2sgr "$g"
    IFS= builtin eval "ret=\"\$ret\${$_ble_textarea_bufferName[*]:i1:i2-i1}\""
  else
    ret=
  fi
}
_ble_textarea_cur=(0 0 32 0)
_ble_textarea_panel=0
_ble_textarea_scroll=
_ble_textarea_scroll_new=
_ble_textarea_gendx=0
_ble_textarea_gendy=0
_ble_textarea_invalidated=1
function ble/textarea#invalidate {
  if [[ $1 == str ]]; then
    ((_ble_textarea_version++))
  else
    _ble_textarea_invalidated=1
  fi
}
function ble/textarea#render/.erase-forward-line.draw {
  local eraser=$_ble_term_el
  if [[ :$render_opts: == *:relative:* ]]; then
    local width=$((cols-x))
    if ((width==0)); then
      eraser=
    elif [[ $_ble_term_ech ]]; then
      eraser=${_ble_term_ech//'%d'/$width}
    else
      ble/string#reserve-prototype "$width"
      eraser=${_ble_string_prototype::width}${_ble_term_cub//'%d'/$width}
    fi
  fi
  ble/canvas/put.draw "$eraser"
}
function ble/textarea#render/.determine-scroll {
  local nline=$((endy+1))
  if ((nline>height)); then
    ((scroll<=nline-height)) || ((scroll=nline-height))
    local _height=$((height-begy)) _nline=$((nline-begy)) _cy=$((cy-begy))
    local margin=$((_height>=6&&_nline>_height+2?2:1))
    local smin smax
    ((smin=_cy-_height+margin,
      smin>nline-height&&(smin=nline-height),
      smax=_cy-margin,
      smax<0&&(smax=0)))
    if ((scroll>smax)); then
      scroll=$smax
    elif ((scroll<smin)); then
      scroll=$smin
    fi
    local wmin=0 wmax index
    if ((scroll)); then
      ble/textmap#get-index-at 0 $((scroll+begy+1)); wmin=$index
    fi
    ble/textmap#get-index-at "$cols" $((scroll+height-1)); wmax=$index
    ((umin<umax)) &&
      ((umin<wmin&&(umin=wmin),
        umax>wmax&&(umax=wmax)))
  else
    scroll=
    height=$nline
  fi
}
function ble/textarea#render/.perform-scroll {
  local new_scroll=$1
  if ((new_scroll!=_ble_textarea_scroll)); then
    local scry=$((begy+1))
    local scrh=$((height-scry))
    local fmin fmax index
    if ((_ble_textarea_scroll>new_scroll)); then
      local shift=$((_ble_textarea_scroll-new_scroll))
      local draw_shift=$((shift<scrh?shift:scrh))
      ble/canvas/panel#goto.draw "$_ble_textarea_panel" 0 $((height-draw_shift))
      ble/canvas/put-dl.draw "$draw_shift"
      ble/canvas/panel#goto.draw "$_ble_textarea_panel" 0 "$scry"
      ble/canvas/put-il.draw "$draw_shift"
      if ((new_scroll==0)); then
        fmin=0
      else
        ble/textmap#get-index-at 0 $((scry+new_scroll)); fmin=$index
      fi
      ble/textmap#get-index-at "$cols" $((scry+new_scroll+draw_shift-1)); fmax=$index
    else
      local shift=$((new_scroll-_ble_textarea_scroll))
      local draw_shift=$((shift<scrh?shift:scrh))
      ble/canvas/panel#goto.draw "$_ble_textarea_panel" 0 "$scry"
      ble/canvas/put-dl.draw "$draw_shift"
      ble/canvas/panel#goto.draw "$_ble_textarea_panel" 0 $((height-draw_shift))
      ble/canvas/put-il.draw "$draw_shift"
      ble/textmap#get-index-at 0 $((new_scroll+height-draw_shift)); fmin=$index
      ble/textmap#get-index-at "$cols" $((new_scroll+height-1)); fmax=$index
    fi
    if ((fmin<fmax)); then
      local fmaxx fmaxy fminx fminy
      ble/textmap#getxy.out --prefix=fmin "$fmin"
      ble/textmap#getxy.out --prefix=fmax "$fmax"
      ble/canvas/panel#goto.draw "$_ble_textarea_panel" "$fminx" $((fminy-new_scroll))
      ((new_scroll==0)) &&
        x=$fminx ble/textarea#render/.erase-forward-line.draw # ... を消す
      local ret; ble/textarea#slice-text-buffer "$fmin" "$fmax"
      ble/canvas/put.draw "$ret"
      ((_ble_canvas_x=fmaxx,
        _ble_canvas_y+=fmaxy-fminy))
      ((umin<umax)) &&
        ((fmin<=umin&&umin<fmax&&(umin=fmax),
          fmin<umax&&umax<=fmax&&(umax=fmin)))
    fi
    _ble_textarea_scroll=$new_scroll
    ble/textarea#render/.show-scroll-at-first-line
  fi
}
function ble/textarea#render/.show-scroll-at-first-line {
  if ((_ble_textarea_scroll!=0)); then
    ble/canvas/panel#goto.draw "$_ble_textarea_panel" "$begx" "$begy"
    local scroll_status="(line $((_ble_textarea_scroll+2))) ..."
    scroll_status=${scroll_status::cols-1-begx}
    x=$begx ble/textarea#render/.erase-forward-line.draw
    ble/canvas/put.draw "$eraser$_ble_term_bold$scroll_status$_ble_term_sgr0"
    ((_ble_canvas_x+=${#scroll_status}))
  fi
}
function ble/textarea#render/.erase-rps1 {
  local rps1_height=${_ble_edit_rprompt_bbox[3]}
  local -a DRAW_BUFF=()
  local y=0
  for ((y=0;y<rps1_height;y++)); do
    ble/canvas/panel#goto.draw "$_ble_textarea_panel" $((cols+1)) "$y"
    ble/canvas/put.draw "$_ble_term_el"
  done
  ble/canvas/bflush.draw
}
function ble/textarea#render/.cleanup-trailing-spaces-after-newline {
  local -a DRAW_BUFF=()
  local -a buffer; ble/string#split-lines buffer "$text"
  local line index=0 pos
  for line in "${buffer[@]}"; do
    ((index+=${#line}))
    ble/string#split-words pos "${_ble_textmap_pos[index]}"
    ble/canvas/panel#goto.draw "$_ble_textarea_panel" "${pos[0]}" "${pos[1]}"
    ble/canvas/put.draw "$_ble_term_el"
    ((index++))
  done
  ble/canvas/bflush.draw
}
function ble/textarea#focus {
  local -a DRAW_BUFF=()
  ble/canvas/panel#goto.draw "$_ble_textarea_panel" "${_ble_textarea_cur[0]}" "${_ble_textarea_cur[1]}"
  ble/canvas/bflush.draw
}
_ble_textarea_caret_state=::
_ble_textarea_version=0
function ble/textarea#render {
  local opts=$1
  local ble_textarea_render_flag=1 # ble/textarea/panel#on-height-change から参照する
  local caret_state=$_ble_textarea_version:$_ble_edit_ind:$_ble_edit_mark:$_ble_edit_mark_active:$_ble_edit_line_disabled:$_ble_edit_overwrite_mode
  local dirty=
  if ((_ble_edit_dirty_draw_beg>=0)); then
    dirty=1
  elif [[ $_ble_textarea_invalidated ]]; then
    dirty=1
  elif [[ $_ble_textarea_caret_state != "$caret_state" ]]; then
    dirty=1
  elif [[ $_ble_textarea_scroll != "$_ble_textarea_scroll_new" ]]; then
    dirty=1
  elif [[ :$opts: == *:leave:* ]]; then
    dirty=1
  fi
  if [[ ! $dirty ]]; then
    ble/textarea#focus
    return
  fi
  local ret
  local cols=${COLUMNS-80}
  local rps1_enabled=; [[ $bleopt_rps1 ]] && ((_ble_textarea_panel==0)) && rps1_enabled=1
  local rps1_clear=
  if [[ $rps1_enabled && :$opts: == *:leave:* && $bleopt_rps1_transient ]]; then
    local rps1_width=${_ble_edit_rprompt_bbox[2]}
    if ((rps1_width&&20+rps1_width<cols&&prox+10+rps1_width<cols)); then
      rps1_clear=1
      ((cols-=rps1_width+1,_ble_term_xenl||cols--))
      ble/textarea#render/.erase-rps1
    fi
  fi
  local x y g lc lg=0
  ble-edit/prompt/update # x y lc ret
  local prox=$x proy=$y prolc=$lc esc_prompt=$ret
  local rps1_show=
  if [[ $rps1_enabled && ! $rps1_clear ]]; then
    local rps1_width=${_ble_edit_rprompt_bbox[2]}
    ((rps1_width&&20+rps1_width<cols&&prox+10+rps1_width<cols)) &&
      ((rps1_show=1,cols-=rps1_width+1,_ble_term_xenl||cols--))
  fi
  local -a BLELINE_RANGE_UPDATE
  BLELINE_RANGE_UPDATE=("$_ble_edit_dirty_draw_beg" "$_ble_edit_dirty_draw_end" "$_ble_edit_dirty_draw_end0")
  ble/dirty-range#clear --prefix=_ble_edit_dirty_draw_
  local text=$_ble_edit_str index=$_ble_edit_ind
  local iN=${#text}
  ((index<0?(index=0):(index>iN&&(index=iN))))
  local umin=-1 umax=-1
  local render_opts=
  [[ $rps1_show ]] && render_opts=relative
  COLUMNS=$cols ble/textmap#update "$text" "$render_opts"
  ble/urange#update "$_ble_textmap_umin" "$_ble_textmap_umax"
  ble/urange#clear --prefix=_ble_textmap_
  ble/textarea#update-text-buffer # text index -> lc lg
  local -a DRAW_BUFF=()
  ble/canvas/panel#reallocate-height.draw
  local begx=$_ble_textmap_begx begy=$_ble_textmap_begy
  local endx=$_ble_textmap_endx endy=$_ble_textmap_endy
  local cx cy
  ble/textmap#getxy.cur --prefix=c "$index" # → cx cy
  local cols=$_ble_textmap_cols
  local height=${_ble_canvas_panel_height[_ble_textarea_panel]}
  local scroll=${_ble_textarea_scroll_new:-$_ble_textarea_scroll}
  ble/textarea#render/.determine-scroll # update: height scroll umin umax
  ble/canvas/panel#set-height.draw "$_ble_textarea_panel" "$height"
  local gend gendx gendy
  if [[ $scroll ]]; then
    ble/textmap#get-index-at "$cols" $((height+scroll-1)); gend=$index
    ble/textmap#getxy.out --prefix=gend "$gend"
    ((gendy-=scroll))
  else
    gend=$iN gendx=$endx gendy=$endy
  fi
  _ble_textarea_gendx=$gendx _ble_textarea_gendy=$gendy
  [[ $rps1_clear ]] &&
    ble/textarea#render/.cleanup-trailing-spaces-after-newline
  local ret esc_line= esc_line_set=
  if [[ ! $_ble_textarea_invalidated ]]; then
    ble/textarea#render/.perform-scroll "$scroll" # update: umin umax
    _ble_textarea_scroll_new=$_ble_textarea_scroll
    if ((umin<umax)); then
      local uminx uminy umaxx umaxy
      ble/textmap#getxy.out --prefix=umin "$umin"
      ble/textmap#getxy.out --prefix=umax "$umax"
      ble/canvas/panel#goto.draw "$_ble_textarea_panel" "$uminx" $((uminy-_ble_textarea_scroll))
      ble/textarea#slice-text-buffer "$umin" "$umax"
      ble/canvas/panel#put.draw "$_ble_textarea_panel" "$ret" "$umaxx" $((umaxy-_ble_textarea_scroll))
    fi
    if ((BLELINE_RANGE_UPDATE[0]>=0)); then
      local endY=$((endy-_ble_textarea_scroll))
      if ((endY<height)); then
        if [[ :$render_opts: == *:relative:* ]]; then
          ble/canvas/panel#goto.draw "$_ble_textarea_panel" "$endx" "$endY"
          x=$endx ble/textarea#render/.erase-forward-line.draw
          ble/canvas/panel#clear-after.draw "$_ble_textarea_panel" 0 $((endY+1))
        else
          ble/canvas/panel#clear-after.draw "$_ble_textarea_panel" "$endx" "$endY"
        fi
      fi
    fi
  else
    ble/canvas/panel#clear.draw "$_ble_textarea_panel"
    ble/canvas/panel#goto.draw "$_ble_textarea_panel"
    if [[ $rps1_show ]]; then
      local rps1out=${_ble_edit_rprompt[6]}
      local rps1x=${_ble_edit_rprompt[1]} rps1y=${_ble_edit_rprompt[2]}
      ble/canvas/panel#goto.draw "$_ble_textarea_panel" $((cols+1)) 0
      ble/canvas/panel#put.draw "$_ble_textarea_panel" "$rps1out" $((cols+1+rps1x)) "$rps1y"
      ble/canvas/panel#goto.draw "$_ble_textarea_panel" 0 0
    fi
    ble/canvas/panel#put.draw "$_ble_textarea_panel" "$esc_prompt" "$prox" "$proy"
    _ble_textarea_scroll=$scroll
    _ble_textarea_scroll_new=$_ble_textarea_scroll
    if [[ ! $_ble_textarea_scroll ]]; then
      ble/textarea#slice-text-buffer # → ret
      esc_line=$ret esc_line_set=1
      ble/canvas/panel#put.draw "$_ble_textarea_panel" "$ret" "$_ble_textarea_gendx" "$_ble_textarea_gendy"
    else
      ble/textarea#render/.show-scroll-at-first-line
      local gbeg=0
      if ((_ble_textarea_scroll)); then
        ble/textmap#get-index-at 0 $((_ble_textarea_scroll+begy+1)); gbeg=$index
      fi
      local gbegx gbegy
      ble/textmap#getxy.out --prefix=gbeg "$gbeg"
      ((gbegy-=_ble_textarea_scroll))
      ble/canvas/panel#goto.draw "$_ble_textarea_panel" "$gbegx" "$gbegy"
      ((_ble_textarea_scroll==0)) &&
        x=$gbegx ble/textarea#render/.erase-forward-line.draw # ... を消す
      ble/textarea#slice-text-buffer "$gbeg" "$gend"
      ble/canvas/panel#put.draw "$_ble_textarea_panel" "$ret" "$_ble_textarea_gendx" "$_ble_textarea_gendy"
    fi
  fi
  local gcx=$cx gcy=$((cy-_ble_textarea_scroll))
  ble/canvas/panel#goto.draw "$_ble_textarea_panel" "$gcx" "$gcy"
  ble/canvas/bflush.draw
  _ble_textarea_cur=("$gcx" "$gcy" "$lc" "$lg")
  _ble_textarea_invalidated= _ble_textarea_caret_state=$caret_state
  if [[ ! $bleopt_internal_suppress_bash_output ]]; then
    if [[ ! $esc_line_set ]]; then
      if [[ ! $_ble_textarea_scroll ]]; then
        ble/textarea#slice-text-buffer
        esc_line=$ret
      else
        local _ble_canvas_x=$begx _ble_canvas_y=$begy
        DRAW_BUFF=()
        ble/textarea#render/.show-scroll-at-first-line
        local gbeg=0
        if ((_ble_textarea_scroll)); then
          ble/textmap#get-index-at 0 $((_ble_textarea_scroll+begy+1)); gbeg=$index
        fi
        local gbegx gbegy
        ble/textmap#getxy.out --prefix=gbeg "$gbeg"
        ((gbegy-=_ble_textarea_scroll))
        ble/canvas/panel#goto.draw "$_ble_textarea_panel" "$gbegx" "$gbegy"
        ((_ble_textarea_scroll==0)) &&
          x=$gbegx ble/textarea#render/.erase-forward-line.draw # ... を消す
        ble/textarea#slice-text-buffer "$gbeg" "$gend"
        ble/canvas/put.draw "$ret"
        ble/canvas/sflush.draw -v esc_line
      fi
    fi
    _ble_textarea_cache=(
      "$esc_prompt$esc_line"
      "${_ble_textarea_cur[@]}"
      "$_ble_textarea_gendx" "$_ble_textarea_gendy")
  fi
}
function ble/textarea#redraw {
  ble/textarea#invalidate
  ble/textarea#render
}
_ble_textarea_cache=()
function ble/textarea#redraw-cache {
  if [[ ! $_ble_textarea_scroll && ${_ble_textarea_cache[0]+set} ]]; then
    local -a d; d=("${_ble_textarea_cache[@]}")
    local -a DRAW_BUFF=()
    ble/canvas/panel#clear.draw "$_ble_textarea_panel"
    ble/canvas/panel#goto.draw "$_ble_textarea_panel"
    ble/canvas/put.draw "${d[0]}"
    ble/canvas/panel#report-cursor-position "$_ble_textarea_panel" "${d[5]}" "${d[6]}"
    _ble_textarea_gendx=${d[5]}
    _ble_textarea_gendy=${d[6]}
    _ble_textarea_cur=("${d[@]:1:4}")
    ble/canvas/panel#goto.draw "$_ble_textarea_panel" "${_ble_textarea_cur[0]}" "${_ble_textarea_cur[1]}"
    ble/canvas/bflush.draw
  else
    ble/textarea#redraw
  fi
}
function ble/textarea#adjust-for-bash-bind {
  if [[ $bleopt_internal_suppress_bash_output ]]; then
    PS1= READLINE_LINE=$'\n' READLINE_POINT=0
  else
    local -a DRAW_BUFF=()
    PS1=
    local ret lc=${_ble_textarea_cur[2]} lg=${_ble_textarea_cur[3]}
    ble/util/c2s "$lc"
    READLINE_LINE=$ret
    if ((_ble_textarea_cur[0]==0)); then
      READLINE_POINT=0
    else
      ble/util/c2w "$lc"
      ((ret>0)) && ble/canvas/put-cub.draw "$ret"
      ble/util/c2bc "$lc"
      READLINE_POINT=$ret
    fi
    ble/color/g2sgr "$lg"
    ble/canvas/put.draw "$ret"
  fi
}
function ble/textarea#save-state {
  local prefix=$1
  local -a vars=() arrs=()
  ble/array#push arrs _ble_edit_prompt
  ble/array#push vars _ble_edit_PS1
  ble/array#push vars "${_ble_edit_VARNAMES[@]}"
  ble/array#push arrs "${_ble_edit_ARRNAMES[@]}"
  ble/array#push vars "${_ble_edit_undo_VARNAMES[@]}"
  ble/array#push arrs "${_ble_edit_undo_ARRNAMES[@]}"
  ble/array#push vars "${_ble_textmap_VARNAMES[@]}"
  ble/array#push arrs "${_ble_textmap_ARRNAMES[@]}"
  ble/array#push arrs _ble_highlight_layer__list
  local layer names
  for layer in "${_ble_highlight_layer__list[@]}"; do
    eval "names=(\"\${!_ble_highlight_layer_$layer@}\")"
    for name in "${names[@]}"; do
      if ble/is-array "$name"; then
        ble/array#push arrs "$name"
      else
        ble/array#push vars "$name"
      fi
    done
  done
  ble/array#push vars "${_ble_textarea_VARNAMES[@]}"
  ble/array#push arrs "${_ble_textarea_ARRNAMES[@]}"
  ble/array#push vars "${_ble_syntax_VARNAMES[@]}"
  ble/array#push arrs "${_ble_syntax_ARRNAMES[@]}"
  eval "${prefix}_VARNAMES=(\"\${vars[@]}\")"
  eval "${prefix}_ARRNAMES=(\"\${arrs[@]}\")"
  ble/util/save-vars "$prefix" "${vars[@]}"
  ble/util/save-arrs "$prefix" "${arrs[@]}"
}
function ble/textarea#restore-state {
  local prefix=$1
  if eval "[[ \$prefix && \${${prefix}_VARNAMES+set} && \${${prefix}_ARRNAMES+set} ]]"; then
    eval "ble/util/restore-vars $prefix \"\${${prefix}_VARNAMES[@]}\""
    eval "ble/util/restore-arrs $prefix \"\${${prefix}_ARRNAMES[@]}\""
  else
    echo "ble/textarea#restore-state: unknown prefix '$prefix'." >&2
    return 1
  fi
}
function ble/textarea#clear-state {
  local prefix=$1
  if [[ $prefix ]]; then
    local vars=${prefix}_VARNAMES arrs=${prefix}_ARRNAMES
    eval "unset -v \"\${$vars[@]/#/$prefix}\" \"\${$arrs[@]/#/$prefix}\" $vars $arrs"
  else
    echo "ble/textarea#restore-state: unknown prefix '$prefix'." >&2
    return 1
  fi
}
function ble/widget/.update-textmap {
  local text=$_ble_edit_str x=$_ble_textmap_begx y=$_ble_textmap_begy
  ble/textmap#update "$text"
}
function ble/widget/redraw-line {
  ble-edit/content/clear-arg
  ble/textarea#invalidate
}
function ble/widget/clear-screen {
  ble-edit/content/clear-arg
  ble-edit/info/hide
  ble/textarea#invalidate
  ble/util/buffer "$_ble_term_clear"
  _ble_canvas_x=0 _ble_canvas_y=0
  ble/term/visible-bell/cancel-erasure
}
function ble/widget/display-shell-version {
  ble-edit/content/clear-arg
  ble/widget/print "GNU bash, version $BASH_VERSION ($MACHTYPE) with ble.sh"
}
function ble/widget/overwrite-mode {
  ble-edit/content/clear-arg
  if [[ $_ble_edit_overwrite_mode ]]; then
    _ble_edit_overwrite_mode=
  else
    _ble_edit_overwrite_mode=1
  fi
}
function ble/widget/set-mark {
  ble-edit/content/clear-arg
  _ble_edit_mark=$_ble_edit_ind
  _ble_edit_mark_active=1
}
function ble/widget/kill-forward-text {
  ble-edit/content/clear-arg
  ((_ble_edit_ind>=${#_ble_edit_str})) && return
  _ble_edit_kill_ring=${_ble_edit_str:_ble_edit_ind}
  _ble_edit_kill_type=
  ble-edit/content/replace "$_ble_edit_ind" ${#_ble_edit_str} ''
  ((_ble_edit_mark>_ble_edit_ind&&(_ble_edit_mark=_ble_edit_ind)))
}
function ble/widget/kill-backward-text {
  ble-edit/content/clear-arg
  ((_ble_edit_ind==0)) && return
  _ble_edit_kill_ring=${_ble_edit_str::_ble_edit_ind}
  _ble_edit_kill_type=
  ble-edit/content/replace 0 "$_ble_edit_ind" ''
  ((_ble_edit_mark=_ble_edit_mark<=_ble_edit_ind?0:_ble_edit_mark-_ble_edit_ind))
  _ble_edit_ind=0
}
function ble/widget/exchange-point-and-mark {
  ble-edit/content/clear-arg
  local m=$_ble_edit_mark p=$_ble_edit_ind
  _ble_edit_ind=$m _ble_edit_mark=$p
}
function ble/widget/yank {
  ble-edit/content/clear-arg
  ble/widget/.insert-string "$_ble_edit_kill_ring"
}
function ble/widget/@marked {
  if [[ $_ble_edit_mark_active != S ]]; then
    _ble_edit_mark=$_ble_edit_ind
    _ble_edit_mark_active=S
  fi
  "ble/widget/$@"
}
function ble/widget/@nomarked {
  if [[ $_ble_edit_mark_active == S ]]; then
    _ble_edit_mark_active=
  fi
  "ble/widget/$@"
}
function ble/widget/.process-range-argument {
  p0=$1 p1=$2 len=${#_ble_edit_str}
  local pt
  ((
    p0>len?(p0=len):p0<0&&(p0=0),
    p1>len?(p1=len):p0<0&&(p1=0),
    p1<p0&&(pt=p1,p1=p0,p0=pt),
    (len=p1-p0)>0
  ))
}
function ble/widget/.delete-range {
  local p0 p1 len
  ble/widget/.process-range-argument "${@:1:2}" || (($3)) || return 1
  if ((len)); then
    ble-edit/content/replace "$p0" "$p1" ''
    ((
      _ble_edit_ind>p1? (_ble_edit_ind-=len):
      _ble_edit_ind>p0&&(_ble_edit_ind=p0),
      _ble_edit_mark>p1? (_ble_edit_mark-=len):
      _ble_edit_mark>p0&&(_ble_edit_mark=p0)
    ))
  fi
  return 0
}
function ble/widget/.kill-range {
  local p0 p1 len
  ble/widget/.process-range-argument "${@:1:2}" || (($3)) || return 1
  _ble_edit_kill_ring=${_ble_edit_str:p0:len}
  _ble_edit_kill_type=$4
  if ((len)); then
    ble-edit/content/replace "$p0" "$p1" ''
    ((
      _ble_edit_ind>p1? (_ble_edit_ind-=len):
      _ble_edit_ind>p0&&(_ble_edit_ind=p0),
      _ble_edit_mark>p1? (_ble_edit_mark-=len):
      _ble_edit_mark>p0&&(_ble_edit_mark=p0)
    ))
  fi
  return 0
}
function ble/widget/.copy-range {
  local p0 p1 len
  ble/widget/.process-range-argument "${@:1:2}" || (($3)) || return 1
  _ble_edit_kill_ring=${_ble_edit_str:p0:len}
  _ble_edit_kill_type=$4
}
function ble/widget/.replace-range {
  local p0 p1 len
  ble/widget/.process-range-argument "${@:1:2}" || (($4)) || return 1
  local str=$3 strlen=${#3}
  ble-edit/content/replace "$p0" "$p1" "$str"
  local delta
  ((delta=strlen-len)) &&
    ((_ble_edit_ind>p1?(_ble_edit_ind+=delta):
      _ble_edit_ind>p0+strlen&&(_ble_edit_ind=p0+strlen),
      _ble_edit_mark>p1?(_ble_edit_mark+=delta):
      _ble_edit_mark>p0+strlen&&(_ble_edit_mark=p0+strlen)))
  return 0
}
function ble/widget/delete-region {
  ble-edit/content/clear-arg
  ble/widget/.delete-range "$_ble_edit_mark" "$_ble_edit_ind"
  _ble_edit_mark_active=
}
function ble/widget/kill-region {
  ble-edit/content/clear-arg
  ble/widget/.kill-range "$_ble_edit_mark" "$_ble_edit_ind"
  _ble_edit_mark_active=
}
function ble/widget/copy-region {
  ble-edit/content/clear-arg
  ble/widget/.copy-range "$_ble_edit_mark" "$_ble_edit_ind"
  _ble_edit_mark_active=
}
function ble/widget/delete-region-or {
  if [[ $_ble_edit_mark_active ]]; then
    ble/widget/delete-region
  else
    "ble/widget/delete-$@"
  fi
}
function ble/widget/kill-region-or {
  if [[ $_ble_edit_mark_active ]]; then
    ble/widget/kill-region
  else
    "ble/widget/kill-$@"
  fi
}
function ble/widget/copy-region-or {
  if [[ $_ble_edit_mark_active ]]; then
    ble/widget/copy-region
  else
    "ble/widget/copy-$@"
  fi
}
function ble/widget/.bell {
  [[ $bleopt_edit_vbell ]] && ble/term/visible-bell "$1"
  [[ $bleopt_edit_abell ]] && ble/term/audible-bell
  return 0
}
_ble_widget_bell_hook=()
function ble/widget/bell {
  ble-edit/content/clear-arg
  _ble_edit_mark_active=
  _ble_edit_arg=
  ble/util/invoke-hook _ble_widget_bell_hook
  ble/widget/.bell "$1"
}
function ble/widget/nop { :; }
function ble/widget/insert-string {
  local content="$*"
  local arg; ble-edit/content/get-arg 1
  if ((arg<0)); then
    ble/widget/.bell "negative repetition number $arg"
    return 1
  elif ((arg==0)); then
    return 0
  elif ((arg>1)); then
    local ret; ble/string#repeat "$content" "$arg"; content=$ret
  fi
  ble/widget/.insert-string "$content"
}
function ble/widget/.insert-string {
  local ins="$*"
  [[ $ins ]] || return
  local dx=${#ins}
  ble-edit/content/replace "$_ble_edit_ind" "$_ble_edit_ind" "$ins"
  ((
    _ble_edit_mark>_ble_edit_ind&&(_ble_edit_mark+=dx),
    _ble_edit_ind+=dx
  ))
  _ble_edit_mark_active=
}
function ble/widget/self-insert {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  ((code==0)) && return
  local ibeg=$_ble_edit_ind iend=$_ble_edit_ind
  local ret ins; ble/util/c2s "$code"; ins=$ret
  local arg; ble-edit/content/get-arg 1
  if ((arg<0)); then
    ble/widget/.bell "negative repetition number $arg"
    return 1
  elif ((arg==0)) || [[ ! $ins ]]; then
    arg=0 ins=
  elif ((arg>1)); then
    ble/string#repeat "$ins" "$arg"; ins=$ret
  fi
  if [[ $bleopt_delete_selection_mode && $_ble_edit_mark_active ]]; then
    ((_ble_edit_mark<_ble_edit_ind?(ibeg=_ble_edit_mark):(iend=_ble_edit_mark),
      _ble_edit_ind=ibeg))
    ((arg==0&&ibeg==iend)) && return
  elif [[ $_ble_edit_overwrite_mode ]] && ((code!=10&&code!=9)); then
    ((arg==0)) && return
    local removed_width
    if [[ $_ble_edit_overwrite_mode == R ]]; then
      local removed_text=${_ble_edit_str:ibeg:arg}
      removed_text=${removed_text%%[$'\n\t']*}
      removed_width=${#removed_text}
      ((iend+=removed_width))
    else
      local ret w; ble/util/c2w-edit "$code"; w=$((arg*ret))
      local iN=${#_ble_edit_str}
      for ((removed_width=0;removed_width<w&&iend<iN;iend++)); do
        local c1 w1
        ble/util/s2c "$_ble_edit_str" "$iend"; c1=$ret
        [[ $c1 == 0 || $c1 == 10 || $c1 == 9 ]] && break
        ble/util/c2w-edit "$c1"; w1=$ret
        ((removed_width+=w1))
      done
      ((removed_width>w)) && ins=$ins${_ble_string_prototype::removed_width-w}
    fi
    if [[ :$ble_widget_self_insert_opts: == *:nolineext:* ]]; then
      if ((removed_width<arg)); then
        ble/widget/.bell
        return 0
      fi
    fi
  fi
  ble-edit/content/replace "$ibeg" "$iend" "$ins"
  ((_ble_edit_ind+=${#ins},
    _ble_edit_mark>ibeg&&(
      _ble_edit_mark<iend?(
        _ble_edit_mark=_ble_edit_ind
      ):(
        _ble_edit_mark+=${#ins}-(iend-ibeg)))))
  _ble_edit_mark_active=
  return 0
}
function ble/widget/batch-insert {
  local -a chars; chars=("${KEYS[@]}")
  if [[ $_ble_edit_overwrite_mode ]]; then
    local -a KEYS=(0)
    local char
    for char in "${chars[@]}"; do
      KEYS=$char ble/widget/self-insert
    done
  else
    local index=0 N=${#chars[@]}
    while ((index<N)) && [[ $_ble_edit_arg || $_ble_edit_mark_active ]]; do
      KEYS=${chars[index]} ble/widget/self-insert
      ((index++))
    done
    if ((index<N)); then
      local ret ins=
      while ((index<N)); do
        ble/util/c2s "${chars[index]}"; ins=$ins$ret
        ((index++))
      done
      ble/widget/insert-string "$ins"
    fi
  fi
}
function ble/widget/quoted-insert.hook {
  ble/widget/self-insert
}
function ble/widget/quoted-insert {
  _ble_edit_mark_active=
  _ble_decode_char__hook=ble/widget/quoted-insert.hook
  return 148
}
function ble/widget/transpose-chars {
  local arg; ble-edit/content/get-arg ''
  if ((arg==0)); then
    [[ ! $arg ]] && ble-edit/content/eolp &&
      ((_ble_edit_ind>0&&_ble_edit_ind--))
    arg=1
  fi
  local p q r
  if ((arg>0)); then
    ((p=_ble_edit_ind-1,
      q=_ble_edit_ind,
      r=_ble_edit_ind+arg))
  else # arg<0
    ((p=_ble_edit_ind-1+arg,
      q=_ble_edit_ind,
      r=_ble_edit_ind+1))
  fi
  if ((p<0||${#_ble_edit_str}<r)); then
    ((_ble_edit_ind=arg<0?0:${#_ble_edit_str}))
    ble/widget/.bell
    return 1
  fi
  local a=${_ble_edit_str:p:q-p}
  local b=${_ble_edit_str:q:r-q}
  ble-edit/content/replace "$p" "$r" "$b$a"
  ((_ble_edit_ind+=arg))
  return 0
}
_ble_edit_bracketed_paste=
_ble_edit_bracketed_paste_proc=
function ble/widget/bracketed-paste {
  ble-edit/content/clear-arg
  _ble_edit_mark_active=
  _ble_edit_bracketed_paste=()
  _ble_edit_bracketed_paste_proc=ble/widget/bracketed-paste.proc
  _ble_decode_char__hook=ble/widget/bracketed-paste.hook
  return 148
}
function ble/widget/bracketed-paste.hook {
  _ble_edit_bracketed_paste=$_ble_edit_bracketed_paste:$1
  local is_end= chars=
  if chars=${_ble_edit_bracketed_paste%:27:91:50:48:49:126} # ESC [ 2 0 1 ~
     [[ $chars != "$_ble_edit_bracketed_paste" ]]; then is_end=1
  elif chars=${_ble_edit_bracketed_paste%:155:50:48:49:126} # CSI 2 0 1 ~
       [[ $chars != "$_ble_edit_bracketed_paste" ]]; then is_end=1
  fi
  if [[ ! $is_end ]]; then
    _ble_decode_char__hook=ble/widget/bracketed-paste.hook
    return 148
  fi
  chars=$chars:
  chars=${chars//:13:10:/:10:} # CR LF -> LF
  chars=${chars//:13:/:10:} # CR -> LF
  chars=(${chars//:/' '})
  local proc=$_ble_edit_bracketed_paste_proc
  _ble_edit_bracketed_paste_proc=
  [[ $proc ]] && builtin eval -- "$proc \"\${chars[@]}\""
}
function ble/widget/bracketed-paste.proc {
  local -a KEYS; KEYS=("$@")
  ble/widget/batch-insert
}
function ble/widget/.delete-backward-char {
  local a=${1:-1}
  if ((_ble_edit_ind-a<0)); then
    return 1
  fi
  local ins=
  if [[ $_ble_edit_overwrite_mode ]]; then
    local next=${_ble_edit_str:_ble_edit_ind:1}
    if [[ $next && $next != [$'\n\t'] ]]; then
      if [[ $_ble_edit_overwrite_mode == R ]]; then
        local w=$a
      else
        local w=0 ret i
        for ((i=0;i<a;i++)); do
          ble/util/s2c "$_ble_edit_str" $((_ble_edit_ind-a+i))
          ble/util/c2w-edit "$ret"
          ((w+=ret))
        done
      fi
      if ((w)); then
        local ret; ble/string#repeat ' ' "$w"; ins=$ret
        ((_ble_edit_mark>=_ble_edit_ind&&(_ble_edit_mark+=w)))
      fi
    fi
  fi
  ble-edit/content/replace $((_ble_edit_ind-a)) "$_ble_edit_ind" "$ins"
  ((_ble_edit_ind-=a,
    _ble_edit_ind+a<_ble_edit_mark?(_ble_edit_mark-=a):
    _ble_edit_ind<_ble_edit_mark&&(_ble_edit_mark=_ble_edit_ind)))
  return 0
}
function ble/widget/.delete-char {
  local a=${1:-1}
  if ((a>0)); then
    if ((${#_ble_edit_str}<_ble_edit_ind+a)); then
      return 1
    else
      ble-edit/content/replace "$_ble_edit_ind" $((_ble_edit_ind+a)) ''
    fi
  elif ((a<0)); then
    ble/widget/.delete-backward-char $((-a))
    return
  else
    if ((${#_ble_edit_str}==0)); then
      return 1
    elif ((_ble_edit_ind<${#_ble_edit_str})); then
      ble-edit/content/replace "$_ble_edit_ind" $((_ble_edit_ind+1)) ''
    else
      _ble_edit_ind=${#_ble_edit_str}
      ble/widget/.delete-backward-char 1
      return
    fi
  fi
  ((_ble_edit_mark>_ble_edit_ind&&_ble_edit_mark--))
  return 0
}
function ble/widget/delete-forward-char {
  local arg; ble-edit/content/get-arg 1
  ((arg==0)) && return 0
  ble/widget/.delete-char "$arg" || ble/widget/.bell
}
function ble/widget/delete-backward-char {
  local arg; ble-edit/content/get-arg 1
  ((arg==0)) && return 0
  [[ $_ble_decode_keymap == vi_imap ]] && ble/keymap:vi/undo/add more
  ble/widget/.delete-char $((-arg)) || ble/widget/.bell
  [[ $_ble_decode_keymap == vi_imap ]] && ble/keymap:vi/undo/add more
}
_ble_edit_exit_count=0
function ble/widget/exit {
  ble-edit/content/clear-arg
  if [[ $WIDGET == "$LASTWIDGET" ]]; then
    ((_ble_edit_exit_count++))
  else
    _ble_edit_exit_count=1
  fi
  local ret; ble-edit/eval-IGNOREEOF
  if ((_ble_edit_exit_count<=ret)); then
    local remain=$((ret-_ble_edit_exit_count+1))
    ble/widget/.bell 'IGNOREEOF'
    ble/widget/print "IGNOREEOF($remain): Use \"exit\" to leave the shell."
    return
  fi
  local opts=$1
  ((_ble_bash>=40000)) && shopt -q checkjobs &>/dev/null && opts=$opts:checkjobs
  if [[ $bleopt_allow_exit_with_jobs ]]; then
    local ret
    if ble/util/assign ret 'compgen -A stopped -- ""' 2>/dev/null; [[ $ret ]]; then
      opts=$opts:twice
    elif [[ :$opts: == *:checkjobs:* ]]; then
      if ble/util/assign ret 'compgen -A running -- ""' 2>/dev/null; [[ $ret ]]; then
        opts=$opts:twice
      fi
    else
      opts=$opts:force
    fi
  fi
  if ! [[ :$opts: == *:force:* || :$opts: == *:twice:* && _ble_edit_exit_count -ge 2 ]]; then
    local joblist
    ble/util/joblist
    if ((${#joblist[@]})); then
      ble/widget/.bell "exit: There are remaining jobs."
      local q=\' Q="'\''" message=
      if [[ :$opts: == *:twice:* ]]; then
        message='There are remaining jobs. Input the same key to exit the shell anyway.'
      else
        message='There are remaining jobs. Use "exit" to leave the shell.'
      fi
      ble/widget/internal-command "echo '${_ble_term_setaf[12]}[ble: ${message//$q/$Q}]$_ble_term_sgr0'; jobs"
      return
    fi
  elif [[ :$opts: == *:checkjobs:* ]]; then
    local joblist
    ble/util/joblist
    ((${#joblist[@]})) && printf '%s\n' "${#joblist[@]}"
  fi
  _ble_edit_line_disabled=1 ble/textarea#render
  ble-edit/info/hide
  local -a DRAW_BUFF=()
  ble/canvas/panel#goto.draw "$_ble_textarea_panel" "$_ble_textarea_gendx" "$_ble_textarea_gendy"
  ble/canvas/bflush.draw
  ble/util/buffer.print "${_ble_term_setaf[12]}[ble: exit]$_ble_term_sgr0"
  ble/util/buffer.flush >&2
  builtin exit 0 &>/dev/null
  builtin exit 0 &>/dev/null
  return 1
}
function ble/widget/delete-forward-char-or-exit {
  if [[ $_ble_edit_str ]]; then
    ble/widget/delete-forward-char
    return
  else
    ble/widget/exit
  fi
}
function ble/widget/delete-forward-backward-char {
  ble-edit/content/clear-arg
  ble/widget/.delete-char 0 || ble/widget/.bell
}
function ble/widget/delete-horizontal-space {
  local arg; ble-edit/content/get-arg ''
  local b=0 rex=$'[ \t]+$'
  [[ ${_ble_edit_str::_ble_edit_ind} =~ $rex ]] &&
    b=${#BASH_REMATCH}
  local a=0 rex=$'^[ \t]+'
  [[ ! $arg && ${_ble_edit_str:_ble_edit_ind} =~ $rex ]] &&
    a=${#BASH_REMATCH}
  ble/widget/.delete-range $((_ble_edit_ind-b)) $((_ble_edit_ind+a))
}
function ble/widget/.forward-char {
  ((_ble_edit_ind+=${1:-1}))
  if ((_ble_edit_ind>${#_ble_edit_str})); then
    _ble_edit_ind=${#_ble_edit_str}
    return 1
  elif ((_ble_edit_ind<0)); then
    _ble_edit_ind=0
    return 1
  fi
}
function ble/widget/forward-char {
  local arg; ble-edit/content/get-arg 1
  ((arg==0)) && return
  ble/widget/.forward-char "$arg" || ble/widget/.bell
}
function ble/widget/backward-char {
  local arg; ble-edit/content/get-arg 1
  ((arg==0)) && return
  ble/widget/.forward-char $((-arg)) || ble/widget/.bell
}
function ble/widget/end-of-text {
  local arg; ble-edit/content/get-arg ''
  if [[ $arg ]]; then
    if ((arg>=10)); then
      _ble_edit_ind=0
    else
      ((arg<0&&(arg=0)))
      local index=$(((19-2*arg)*${#_ble_edit_str}/20))
      local ret; ble-edit/content/find-logical-bol "$index"
      _ble_edit_ind=$ret
    fi
  else
    _ble_edit_ind=${#_ble_edit_str}
  fi
}
function ble/widget/beginning-of-text {
  local arg; ble-edit/content/get-arg ''
  if [[ $arg ]]; then
    if ((arg>=10)); then
      _ble_edit_ind=${#_ble_edit_str}
    else
      ((arg<0&&(arg=0)))
      local index=$(((2*arg+1)*${#_ble_edit_str}/20))
      local ret; ble-edit/content/find-logical-bol "$index"
      _ble_edit_ind=$ret
    fi
  else
    _ble_edit_ind=0
  fi
}
function ble/widget/beginning-of-logical-line {
  local arg; ble-edit/content/get-arg 1
  local ret; ble-edit/content/find-logical-bol "$_ble_edit_ind" $((arg-1))
  _ble_edit_ind=$ret
}
function ble/widget/end-of-logical-line {
  local arg; ble-edit/content/get-arg 1
  local ret; ble-edit/content/find-logical-eol "$_ble_edit_ind" $((arg-1))
  _ble_edit_ind=$ret
}
function ble/widget/kill-backward-logical-line {
  local arg; ble-edit/content/get-arg ''
  if [[ $arg ]]; then
    local ret; ble-edit/content/find-logical-eol "$_ble_edit_ind" $((-arg)); local index=$ret
    if ((arg>0)); then
      if ((_ble_edit_ind<=index)); then
        index=0
      else
        ble/string#count-char "${_ble_edit_str:index:_ble_edit_ind-index}" $'\n'
        ((ret<arg)) && index=0
      fi
      [[ $flag_beg ]] && index=0
    fi
    ret=$index
  else
    local ret; ble-edit/content/find-logical-bol
    ((0<ret&&ret==_ble_edit_ind&&ret--))
  fi
  ble/widget/.kill-range "$ret" "$_ble_edit_ind"
}
function ble/widget/kill-forward-logical-line {
  local arg; ble-edit/content/get-arg ''
  if [[ $arg ]]; then
    local ret; ble-edit/content/find-logical-bol "$_ble_edit_ind" "$arg"; local index=$ret
    if ((arg>0)); then
      if ((index<=_ble_edit_ind)); then
        index=${#_ble_edit_str}
      else
        ble/string#count-char "${_ble_edit_str:_ble_edit_ind:index-_ble_edit_ind}" $'\n'
        ((ret<arg)) && index=${#_ble_edit_str}
      fi
    fi
    ret=$index
  else
    local ret; ble-edit/content/find-logical-eol
    ((ret<${#_ble_edit_ind}&&_ble_edit_ind==ret&&ret++))
  fi
  ble/widget/.kill-range "$_ble_edit_ind" "$ret"
}
function ble/widget/forward-history-line.impl {
  local arg=$1
  ((arg==0)) && return 0
  local rest=$((arg>0?arg:-arg))
  if ((arg>0)); then
    if [[ ! $_ble_edit_history_prefix && ! $_ble_edit_history_loaded ]]; then
      ble/widget/.bell 'end of history'
      return 1
    fi
  fi
  local index; ble-edit/history/get-index
  local expr_next='--index>=0'
  if ((arg>0)); then
    local count; ble-edit/history/get-count
    expr_next="++index<=$count"
  fi
  while ((expr_next)); do
    if ((--rest<=0)); then
      ble-edit/history/goto "$index" # 位置は goto に任せる
      return
    fi
    local entry; ble-edit/history/get-editted-entry "$index"
    if [[ $entry == *$'\n'* ]]; then
      local ret; ble/string#count-char "$entry" $'\n'
      if ((rest<=ret)); then
        ble-edit/history/goto "$index"
        if ((arg>0)); then
          ble-edit/content/find-logical-eol 0 "$rest"
        else
          ble-edit/content/find-logical-eol ${#entry} $((-rest))
        fi
        _ble_edit_ind=$ret
        return
      fi
      ((rest-=ret))
    fi
  done
  if ((arg>0)); then
    ble-edit/history/goto "$count"
    _ble_edit_ind=${#_ble_edit_str}
    ble/widget/.bell 'end of history'
  else
    ble-edit/history/goto 0
    _ble_edit_ind=0
    ble/widget/.bell 'beginning of history'
  fi
  return 0
}
function ble/widget/forward-logical-line.impl {
  local arg=$1 opts=$2
  ((arg==0)) && return 0
  local ind=$_ble_edit_ind
  if ((arg>0)); then
    ((ind<${#_ble_edit_str})) || return 1
  else
    ((ind>0)) || return 1
  fi
  local ret; ble-edit/content/find-logical-bol "$ind" "$arg"; local bol2=$ret
  if ((arg>0)); then
    if ((ind<bol2)); then
      ble/string#count-char "${_ble_edit_str:ind:bol2-ind}" $'\n'
      ((arg-=ret))
    fi
  else
    if ((ind>bol2)); then
      ble/string#count-char "${_ble_edit_str:bol2:ind-bol2}" $'\n'
      ((arg+=ret))
    fi
  fi
  if ((arg==0)); then
    ble-edit/content/find-logical-bol "$ind" ; local bol1=$ret
    ble-edit/content/find-logical-eol "$bol2"; local eol2=$ret
    local dst=$((bol2+ind-bol1))
    ((_ble_edit_ind=dst<eol2?dst:eol2))
    return 0
  fi
  if ((arg>0)); then
    ble-edit/content/find-logical-eol "$bol2"
  else
    ret=$bol2
  fi
  _ble_edit_ind=$ret
  if [[ :$opts: == *:history:* && ! $_ble_edit_mark_active ]]; then
    ble/widget/forward-history-line.impl "$arg"
    return
  fi
  if ((arg>0)); then
    ble/widget/.bell 'end of string'
  else
    ble/widget/.bell 'beginning of string'
  fi
  return 0
}
function ble/widget/forward-logical-line {
  local opts=$1
  local arg; ble-edit/content/get-arg 1
  ble/widget/forward-logical-line.impl "$arg" "$opts"
}
function ble/widget/backward-logical-line {
  local opts=$1
  local arg; ble-edit/content/get-arg 1
  ble/widget/forward-logical-line.impl $((-arg)) "$opts"
}
function ble/keymap:emacs/find-graphical-eol {
  local axis=${1:-$_ble_edit_ind} arg=${2:-0}
  local x y index
  ble/textmap#getxy.cur "$axis"
  ble/textmap#get-index-at 0 $((y+arg+1))
  if ((index>0)); then
    local ax ay
    ble/textmap#getxy.cur --prefix=a "$index"
    ((ay>y+arg&&index--))
  fi
  ret=$index
}
function ble/widget/beginning-of-graphical-line {
  ble/textmap#is-up-to-date || ble/widget/.update-textmap
  local arg; ble-edit/content/get-arg 1
  local x y index
  ble/textmap#getxy.cur "$_ble_edit_ind"
  ble/textmap#get-index-at 0 $((y+arg-1))
  _ble_edit_ind=$index
}
function ble/widget/end-of-graphical-line {
  ble/textmap#is-up-to-date || ble/widget/.update-textmap
  local arg; ble-edit/content/get-arg 1
  local ret; ble/keymap:emacs/find-graphical-eol "$_ble_edit_ind" $((arg-1))
  _ble_edit_ind=$ret
}
function ble/widget/kill-backward-graphical-line {
  ble/textmap#is-up-to-date || ble/widget/.update-textmap
  local arg; ble-edit/content/get-arg ''
  if [[ ! $arg ]]; then
    local x y index
    ble/textmap#getxy.cur "$_ble_edit_ind"
    ble/textmap#get-index-at 0 "$y"
    ((index==_ble_edit_ind&&index>0&&index--))
    ble/widget/.kill-range "$index" "$_ble_edit_ind"
  else
    local ret; ble/keymap:emacs/find-graphical-eol "$_ble_edit_ind" $((-arg))
    ble/widget/.kill-range "$ret" "$_ble_edit_ind"
  fi
}
function ble/widget/kill-forward-graphical-line {
  ble/textmap#is-up-to-date || ble/widget/.update-textmap
  local arg; ble-edit/content/get-arg ''
  local x y index ax ay
  ble/textmap#getxy.cur "$_ble_edit_ind"
  ble/textmap#get-index-at 0 $((y+${arg:-1}))
  if [[ ! $arg ]] && ((_ble_edit_ind<index-1)); then
    ble/textmap#getxy.cur --prefix=a "$index"
    ((ay>y&&index--))
  fi
  ble/widget/.kill-range "$_ble_edit_ind" "$index"
}
function ble/widget/forward-graphical-line.impl {
  ble/textmap#is-up-to-date || ble/widget/.update-textmap
  local arg=$1 opts=$2
  ((arg==0)) && return 0
  local x y index ax ay
  ble/textmap#getxy.cur "$_ble_edit_ind"
  ble/textmap#get-index-at "$x" $((y+arg))
  ble/textmap#getxy.cur --prefix=a "$index"
  ((arg-=ay-y))
  _ble_edit_ind=$index # 何れにしても移動は行う
  ((arg==0)) && return 0
  if [[ :$opts: == *:history:* && ! $_ble_edit_mark_active ]]; then
    ble/widget/forward-history-line.impl "$arg"
    return
  fi
  if ((arg>0)); then
    ble/widget/.bell 'end of string'
  else
    ble/widget/.bell 'beginning of string'
  fi
  return 0
}
function ble/widget/forward-graphical-line {
  local opts=$1
  local arg; ble-edit/content/get-arg 1
  ble/widget/forward-graphical-line.impl "$arg" "$opts"
}
function ble/widget/backward-graphical-line {
  local opts=$1
  local arg; ble-edit/content/get-arg 1
  ble/widget/forward-graphical-line.impl $((-arg)) "$opts"
}
function ble/widget/beginning-of-line {
  if ble/edit/use-textmap; then
    ble/widget/beginning-of-graphical-line
  else
    ble/widget/beginning-of-logical-line
  fi
}
function ble/widget/non-space-beginning-of-line {
  local old=$_ble_edit_ind
  ble/widget/beginning-of-logical-line
  local bol=$_ble_edit_ind ret=
  ble-edit/content/find-non-space "$bol"
  [[ $ret == $old ]] && ret=$bol # toggle
  _ble_edit_ind=$ret
  return 0
}
function ble/widget/end-of-line {
  if ble/edit/use-textmap; then
    ble/widget/end-of-graphical-line
  else
    ble/widget/end-of-logical-line
  fi
}
function ble/widget/kill-backward-line {
  if ble/edit/use-textmap; then
    ble/widget/kill-backward-graphical-line
  else
    ble/widget/kill-backward-logical-line
  fi
}
function ble/widget/kill-forward-line {
  if ble/edit/use-textmap; then
    ble/widget/kill-forward-graphical-line
  else
    ble/widget/kill-forward-logical-line
  fi
}
function ble/widget/forward-line {
  if ble/edit/use-textmap; then
    ble/widget/forward-graphical-line "$@"
  else
    ble/widget/forward-logical-line "$@"
  fi
}
function ble/widget/backward-line {
  if ble/edit/use-textmap; then
    ble/widget/backward-graphical-line "$@"
  else
    ble/widget/backward-logical-line "$@"
  fi
}
function ble/widget/.genword-setup-cword {
  WSET='_a-zA-Z0-9'; WSEP="^$WSET"
}
function ble/widget/.genword-setup-uword {
  WSEP="${IFS:-$' \t\n'}"; WSET="^$WSEP"
}
function ble/widget/.genword-setup-sword {
  WSEP=$'|%WSEP%;()<> \t\n'; WSET="^$WSEP"
}
function ble/widget/.genword-setup-fword {
  WSEP="/${IFS:-$' \t\n'}"; WSET="^$WSEP"
}
function ble/widget/.locate-backward-genword {
  local x=${1:-$_ble_edit_ind}
  c=${_ble_edit_str::x}; c=${c##*[$WSET]}; c=$((x-${#c}))
  b=${_ble_edit_str::c}; b=${b##*[$WSEP]}; b=$((c-${#b}))
  a=${_ble_edit_str::b}; a=${a##*[$WSET]}; a=$((b-${#a}))
}
function ble/widget/.locate-forward-genword {
  local x=${1:-$_ble_edit_ind}
  s=${_ble_edit_str:x}; s=${s%%[$WSET]*}; s=$((x+${#s}))
  t=${_ble_edit_str:s}; t=${t%%[$WSEP]*}; t=$((s+${#t}))
  u=${_ble_edit_str:t}; u=${u%%[$WSET]*}; u=$((t+${#u}))
}
function ble/widget/.locate-current-genword {
  local x=${1:-$_ble_edit_ind}
  local a b c # <a> *<b>w*<c> *<x>
  ble/widget/.locate-backward-genword
  r=$a
  ble/widget/.locate-forward-genword "$r"
}
function ble/widget/.delete-forward-genword {
  local x=${1:-$_ble_edit_ind} s t u
  ble/widget/.locate-forward-genword
  if ((x!=t)); then
    ble/widget/.delete-range "$x" "$t"
  else
    ble/widget/.bell
  fi
}
function ble/widget/.delete-backward-genword {
  local a b c x=${1:-$_ble_edit_ind}
  ble/widget/.locate-backward-genword
  if ((x>c&&(c=x),b!=c)); then
    [[ $_ble_decode_keymap == vi_imap ]] && ble/keymap:vi/undo/add more
    ble/widget/.delete-range "$b" "$c"
    [[ $_ble_decode_keymap == vi_imap ]] && ble/keymap:vi/undo/add more
  else
    ble/widget/.bell
  fi
}
function ble/widget/.delete-genword {
  local x=${1:-$_ble_edit_ind} r s t u
  ble/widget/.locate-current-genword "$x"
  if ((x>t&&(t=x),r!=t)); then
    ble/widget/.delete-range "$r" "$t"
  else
    ble/widget/.bell
  fi
}
function ble/widget/.kill-forward-genword {
  local x=${1:-$_ble_edit_ind} s t u
  ble/widget/.locate-forward-genword
  if ((x!=t)); then
    ble/widget/.kill-range "$x" "$t"
  else
    ble/widget/.bell
  fi
}
function ble/widget/.kill-backward-genword {
  local a b c x=${1:-$_ble_edit_ind}
  ble/widget/.locate-backward-genword
  if ((x>c&&(c=x),b!=c)); then
    ble/widget/.kill-range "$b" "$c"
  else
    ble/widget/.bell
  fi
}
function ble/widget/.kill-genword {
  local x=${1:-$_ble_edit_ind} r s t u
  ble/widget/.locate-current-genword "$x"
  if ((x>t&&(t=x),r!=t)); then
    ble/widget/.kill-range "$r" "$t"
  else
    ble/widget/.bell
  fi
}
function ble/widget/.copy-forward-genword {
  local x=${1:-$_ble_edit_ind} s t u
  ble/widget/.locate-forward-genword
  ble/widget/.copy-range "$x" "$t"
}
function ble/widget/.copy-backward-genword {
  local a b c x=${1:-$_ble_edit_ind}
  ble/widget/.locate-backward-genword
  ble/widget/.copy-range "$b" $((c>x?c:x))
}
function ble/widget/.copy-genword {
  local x=${1:-$_ble_edit_ind} r s t u
  ble/widget/.locate-current-genword "$x"
  ble/widget/.copy-range "$r" $((t>x?t:x))
}
function ble/widget/.forward-genword {
  local x=${1:-$_ble_edit_ind} s t u
  ble/widget/.locate-forward-genword "$x"
  if ((x==t)); then
    ble/widget/.bell
  else
    _ble_edit_ind=$t
  fi
}
function ble/widget/.backward-genword {
  local a b c x=${1:-$_ble_edit_ind}
  ble/widget/.locate-backward-genword "$x"
  if ((x==b)); then
    ble/widget/.bell
  else
    _ble_edit_ind=$b
  fi
}
function ble/widget/delete-forward-cword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-cword
  ble/widget/.delete-forward-genword "$@"
}
function ble/widget/delete-backward-cword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-cword
  ble/widget/.delete-backward-genword "$@"
}
function ble/widget/delete-cword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-cword
  ble/widget/.delete-genword "$@"
}
function ble/widget/kill-forward-cword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-cword
  ble/widget/.kill-forward-genword "$@"
}
function ble/widget/kill-backward-cword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-cword
  ble/widget/.kill-backward-genword "$@"
}
function ble/widget/kill-cword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-cword
  ble/widget/.kill-genword "$@"
}
function ble/widget/copy-forward-cword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-cword
  ble/widget/.copy-forward-genword "$@"
}
function ble/widget/copy-backward-cword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-cword
  ble/widget/.copy-backward-genword "$@"
}
function ble/widget/copy-cword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-cword
  ble/widget/.copy-genword "$@"
}
function ble/widget/delete-forward-uword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-uword
  ble/widget/.delete-forward-genword "$@"
}
function ble/widget/delete-backward-uword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-uword
  ble/widget/.delete-backward-genword "$@"
}
function ble/widget/delete-uword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-uword
  ble/widget/.delete-genword "$@"
}
function ble/widget/kill-forward-uword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-uword
  ble/widget/.kill-forward-genword "$@"
}
function ble/widget/kill-backward-uword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-uword
  ble/widget/.kill-backward-genword "$@"
}
function ble/widget/kill-uword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-uword
  ble/widget/.kill-genword "$@"
}
function ble/widget/copy-forward-uword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-uword
  ble/widget/.copy-forward-genword "$@"
}
function ble/widget/copy-backward-uword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-uword
  ble/widget/.copy-backward-genword "$@"
}
function ble/widget/copy-uword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-uword
  ble/widget/.copy-genword "$@"
}
function ble/widget/delete-forward-sword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-sword
  ble/widget/.delete-forward-genword "$@"
}
function ble/widget/delete-backward-sword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-sword
  ble/widget/.delete-backward-genword "$@"
}
function ble/widget/delete-sword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-sword
  ble/widget/.delete-genword "$@"
}
function ble/widget/kill-forward-sword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-sword
  ble/widget/.kill-forward-genword "$@"
}
function ble/widget/kill-backward-sword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-sword
  ble/widget/.kill-backward-genword "$@"
}
function ble/widget/kill-sword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-sword
  ble/widget/.kill-genword "$@"
}
function ble/widget/copy-forward-sword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-sword
  ble/widget/.copy-forward-genword "$@"
}
function ble/widget/copy-backward-sword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-sword
  ble/widget/.copy-backward-genword "$@"
}
function ble/widget/copy-sword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-sword
  ble/widget/.copy-genword "$@"
}
function ble/widget/delete-forward-fword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-fword
  ble/widget/.delete-forward-genword "$@"
}
function ble/widget/delete-backward-fword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-fword
  ble/widget/.delete-backward-genword "$@"
}
function ble/widget/delete-fword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-fword
  ble/widget/.delete-genword "$@"
}
function ble/widget/kill-forward-fword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-fword
  ble/widget/.kill-forward-genword "$@"
}
function ble/widget/kill-backward-fword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-fword
  ble/widget/.kill-backward-genword "$@"
}
function ble/widget/kill-fword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-fword
  ble/widget/.kill-genword "$@"
}
function ble/widget/copy-forward-fword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-fword
  ble/widget/.copy-forward-genword "$@"
}
function ble/widget/copy-backward-fword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-fword
  ble/widget/.copy-backward-genword "$@"
}
function ble/widget/copy-fword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-fword
  ble/widget/.copy-genword "$@"
}
function ble/widget/forward-cword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-cword
  ble/widget/.forward-genword "$@"
}
function ble/widget/backward-cword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-cword
  ble/widget/.backward-genword "$@"
}
function ble/widget/forward-uword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-uword
  ble/widget/.forward-genword "$@"
}
function ble/widget/backward-uword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-uword
  ble/widget/.backward-genword "$@"
}
function ble/widget/forward-sword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-sword
  ble/widget/.forward-genword "$@"
}
function ble/widget/backward-sword {
  ble-edit/content/clear-arg
  local WSET WSEP; ble/widget/.genword-setup-sword
  ble/widget/.backward-genword "$@"
}
_ble_edit_exec_lines=()
_ble_edit_exec_lastexit=0
_ble_edit_exec_lastarg=$BASH
function ble-edit/exec/register {
  local BASH_COMMAND=$1
  ble/array#push _ble_edit_exec_lines "$1"
}
function ble-edit/exec/.setexit {
  return "$_ble_edit_exec_lastexit"
}
_ble_edit_exec_eol_mark=('' '' 0)
function ble-edit/exec/.adjust-eol {
  if [[ $bleopt_prompt_eol_mark != "${_ble_edit_exec_eol_mark[0]}" ]]; then
    if [[ $bleopt_prompt_eol_mark ]]; then
      local ret= x=0 y=0 g=0 x1=0 x2=0 y1=0 y2=0
      LINES=1 COLUMNS=80 ble/canvas/trace "$bleopt_prompt_eol_mark" truncate:measure-bbox
      _ble_edit_exec_eol_mark=("$bleopt_prompt_eol_mark" "$ret" "$x2")
    else
      _ble_edit_exec_eol_mark=('' '' 0)
    fi
  fi
  local cols=${COLUMNS:-80}
  local -a DRAW_BUFF=()
  local eol_mark=${_ble_edit_exec_eol_mark[1]}
  if [[ $eol_mark ]]; then
    ble/canvas/put.draw "$_ble_term_sc"
    if ((_ble_edit_exec_eol_mark[2]>cols)); then
      local x=0 y=0 g=0
      LINES=1 COLUMNS=$cols ble/canvas/trace.draw "$bleopt_prompt_eol_mark" truncate
    else
      ble/canvas/put.draw "$eol_mark"
    fi
    ble/canvas/put.draw "$_ble_term_sgr0$_ble_term_rc"
  fi
  ble/canvas/put-cuf.draw $((_ble_term_xenl?cols-2:cols-3))
  ble/canvas/put.draw "  $_ble_term_cr$_ble_term_el"
  ble/canvas/bflush.draw
}
function ble-edit/exec/.reset-builtins-1 {
  local POSIXLY_CORRECT=y
  local -a builtins1; builtins1=(builtin unset enable unalias)
  local -a builtins2; builtins2=(return break continue declare typeset local eval echo)
  local -a keywords1; keywords1=(if then elif else case esac while until for select do done '{' '}' '[[' function)
  builtin unset -f "${builtins1[@]}"
  builtin unset -f "${builtins2[@]}"
  builtin unalias "${builtins1[@]}" "${builtins2[@]}" "${keywords1[@]}"
  ble/base/unset-POSIXLY_CORRECT
}
function ble-edit/exec/.reset-builtins-2 {
  builtin unset -f :
}
_ble_edit_exec_BASH_REMATCH=()
_ble_edit_exec_BASH_REMATCH_rex=none
function ble-edit/exec/save-BASH_REMATCH/increase {
  local delta=$1
  ((delta)) || return
  ((i+=delta))
  if ((delta==1)); then
    rex=$rex.
  else
    rex=$rex.{$delta}
  fi
}
function ble-edit/exec/save-BASH_REMATCH/is-updated {
  local i n=${#_ble_edit_exec_BASH_REMATCH[@]}
  ((n!=${#BASH_REMATCH[@]})) && return 0
  for ((i=0;i<n;i++)); do
    [[ ${_ble_edit_exec_BASH_REMATCH[i]} != "${BASH_REMATCH[i]}" ]] && return 0
  done
  return 1
}
function ble-edit/exec/save-BASH_REMATCH {
  ble-edit/exec/save-BASH_REMATCH/is-updated || return
  local size=${#BASH_REMATCH[@]}
  if ((size==0)); then
    _ble_edit_exec_BASH_REMATCH=()
    _ble_edit_exec_BASH_REMATCH_rex=none
    return
  fi
  local rex= i=0
  local text=$BASH_REMATCH sub ret isub
  local -a rparens=()
  local isub rex i=0
  for ((isub=1;isub<size;isub++)); do
    local sub=${BASH_REMATCH[isub]}
    local r rN=${#rparens[@]}
    for ((r=rN-1;r>=0;r--)); do
      local end=${rparens[r]}
      if ble/string#index-of "${text:i:end-i}" "$sub"; then
        ble-edit/exec/save-BASH_REMATCH/increase "$ret"
        ble/array#push rparens $((i+${#sub}))
        rex=$rex'('
        break
      else
        ble-edit/exec/save-BASH_REMATCH/increase $((end-i))
        rex=$rex')'
        unset -v 'rparens[r]'
      fi
    done
    ((r>=0)) && continue
    if ble/string#index-of "${text:i}" "$sub"; then
      ble-edit/exec/save-BASH_REMATCH/increase "$ret"
      ble/array#push rparens $((i+${#sub}))
      rex=$rex'('
    else
      break # 復元失敗
    fi
  done
  local r rN=${#rparens[@]}
  for ((r=rN-1;r>=0;r--)); do
    local end=${rparens[r]}
    ble-edit/exec/save-BASH_REMATCH/increase $((end-i))
    rex=$rex')'
    unset -v 'rparens[r]'
  done
  ble-edit/exec/save-BASH_REMATCH/increase $((${#text}-i))
  _ble_edit_exec_BASH_REMATCH=("${BASH_REMATCH[@]}")
  _ble_edit_exec_BASH_REMATCH_rex=$rex
}
function ble-edit/exec/restore-BASH_REMATCH {
  [[ $_ble_edit_exec_BASH_REMATCH =~ $_ble_edit_exec_BASH_REMATCH_rex ]]
}
function ble/builtin/exit {
  local ext=${1-$?}
  if ble/util/is-running-in-subshell || [[ $_ble_decode_bind_state == none ]]; then
    builtin exit "$ext"
    return
  fi
  local joblist
  ble/util/joblist
  if ((${#joblist[@]})); then
    local ret
    while
      local cancel_reason=
      if ble/util/assign ret 'compgen -A stopped -- ""' 2>/dev/null; [[ $ret ]]; then
        cancel_reason='stopped jobs'
      elif [[ :$opts: == *:checkjobs:* ]]; then
        if ble/util/assign ret 'compgen -A running -- ""' 2>/dev/null; [[ $ret ]]; then
          cancel_reason='running jobs'
        fi
      fi
      [[ $cancel_reason ]]
    do
      jobs
      ble/builtin/read -ep "\e[38;5;12m[ble: There are $cancel_reason]\e[m Leave the shell anyway? [yes/No] " ret
      case $ret in
      ([yY]|[yY][eE][sS]) break ;;
      ([nN]|[nN][oO]|'')  return ;;
      esac
    done
  fi
  echo "${_ble_term_setaf[12]}[ble: exit]$_ble_term_sgr0" >&2
  builtin exit "$ext" &>/dev/null
  builtin exit "$ext" &>/dev/null
  return 1 # exit できなかった場合は 1 らしい
}
function exit { ble/builtin/exit "$@"; }
function ble-edit/exec:exec/.eval-TRAPINT {
  builtin echo >&2
  if ((_ble_bash>=40300)); then
    _ble_edit_exec_INT=130
  else
    _ble_edit_exec_INT=128
  fi
  trap 'ble-edit/exec:exec/.eval-TRAPDEBUG SIGINT "$*" && return' DEBUG
}
function ble-edit/exec:exec/.eval-TRAPDEBUG {
  if ((_ble_edit_exec_INT&&_ble_edit_exec_in_eval)); then
    builtin echo "${_ble_term_setaf[9]}[ble: $1]$_ble_term_sgr0 ${FUNCNAME[1]} $2" >&2
    return 0
  else
    trap - DEBUG # 何故か効かない
    return 1
  fi
}
function ble-edit/exec:exec/.eval-prologue {
  ble-edit/exec/restore-BASH_REMATCH
  ble/base/restore-bash-options
  ble/base/restore-POSIXLY_CORRECT
  set -H
  trap 'ble-edit/exec:exec/.eval-TRAPINT; return 128' INT
}
function ble-edit/exec:exec/.save-last-arg {
  _ble_edit_exec_lastarg=$_ _ble_edit_exec_lastexit=$?
  ble/base/adjust-bash-options
  return "$_ble_edit_exec_lastexit"
}
function ble-edit/exec:exec/.eval {
  local _ble_edit_exec_in_eval=1 nl=$'\n'
  ble-edit/exec/.setexit "$_ble_edit_exec_lastarg" # set $? and $_
  builtin eval -- "$BASH_COMMAND${nl}ble-edit/exec:exec/.save-last-arg"
}
function ble-edit/exec:exec/.eval-epilogue {
  trap - INT DEBUG # DEBUG 削除が何故か効かない
  ble/base/adjust-bash-options
  ble/base/adjust-POSIXLY_CORRECT
  _ble_edit_PS1=$PS1
  _ble_edit_IFS=$IFS
  ble-edit/adjust-IGNOREEOF
  ble-edit/exec/save-BASH_REMATCH
  ble-edit/exec/.adjust-eol
  if ((_ble_edit_exec_lastexit==0)); then
    _ble_edit_exec_lastexit=$_ble_edit_exec_INT
  fi
  if ((_ble_edit_exec_lastexit!=0)); then
    if type -t TRAPERR &>/dev/null; then
      TRAPERR
    else
      builtin echo "${_ble_term_setaf[9]}[ble: exit $_ble_edit_exec_lastexit]$_ble_term_sgr0" >&2
    fi
  fi
}
function ble-edit/exec:exec/.recursive {
  (($1>=${#_ble_edit_exec_lines})) && return
  local BASH_COMMAND=${_ble_edit_exec_lines[$1]}
  _ble_edit_exec_lines[$1]=
  if [[ ${BASH_COMMAND//[ 	]/} ]]; then
    local PS1=$_ble_edit_PS1
    local IFS=$_ble_edit_IFS
    local IGNOREEOF; ble-edit/restore-IGNOREEOF
    local HISTCMD
    ble-edit/history/get-count -v HISTCMD
    local _ble_edit_exec_INT=0
    ble-edit/exec:exec/.eval-prologue
    ble-edit/exec:exec/.eval
    _ble_edit_exec_lastexit=$?
    ble-edit/exec:exec/.eval-epilogue
  fi
  ble-edit/exec:exec/.recursive $(($1+1))
}
_ble_edit_exec_replacedDeclare=
_ble_edit_exec_replacedTypeset=
function ble-edit/exec:exec/.isGlobalContext {
  local offset=$1
  local path
  for path in "${FUNCNAME[@]:offset+1}"; do
    if [[ $path = ble-edit/exec:exec/.eval ]]; then
      return 0
    elif [[ $path != source ]]; then
      return 1
    fi
  done
  return 0
}
function ble-edit/exec:exec {
  [[ ${#_ble_edit_exec_lines[@]} -eq 0 ]] && return
  if ((_ble_bash>=40200)); then
    if ! builtin declare -f declare &>/dev/null; then
      _ble_edit_exec_replacedDeclare=1
      declare() {
        if ble-edit/exec:exec/.isGlobalContext 1; then
          builtin declare -g "$@"
        else
          builtin declare "$@"
        fi
      }
    fi
    if ! builtin declare -f typeset &>/dev/null; then
      _ble_edit_exec_replacedTypeset=1
      typeset() {
        if ble-edit/exec:exec/.isGlobalContext 1; then
          builtin typeset -g "$@"
        else
          builtin typeset "$@"
        fi
      }
    fi
  fi
  ble/term/leave
  ble/util/buffer.flush >&2
  ble-edit/exec:exec/.recursive 0
  ble/term/enter
  _ble_edit_exec_lines=()
  if [[ $_ble_edit_exec_replacedDeclare ]]; then
    _ble_edit_exec_replacedDeclare=
    unset -f declare
  fi
  if [[ $_ble_edit_exec_replacedTypeset ]]; then
    _ble_edit_exec_replacedTypeset=
    unset -f typeset
  fi
}
function ble-edit/exec:exec/process {
  ble-edit/exec:exec
  ble-edit/bind/.check-detach
  return $?
}
function ble-edit/exec:gexec/.eval-TRAPINT {
  builtin echo >&2
  if ((_ble_bash>=40300)); then
    _ble_edit_exec_INT=130
  else
    _ble_edit_exec_INT=128
  fi
  trap 'ble-edit/exec:gexec/.eval-TRAPDEBUG SIGINT "$*" && { return &>/dev/null || break &>/dev/null;}' DEBUG
}
function ble-edit/exec:gexec/.eval-TRAPDEBUG {
  if ((_ble_edit_exec_INT!=0)); then
    local IFS=$' \t\n'
    local depth=${#FUNCNAME[*]}
    local rex='^\ble-edit/exec:gexec/.'
    if ((depth>=2)) && ! [[ ${FUNCNAME[*]:depth-1} =~ $rex ]]; then
      builtin echo "${_ble_term_setaf[9]}[ble: $1]$_ble_term_sgr0 ${FUNCNAME[1]} $2" >&2
      return 0
    fi
    local rex='^(\ble-edit/exec:gexec/.|trap - )'
    if ((depth==1)) && ! [[ $BASH_COMMAND =~ $rex ]]; then
      builtin echo "${_ble_term_setaf[9]}[ble: $1]$_ble_term_sgr0 $BASH_COMMAND $2" >&2
      return 0
    fi
  fi
  trap - DEBUG # 何故か効かない
  return 1
}
function ble-edit/exec:gexec/.begin {
  local IFS=$' \t\n'
  _ble_decode_bind_hook=
  ble/term/leave
  ble/util/buffer.flush >&2
  ble-edit/bind/stdout.on
  set -H
  trap 'ble-edit/exec:gexec/.eval-TRAPINT' INT
}
function ble-edit/exec:gexec/.end {
  local IFS=$' \t\n'
  trap - INT DEBUG
  ble/util/joblist.flush >&2
  ble-edit/bind/.check-detach && return 0
  ble/term/enter
  ble-edit/bind/.tail # flush will be called here
}
function ble-edit/exec:gexec/.eval-prologue {
  local IFS=$' \t\n'
  BASH_COMMAND=$1
  ble-edit/restore-PS1
  ble-edit/restore-IGNOREEOF
  unset -v HISTCMD; ble-edit/history/get-count -v HISTCMD
  _ble_edit_exec_INT=0
  ble/util/joblist.clear
  ble-edit/exec/restore-BASH_REMATCH
  ble/base/restore-bash-options
  ble/base/restore-POSIXLY_CORRECT
  ble-edit/exec/.setexit # set $?
} &>/dev/null # set -x 対策 #D0930
function ble-edit/exec:gexec/.save-last-arg {
  _ble_edit_exec_lastarg=$_ _ble_edit_exec_lastexit=$?
  ble/base/adjust-bash-options
  return "$_ble_edit_exec_lastexit"
}
function ble-edit/exec:gexec/.eval-epilogue {
  _ble_edit_exec_lastexit=$?
  ble-edit/exec/.reset-builtins-1
  if ((_ble_edit_exec_lastexit==0)); then
    _ble_edit_exec_lastexit=$_ble_edit_exec_INT
  fi
  _ble_edit_exec_INT=0
  local IFS=$' \t\n'
  trap - DEBUG # DEBUG 削除が何故か効かない
  ble/base/adjust-bash-options
  ble/base/adjust-POSIXLY_CORRECT
  ble-edit/exec/.reset-builtins-2
  ble-edit/adjust-IGNOREEOF
  ble-edit/adjust-PS1
  ble-edit/exec/save-BASH_REMATCH
  ble/util/reset-keymap-of-editing-mode
  ble-edit/exec/.adjust-eol
  if ((_ble_edit_exec_lastexit)); then
    if builtin type -t TRAPERR &>/dev/null; then
      TRAPERR
    else
      builtin echo "${_ble_term_setaf[9]}[ble: exit $_ble_edit_exec_lastexit]$_ble_term_sgr0" >&3
    fi
  fi
}
function ble-edit/exec:gexec/.setup {
  ((${#_ble_edit_exec_lines[@]}==0)) && return 1
  ble/util/buffer.flush >&2
  local apos=\' APOS="'\\''"
  local cmd
  local -a buff
  local count=0
  buff[${#buff[@]}]=ble-edit/exec:gexec/.begin
  for cmd in "${_ble_edit_exec_lines[@]}"; do
    if [[ "$cmd" == *[^' 	']* ]]; then
      local prologue="ble-edit/exec:gexec/.eval-prologue '${cmd//$apos/$APOS}' \"\$_ble_edit_exec_lastarg\""
      buff[${#buff[@]}]="builtin eval -- '${prologue//$apos/$APOS}"
      buff[${#buff[@]}]="${cmd//$apos/$APOS}"
      buff[${#buff[@]}]="{ ble-edit/exec:gexec/.save-last-arg; } &>/dev/null'" # Note: &>/dev/null は set -x 対策 #D0930
      buff[${#buff[@]}]="{ ble-edit/exec:gexec/.eval-epilogue; } 3>&2 &>/dev/null"
      ((count++))
    fi
  done
  _ble_edit_exec_lines=()
  ((count==0)) && return 1
  buff[${#buff[@]}]='trap - INT DEBUG' # trap - は一番外側でないと効かない様だ
  buff[${#buff[@]}]=ble-edit/exec:gexec/.end
  IFS=$'\n' builtin eval '_ble_decode_bind_hook="${buff[*]}"'
  return 0
}
function ble-edit/exec:gexec/process {
  ble-edit/exec:gexec/.setup
  return $?
}
function ble/widget/.insert-newline {
  local opts=$1
  if [[ :$opts: == *:keep-info:* && $_ble_textarea_panel == 0 ]] &&
       ! ble/util/joblist.has-events
  then
    ble/textarea#render leave
    local -a DRAW_BUFF=()
    ble/canvas/panel#increase-height.draw "$_ble_textarea_panel" 1
    ble/canvas/panel#goto.draw "$_ble_textarea_panel" 0 $((_ble_textarea_gendy+1))
    ble/canvas/bflush.draw
  else
    ble-edit/info/hide
    ble/textarea#render leave
    local -a DRAW_BUFF=()
    ble/canvas/panel#goto.draw "$_ble_textarea_panel" "$_ble_textarea_gendx" "$_ble_textarea_gendy"
    ble/canvas/put.draw "$_ble_term_nl"
    ble/canvas/bflush.draw
    ble/util/joblist.bflush
  fi
  ble/textarea#invalidate
  _ble_canvas_x=0 _ble_canvas_y=0
  _ble_textarea_gendx=0 _ble_textarea_gendy=0
  _ble_canvas_panel_height[_ble_textarea_panel]=1
}
function ble/widget/.hide-current-line {
  ble-edit/info/hide
  local -a DRAW_BUFF=()
  ble/canvas/panel#clear.draw "$_ble_textarea_panel"
  ble/canvas/panel#goto.draw "$_ble_textarea_panel" 0 0
  ble/canvas/bflush.draw
  ble/textarea#invalidate
  _ble_canvas_x=0 _ble_canvas_y=0
  _ble_textarea_gendx=0 _ble_textarea_gendy=0
  _ble_canvas_panel_height[_ble_textarea_panel]=1
}
function ble/widget/.newline/clear-content {
  [[ $_ble_edit_overwrite_mode ]] &&
    ble/term/cursor-state/reveal
  ble-edit/content/reset '' newline
  _ble_edit_ind=0
  _ble_edit_mark=0
  _ble_edit_mark_active=
  _ble_edit_overwrite_mode=
}
function ble/widget/.newline {
  local opts=$1
  _ble_edit_mark_active=
  if [[ $_ble_complete_menu_active ]]; then
    _ble_complete_menu_active=
    [[ $_ble_highlight_layer_menu_filter_beg ]] &&
      ble/textarea#invalidate str # (#D0995)
  fi
  ble/widget/.insert-newline "$opts"
  ((LINENO=++_ble_edit_LINENO))
  ble-edit/history/onleave.fire
  ble/widget/.newline/clear-content
}
function ble/widget/discard-line {
  ble-edit/content/clear-arg
  _ble_edit_line_disabled=1 ble/widget/.newline keep-info
  ble/textarea#render
}
if ((_ble_bash>=30100)); then
  function ble/edit/hist_expanded/.core {
    builtin history -p -- "$BASH_COMMAND"
  }
else
  function ble/edit/hist_expanded/.core {
    local line1= line2=
    ble/util/assign line1 'HISTTIMEFORMAT= builtin history 1'
    builtin history -p -- '' &>/dev/null
    ble/util/assign line2 'HISTTIMEFORMAT= builtin history 1'
    if [[ $line1 != "$line2" ]]; then
      local rex_head='^[[:space:]]*[0-9]+[[:space:]]*'
      [[ $line1 =~ $rex_head ]] &&
        line1=${line1:${#BASH_REMATCH}}
      local tmp=$_ble_base_run/$$.ble_edit_history_add.txt
      printf '%s\n' "$line1" "$line1" >| "$tmp"
      builtin history -r "$tmp"
    fi
    builtin history -p -- "$BASH_COMMAND"
  }
fi
function ble-edit/hist_expanded/.expand {
  ble/edit/hist_expanded/.core 2>/dev/null; local ext=$?
  ((ext)) && echo "$BASH_COMMAND"
  builtin echo -n :
  return "$ext"
}
function ble-edit/hist_expanded.update {
  local BASH_COMMAND="$*"
  if [[ ! -o histexpand || ! ${BASH_COMMAND//[ 	]} ]]; then
    hist_expanded=$BASH_COMMAND
    return 0
  elif ble/util/assign hist_expanded 'ble-edit/hist_expanded/.expand'; then
    hist_expanded=${hist_expanded%$_ble_term_nl:}
    return 0
  else
    hist_expanded=$BASH_COMMAND
    return 1
  fi
}
function ble/widget/accept-line {
  ble-edit/content/clear-arg
  local BASH_COMMAND=$_ble_edit_str
  if [[ ! ${BASH_COMMAND//[ 	]} ]]; then
    ble/widget/.newline keep-info
    ble/textarea#render
    ble/util/buffer.flush >&2
    return
  fi
  local hist_expanded
  if ! ble-edit/hist_expanded.update "$BASH_COMMAND"; then
    _ble_edit_line_disabled=1 ble/widget/.insert-newline
    shopt -q histreedit &>/dev/null || ble/widget/.newline/clear-content
    ble/util/buffer.flush >&2
    ble/edit/hist_expanded/.core 1>/dev/null # エラーメッセージを表示
    return
  fi
  local hist_is_expanded=
  if [[ $hist_expanded != "$BASH_COMMAND" ]]; then
    if shopt -q histverify &>/dev/null; then
      _ble_edit_line_disabled=1 ble/widget/.insert-newline
      ble-edit/content/reset-and-check-dirty "$hist_expanded"
      _ble_edit_ind=${#hist_expanded}
      _ble_edit_mark=0
      _ble_edit_mark_active=
      return
    fi
    BASH_COMMAND=$hist_expanded
    hist_is_expanded=1
  fi
  ble/widget/.newline
  [[ $hist_is_expanded ]] && ble/util/buffer.print "${_ble_term_setaf[12]}[ble: expand]$_ble_term_sgr0 $BASH_COMMAND"
  ((++_ble_edit_CMD))
  ble-edit/history/add "$BASH_COMMAND"
  ble-edit/exec/register "$BASH_COMMAND"
}
function ble/widget/accept-and-next {
  ble-edit/content/clear-arg
  local index count
  ble-edit/history/get-index -v index
  ble-edit/history/get-count -v count
  if ((index+1<count)); then
    local HISTINDEX_NEXT=$((index+1)) # to be modified in accept-line
    ble/widget/accept-line
    ble-edit/history/goto "$HISTINDEX_NEXT"
  else
    local content=$_ble_edit_str
    ble/widget/accept-line
    ble-edit/history/get-count -v count
    if ((count)); then
      local entry; ble-edit/history/get-entry $((count-1))
      if [[ $entry == "$content" ]]; then
        ble-edit/history/goto $((count-1))
      fi
    fi
    [[ $_ble_edit_str != "$content" ]] &&
      ble-edit/content/reset "$content"
  fi
}
function ble/widget/newline {
  local -a KEYS=(10)
  ble/widget/self-insert
}
function ble-edit/is-single-complete-line {
  ble-edit/content/is-single-line || return 1
  [[ $_ble_edit_str ]] && ble-decode/has-input && return 1
  if shopt -q cmdhist &>/dev/null; then
    ble-edit/content/update-syntax
    ble/syntax:bash/is-complete || return 1
  fi
  return 0
}
function ble/widget/accept-single-line-or {
  if ble-edit/is-single-complete-line; then
    ble/widget/accept-line
  else
    ble/widget/"$@"
  fi
}
function ble/widget/accept-single-line-or-newline {
  ble/widget/accept-single-line-or newline
}
_ble_edit_undo_VARNAMES=(_ble_edit_undo _ble_edit_undo_history)
_ble_edit_undo_ARRNAMES=(_ble_edit_undo_index _ble_edit_undo_hindex)
_ble_edit_undo=()
_ble_edit_undo_index=0
_ble_edit_undo_history=()
_ble_edit_undo_hindex=
function ble-edit/undo/.check-hindex {
  local hindex; ble-edit/history/get-index -v hindex
  [[ $_ble_edit_undo_hindex == "$hindex" ]] && return 0
  if [[ $_ble_edit_undo_hindex ]]; then
    local uindex=${_ble_edit_undo_index:-${#_ble_edit_undo[@]}}
    local q=\' Q="'\''" value
    ble/util/sprintf value "'%s' " "$uindex" "${_ble_edit_undo[@]//$q/$Q}"
    _ble_edit_undo_history[_ble_edit_undo_hindex]=$value
  fi
  if [[ ${_ble_edit_undo_history[hindex]} ]]; then
    builtin eval "local -a data=(${_ble_edit_undo_history[hindex]})"
    _ble_edit_undo=("${data[@]:1}")
    _ble_edit_undo_index=${data[0]}
  else
    _ble_edit_undo=()
    _ble_edit_undo_index=0
  fi
  _ble_edit_undo_hindex=$hindex
}
function ble-edit/undo/clear-all {
  _ble_edit_undo=()
  _ble_edit_undo_index=0
  _ble_edit_undo_history=()
  _ble_edit_undo_hindex=
}
function ble-edit/undo/.get-current-state {
  if ((_ble_edit_undo_index==0)); then
    str=
    if [[ $_ble_edit_history_prefix || $_ble_edit_history_loaded ]]; then
      local index; ble-edit/history/get-index
      ble-edit/history/get-entry -v str "$index"
    fi
    ind=${#entry}
  else
    local entry=${_ble_edit_undo[_ble_edit_undo_index-1]}
    str=${entry#*:} ind=${entry%%:*}
  fi
}
function ble-edit/undo/add {
  ble-edit/undo/.check-hindex
  local str ind; ble-edit/undo/.get-current-state
  [[ $str == "$_ble_edit_str" ]] && return 0
  _ble_edit_undo[_ble_edit_undo_index++]=$_ble_edit_ind:$_ble_edit_str
  if ((${#_ble_edit_undo[@]}>_ble_edit_undo_index)); then
    _ble_edit_undo=("${_ble_edit_undo[@]::_ble_edit_undo_index}")
  fi
}
function ble-edit/undo/.load {
  local str ind; ble-edit/undo/.get-current-state
  if [[ $bleopt_undo_point == end || $bleopt_undo_point == beg ]]; then
    local old=$_ble_edit_str new=$str ret
    if [[ $bleopt_undo_point == end ]]; then
      ble/string#common-suffix "${old:_ble_edit_ind}" "$new"; local s1=${#ret}
      local old=${old::${#old}-s1} new=${new:${#new}-s1}
      ble/string#common-prefix "${old::_ble_edit_ind}" "$new"; local p1=${#ret}
      local old=${old:p1} new=${new:p1}
      ble/string#common-suffix "$old" "$new"; local s2=${#ret}
      local old=${old::${#old}-s2} new=${new:${#new}-s2}
      ble/string#common-prefix "$old" "$new"; local p2=${#ret}
    else
      ble/string#common-prefix "${old::_ble_edit_ind}" "$new"; local p1=${#ret}
      local old=${old:p1} new=${new:p1}
      ble/string#common-suffix "${old:_ble_edit_ind-p1}" "$new"; local s1=${#ret}
      local old=${old::${#old}-s1} new=${new:${#new}-s1}
      ble/string#common-prefix "$old" "$new"; local p2=${#ret}
      local old=${old:p2} new=${new:p2}
      ble/string#common-suffix "$old" "$new"; local s2=${#ret}
    fi
    local beg=$((p1+p2)) end0=$((${#_ble_edit_str}-s1-s2)) end=$((${#str}-s1-s2))
    ble-edit/content/replace "$beg" "$end0" "${str:beg:end-beg}"
    if [[ $bleopt_undo_point == end ]]; then
      ind=$end
    else
      ind=$beg
    fi
  else
    ble-edit/content/reset-and-check-dirty "$str"
  fi
  _ble_edit_ind=$ind
  return
}
function ble-edit/undo/undo {
  local arg=${1:-1}
  ble-edit/undo/.check-hindex
  ble-edit/undo/add # 最後に add/load してから変更があれば記録
  ((_ble_edit_undo_index)) || return 1
  ((_ble_edit_undo_index-=arg))
  ((_ble_edit_undo_index<0&&(_ble_edit_undo_index=0)))
  ble-edit/undo/.load
}
function ble-edit/undo/redo {
  local arg=${1:-1}
  ble-edit/undo/.check-hindex
  ble-edit/undo/add # 最後に add/load してから変更があれば記録
  local ucount=${#_ble_edit_undo[@]}
  ((_ble_edit_undo_index<ucount)) || return 1
  ((_ble_edit_undo_index+=arg))
  ((_ble_edit_undo_index>=ucount&&(_ble_edit_undo_index=ucount)))
  ble-edit/undo/.load
}
function ble-edit/undo/revert {
  ble-edit/undo/.check-hindex
  ble-edit/undo/add # 最後に add/load してから変更があれば記録
  ((_ble_edit_undo_index)) || return 1
  ((_ble_edit_undo_index=0))
  ble-edit/undo/.load
}
function ble-edit/undo/revert-toggle {
  local arg=${1:-1}
  ((arg%2==0)) && return 0
  ble-edit/undo/.check-hindex
  ble-edit/undo/add # 最後に add/load してから変更があれば記録
  if ((_ble_edit_undo_index)); then
    ((_ble_edit_undo_index=0))
    ble-edit/undo/.load
  elif ((${#_ble_edit_undo[@]})); then
    ((_ble_edit_undo_index=${#_ble_edit_undo[@]}))
    ble-edit/undo/.load
  else
    return 1
  fi
}
bleopt/declare -v history_preserve_point ''
_ble_edit_history=()
_ble_edit_history_edit=()
_ble_edit_history_dirt=()
_ble_edit_history_ind=0
_ble_edit_history_onleave=()
_ble_edit_history_prefix=
_ble_edit_history_loaded=
_ble_edit_history_count=
function ble-edit/history/onleave.fire {
  local -a observers
  eval "observers=(\"\${${_ble_edit_history_prefix:-_ble_edit}_history_onleave[@]}\")"
  local obs; for obs in "${observers[@]}"; do "$obs" "$@"; done
}
function ble-edit/history/get-index {
  local _var=index
  [[ $1 == -v ]] && { _var=$2; shift 2; }
  if [[ $_ble_edit_history_prefix ]]; then
    (($_var=${_ble_edit_history_prefix}_history_ind))
  elif [[ $_ble_edit_history_loaded ]]; then
    (($_var=_ble_edit_history_ind))
  else
    ble-edit/history/get-count -v "$_var"
  fi
}
function ble-edit/history/get-count {
  local _var=count _ret
  [[ $1 == -v ]] && { _var=$2; shift 2; }
  if [[ $_ble_edit_history_prefix ]]; then
    eval "_ret=\${#${_ble_edit_history_prefix}_history[@]}"
  elif [[ $_ble_edit_history_loaded ]]; then
    _ret=${#_ble_edit_history[@]}
  else
    if [[ ! $_ble_edit_history_count ]]; then
      local history_line
      ble/util/assign history_line 'builtin history 1'
      ble/string#split-words history_line "$history_line"
      _ble_edit_history_count=${history_line[0]}
    fi
    _ret=$_ble_edit_history_count
  fi
  (($_var=_ret))
}
function ble-edit/history/get-entry {
  ble-edit/history/load
  local __var=entry
  [[ $1 == -v ]] && { __var=$2; shift 2; }
  eval "$__var=\${${_ble_edit_history_prefix:-_ble_edit}_history[\$1]}"
}
function ble-edit/history/get-editted-entry {
  ble-edit/history/load
  local __var=entry
  [[ $1 == -v ]] && { __var=$2; shift 2; }
  eval "$__var=\${${_ble_edit_history_prefix:-_ble_edit}_history_edit[\$1]}"
}
if ((_ble_bash>=40000)); then
  _ble_edit_history_loading=0
  _ble_edit_history_loading_bgpid=
  function ble-edit/history/load/.background-initialize {
    if ! builtin history -p '!1' &>/dev/null; then
      builtin history -n
    fi
    local -x HISTTIMEFORMAT=__ble_ext__
    local -x INDEX_FILE=$history_indfile
    local opt_cygwin=; [[ $OSTYPE == cygwin* ]] && opt_cygwin=1
    local apos=\'
    builtin history | ble/bin/awk -v apos="$apos" -v opt_cygwin="$opt_cygwin" '
      BEGIN {
        n = 0;
        hindex = 0;
        INDEX_FILE = ENVIRON["INDEX_FILE"];
        printf("") > INDEX_FILE; # create file
        if (opt_cygwin) print "_ble_edit_history=(";
      }
      function flush_line() {
        if (n < 1) return;
        if (n == 1) {
          if (t ~ /^eval -- \$'$apos'([^'$apos'\\]|\\.)*'$apos'$/)
            print hindex > INDEX_FILE;
          hindex++;
        } else {
          gsub(/['$apos'\\]/, "\\\\&", t);
          gsub(/\n/, "\\n", t);
          print hindex > INDEX_FILE;
          t = "eval -- $" apos t apos;
          hindex++;
        }
        if (opt_cygwin) {
          gsub(/'$apos'/, "'$apos'\\'$apos$apos'", t);
          t = apos t apos;
        }
        print t;
        n = 0;
        t = "";
      }
      {
        if (sub(/^ *[0-9]+\*? +(__ble_ext__|\?\?)/, "", $0))
          flush_line();
        t = ++n == 1 ? $0 : t "\n" $0;
      }
      END {
        flush_line();
        if (opt_cygwin) print ")";
      }
    ' >| "$history_tmpfile.part"
    ble/bin/mv -f "$history_tmpfile.part" "$history_tmpfile"
  }
  function ble-edit/history/load {
    [[ $_ble_edit_history_prefix ]] && return
    [[ $_ble_edit_history_loaded ]] && return
    local opt_async=; [[ $1 == async ]] && opt_async=1
    local opt_info=; ((_ble_edit_attached)) && [[ ! $opt_async ]] && opt_info=1
    local opt_cygwin=; [[ $OSTYPE == cygwin* ]] && opt_cygwin=1
    local history_tmpfile=$_ble_base_run/$$.edit-history-load
    local history_indfile=$_ble_base_run/$$.edit-history-load-multiline-index
    while :; do
      case $_ble_edit_history_loading in
      (0) [[ $opt_info ]] && ble-edit/info/immediate-show text "loading history..."
          : >| "$history_tmpfile"
          if [[ $opt_async ]]; then
            _ble_edit_history_loading_bgpid=$(
              shopt -u huponexit; ble-edit/history/load/.background-initialize </dev/null &>/dev/null & echo $!)
            function ble-edit/history/load/.background-initialize-completed {
              local history_tmpfile=$_ble_base_run/$$.edit-history-load
              [[ -s $history_tmpfile ]] || ! builtin kill -0 "$_ble_edit_history_loading_bgpid"
            } &>/dev/null
            ((_ble_edit_history_loading++))
          else
            ble-edit/history/load/.background-initialize
            ((_ble_edit_history_loading+=3))
          fi ;;
      (1) if [[ $opt_async ]] && ble/util/is-running-in-idle; then
            ble/util/idle.wait-condition ble-edit/history/load/.background-initialize-completed
            ((_ble_edit_history_loading++))
            return
          fi
          ((_ble_edit_history_loading++)) ;;
      (2) while ! ble-edit/history/load/.background-initialize-completed; do
            ble/util/msleep 50
            [[ $opt_async ]] && ble-decode/has-input && return 148
          done
          ((_ble_edit_history_loading++)) ;;
      (3) if [[ $opt_cygwin ]]; then
            source "$history_tmpfile"
          else
            ble/util/mapfile _ble_edit_history < "$history_tmpfile"
          fi
          ((_ble_edit_history_loading++)) ;;
      (4) if [[ $opt_cygwin ]]; then
            _ble_edit_history_edit=("${_ble_edit_history[@]}")
          else
            ble/util/mapfile _ble_edit_history_edit < "$history_tmpfile"
          fi
          ((_ble_edit_history_loading++)) ;;
      (5) local -a indices_to_fix
          ble/util/mapfile indices_to_fix < "$history_indfile"
          local i rex='^eval -- \$'\''([^\'\'']|\\.)*'\''$'
          for i in "${indices_to_fix[@]}"; do
            [[ ${_ble_edit_history[i]} =~ $rex ]] &&
              eval "_ble_edit_history[i]=${_ble_edit_history[i]:8}"
          done
          ((_ble_edit_history_loading++)) ;;
      (6) local -a indices_to_fix
          [[ ${indices_to_fix+set} ]] ||
            ble/util/mapfile indices_to_fix < "$history_indfile"
          for i in "${indices_to_fix[@]}"; do
            [[ ${_ble_edit_history_edit[i]} =~ $rex ]] &&
              eval "_ble_edit_history_edit[i]=${_ble_edit_history_edit[i]:8}"
          done
          _ble_edit_history_count=${#_ble_edit_history[@]}
          _ble_edit_history_ind=$_ble_edit_history_count
          _ble_edit_history_loaded=1
          [[ $opt_info ]] && ble-edit/info/immediate-clear
          ((_ble_edit_history_loading++))
          return 0 ;;
      (*) return 1 ;;
      esac
      [[ $opt_async ]] && ble-decode/has-input && return 148
    done
  }
  function ble-edit/history/clear-background-load {
    _ble_edit_history_loading=0
  }
else
  function ble-edit/history/.generate-source-to-load-history {
    if ! builtin history -p '!1' &>/dev/null; then
      builtin history -n
    fi
    HISTTIMEFORMAT=__ble_ext__
    local apos="'"
    builtin history | ble/bin/awk -v apos="'" '
      BEGIN{
        n="";
        print "_ble_edit_history=("
      }
      /^ *[0-9]+\*? +(__ble_ext__|\?\?)/ {
        if (n != "") {
          n = "";
          print "  " apos t apos;
        }
        n = $1; t = "";
        sub(/^ *[0-9]+\*? +(__ble_ext__|\?\?)/, "", $0);
      }
      {
        line = $0;
        if (line ~ /^eval -- \$'$apos'([^'$apos'\\]|\\.)*'$apos'$/)
          line = apos substr(line, 9) apos;
        else
          gsub(apos, apos "\\" apos apos, line);
        t = t != "" ? t "\n" line : line;
      }
      END {
        if (n != "") {
          n = "";
          print "  " apos t apos;
        }
        print ")"
      }
    '
  }
  function ble-edit/history/load {
    [[ $_ble_edit_history_prefix ]] && return
    [[ $_ble_edit_history_loaded ]] && return
    _ble_edit_history_loaded=1
    ((_ble_edit_attached)) &&
      ble-edit/info/immediate-show text "loading history..."
    builtin eval -- "$(ble-edit/history/.generate-source-to-load-history)"
    _ble_edit_history_edit=("${_ble_edit_history[@]}")
    _ble_edit_history_count=${#_ble_edit_history[@]}
    _ble_edit_history_ind=$_ble_edit_history_count
    if ((_ble_edit_attached)); then
      ble-edit/info/clear
    fi
  }
  function ble-edit/history/clear-background-load { :; }
fi
function ble-edit/history/add/.command-history {
  [[ -o history ]] || ((_ble_bash<30200)) || return
  if [[ $_ble_edit_history_loaded ]]; then
    _ble_edit_history_ind=${#_ble_edit_history[@]}
    local index
    for index in "${!_ble_edit_history_dirt[@]}"; do
      _ble_edit_history_edit[index]=${_ble_edit_history[index]}
    done
    _ble_edit_history_dirt=()
    ble-edit/undo/clear-all
  fi
  local cmd=$1
  if [[ $HISTIGNORE ]]; then
    local pats pat
    ble/string#split pats : "$HISTIGNORE"
    for pat in "${pats[@]}"; do
      [[ $cmd == $pat ]] && return
    done
  fi
  local histfile=
  if [[ $_ble_edit_history_loaded ]]; then
    if [[ $HISTCONTROL ]]; then
      local ignorespace ignoredups erasedups spec
      for spec in ${HISTCONTROL//:/ }; do
        case "$spec" in
        (ignorespace) ignorespace=1 ;;
        (ignoredups)  ignoredups=1 ;;
        (ignoreboth)  ignorespace=1 ignoredups=1 ;;
        (erasedups)   erasedups=1 ;;
        esac
      done
      if [[ $ignorespace ]]; then
        [[ $cmd == [' 	']* ]] && return
      fi
      if [[ $ignoredups ]]; then
        local lastIndex=$((${#_ble_edit_history[@]}-1))
        ((lastIndex>=0)) && [[ $cmd == "${_ble_edit_history[lastIndex]}" ]] && return
      fi
      if [[ $erasedups ]]; then
        local indexNext=$HISTINDEX_NEXT
        local i n=-1 N=${#_ble_edit_history[@]}
        for ((i=0;i<N;i++)); do
          if [[ ${_ble_edit_history[i]} != "$cmd" ]]; then
            if ((++n!=i)); then
              _ble_edit_history[n]=${_ble_edit_history[i]}
              _ble_edit_history_edit[n]=${_ble_edit_history_edit[i]}
            fi
          else
            ((i<HISTINDEX_NEXT&&HISTINDEX_NEXT--))
          fi
        done
        for ((i=N-1;i>n;i--)); do
          unset -v '_ble_edit_history[i]'
          unset -v '_ble_edit_history_edit[i]'
        done
        [[ ${HISTINDEX_NEXT+set} ]] && HISTINDEX_NEXT=$indexNext
      fi
    fi
    local topIndex=${#_ble_edit_history[@]}
    _ble_edit_history[topIndex]=$cmd
    _ble_edit_history_edit[topIndex]=$cmd
    _ble_edit_history_count=$((topIndex+1))
    _ble_edit_history_ind=$_ble_edit_history_count
    ((_ble_bash<30100)) && histfile=${HISTFILE:-$HOME/.bash_history}
  else
    if [[ $HISTCONTROL ]]; then
      _ble_edit_history_count=
    else
      [[ $_ble_edit_history_count ]] &&
        ((_ble_edit_history_count++))
    fi
  fi
  if [[ $cmd == *$'\n'* ]]; then
    ble/util/sprintf cmd 'eval -- %q' "$cmd"
  fi
  if [[ $histfile ]]; then
    local tmp=$_ble_base_run/$$.ble_edit_history_add.txt
    builtin printf '%s\n' "$cmd" >> "$histfile"
    builtin printf '%s\n' "$cmd" >| "$tmp"
    builtin history -r "$tmp"
  else
    ble-edit/history/clear-background-load
    builtin history -s -- "$cmd"
  fi
}
function ble-edit/history/add {
  local command=$1
  if [[ $_ble_edit_history_prefix ]]; then
    local code='
      local index
      for index in "${!PREFIX_history_dirt[@]}"; do
        PREFIX_history_edit[index]=${PREFIX_history[index]}
      done
      PREFIX_history_dirt=()
      local topIndex=${#PREFIX_history[@]}
      PREFIX_history[topIndex]=$command
      PREFIX_history_edit[topIndex]=$command
      PREFIX_history_ind=$((topIndex+1))'
    eval "${code//PREFIX/$_ble_edit_history_prefix}"
  else
    ble-edit/history/add/.command-history "$command"
  fi
}
function ble-edit/history/goto {
  ble-edit/history/load
  local histlen= index0= index1=$1
  ble-edit/history/get-count -v histlen
  ble-edit/history/get-index -v index0
  ((index0==index1)) && return
  if ((index1>histlen)); then
    index1=histlen
    ble/widget/.bell
  elif ((index1<0)); then
    index1=0
    ble/widget/.bell
  fi
  ((index0==index1)) && return
  local code='
    if [[ ${PREFIX_history_edit[index0]} != "$_ble_edit_str" ]]; then
      PREFIX_history_edit[index0]=$_ble_edit_str
      PREFIX_history_dirt[index0]=1
    fi
    ble-edit/history/onleave.fire
    PREFIX_history_ind=$index1
    ble-edit/content/reset "${PREFIX_history_edit[index1]}" history'
  eval "${code//PREFIX/${_ble_edit_history_prefix:-_ble_edit}}"
  if [[ $bleopt_history_preserve_point ]]; then
    if ((_ble_edit_ind>${#_ble_edit_str})); then
      _ble_edit_ind=${#_ble_edit_str}
    fi
  else
    if ((index1<index0)); then
      _ble_edit_ind=${#_ble_edit_str}
    else
      local first_line=${_ble_edit_str%%$'\n'*}
      _ble_edit_ind=${#first_line}
    fi
  fi
  _ble_edit_mark=0
  _ble_edit_mark_active=
}
function ble/widget/history-next {
  if [[ $_ble_edit_history_prefix || $_ble_edit_history_loaded ]]; then
    local arg; ble-edit/content/get-arg 1
    local index; ble-edit/history/get-index
    ble-edit/history/goto $((index+arg))
  else
    ble-edit/content/clear-arg
    ble/widget/.bell
  fi
}
function ble/widget/history-prev {
  local arg; ble-edit/content/get-arg 1
  local index; ble-edit/history/get-index
  ble-edit/history/goto $((index-arg))
}
function ble/widget/history-beginning {
  ble-edit/content/clear-arg
  ble-edit/history/goto 0
}
function ble/widget/history-end {
  ble-edit/content/clear-arg
  if [[ $_ble_edit_history_prefix || $_ble_edit_history_loaded ]]; then
    local count; ble-edit/history/get-count
    ble-edit/history/goto "$count"
  else
    ble/widget/.bell
  fi
}
function ble/widget/history-expand-line {
  ble-edit/content/clear-arg
  local hist_expanded
  ble-edit/hist_expanded.update "$_ble_edit_str" || return 1
  [[ $_ble_edit_str == "$hist_expanded" ]] && return 1
  ble-edit/content/reset-and-check-dirty "$hist_expanded"
  _ble_edit_ind=${#hist_expanded}
  _ble_edit_mark=0
  _ble_edit_mark_active=
  return 0
}
function ble/widget/history-expand-backward-line {
  ble-edit/content/clear-arg
  local prevline=${_ble_edit_str::_ble_edit_ind} hist_expanded
  ble-edit/hist_expanded.update "$prevline" || return 1
  [[ $prevline == "$hist_expanded" ]] && return 1
  local ret
  ble/string#common-prefix "$prevline" "$hist_expanded"; local dmin=${#ret}
  ble-edit/content/replace "$dmin" "$_ble_edit_ind" "${hist_expanded:dmin}"
  _ble_edit_ind=${#hist_expanded}
  _ble_edit_mark=0
  _ble_edit_mark_active=
  return 0
}
function ble/widget/magic-space {
  [[ $_ble_decode_keymap == vi_imap ]] &&
    local oind=$_ble_edit_ind ostr=$_ble_edit_str
  local arg; ble-edit/content/get-arg ''
  ble/widget/history-expand-backward-line ||
    ble/complete/sabbrev/expand
  local ext=$?
  ((ext==148)) && return 148 # sabbrev/expand でメニュー補完に入った時など。
  [[ $_ble_decode_keymap == vi_imap ]] &&
    if [[ $ostr != "$_ble_edit_str" ]]; then
      _ble_edit_ind=$oind _ble_edit_str=$ostr ble/keymap:vi/undo/add more
      ble/keymap:vi/undo/add more
    fi
  local -a KEYS=(32)
  _ble_edit_arg=$arg
  ble/widget/self-insert
}
function ble/highlight/layer:region/mark:search/get-face { face=region_match; }
function ble-edit/isearch/search {
  local needle=$1 opts=$2
  beg= end=
  [[ :$opts: != *:regex:* ]]; local has_regex=$?
  [[ :$opts: != *:extend:* ]]; local has_extend=$?
  local flag_empty_retry=
  if [[ :$opts: == *:-:* ]]; then
    local start=$((has_extend?_ble_edit_mark+1:_ble_edit_ind))
    if ((has_regex)); then
      ble-edit/isearch/.shift-backward-references
      local rex="^.*($needle)" padding=$((${#_ble_edit_str}-start))
      ((padding)) && rex="$rex.{$padding}"
      if [[ $_ble_edit_str =~ $rex ]]; then
        local rematch1=${BASH_REMATCH[1]}
        if [[ $rematch1 || $BASH_REMATCH == "$_ble_edit_str" || :$opts: == *:allow_empty:* ]]; then
          ((end=${#BASH_REMATCH}-padding,
            beg=end-${#rematch1}))
          return 0
        else
          flag_empty_retry=1
        fi
      fi
    else
      if [[ $needle ]]; then
        local target=${_ble_edit_str::start}
        local m=${target%"$needle"*}
        if [[ $target != "$m" ]]; then
          beg=${#m}
          end=$((beg+${#needle}))
          return 0
        fi
      else
        if [[ :$opts: == *:allow_empty:* ]] || ((--start>=0)); then
          ((beg=end=start))
          return 0
        fi
      fi
    fi
  elif [[ :$opts: == *:B:* ]]; then
    local start=$((has_extend?_ble_edit_ind:_ble_edit_ind-1))
    ((start<0)) && return 1
    if ((has_regex)); then
      ble-edit/isearch/.shift-backward-references
      local rex="^.{0,$start}($needle)"
      ((start==0)) && rex="^($needle)"
      if [[ $_ble_edit_str =~ $rex ]]; then
        local rematch1=${BASH_REMATCH[1]}
        if [[ $rematch1 || :$opts: == *:allow_empty:* ]]; then
          ((end=${#BASH_REMATCH},
            beg=end-${#rematch1}))
          return 0
        else
          flag_empty_retry=1
        fi
      fi
    else
      if [[ $needle ]]; then
        local target=${_ble_edit_str::start+${#needle}}
        local m=${target%"$needle"*}
        if [[ $target != "$m" ]]; then
          ((beg=${#m},
            end=beg+${#needle}))
          return 0
        fi
      else
        if [[ :$opts: == *:allow_empty:* ]] && ((--start>=0)); then
          ((beg=end=start))
          return 0
        fi
      fi
    fi
  else
    local start=$((has_extend?_ble_edit_mark:_ble_edit_ind))
    if ((has_regex)); then
      ble-edit/isearch/.shift-backward-references
      local rex="($needle).*\$"
      ((start)) && rex=".{$start}$rex"
      if [[ $_ble_edit_str =~ $rex ]]; then
        local rematch1=${BASH_REMATCH[1]}
        if [[ $rematch1 || :$opts: == *:allow_empty:* ]]; then
          ((beg=${#_ble_edit_str}-${#BASH_REMATCH}+start))
          ((end=beg+${#rematch1}))
          return 0
        else
          flag_empty_retry=1
        fi
      fi
    else
      if [[ $needle ]]; then
        local target=${_ble_edit_str:start}
        local m=${target#*"$needle"}
        if [[ $target != "$m" ]]; then
          ((end=${#_ble_edit_str}-${#m}))
          ((beg=end-${#needle}))
          return 0
        fi
      else
        if [[ :$opts: == *:allow_empty:* ]] || ((++start<=${#_ble_edit_str})); then
          ((beg=end=start))
          return 0
        fi
      fi
    fi
  fi
  if [[ $flag_empty_retry ]]; then
    if [[ :$opts: == *:[-B]:* ]]; then
      if ((--start>=0)); then
        local mark=$_ble_edit_mark; ((mark&&mark--))
        local ind=$_ble_edit_ind; ((ind&&ind--))
        opts=$opts:allow_empty
        _ble_edit_mark=$mark _ble_edit_ind=$ind ble-edit/isearch/search "$needle" "$opts"
        return
      fi
    else
      if ((++start<=${#_ble_edit_str})); then
        local mark=$_ble_edit_mark; ((mark<${#_ble_edit_str}&&mark++))
        local ind=$_ble_edit_ind; ((ind<${#_ble_edit_str}&&ind++))
        opts=$opts:allow_empty
        _ble_edit_mark=$mark _ble_edit_ind=$ind ble-edit/isearch/search "$needle" "$opts"
        return
      fi
    fi
  fi
  return 1
}
function ble-edit/isearch/.shift-backward-references {
    local rex_cc='\[[@][^]@]+[@]\]' # [:space:] [=a=] [.a.] など。
    local rex_bracket_expr='\[\^?]?('${rex_cc//@/:}'|'${rex_cc//@/=}'|'${rex_cc//@/.}'|[^][]|\[[^]:=.])*\[?\]'
    local rex='^('$rex_bracket_expr'|\\[^1-8])*\\[1-8]'
    local buff=
    while [[ $needle =~ $rex ]]; do
      local mlen=${#BASH_REMATCH}
      buff=$buff${BASH_REMATCH::mlen-1}$((10#${BASH_REMATCH:mlen-1}+1))
      needle=${needle:mlen}
    done
    needle=$buff$needle
}
function ble-edit/isearch/.read-search-options {
  local opts=$1
  search_type=fixed
  case :$opts: in
  (*:regex:*)     search_type=regex ;;
  (*:glob:*)      search_type=glob  ;;
  (*:head:*)      search_type=head ;;
  (*:tail:*)      search_type=tail ;;
  (*:condition:*) search_type=condition ;;
  (*:predicate:*) search_type=predicate ;;
  esac
  [[ :$opts: != *:stop_check:* ]]; has_stop_check=$?
  [[ :$opts: != *:progress:* ]]; has_progress=$?
  [[ :$opts: != *:backward:* ]]; has_backward=$?
}
function ble-edit/isearch/backward-search-history-blockwise {
  local opts=$1
  local search_type has_stop_check has_progress has_backward
  ble-edit/isearch/.read-search-options "$opts"
  ble-edit/history/load
  if [[ $_ble_edit_history_prefix ]]; then
    local -a _ble_edit_history_edit
    eval "_ble_edit_history_edit=(\"\${${_ble_edit_history_prefix}_history_edit[@]}\")"
  fi
  local NSTPCHK=1000 # 十分高速なのでこれぐらい大きくてOK
  local NPROGRESS=$((NSTPCHK*2)) # 倍数である必要有り
  local irest block j i=$index
  index=
  local flag_cycled= range_min range_max
  while :; do
    if ((i<=start)); then
      range_min=0 range_max=$start
    else
      flag_cycled=1
      range_min=$((start+1)) range_max=$i
    fi
    while ((i>=range_min)); do
      ((block=range_max-i,
        block<5&&(block=5),
        block>i+1-range_min&&(block=i+1-range_min),
        irest=NSTPCHK-isearch_time%NSTPCHK,
        block>irest&&(block=irest)))
      case $search_type in
      (regex)     for ((j=i-block;++j<=i;)); do
                    [[ ${_ble_edit_history_edit[j]} =~ $needle ]] && index=$j
                  done ;;
      (glob)      for ((j=i-block;++j<=i;)); do
                    [[ ${_ble_edit_history_edit[j]} == $needle ]] && index=$j
                  done ;;
      (head)      for ((j=i-block;++j<=i;)); do
                    [[ ${_ble_edit_history_edit[j]} == "$needle"* ]] && index=$j
                  done ;;
      (tail)      for ((j=i-block;++j<=i;)); do
                    [[ ${_ble_edit_history_edit[j]} == *"$needle" ]] && index=$j
                  done ;;
      (condition) eval "function ble-edit/isearch/.search-block.proc {
                    local LINE INDEX
                    for ((j=i-block;++j<=i;)); do
                      LINE=\${_ble_edit_history_edit[j]} INDEX=\$j
                      { $needle; } && index=\$j
                    done
                  }"
                  ble-edit/isearch/.search-block.proc ;;
      (predicate) for ((j=i-block;++j<=i;)); do
                    "$needle" "${_ble_edit_history_edit[j]}" "$j" && index=$j
                  done ;;
      (*)         for ((j=i-block;++j<=i;)); do
                    [[ ${_ble_edit_history_edit[j]} == *"$needle"* ]] && index=$j
                  done ;;
      esac
      ((isearch_time+=block))
      [[ $index ]] && return 0
      ((i-=block))
      if ((has_stop_check&&isearch_time%NSTPCHK==0)) && ble-decode/has-input; then
        index=$i
        return 148
      elif ((has_progress&&isearch_time%NPROGRESS==0)); then
        "$isearch_progress_callback" "$i"
      fi
    done
    if [[ ! $flag_cycled && :$opts: == *:cyclic:* ]]; then
      ((i=${#_ble_edit_history_edit[@]}-1))
      ((start<i)) || return 1
    else
      return 1
    fi
  done
}
function ble-edit/isearch/next-history/forward-search-history.impl {
  local opts=$1
  local search_type has_stop_check has_progress has_backward
  ble-edit/isearch/.read-search-options "$opts"
  ble-edit/history/load
  if [[ $_ble_edit_history_prefix ]]; then
    local -a _ble_edit_history_edit
    eval "_ble_edit_history_edit=(\"\${${_ble_edit_history_prefix}_history_edit[@]}\")"
  fi
  while :; do
    local flag_cycled= expr_cond expr_incr
    if ((has_backward)); then
      if ((index<=start)); then
        expr_cond='index>=0' expr_incr='index--'
      else
        expr_cond='index>start' expr_incr='index--' flag_cycled=1
      fi
    else
      if ((index>=start)); then
        expr_cond="index<${#_ble_edit_history_edit[@]}" expr_incr='index++'
      else
        expr_cond="index<start" expr_incr='index++' flag_cycled=1
      fi
    fi
    case $search_type in
    (regex)
      for ((;expr_cond;expr_incr)); do
        ((isearch_time++,has_stop_check&&isearch_time%100==0)) &&
          ble-decode/has-input && return 148
        [[ ${_ble_edit_history_edit[index]} =~ $needle ]] && return 0
        ((has_progress&&isearch_time%1000==0)) &&
          "$isearch_progress_callback" "$index"
      done ;;
    (glob)
      for ((;expr_cond;expr_incr)); do
        ((isearch_time++,has_stop_check&&isearch_time%100==0)) &&
          ble-decode/has-input && return 148
        [[ ${_ble_edit_history_edit[index]} == $needle ]] && return 0
        ((has_progress&&isearch_time%1000==0)) &&
          "$isearch_progress_callback" "$index"
      done ;;
    (head)
      for ((;expr_cond;expr_incr)); do
        ((isearch_time++,has_stop_check&&isearch_time%100==0)) &&
          ble-decode/has-input && return 148
        [[ ${_ble_edit_history_edit[index]} == "$needle"* ]] && return 0
        ((has_progress&&isearch_time%1000==0)) &&
          "$isearch_progress_callback" "$index"
      done ;;
    (tail)
      for ((;expr_cond;expr_incr)); do
        ((isearch_time++,has_stop_check&&isearch_time%100==0)) &&
          ble-decode/has-input && return 148
        [[ ${_ble_edit_history_edit[index]} == *"$needle" ]] && return 0
        ((has_progress&&isearch_time%1000==0)) &&
          "$isearch_progress_callback" "$index"
      done ;;
    (condition)
      for ((;expr_cond;expr_incr)); do
        ((isearch_time++,has_stop_check&&isearch_time%100==0)) &&
          ble-decode/has-input && return 148
        LINE=${_ble_edit_history_edit[index]} INDEX=$index eval "$needle" && return 0
        ((has_progress&&isearch_time%1000==0)) &&
          "$isearch_progress_callback" "$index"
      done ;;
    (predicate)
      for ((;expr_cond;expr_incr)); do
        ((isearch_time++,has_stop_check&&isearch_time%100==0)) &&
          ble-decode/has-input && return 148
        "$needle" "${_ble_edit_history_edit[index]}" "$index" && return 0
        ((has_progress&&isearch_time%1000==0)) &&
          "$isearch_progress_callback" "$index"
      done ;;
    (*)
      for ((;expr_cond;expr_incr)); do
        ((isearch_time++,has_stop_check&&isearch_time%100==0)) &&
          ble-decode/has-input && return 148
        [[ ${_ble_edit_history_edit[index]} == *"$needle"* ]] && return 0
        ((has_progress&&isearch_time%1000==0)) &&
          "$isearch_progress_callback" "$index"
      done ;;
    esac
    if [[ ! $flag_cycled && :$opts: == *:cyclic:* ]]; then
      if ((has_backward)); then
        ((index=${#_ble_edit_history_edit[@]}-1))
        ((index>start)) || return 1
      else
        ((index=0))
        ((index<start)) || return 1
      fi
    else
      return 1
    fi
  done
}
function ble-edit/isearch/forward-search-history {
  ble-edit/isearch/next-history/forward-search-history.impl "$1"
}
function ble-edit/isearch/backward-search-history {
  ble-edit/isearch/next-history/forward-search-history.impl "$1:backward"
}
_ble_edit_isearch_str=
_ble_edit_isearch_dir=-
_ble_edit_isearch_arr=()
_ble_edit_isearch_old=
function ble-edit/isearch/status/append-progress-bar {
  ble/util/is-unicode-output || return
  local pos=$1 count=$2 dir=$3
  [[ :$dir: == *:-:* || :$dir: == *:backward:* ]] && ((pos=count-1-pos))
  local ret; ble/string#create-unicode-progress-bar "$pos" "$count" 5
  text=$text$' \e[1;38;5;69;48;5;253m'$ret$'\e[m '
}
function ble-edit/isearch/.show-status-with-progress.fib {
  local ll rr
  if [[ $_ble_edit_isearch_dir == - ]]; then
    ll=\<\< rr="  "
  else
    ll="  " rr=">>"
  fi
  local index; ble-edit/history/get-index
  local histIndex='!'$((index+1))
  local text="(${#_ble_edit_isearch_arr[@]}: $ll $histIndex $rr) \`$_ble_edit_isearch_str'"
  if [[ $1 ]]; then
    local pos=$1
    local count; ble-edit/history/get-count
    text=$text' searching...'
    ble-edit/isearch/status/append-progress-bar "$pos" "$count" "$_ble_edit_isearch_dir"
    local percentage=$((count?pos*1000/count:1000))
    text=$text" @$pos ($((percentage/10)).$((percentage%10))%)"
  fi
  ((fib_ntask)) && text="$text *$fib_ntask"
  ble-edit/info/show ansi "$text"
}
function ble-edit/isearch/.show-status.fib {
  ble-edit/isearch/.show-status-with-progress.fib
}
function ble-edit/isearch/show-status {
  local fib_ntask=${#_ble_util_fiberchain[@]}
  ble-edit/isearch/.show-status.fib
}
function ble-edit/isearch/erase-status {
  ble-edit/info/default
}
function ble-edit/isearch/.set-region {
  local beg=$1 end=$2
  if ((beg<end)); then
    if [[ $_ble_edit_isearch_dir == - ]]; then
      _ble_edit_ind=$beg
      _ble_edit_mark=$end
    else
      _ble_edit_ind=$end
      _ble_edit_mark=$beg
    fi
    _ble_edit_mark_active=search
  elif ((beg==end)); then
    _ble_edit_ind=$beg
    _ble_edit_mark=$beg
    _ble_edit_mark_active=
  else
    _ble_edit_mark_active=
  fi
}
function ble-edit/isearch/.push-isearch-array {
  local hash=$beg:$end:$needle
  local ilast=$((${#_ble_edit_isearch_arr[@]}-1))
  if ((ilast>=0)) && [[ ${_ble_edit_isearch_arr[ilast]} == "$ind:"[-+]":$hash" ]]; then
    unset -v "_ble_edit_isearch_arr[$ilast]"
    return
  fi
  local oind; ble-edit/history/get-index -v oind
  local obeg=$_ble_edit_ind oend=$_ble_edit_mark
  [[ $_ble_edit_mark_active ]] || oend=$obeg
  ((obeg>oend)) && local obeg=$oend oend=$obeg
  local oneedle=$_ble_edit_isearch_str
  local ohash=$obeg:$oend:$oneedle
  [[ $ind == "$oind" && $hash == "$ohash" ]] && return
  ble/array#push _ble_edit_isearch_arr "$oind:$_ble_edit_isearch_dir:$ohash"
}
function ble-edit/isearch/.goto-match.fib {
  local ind=$1 beg=$2 end=$3 needle=$4
  ble-edit/isearch/.push-isearch-array
  _ble_edit_isearch_str=$needle
  [[ $needle ]] && _ble_edit_isearch_old=$needle
  local oind; ble-edit/history/get-index -v oind
  ((oind!=ind)) && ble-edit/history/goto "$ind"
  ble-edit/isearch/.set-region "$beg" "$end"
  ble-edit/isearch/.show-status.fib
  ble/textarea#redraw
}
function ble-edit/isearch/.next.fib {
  local opts=$1
  if [[ ! $fib_suspend ]]; then
    if [[ :$opts: == *:forward:* || :$opts: == *:backward:* ]]; then
      if [[ :$opts: == *:forward:* ]]; then
        _ble_edit_isearch_dir=+
      else
        _ble_edit_isearch_dir=-
      fi
    fi
    local needle=${2-$_ble_edit_isearch_str}
    local beg= end= search_opts=$_ble_edit_isearch_dir
    if [[ :$opts: == *:append:* ]]; then
      search_opts=$search_opts:extend
      ble/path#remove opts append
    fi
    if [[ $needle ]] && ble-edit/isearch/search "$needle" "$search_opts"; then
      local ind; ble-edit/history/get-index -v ind
      ble-edit/isearch/.goto-match.fib "$ind" "$beg" "$end" "$needle"
      return
    fi
  fi
  ble-edit/isearch/.next-history.fib "$opts" "$needle"
}
function ble-edit/isearch/.next-history.fib {
  local opts=$1
  if [[ $fib_suspend ]]; then
    local needle=${fib_suspend#*:} isAdd=
    local index start; eval "${fib_suspend%%:*}"
    fib_suspend=
  else
    local needle=${2-$_ble_edit_isearch_str} isAdd=
    [[ :$opts: == *:append:* ]] && isAdd=1
    local start; ble-edit/history/get-index -v start
    local index=$start
  fi
  if ((!isAdd)); then
    if [[ $_ble_edit_isearch_dir == - ]]; then
      ((index--))
    else
      ((index++))
    fi
  fi
  local isearch_progress_callback=ble-edit/isearch/.show-status-with-progress.fib
  if [[ $_ble_edit_isearch_dir == - ]]; then
    ble-edit/isearch/backward-search-history-blockwise stop_check:progress
  else
    ble-edit/isearch/forward-search-history stop_check:progress
  fi
  local ext=$?
  if ((ext==0)); then
    local str; ble-edit/history/get-editted-entry -v str "$index"
    if [[ $needle ]]; then
      if [[ $_ble_edit_isearch_dir == - ]]; then
        local prefix=${str%"$needle"*}
      else
        local prefix=${str%%"$needle"*}
      fi
      local beg=${#prefix} end=$((${#prefix}+${#needle}))
    else
      local beg=${#str} end=${#str}
    fi
    ble-edit/isearch/.goto-match.fib "$index" "$beg" "$end" "$needle"
  elif ((ext==148)); then
    fib_suspend="index=$index start=$start:$needle"
    return
  else
    ble/widget/.bell "isearch: \`$needle' not found"
    return
  fi
}
function ble-edit/isearch/forward.fib {
  if [[ ! $_ble_edit_isearch_str ]]; then
    ble-edit/isearch/.next.fib forward "$_ble_edit_isearch_old"
  else
    ble-edit/isearch/.next.fib forward
  fi
}
function ble-edit/isearch/backward.fib {
  if [[ ! $_ble_edit_isearch_str ]]; then
    ble-edit/isearch/.next.fib backward "$_ble_edit_isearch_old"
  else
    ble-edit/isearch/.next.fib backward
  fi
}
function ble-edit/isearch/self-insert.fib {
  local needle=
  if [[ ! $fib_suspend ]]; then
    local code=$1
    ((code==0)) && return
    local ret; ble/util/c2s "$code"
    needle=$_ble_edit_isearch_str$ret
  fi
  ble-edit/isearch/.next.fib append "$needle"
}
function ble-edit/isearch/insert-string.fib {
  local needle=
  [[ ! $fib_suspend ]] &&
    needle=$_ble_edit_isearch_str$1
  ble-edit/isearch/.next.fib append "$needle"
}
function ble-edit/isearch/history-forward.fib {
  _ble_edit_isearch_dir=+
  ble-edit/isearch/.next-history.fib
}
function ble-edit/isearch/history-backward.fib {
  _ble_edit_isearch_dir=-
  ble-edit/isearch/.next-history.fib
}
function ble-edit/isearch/history-self-insert.fib {
  local needle=
  if [[ ! $fib_suspend ]]; then
    local code=$1
    ((code==0)) && return
    local ret; ble/util/c2s "$code"
    needle=$_ble_edit_isearch_str$ret
  fi
  ble-edit/isearch/.next-history.fib append "$needle"
}
function ble-edit/isearch/prev {
  local sz=${#_ble_edit_isearch_arr[@]}
  ((sz==0)) && return 0
  local ilast=$((sz-1))
  local top=${_ble_edit_isearch_arr[ilast]}
  unset -v '_ble_edit_isearch_arr[ilast]'
  local ind dir beg end
  ind=${top%%:*}; top=${top#*:}
  dir=${top%%:*}; top=${top#*:}
  beg=${top%%:*}; top=${top#*:}
  end=${top%%:*}; top=${top#*:}
  _ble_edit_isearch_dir=$dir
  ble-edit/history/goto "$ind"
  ble-edit/isearch/.set-region "$beg" "$end"
  _ble_edit_isearch_str=$top
  [[ $top ]] && _ble_edit_isearch_old=$top
  ble-edit/isearch/show-status
}
function ble-edit/isearch/process {
  local isearch_time=0
  ble/util/fiberchain#resume
  ble-edit/isearch/show-status
}
function ble/widget/isearch/forward {
  ble/util/fiberchain#push forward
  ble-edit/isearch/process
}
function ble/widget/isearch/backward {
  ble/util/fiberchain#push backward
  ble-edit/isearch/process
}
function ble/widget/isearch/self-insert {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  ble/util/fiberchain#push "self-insert $code"
  ble-edit/isearch/process
}
function ble/widget/isearch/history-forward {
  ble/util/fiberchain#push history-forward
  ble-edit/isearch/process
}
function ble/widget/isearch/history-backward {
  ble/util/fiberchain#push history-backward
  ble-edit/isearch/process
}
function ble/widget/isearch/history-self-insert {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  ble/util/fiberchain#push "history-self-insert $code"
  ble-edit/isearch/process
}
function ble/widget/isearch/prev {
  local nque
  if ((nque=${#_ble_util_fiberchain[@]})); then
    local ret; ble/array#pop _ble_util_fiberchain
    ble-edit/isearch/process
  else
    ble-edit/isearch/prev
  fi
}
function ble/widget/isearch/.restore-mark-state {
  local old_mark_active=${_ble_edit_isearch_save[3]}
  if [[ $old_mark_active ]]; then
    local index; ble-edit/history/get-index
    if ((index==_ble_edit_isearch_save[0])); then
      _ble_edit_mark=${_ble_edit_isearch_save[2]}
      if [[ $old_mark_active != S ]] || ((_ble_edit_index==_ble_edit_isearch_save[1])); then
        _ble_edit_mark_active=$old_mark_active
      fi
    fi
  fi
}
function ble/widget/isearch/exit.impl {
  ble-decode/keymap/pop
  _ble_edit_isearch_arr=()
  _ble_edit_isearch_dir=
  _ble_edit_isearch_str=
  ble-edit/isearch/erase-status
}
function ble/widget/isearch/exit-with-region {
  ble/widget/isearch/exit.impl
  [[ $_ble_edit_mark_active ]] &&
    _ble_edit_mark_active=S
}
function ble/widget/isearch/exit {
  ble/widget/isearch/exit.impl
  _ble_edit_mark_active=
  ble/widget/isearch/.restore-mark-state
}
function ble/widget/isearch/cancel {
  if ((${#_ble_util_fiberchain[@]})); then
    ble/util/fiberchain#clear
    ble-edit/isearch/show-status # 進捗状況だけ消去
  else
    if ((${#_ble_edit_isearch_arr[@]})); then
      local step
      ble/string#split step : "${_ble_edit_isearch_arr[0]}"
      ble-edit/history/goto "${step[0]}"
    fi
    ble/widget/isearch/exit.impl
    _ble_edit_ind=${_ble_edit_isearch_save[1]}
    _ble_edit_mark=${_ble_edit_isearch_save[2]}
    _ble_edit_mark_active=${_ble_edit_isearch_save[3]}
  fi
}
function ble/widget/isearch/exit-default {
  ble/widget/isearch/exit-with-region
  ble-decode-key "${KEYS[@]}"
}
function ble/widget/isearch/accept-line {
  if ((${#_ble_util_fiberchain[@]})); then
    ble/widget/.bell "isearch: now searching..."
  else
    ble/widget/isearch/exit
    ble-decode-key 13 # RET
  fi
}
function ble/widget/isearch/exit-delete-forward-char {
  ble/widget/isearch/exit
  ble/widget/delete-forward-char
}
function ble/widget/history-isearch.impl {
  local opts=$1
  ble-edit/content/clear-arg
  ble-decode/keymap/push isearch
  ble/util/fiberchain#initialize ble-edit/isearch
  local index; ble-edit/history/get-index
  _ble_edit_isearch_save=("$index" "$_ble_edit_ind" "$_ble_edit_mark" "$_ble_edit_mark_active")
  if [[ :$opts: == *:forward:* ]]; then
    _ble_edit_isearch_dir=+
  else
    _ble_edit_isearch_dir=-
  fi
  _ble_edit_isearch_arr=()
  _ble_edit_mark=$_ble_edit_ind
  ble-edit/isearch/show-status
}
function ble/widget/history-isearch-backward {
  ble/widget/history-isearch.impl backward
}
function ble/widget/history-isearch-forward {
  ble/widget/history-isearch.impl forward
}
function ble-decode/keymap:isearch/define {
  local ble_bind_keymap=isearch
  ble-bind -f __defchar__ isearch/self-insert
  ble-bind -f C-r         isearch/backward
  ble-bind -f C-s         isearch/forward
  ble-bind -f 'C-?'       isearch/prev
  ble-bind -f 'DEL'       isearch/prev
  ble-bind -f 'C-h'       isearch/prev
  ble-bind -f 'BS'        isearch/prev
  ble-bind -f __default__ isearch/exit-default
  ble-bind -f 'C-g'       isearch/cancel
  ble-bind -f 'C-x C-g'   isearch/cancel
  ble-bind -f 'C-M-g'     isearch/cancel
  ble-bind -f C-m         isearch/exit
  ble-bind -f RET         isearch/exit
  ble-bind -f C-j         isearch/accept-line
  ble-bind -f C-RET       isearch/accept-line
}
_ble_edit_nsearch_needle=
_ble_edit_nsearch_opts=
_ble_edit_nsearch_stack=()
_ble_edit_nsearch_match=
_ble_edit_nsearch_index=
function ble-edit/nsearch/.show-status.fib {
  local ll rr
  if [[ :$_ble_edit_isearch_opts: == *:forward:* ]]; then
    ll="  " rr=">>"
  else
    ll=\<\< rr="  " # Note: Emacs workaround: '<<' や "<<" と書けない。
  fi
  local index='!'$((_ble_edit_nsearch_match+1))
  local nmatch=${#_ble_edit_nsearch_stack[@]}
  local needle=$_ble_edit_nsearch_needle
  local text="(nsearch#$nmatch: $ll $index $rr) \`$needle'"
  if [[ $1 ]]; then
    local pos=$1
    local count; ble-edit/history/get-count
    text=$text' searching...'
    ble-edit/isearch/status/append-progress-bar "$pos" "$count" "$_ble_edit_isearch_opts"
    local percentage=$((count?pos*1000/count:1000))
    text=$text" @$pos ($((percentage/10)).$((percentage%10))%)"
  fi
  local ntask=$fib_ntask
  ((ntask)) && text="$text *$ntask"
  ble-edit/info/show ansi "$text"
}
function ble-edit/nsearch/show-status {
  local fib_ntask=${#_ble_util_fiberchain[@]}
  ble-edit/nsearch/.show-status.fib
}
function ble-edit/nsearch/erase-status {
  ble-edit/info/default
}
function ble-edit/nsearch/.search.fib {
  local opts=$1
  local opt_forward=
  [[ :$opts: == *:forward:* ]] && opt_forward=1
  local nstack=${#_ble_edit_nsearch_stack[@]}
  if ((nstack>=2)); then
    local record_type=${_ble_edit_nsearch_stack[nstack-1]%%,*}
    if 
      if [[ $opt_forward ]]; then
        [[ $record_type == backward ]]
      else
        [[ $record_type == forward ]]
      fi
    then
      local ret; ble/array#pop _ble_edit_nsearch_stack
      local record line=${ret#*:}
      ble/string#split record , "${ret%%:*}"
      ble-edit/content/reset-and-check-dirty "$line"
      _ble_edit_nsearch_match=${record[1]}
      _ble_edit_nsearch_index=${record[1]}
      _ble_edit_ind=${record[2]}
      _ble_edit_mark=${record[3]}
      if ((_ble_edit_mark!=_ble_edit_ind)); then
        _ble_edit_mark_active=search
      else
        _ble_edit_mark_active=
      fi
      ble-edit/nsearch/.show-status.fib
      ble/textarea#redraw
      fib_suspend=
      return 0
    fi
  fi
  local index start opt_resume=
  if [[ $fib_suspend ]]; then
    opt_resume=1
    eval "$fib_suspend"
    fib_suspend=
  else
    local index=$_ble_edit_nsearch_index
    local start=$index
  fi
  local needle=$_ble_edit_nsearch_needle
  if
    if [[ $opt_forward ]]; then
      local count; ble-edit/history/get-count
      [[ $opt_resume ]] || ((++index))
      ((index<count))
    else
      [[ $opt_resume ]] || ((--index))
      ((index>=0))
    fi
  then
    local isearch_time=$fib_clock
    local isearch_progress_callback=ble-edit/nsearch/.show-status.fib
    local isearch_opts=stop_check:progress; [[ :$opts: != *:substr:* ]] && isearch_opts=$isearch_opts:head
    if [[ $opt_forward ]]; then
      ble-edit/isearch/forward-search-history "$isearch_opts"; local ext=$?
    else
      ble-edit/isearch/backward-search-history-blockwise "$isearch_opts"; local ext=$?
    fi
    fib_clock=$isearch_time
  else
    local ext=1
  fi
  if ((ext==0)); then
    local old_match=$_ble_edit_nsearch_match
    ble/array#push _ble_edit_nsearch_stack "backward,$old_match,$_ble_edit_ind,$_ble_edit_mark:$_ble_edit_str"
    local line; ble-edit/history/get-editted-entry -v line "$index"
    local prefix=${line%%"$needle"*}
    local beg=${#prefix}
    local end=$((beg+${#needle}))
    _ble_edit_nsearch_match=$index
    _ble_edit_nsearch_index=$index
    ble-edit/content/reset-and-check-dirty "$line"
    ((_ble_edit_mark=beg,_ble_edit_ind=end))
    if ((_ble_edit_mark!=_ble_edit_ind)); then
      _ble_edit_mark_active=search
    else
      _ble_edit_mark_active=
    fi
    ble-edit/nsearch/.show-status.fib
    ble/textarea#redraw
  elif ((ext==148)); then
    fib_suspend="index=$index start=$start"
    return 148
  else
    ble/widget/.bell "ble.sh: nsearch: '$needle' not found"
    ble-edit/nsearch/.show-status.fib
    if [[ $opt_forward ]]; then
      local count; ble-edit/history/get-count
      ((_ble_edit_nsearch_index=count-1))
    else
      ((_ble_edit_nsearch_index=0))
    fi
    return "$ext"
  fi
}
function ble-edit/nsearch/forward.fib {
  ble-edit/nsearch/.search.fib "$_ble_edit_nsearch_opts:forward"
}
function ble-edit/nsearch/backward.fib {
  ble-edit/nsearch/.search.fib "$_ble_edit_nsearch_opts:backward"
}
function ble/widget/history-search {
  local opts=$1
  ble-edit/content/clear-arg
  if [[ :$opts: == *:input:* ]]; then
    ble/builtin/read -ep "nsearch> " _ble_edit_nsearch_needle || return 1
  else
    _ble_edit_nsearch_needle=${_ble_edit_str::_ble_edit_ind}
  fi
  _ble_edit_nsearch_stack=()
  local index; ble-edit/history/get-index
  _ble_edit_nsearch_match=$index
  _ble_edit_nsearch_index=$index
  if [[ :$opts: == *:substr:* ]]; then
    _ble_edit_nsearch_opts=substr
  else
    _ble_edit_nsearch_opts=
  fi
  _ble_edit_mark_active=
  ble-decode/keymap/push nsearch
  ble/util/fiberchain#initialize ble-edit/nsearch
  if [[ :$opts: == *:forward:* ]]; then
    ble/util/fiberchain#push forward
  else
    ble/util/fiberchain#push backward
  fi
  ble/util/fiberchain#resume
}
function ble/widget/history-nsearch-backward {
  ble/widget/history-search input:substr:backward
}
function ble/widget/history-nsearch-forward {
  ble/widget/history-search input:substr:forward
}
function ble/widget/history-search-backward {
  ble/widget/history-search backward
}
function ble/widget/history-search-forward {
  ble/widget/history-search forward
}
function ble/widget/history-substring-search-backward {
  ble/widget/history-search substr:backward
}
function ble/widget/history-substring-search-forward {
  ble/widget/history-search substr:forward
}
function ble/widget/nsearch/forward {
  local ntask=${#_ble_util_fiberchain[@]}
  if ((ntask>=1)) && [[ ${_ble_util_fiberchain[ntask-1]%%:*} == backward ]]; then
    local ret; ble/array#pop _ble_util_fiberchain
  else
    ble/util/fiberchain#push forward
  fi
  ble/util/fiberchain#resume
}
function ble/widget/nsearch/backward {
  local ntask=${#_ble_util_fiberchain[@]}
  if ((ntask>=1)) && [[ ${_ble_util_fiberchain[ntask-1]%%:*} == forward ]]; then
    local ret; ble/array#pop _ble_util_fiberchain
  else
    ble/util/fiberchain#push backward
  fi
  ble/util/fiberchain#resume
}
function ble/widget/nsearch/exit {
  ble-decode/keymap/pop
  _ble_edit_mark_active=
  ble-edit/nsearch/erase-status
}
function ble/widget/nsearch/exit-default {
  ble/widget/nsearch/exit
  ble-decode-key "${KEYS[@]}"
}
function ble/widget/nsearch/cancel {
  if ((${#_ble_util_fiberchain[@]})); then
    ble/util/fiberchain#clear
    ble-edit/nsearch/show-status
  else
    ble/widget/nsearch/exit
    local record=${_ble_edit_nsearch_stack[0]}
    if [[ $record ]]; then
      local line=${record#*:}
      ble/string#split record , "${record%%:*}"
      ble-edit/content/reset-and-check-dirty "$line"
      _ble_edit_ind=${record[2]}
      _ble_edit_mark=${record[3]}
    fi
  fi
}
function ble/widget/nsearch/accept-line {
  if ((${#_ble_util_fiberchain[@]})); then
    ble/widget/.bell "nsearch: now searching..."
  else
    ble/widget/nsearch/exit
    ble-decode-key 13 # RET
  fi
}
function ble-decode/keymap:nsearch/define {
  local ble_bind_keymap=nsearch
  ble-bind -f __default__ nsearch/exit-default
  ble-bind -f 'C-g'       nsearch/cancel
  ble-bind -f 'C-x C-g'   nsearch/cancel
  ble-bind -f 'C-M-g'     nsearch/cancel
  ble-bind -f C-m         nsearch/exit
  ble-bind -f RET         nsearch/exit
  ble-bind -f C-j         nsearch/accept-line
  ble-bind -f C-RET       nsearch/accept-line
  ble-bind -f C-r         nsearch/backward
  ble-bind -f C-s         nsearch/forward
  ble-bind -f C-p         nsearch/backward
  ble-bind -f C-n         nsearch/forward
  ble-bind -f up          nsearch/backward
  ble-bind -f down        nsearch/forward
}
function ble-decode/keymap:safe/.bind {
  [[ $ble_bind_nometa && $1 == *M-* ]] && return
  ble-bind -f "$1" "$2"
}
function ble-decode/keymap:safe/bind-common {
  ble-decode/keymap:safe/.bind insert      'overwrite-mode'
  ble-decode/keymap:safe/.bind __batch_char__ 'batch-insert'
  ble-decode/keymap:safe/.bind __defchar__ 'self-insert'
  ble-decode/keymap:safe/.bind 'C-q'       'quoted-insert'
  ble-decode/keymap:safe/.bind 'C-v'       'quoted-insert'
  ble-decode/keymap:safe/.bind 'M-C-m'     'newline'
  ble-decode/keymap:safe/.bind 'M-RET'     'newline'
  ble-decode/keymap:safe/.bind paste_begin 'bracketed-paste'
  ble-decode/keymap:safe/.bind 'C-@'       'set-mark'
  ble-decode/keymap:safe/.bind 'C-SP'      'set-mark'
  ble-decode/keymap:safe/.bind 'NUL'       'set-mark'
  ble-decode/keymap:safe/.bind 'M-SP'      'set-mark'
  ble-decode/keymap:safe/.bind 'C-x C-x'   'exchange-point-and-mark'
  ble-decode/keymap:safe/.bind 'C-w'       'kill-region-or uword'
  ble-decode/keymap:safe/.bind 'M-w'       'copy-region-or uword'
  ble-decode/keymap:safe/.bind 'C-y'       'yank'
  ble-decode/keymap:safe/.bind 'M-\'       'delete-horizontal-space'
  ble-decode/keymap:safe/.bind 'C-f'       '@nomarked forward-char'
  ble-decode/keymap:safe/.bind 'C-b'       '@nomarked backward-char'
  ble-decode/keymap:safe/.bind 'right'     '@nomarked forward-char'
  ble-decode/keymap:safe/.bind 'left'      '@nomarked backward-char'
  ble-decode/keymap:safe/.bind 'S-C-f'     '@marked forward-char'
  ble-decode/keymap:safe/.bind 'S-C-b'     '@marked backward-char'
  ble-decode/keymap:safe/.bind 'S-right'   '@marked forward-char'
  ble-decode/keymap:safe/.bind 'S-left'    '@marked backward-char'
  ble-decode/keymap:safe/.bind 'C-d'       'delete-region-or forward-char'
  ble-decode/keymap:safe/.bind 'delete'    'delete-region-or forward-char'
  ble-decode/keymap:safe/.bind 'C-?'       'delete-region-or backward-char'
  ble-decode/keymap:safe/.bind 'DEL'       'delete-region-or backward-char'
  ble-decode/keymap:safe/.bind 'C-h'       'delete-region-or backward-char'
  ble-decode/keymap:safe/.bind 'BS'        'delete-region-or backward-char'
  ble-decode/keymap:safe/.bind 'C-t'       'transpose-chars'
  ble-decode/keymap:safe/.bind 'C-right'   '@nomarked forward-cword'
  ble-decode/keymap:safe/.bind 'C-left'    '@nomarked backward-cword'
  ble-decode/keymap:safe/.bind 'M-right'   '@nomarked forward-sword'
  ble-decode/keymap:safe/.bind 'M-left'    '@nomarked backward-sword'
  ble-decode/keymap:safe/.bind 'S-C-right' '@marked forward-cword'
  ble-decode/keymap:safe/.bind 'S-C-left'  '@marked backward-cword'
  ble-decode/keymap:safe/.bind 'M-S-right' '@marked forward-sword'
  ble-decode/keymap:safe/.bind 'M-S-left'  '@marked backward-sword'
  ble-decode/keymap:safe/.bind 'M-d'       'kill-forward-cword'
  ble-decode/keymap:safe/.bind 'M-h'       'kill-backward-cword'
  ble-decode/keymap:safe/.bind 'C-delete'  'delete-forward-cword'
  ble-decode/keymap:safe/.bind 'C-_'       'delete-backward-cword'
  ble-decode/keymap:safe/.bind 'C-DEL'     'delete-backward-cword'
  ble-decode/keymap:safe/.bind 'C-BS'      'delete-backward-cword'
  ble-decode/keymap:safe/.bind 'M-delete'  'copy-forward-sword'
  ble-decode/keymap:safe/.bind 'M-C-?'     'copy-backward-sword'
  ble-decode/keymap:safe/.bind 'M-DEL'     'copy-backward-sword'
  ble-decode/keymap:safe/.bind 'M-C-h'     'copy-backward-sword'
  ble-decode/keymap:safe/.bind 'M-BS'      'copy-backward-sword'
  ble-decode/keymap:safe/.bind 'M-f'       '@nomarked forward-cword'
  ble-decode/keymap:safe/.bind 'M-b'       '@nomarked backward-cword'
  ble-decode/keymap:safe/.bind 'M-F'       '@marked forward-cword'
  ble-decode/keymap:safe/.bind 'M-B'       '@marked backward-cword'
  ble-decode/keymap:safe/.bind 'M-S-f'     '@marked forward-cword'
  ble-decode/keymap:safe/.bind 'M-S-b'     '@marked backward-cword'
  ble-decode/keymap:safe/.bind 'C-a'       '@nomarked beginning-of-line'
  ble-decode/keymap:safe/.bind 'C-e'       '@nomarked end-of-line'
  ble-decode/keymap:safe/.bind 'home'      '@nomarked beginning-of-line'
  ble-decode/keymap:safe/.bind 'end'       '@nomarked end-of-line'
  ble-decode/keymap:safe/.bind 'S-C-a'     '@marked beginning-of-line'
  ble-decode/keymap:safe/.bind 'S-C-e'     '@marked end-of-line'
  ble-decode/keymap:safe/.bind 'S-home'    '@marked beginning-of-line'
  ble-decode/keymap:safe/.bind 'S-end'     '@marked end-of-line'
  ble-decode/keymap:safe/.bind 'M-m'       '@nomarked non-space-beginning-of-line'
  ble-decode/keymap:safe/.bind 'M-S-m'     '@marked non-space-beginning-of-line'
  ble-decode/keymap:safe/.bind 'M-M'       '@marked non-space-beginning-of-line'
  ble-decode/keymap:safe/.bind 'C-p'       '@nomarked backward-line' # overwritten by bind-history
  ble-decode/keymap:safe/.bind 'up'        '@nomarked backward-line' # overwritten by bind-history
  ble-decode/keymap:safe/.bind 'C-n'       '@nomarked forward-line'  # overwritten by bind-history
  ble-decode/keymap:safe/.bind 'down'      '@nomarked forward-line'  # overwritten by bind-history
  ble-decode/keymap:safe/.bind 'C-k'       'kill-forward-line'
  ble-decode/keymap:safe/.bind 'C-u'       'kill-backward-line'
  ble-decode/keymap:safe/.bind 'S-C-p'     '@marked backward-line'
  ble-decode/keymap:safe/.bind 'S-up'      '@marked backward-line'
  ble-decode/keymap:safe/.bind 'S-C-n'     '@marked forward-line'
  ble-decode/keymap:safe/.bind 'S-down'    '@marked forward-line'
  ble-decode/keymap:safe/.bind 'C-home'    '@nomarked beginning-of-text'
  ble-decode/keymap:safe/.bind 'C-end'     '@nomarked end-of-text'
  ble-decode/keymap:safe/.bind 'S-C-home'  '@marked beginning-of-text'
  ble-decode/keymap:safe/.bind 'S-C-end'   '@marked end-of-text'
}
function ble-decode/keymap:safe/bind-history {
  ble-decode/keymap:safe/.bind 'C-r'       'history-isearch-backward'
  ble-decode/keymap:safe/.bind 'C-s'       'history-isearch-forward'
  ble-decode/keymap:safe/.bind 'M-<'       'history-beginning'
  ble-decode/keymap:safe/.bind 'M->'       'history-end'
  ble-decode/keymap:safe/.bind 'C-prior'   'history-beginning'
  ble-decode/keymap:safe/.bind 'C-next'    'history-end'
  ble-decode/keymap:safe/.bind 'C-p'       '@nomarked backward-line history'
  ble-decode/keymap:safe/.bind 'up'        '@nomarked backward-line history'
  ble-decode/keymap:safe/.bind 'C-n'       '@nomarked forward-line history'
  ble-decode/keymap:safe/.bind 'down'      '@nomarked forward-line history'
  ble-decode/keymap:safe/.bind 'C-x C-p'   'history-search-backward'
  ble-decode/keymap:safe/.bind 'C-x up'    'history-search-backward'
  ble-decode/keymap:safe/.bind 'C-x C-n'   'history-search-forward'
  ble-decode/keymap:safe/.bind 'C-x down'  'history-search-forward'
  ble-decode/keymap:safe/.bind 'C-x p'     'history-substring-search-backward'
  ble-decode/keymap:safe/.bind 'C-x n'     'history-substring-search-forward'
  ble-decode/keymap:safe/.bind 'C-x <'     'history-nsearch-backward'
  ble-decode/keymap:safe/.bind 'C-x >'     'history-nsearch-forward'
}
function ble-decode/keymap:safe/bind-complete {
  ble-decode/keymap:safe/.bind 'C-i'       'complete'
  ble-decode/keymap:safe/.bind 'TAB'       'complete'
  ble-decode/keymap:safe/.bind 'M-?'       'complete show_menu'
  ble-decode/keymap:safe/.bind 'M-*'       'complete insert_all'
  ble-decode/keymap:safe/.bind 'C-TAB'     'menu-complete'
  ble-decode/keymap:safe/.bind 'auto_complete_enter' 'auto-complete-enter'
  ble-decode/keymap:safe/.bind 'M-/'       'complete context=filename'
  ble-decode/keymap:safe/.bind 'M-~'       'complete context=username'
  ble-decode/keymap:safe/.bind 'M-$'       'complete context=variable'
  ble-decode/keymap:safe/.bind 'M-@'       'complete context=hostname'
  ble-decode/keymap:safe/.bind 'M-!'       'complete context=command'
  ble-decode/keymap:safe/.bind 'C-x /'     'complete show_menu:context=filename'
  ble-decode/keymap:safe/.bind 'C-x ~'     'complete show_menu:context=username'
  ble-decode/keymap:safe/.bind 'C-x $'     'complete show_menu:context=variable'
  ble-decode/keymap:safe/.bind 'C-x @'     'complete show_menu:context=hostname'
  ble-decode/keymap:safe/.bind 'C-x !'     'complete show_menu:context=command'
  ble-decode/keymap:safe/.bind "M-'"       'sabbrev-expand'
  ble-decode/keymap:safe/.bind "C-x '"     'sabbrev-expand'
  ble-decode/keymap:safe/.bind 'C-x C-r'   'dabbrev-expand'
  ble-decode/keymap:safe/.bind 'M-g'       'complete context=glob'
  ble-decode/keymap:safe/.bind 'C-x *'     'complete insert_all:context=glob'
  ble-decode/keymap:safe/.bind 'C-x g'     'complete show_menu:context=glob'
}
function ble/widget/safe/__attach__ {
  ble-edit/info/set-default text ''
}
function ble-decode/keymap:safe/define {
  local ble_bind_keymap=safe
  local ble_bind_nometa=
  ble-decode/keymap:safe/bind-common
  ble-decode/keymap:safe/bind-history
  ble-decode/keymap:safe/bind-complete
  ble-bind -f 'C-d'      'delete-region-or forward-char-or-exit'
  ble-bind -f 'SP'       magic-space
  ble-bind -f 'M-^'      history-expand-line
  ble-bind -f __attach__ safe/__attach__
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
}
function ble-edit/bind/load-keymap-definition:safe {
  ble-decode/keymap/load safe
}
ble/util/autoload "keymap/emacs.sh" \
                  ble-decode/keymap:emacs/define
ble/util/autoload "keymap/vi.sh" \
                  ble-decode/keymap:vi_{i,n,o,x,s,c}map/define
ble/util/autoload "keymap/vi_digraph.sh" \
                  ble-decode/keymap:vi_digraph/define
_ble_edit_read_accept=
_ble_edit_read_result=
function ble/widget/read/accept {
  _ble_edit_read_accept=1
  _ble_edit_read_result=$_ble_edit_str
  ble-decode/keymap/pop
}
function ble/widget/read/cancel {
  local _ble_edit_line_disabled=1
  ble/widget/read/accept
  _ble_edit_read_accept=2
}
function ble-decode/keymap:read/define {
  local ble_bind_keymap=read
  local ble_bind_nometa=
  ble-decode/keymap:safe/bind-common
  ble-decode/keymap:safe/bind-history
  ble-bind -f 'C-c' read/cancel
  ble-bind -f 'C-\' read/cancel
  ble-bind -f 'C-m' read/accept
  ble-bind -f 'RET' read/accept
  ble-bind -f 'C-j' read/accept
  ble-bind -f  'C-g'     bell
  ble-bind -f  'C-l'     redraw-line
  ble-bind -f  'M-l'     redraw-line
  ble-bind -f  'C-x C-v' display-shell-version
  ble-bind -f 'C-]' bell
  ble-bind -f 'C-^' bell
}
_ble_edit_read_history=()
_ble_edit_read_history_edit=()
_ble_edit_read_history_dirt=()
_ble_edit_read_history_ind=0
_ble_edit_read_history_onleave=()
function ble/builtin/read/.process-option {
  case $1 in
  (-e) opt_readline=1 ;;
  (-i) opt_default=$2 ;;
  (-p) opt_prompt=$2 ;;
  (-u) opt_fd=$2
       ble/array#push opts_in "$@" ;;
  (-t) opt_timeout=$2 ;;
  (*)  ble/array#push opts "$@" ;;
  esac
}
function ble/builtin/read/.read-arguments {
  local is_normal_args=
  vars=()
  opts=()
  while (($#)); do
    local arg=$1; shift
    if [[ $is_normal_args || $arg != -* ]]; then
      ble/array#push vars "$arg"
      continue
    fi
    if [[ $arg == -- ]]; then
      is_normal_args=1
      continue
    fi
    local i n=${#arg}
    for ((i=1;i<n;i++)); do
      case -${arg:i} in
      (-[adinNptu])  ble/builtin/read/.process-option -${arg:i:1} "$1"; shift; break ;;
      (-[adinNptu]*) ble/builtin/read/.process-option -${arg:i:1} "${arg:i+1}"; break ;;
      (-[ers]*)      ble/builtin/read/.process-option -${arg:i:1} ;;
      esac
    done
  done
}
function ble/builtin/read/.setup-textarea {
  local def_kmap; ble-decode/DEFAULT_KEYMAP -v def_kmap
  ble-decode/keymap/push read
  [[ $_ble_edit_read_context == external ]] &&
    _ble_canvas_panel_height[0]=0
  _ble_textarea_panel=1
  ble/textarea#invalidate
  ble-edit/info/set-default ansi ''
  _ble_edit_PS1=$opt_prompt
  _ble_edit_prompt=("" 0 0 0 32 0 "" "")
  _ble_edit_dirty_observer=()
  ble/widget/.newline/clear-content
  _ble_edit_arg=
  ble-edit/content/reset "$opt_default" newline
  _ble_edit_ind=${#opt_default}
  ble-edit/undo/clear-all
  _ble_edit_history_prefix=_ble_edit_read_
  _ble_syntax_lang=text
  _ble_highlight_layer__list=(plain region overwrite_mode disabled)
}
function ble/builtin/read/TRAPWINCH {
  local IFS=$_ble_term_IFS
  _ble_textmap_pos=()
  ble/util/buffer "$_ble_term_ed"
  ble/textarea#redraw
}
function ble/builtin/read/.loop {
  set +m # ジョブ管理を無効にする
  shopt -u failglob
  local x0=$_ble_canvas_x y0=$_ble_canvas_y
  ble/builtin/read/.setup-textarea
  trap -- ble/builtin/read/TRAPWINCH WINCH
  local ret= timeout=
  if [[ $opt_timeout ]]; then
    ble/util/clock; local start_time=$ret
    ((start_time&&(start_time-=_ble_util_clock_reso-1)))
    if [[ $opt_timeout == *.* ]]; then
      local mantissa=${opt_timeout%%.*}
      local fraction=${opt_timeout##*.}000
      ((timeout=mantissa*1000+10#${fraction::3}))
    else
      ((timeout=opt_timeout*1000))
    fi
    ((timeout<0)) && timeout=
  fi
  ble-edit/info/reveal
  ble/textarea#render
  ble/util/buffer.flush >&2
  local _ble_decode_input_count=0
  local ble_decode_char_nest=
  local -a _ble_decode_char_buffer=()
  local char=
  local _ble_edit_read_accept=
  local _ble_edit_read_result=
  while [[ ! $_ble_edit_read_accept ]]; do
    local timeout_option=
    if [[ $timeout ]]; then
      if ((_ble_bash>=40000)); then
        local timeout_frac=000$((timeout%1000))
        timeout_option="-t $((timeout/1000)).${timeout_frac:${#timeout_frac}-3}"
      else
        timeout_option="-t $((timeout/1000))"
      fi
    fi
    IFS= builtin read -r -d '' -n 1 $timeout_option char "${opts_in[@]}"; local ext=$?
    if ((ext==142)); then
      _ble_edit_read_accept=142
      break
    fi
    if [[ $timeout ]]; then
      ble/util/clock; local current_time=$ret
      ((timeout-=current_time-start_time))
      if ((timeout<=0)); then
        _ble_edit_read_accept=142
        break
      fi
      start_time=$current_time
    fi
    ble/util/s2c "$char"
    ble-decode-char "$ret"
    [[ $_ble_edit_read_accept ]] && break
    ble/util/is-stdin-ready && continue
    ble-decode/.hook/erase-progress
    ble-edit/info/reveal
    ble/textarea#render
    ble/util/buffer.flush >&2
  done
  if [[ $_ble_edit_read_context == internal ]]; then
    local -a DRAW_BUFF=()
    ble/canvas/panel#set-height.draw "$_ble_textarea_panel" 0
    ble/canvas/goto.draw "$x0" "$y0"
    ble/canvas/bflush.draw
  else
    if ((_ble_edit_read_accept==1)); then
      ble/widget/.insert-newline
    else
      _ble_edit_line_disabled=1 ble/widget/.insert-newline
    fi
  fi
  ble/util/buffer.flush >&2
  if ((_ble_edit_read_accept==1)); then
    local q=\' Q="'\''"
    printf %s "__ble_input='${_ble_edit_read_result//$q/$Q}'"
  elif ((_ble_edit_read_accept==142)); then
    return "$ext"
  else
    return 1
  fi
}
function ble/builtin/read/.impl {
  local -a opts=() vars=() opts_in=()
  local opt_readline= opt_prompt= opt_default= opt_timeout= opt_fd=0
  ble/builtin/read/.read-arguments "$@"
  if ! [[ $opt_readline && -t $opt_fd ]]; then
    [[ $opt_prompt ]] && ble/array#push opts -p "$opt_prompt"
    [[ $opt_timeout ]] && ble/array#push opts -t "$opt_timeout"
    __ble_args=("${opts[@]}" "${opts_in[@]}" -- "${vars[@]}")
    __ble_command='builtin read "${__ble_args[@]}"'
    return
  fi
  ble-decode/keymap/load read
  local result _ble_edit_read_context=$_ble_term_state
  ble/util/buffer.flush >&2
  [[ $_ble_edit_read_context == external ]] && ble/term/enter # 外側にいたら入る
  result=$(ble/builtin/read/.loop); local ext=$?
  [[ $_ble_edit_read_context == external ]] && ble/term/leave # 元の状態に戻る
  [[ $_ble_edit_read_context == internal ]] && ((_ble_canvas_panel_height[1]=0))
  if ((ext==0)); then
    builtin eval -- "$result"
    __ble_args=("${opts[@]}" -- "${vars[@]}")
    __ble_command='builtin read "${__ble_args[@]}" <<< "$__ble_input"'
  fi
  return "$ext"
}
function ble/builtin/read {
  if [[ $_ble_decode_bind_state == none ]]; then
    builtin read "$@"
    return
  fi
  local __ble_command= __ble_args= __ble_input=
  ble/builtin/read/.impl "$@"; local __ble_ext=$?
  [[ $__ble_command ]] || return "$__ble_ext"
  builtin eval -- "$__ble_command"
  return
}
function read { ble/builtin/read "$@"; }
function ble/widget/command-help/.read-man {
  local pager="sh -c 'cat >| \"\$BLETMPFILE\"'" tmp=$_ble_util_assign_base
  BLETMPFILE=$tmp MANPAGER=$pager PAGER=$pager MANOPT= man "$@" 2>/dev/null; local ext=$? # 668ms
  ble/util/readfile man_content "$tmp" # 80ms
  return "$ext"
}
function ble/widget/command-help/.locate-in-man-bash {
  local command=$1
  local ret rex
  local rex_esc=$'(\e\\[[ -?]*[@-~]||.\b)' cr=$'\r'
  local pager; ble/util/get-pager pager
  local pager_cmd=${pager%%[$' \t\n']*}
  [[ ${pager_cmd##*/} == less ]] || return 1
  local awk=awk; type -t gawk &>/dev/null && awk=gawk
  local man_content; ble/widget/command-help/.read-man bash || return 1 # 733ms (3 fork: man, sh, cat)
  local cmd_awk
  case $command in
  ('function')  cmd_awk='name () compound-command' ;;
  ('until')     cmd_awk=while ;;
  ('command')   cmd_awk='command [' ;;
  ('source')    cmd_awk=. ;;
  ('typeset')   cmd_awk=declare ;;
  ('readarray') cmd_awk=mapfile ;;
  ('[')         cmd_awk=test ;;
  (*)           cmd_awk=$command ;;
  esac
  ble/string#escape-for-awk-regex "$cmd_awk"; local rex_awk=$ret
  rex='\b$'; [[ $awk == gawk && $cmd_awk =~ $rex ]] && rex_awk=$rex_awk'\y'
  local awk_script='{
    gsub(/'"$rex_esc"'/, "");
    if (!par && $0 ~ /^[[:space:]]*'"$rex_awk"'/) { print NR; exit; }
    par = !($0 ~ /^[[:space:]]*$/);
  }'
  local awk_out; ble/util/assign awk_out '"$awk" "$awk_script" 2>/dev/null <<< "$man_content"' || return 1 # 206ms (1 fork)
  local iline=${awk_out%$'\n'}; [[ $iline ]] || return 1
  ble/string#escape-for-extended-regex "$command"; local rex_ext=$ret
  rex='\b$'; [[ $command =~ $rex ]] && rex_ext=$rex_ext'\b'
  rex='^\b'; [[ $command =~ $rex ]] && rex_ext="($rex_esc|\b)$rex_ext"
  local manpager="$pager -r +'/$rex_ext$cr$((iline-1))g'"
  eval "$manpager" <<< "$man_content" # 1 fork
}
function ble/widget/command-help.core {
  ble/function#try ble/cmdinfo/help:"$command" && return
  ble/function#try ble/cmdinfo/help "$command" && return
  if [[ $type == builtin || $type == keyword ]]; then
    ble/widget/command-help/.locate-in-man-bash "$command" && return
  elif [[ $type == function ]]; then
    local pager=ble/util/pager
    type -t source-highlight &>/dev/null &&
      pager='source-highlight -s sh -f esc | '$pager
    LESS="$LESS -r" eval 'declare -f "$command" | '"$pager" && return
  fi
  if ble/is-function ble/bin/man; then
    MANOPT= ble/bin/man "${command##*/}" 2>/dev/null && return
  fi
  if local content; content=$("$command" --help 2>&1) && [[ $content ]]; then
    builtin printf '%s\n' "$content" | ble/util/pager
    return 0
  fi
  echo "ble: help of \`$command' not found" >&2
  return 1
}
function ble/widget/command-help/.type/.resolve-alias {
  local literal=$1 command=$2 type=alias
  local last_literal=$1 last_command=$2
  while
    [[ $command == "$literal" ]] || break # Note: type=alias
    local old_literal=$literal old_command=$command
    local alias_def
    ble/util/assign alias_def "alias $command"
    unalias "$command"
    eval "alias_def=${alias_def#*=}" # remove quote
    literal=${alias_def%%[$' \t\n']*} command= type=
    ble/syntax:bash/simple-word/is-simple "$literal" || break # Note: type=
    local ret; ble/syntax:bash/simple-word/eval "$literal"; command=$ret
    ble/util/type type "$command"
    [[ $type ]] || break # Note: type=
    last_literal=$literal
    last_command=$command
    [[ $type == alias ]]
  do :; done
  if [[ ! $type || $type == alias ]]; then
    literal=$last_literal
    command=$last_command
    unalias "$command" &>/dev/null
    ble/util/type type "$command"
  fi
  local q="'" Q="'\''"
  printf "type='%s'\n" "${type//$q/$Q}"
  printf "literal='%s'\n" "${literal//$q/$Q}"
  printf "command='%s'\n" "${command//$q/$Q}"
  return
} 2>/dev/null
function ble/widget/command-help/.type {
  local literal=$1
  type= command=
  ble/syntax:bash/simple-word/is-simple "$literal" || return 1
  local ret; ble/syntax:bash/simple-word/eval "$literal"; command=$ret
  ble/util/type type "$command"
  if [[ $type == alias ]]; then
    eval "$(ble/widget/command-help/.type/.resolve-alias "$literal" "$command")"
  fi
  if [[ $type == keyword && $command != "$literal" ]]; then
    if [[ $command == %* ]] && jobs -- "$command" &>/dev/null; then
      type=jobs
    elif ble/is-function "$command"; then
      type=function
    elif enable -p | ble/bin/grep -q -F -x "enable $cmd" &>/dev/null; then
      type=builtin
    elif type -P -- "$cmd" &>/dev/null; then
      type=file
    else
      type=
      return 1
    fi
  fi
}
function ble/widget/command-help.impl {
  local literal=$1
  if [[ ! $literal ]]; then
    ble/widget/.bell
    return 1
  fi
  local type command; ble/widget/command-help/.type "$literal"
  if [[ ! $type ]]; then
    ble/widget/.bell "command \`$command' not found"
    return 1
  fi
  ble/widget/external-command ble/widget/command-help.core
}
function ble/widget/command-help {
  ble-edit/content/clear-arg
  local comp_cword comp_words comp_line comp_point
  if ble/syntax:bash/extract-command "$_ble_edit_ind"; then
    local cmd=${comp_words[0]}
  else
    local args; ble/string#split-words args "$_ble_edit_str"
    local cmd=${args[0]}
  fi
  ble/widget/command-help.impl "$cmd"
}
function ble-edit/bind/stdout.on { :;}
function ble-edit/bind/stdout.off { ble/util/buffer.flush >&2;}
function ble-edit/bind/stdout.finalize { :;}
if [[ $bleopt_internal_suppress_bash_output ]]; then
  _ble_edit_io_stdout=
  _ble_edit_io_stderr=
  ble/util/openat _ble_edit_io_stdout '>&1'
  ble/util/openat _ble_edit_io_stderr '>&2'
  _ble_edit_io_fname1=$_ble_base_run/$$.stdout
  _ble_edit_io_fname2=$_ble_base_run/$$.stderr
  function ble-edit/bind/stdout.on {
    exec 1>&$_ble_edit_io_stdout 2>&$_ble_edit_io_stderr
  }
  function ble-edit/bind/stdout.off {
    ble/util/buffer.flush >&2
    ble-edit/bind/stdout/check-stderr
    exec 1>>$_ble_edit_io_fname1 2>>$_ble_edit_io_fname2
  }
  function ble-edit/bind/stdout.finalize {
    ble-edit/bind/stdout.on
    [[ -f $_ble_edit_io_fname1 ]] && ble/bin/rm -f "$_ble_edit_io_fname1"
    [[ -f $_ble_edit_io_fname2 ]] && ble/bin/rm -f "$_ble_edit_io_fname2"
  }
  function ble-edit/bind/stdout/check-stderr {
    local file=${1:-$_ble_edit_io_fname2}
    if ble/is-function ble/term/visible-bell; then
      if [[ -f $file && -s $file ]]; then
        local message= line
        while IFS= builtin read -r line || [[ $line ]]; do
          if [[ $line == 'bash: '* || $line == "${BASH##*/}: "* ]]; then
            message="$message${message:+; }$line"
          fi
        done < "$file"
        [[ $message ]] && ble/term/visible-bell "$message"
        : >| "$file"
      fi
    fi
  }
  if ((_ble_bash<40000)); then
    function ble-edit/bind/stdout/TRAPUSR1 {
      [[ $_ble_term_state == internal ]] || return
      local IFS=$' \t\n'
      local file=$_ble_edit_io_fname2.proc
      if [[ -s $file ]]; then
        local content cmd
        ble/util/readfile content "$file"
        : >| "$file"
        for cmd in $content; do
          case "$cmd" in
          (eof)
            ble-decode/.hook 4
            builtin eval "$_ble_decode_bind_hook" ;;
          esac
        done
      fi
    }
    trap -- 'ble-edit/bind/stdout/TRAPUSR1' USR1
    ble/bin/rm -f "$_ble_edit_io_fname2.pipe"
    ble/bin/mkfifo "$_ble_edit_io_fname2.pipe"
    {
      {
        function ble-edit/stdout/check-ignoreeof-message {
          local line=$1
          [[ $line == *$bleopt_internal_ignoreeof_trap* ||
               $line == *'Use "exit" to leave the shell.'* ||
               $line == *'ログアウトする為には exit を入力して下さい'* ||
               $line == *'シェルから脱出するには "exit" を使用してください。'* ||
               $line == *'シェルから脱出するのに "exit" を使いなさい.'* ||
               $line == *'Gebruik Kaart na Los Tronk'* ]] && return 0
          [[ $line == *exit* ]] && ble/bin/grep -q -F "$line" "$_ble_base"/lib/core-edit.ignoreeof-messages.txt
        }
        while IFS= builtin read -r line; do
          SPACE=$' \n\t'
          if [[ $line == *[^$SPACE]* ]]; then
            builtin printf '%s\n' "$line" >> "$_ble_edit_io_fname2"
          fi
          if [[ $bleopt_internal_ignoreeof_trap ]] && ble-edit/stdout/check-ignoreeof-message "$line"; then
            builtin echo eof >> "$_ble_edit_io_fname2.proc"
            kill -USR1 $$
            ble/util/msleep 100 # 連続で送ると bash が落ちるかも (落ちた事はないが念の為)
          fi
        done < "$_ble_edit_io_fname2.pipe"
      } &>/dev/null & disown
    } &>/dev/null
    ble/util/openat _ble_edit_fd_stderr_pipe '> "$_ble_edit_io_fname2.pipe"'
    function ble-edit/bind/stdout.off {
      ble/util/buffer.flush >&2
      ble-edit/bind/stdout/check-stderr
      exec 1>>$_ble_edit_io_fname1 2>&$_ble_edit_fd_stderr_pipe
    }
  fi
fi
[[ $_ble_edit_detach_flag != reload ]] &&
  _ble_edit_detach_flag=
function ble-edit/bind/.exit-TRAPRTMAX {
  ble/base/unload
  builtin exit 0
}
function ble-edit/bind/.check-detach {
  if [[ ! -o emacs && ! -o vi ]]; then
    builtin echo "${_ble_term_setaf[9]}[ble: unsupported]$_ble_term_sgr0 Sorry, ble.sh is supported only with some editing mode (set -o emacs/vi)." 1>&2
    ble-detach
  fi
  if [[ $_ble_edit_detach_flag || ! $_ble_attached ]]; then
    type=$_ble_edit_detach_flag
    _ble_edit_detach_flag=
    local attached=$_ble_attached
    [[ $attached ]] && ble-detach/impl
    if [[ $type == exit ]]; then
      ble-detach/message "${_ble_term_setaf[12]}[ble: exit]$_ble_term_sgr0"
      trap 'ble-edit/bind/.exit-TRAPRTMAX' RTMAX
      kill -RTMAX $$
    else
      ble-detach/message \
        "${_ble_term_setaf[12]}[ble: detached]$_ble_term_sgr0" \
        "Please run \`stty sane' to recover the correct TTY state."
      if ((_ble_bash>=40000)); then
        READLINE_LINE='stty sane;' READLINE_POINT=10
        printf %s "$READLINE_LINE"
      fi
    fi
    if [[ $attached ]]; then
      ble/base/restore-bash-options
      ble/base/restore-POSIXLY_CORRECT
      builtin eval "$_ble_base_restore_FUNCNEST" # これ以降関数は呼び出せない
    else
      ble-edit/exec:"$bleopt_internal_exec_type"/.eval-prologue
    fi
    return 0
  else
    local state=$_ble_decode_bind_state
    if [[ ( $state == emacs || $state == vi ) && ! -o $state ]]; then
      ble-decode/reset-default-keymap
      ble-decode/detach
      ble-decode/attach
    fi
    return 1
  fi
}
if ((_ble_bash>=40100)); then
  function ble-edit/bind/.head/adjust-bash-rendering {
    ble/textarea#redraw-cache
    ble/util/buffer.flush >&2
  }
else
  function ble-edit/bind/.head/adjust-bash-rendering {
    ((_ble_canvas_y++,_ble_canvas_x=0))
    local -a DRAW_BUFF=()
    ble/canvas/panel#goto.draw "$_ble_textarea_panel" "${_ble_edit_cur[0]}" "${_ble_edit_cur[1]}"
    ble/canvas/flush.draw
  }
fi
function ble-edit/bind/.head {
  ble-edit/bind/stdout.on
  [[ $bleopt_internal_suppress_bash_output ]] ||
    ble-edit/bind/.head/adjust-bash-rendering
}
function ble-edit/bind/.tail-without-draw {
  ble-edit/bind/stdout.off
}
if ((_ble_bash>=40000)); then
  function ble-edit/bind/.tail {
    ble-edit/info/reveal
    ble/textarea#render
    ble/util/idle.do && ble/textarea#render
    ble/textarea#adjust-for-bash-bind # bash-4.0+
    ble-edit/bind/stdout.off
  }
else
  function ble-edit/bind/.tail {
    ble-edit/info/reveal
    ble/textarea#render # bash-3 では READLINE_LINE を設定する方法はないので常に 0 幅
    ble/util/idle.do && ble/textarea#render # bash-4.0+
    ble-edit/bind/stdout.off
  }
fi
function ble-decode/PROLOGUE {
  ble-edit/bind/.head
  ble-decode-bind/uvw
  ble/term/enter
}
function ble-decode/EPILOGUE {
  if ((_ble_bash>=40000)); then
    if ble-decode/has-input; then
      ble-edit/bind/.tail-without-draw
      return 0
    fi
  fi
  "ble-edit/exec:$bleopt_internal_exec_type/process" && return 0
  ble-edit/bind/.tail
  return 0
}
function ble/widget/print {
  ble-edit/content/clear-arg
  local message=$1
  [[ ${message//[$_ble_term_IFS]} ]] || return
  _ble_edit_line_disabled=1 ble/widget/.insert-newline
  ble/util/buffer.flush >&2
  builtin printf '%s\n' "$message" >&2
}
function ble/widget/internal-command {
  ble-edit/content/clear-arg
  local -a BASH_COMMAND
  BASH_COMMAND=("$*")
  [[ ${BASH_COMMAND//[$_ble_term_IFS]} ]] || return 1
  _ble_edit_line_disabled=1 ble/widget/.insert-newline
  eval "$BASH_COMMAND"
}
function ble/widget/external-command {
  ble-edit/content/clear-arg
  local -a BASH_COMMAND
  BASH_COMMAND=("$*")
  [[ ${BASH_COMMAND//[$_ble_term_IFS]} ]] || return 1
  ble-edit/info/hide
  ble/textarea#invalidate
  local -a DRAW_BUFF=()
  ble/canvas/panel#set-height.draw "$_ble_textarea_panel" 0
  ble/canvas/panel#goto.draw "$_ble_textarea_panel" 0 0
  ble/canvas/bflush.draw
  ble/term/leave
  ble/util/buffer.flush >&2
  eval "$BASH_COMMAND"; local ext=$?
  ble/term/enter
  return "$ext"
}
function ble/widget/execute-command {
  ble-edit/content/clear-arg
  local -a BASH_COMMAND
  BASH_COMMAND=("$*")
  _ble_edit_line_disabled=1 ble/widget/.insert-newline
  [[ ${BASH_COMMAND//[$_ble_term_IFS]} ]] || return 1
  ble-edit/exec/register "$BASH_COMMAND"
}
function ble/widget/.SHELL_COMMAND { ble/widget/execute-command "$@"; }
function ble/widget/.EDIT_COMMAND {
  local command=$1
  local READLINE_LINE=$_ble_edit_str
  local READLINE_POINT=$_ble_edit_ind
  ble/widget/.hide-current-line
  ble/util/buffer.flush >&2
  eval "$command" || return 1
  ble-edit/content/clear-arg
  [[ $READLINE_LINE != "$_ble_edit_str" ]] &&
    ble-edit/content/reset-and-check-dirty "$READLINE_LINE"
  ((_ble_edit_ind=READLINE_POINT))
}
function ble-decode/DEFAULT_KEYMAP {
  local ret
  bleopt/get:default_keymap; local defmap=$ret
  if ble-edit/bind/load-keymap-definition "$defmap"; then
    if [[ $defmap == vi ]]; then
      builtin eval -- "$2=vi_imap"
    else
      builtin eval -- "$2=\$defmap"
    fi && ble-decode/keymap/is-keymap "${!2}" && return 0
  fi
  echo "ble.sh: The definition of the default keymap \"$bleopt_default_keymap\" is not found. ble.sh uses \"safe\" keymap instead."
  ble-edit/bind/load-keymap-definition safe &&
    builtin eval -- "$2=safe" &&
    bleopt_default_keymap=safe
}
function ble-edit/bind/load-keymap-definition {
  local name=$1
  if ble/is-function ble-edit/bind/load-keymap-definition:"$name"; then
    ble-edit/bind/load-keymap-definition:"$name"
  else
    source "$_ble_base/keymap/$name.sh"
  fi
}
function ble-edit/bind/clear-keymap-definition-loader {
  unset -f ble-edit/bind/load-keymap-definition:safe
  unset -f ble-edit/bind/load-keymap-definition:emacs
  unset -f ble-edit/bind/load-keymap-definition:vi
}
function ble-edit/initialize {
  ble-edit/prompt/initialize
}
function ble-edit/attach {
  ble-edit/attach/.attach
  _ble_canvas_x=0 _ble_canvas_y=0
  ble/util/buffer "$_ble_term_cr"
}
function ble-edit/reset-history {
  if ((_ble_bash>=40000)); then
    _ble_edit_history_loaded=
    ble-edit/history/clear-background-load
    ble/util/idle.push 'ble-edit/history/load async'
  elif ((_ble_bash>=30100)) && [[ $bleopt_history_lazyload ]]; then
    _ble_edit_history_loaded=
  else
    ble-edit/history/load
  fi
}
function ble-edit/detach {
  ble-edit/bind/stdout.finalize
  ble-edit/attach/.detach
}
ble/function#try ble/util/idle.push 'ble/util/import "$_ble_base/lib/core-complete.sh"'
ble/util/autoload "$_ble_base/lib/core-complete.sh" \
             ble/widget/complete \
             ble/widget/menu-complete \
             ble/widget/auto-complete-enter \
             ble/widget/sabbrev-expand \
             ble/widget/dabbrev-expand \
             ble-sabbrev
_ble_complete_load_hook=()
_ble_complete_insert_hook=()
if ! declare -p _ble_complete_sabbrev &>/dev/null; then # reload #D0875
  if ((_ble_bash>=40200)); then
    declare -gA _ble_complete_sabbrev=()
  elif ((_ble_bash>=40000&&!_ble_bash_loaded_in_function)); then
    declare -A _ble_complete_sabbrev=()
  fi
fi
bleopt/declare -n complete_polling_cycle 50
bleopt_complete_stdin_frequency='[obsoleted]'
function bleopt/check:complete_stdin_frequency {
  var=bleopt_complete_polling_cycle
  echo 'bleopt: The option "complete_stdin_frequency" is obsoleted. Please use "complete_polling_cycle".' >&2
  return 0
}
bleopt/declare -v complete_ambiguous 1
bleopt/declare -v complete_contract_function_names 1
bleopt/declare -v complete_auto_complete 1
bleopt/declare -v complete_auto_history 1
bleopt/declare -n complete_auto_delay 1
bleopt/declare -n complete_menu_style align-nowrap
function bleopt/check:complete_menu_style {
  if ! ble/is-function "ble/complete/menu/style:$value/construct"; then
    echo "bleopt: Invalid value complete_menu_style='$value'." \
         "A function 'ble/complete/menu/style:$value/construct' is not defined." >&2
    return 1
  fi
  return 0
}
bleopt/declare -n complete_menu_align 20
bleopt/declare -v complete_menu_complete 1
bleopt/declare -v complete_menu_filter 1
ble/util/autoload "$_ble_base/lib/core-complete.sh" \
                  ble/complete/menu/style:align/construct \
                  ble/complete/menu/style:align-nowrap/construct \
                  ble/complete/menu/style:dense/construct \
                  ble/complete/menu/style:dense-nowrap/construct \
                  ble-decode/keymap:auto_complete/define \
                  ble-decode/keymap:menu_complete/define \
                  ble-decode/keymap:dabbrev/define \
                  ble/complete/sabbrev/expand
ble-color-defface menu_complete fg=12,bg=252
ble-color-defface auto_complete bg=254,fg=238
_ble_syntax_VARNAMES=(
  _ble_syntax_text
  _ble_syntax_lang
  _ble_syntax_attr_umin
  _ble_syntax_attr_umax
  _ble_syntax_word_umin
  _ble_syntax_word_umax
  _ble_syntax_vanishing_word_umin
  _ble_syntax_vanishing_word_umax
  _ble_syntax_dbeg
  _ble_syntax_dend)
_ble_syntax_ARRNAMES=(
  _ble_syntax_stat
  _ble_syntax_nest
  _ble_syntax_tree
  _ble_syntax_attr)
_ble_syntax_lang=bash
function ble/highlight/layer:syntax/update { return; }
function ble/highlight/layer:syntax/getg { return; }
function ble/syntax:bash/is-complete { true; }
ble/util/autoload "$_ble_base/lib/core-syntax.sh" \
             ble/syntax/completion-context/generate \
             ble/syntax:bash/is-complete \
             ble/syntax:bash/extract-command \
             ble/syntax:bash/simple-word/eval \
             ble/syntax:bash/simple-word/is-simple \
             ble/syntax:bash/simple-word/reconstruct-incomplete-word
function ble/syntax/import {
  ble/util/import "$_ble_base/lib/core-syntax.sh"
}
ble/function#try ble/util/idle.push ble/syntax/import ||
  ble/syntax/import
bleopt/declare -v filename_ls_colors ''
if ((_ble_bash>=40200||_ble_bash>=40000&&!_ble_bash_loaded_in_function)); then
  if ((_ble_bash>=40200)); then
    declare -gA _ble_syntax_highlight_filetype=()
    declare -gA _ble_syntax_highlight_lscolors_ext=()
  else
    declare -A _ble_syntax_highlight_filetype=()
    declare -A _ble_syntax_highlight_lscolors_ext=()
  fi
fi
_ble_attached=
function ble-attach {
  if (($#)); then
    ble/base/print-usage-for-no-argument-command 'Attach to ble.sh.' "$@"
    return
  fi
  if [[ $_ble_edit_detach_flag ]]; then
    case $_ble_edit_detach_flag in
    (exit) return 0 ;;
    (*) _ble_edit_detach_flag= ;; # cancel "detach"
    esac
  fi
  [[ $_ble_attached ]] && return
  _ble_attached=1
  ble/base/adjust-bash-options
  ble/base/adjust-POSIXLY_CORRECT
  ble/canvas/attach
  ble/term/enter      # 3ms (起動時のずれ防止の為 stty)
  ble-edit/initialize # 3ms
  ble-edit/attach     # 0ms (_ble_edit_PS1 他の初期化)
  ble/textarea#redraw # 37ms
  ble/util/buffer.flush >&2
  local IFS=$' \t\n'
  ble-decode/initialize # 7ms
  ble-decode/reset-default-keymap # 264ms (keymap/vi.sh)
  if ! ble-decode/attach; then # 53ms
    _ble_attached=
    ble-edit/detach
    return 1
  fi
  ble-edit/reset-history # 27s for bash-3.0
  ble-edit/info/default
  ble-edit/bind/.tail
}
function ble-detach {
  if (($#)); then
    ble/base/print-usage-for-no-argument-command 'Detach from ble.sh.' "$@"
    return
  fi
  [[ $_ble_attached && ! $_ble_edit_detach_flag ]] || return
  _ble_edit_detach_flag=${1:-detach} # schedule detach
}
function ble-detach/impl {
  [[ $_ble_attached ]] || return
  _ble_attached=
  ble-edit/detach
  ble-decode/detach
  READLINE_LINE='' READLINE_POINT=0
}
function ble-detach/message {
  ble/util/buffer.flush >&2
  printf '%s\n' "$@" 1>&2
  ble-edit/info/hide
  ble/textarea#render
  ble/util/buffer.flush >&2
}
function ble/base/unload-for-reload {
  if [[ $_ble_attached ]]; then
    ble-detach/impl
    echo "${_ble_term_setaf[12]}[ble: reload]$_ble_term_sgr0" 1>&2
    [[ $_ble_edit_detach_flag ]] ||
      _ble_edit_detach_flag=reload
  fi
  ble/base/unload
  return 0
}
function ble/base/unload {
  ble/util/is-running-in-subshell && return 1
  local IFS=$' \t\n'
  ble/term/stty/TRAPEXIT
  ble/term/leave
  ble/util/buffer.flush >&2
  ble/util/openat/finalize
  ble/util/import/finalize
  ble-edit/bind/clear-keymap-definition-loader
  ble/bin/rm -f "$_ble_base_run/$$".*
  return 0
}
trap ble/base/unload EXIT
_ble_base_attach_PROMPT_COMMAND=
_ble_base_attach_from_prompt=
function ble/base/attach-from-PROMPT_COMMAND {
  [[ $PROMPT_COMMAND != ble/base/attach-from-PROMPT_COMMAND ]] && local PROMPT_COMMAND
  PROMPT_COMMAND=$_ble_base_attach_PROMPT_COMMAND
  ble-edit/prompt/update/.eval-prompt_command
  [[ $_ble_base_attach_from_prompt ]] || return 0
  _ble_base_attach_from_prompt=
  ble-attach
  ble/util/joblist.flush &>/dev/null
  ble/util/joblist.check
}
function ble/base/process-blesh-arguments {
  local opt_attach=attach
  local opt_rcfile=
  local opt_error=
  while (($#)); do
    local arg=$1; shift
    case $arg in
    (--noattach|noattach)
      opt_attach=none ;;
    (--attach=*) opt_attach=${arg#*=} ;;
    (--attach)   opt_attach=$1; shift ;;
    (--rcfile=*|--init-file=*|--rcfile|--init-file)
      if [[ $arg != *=* ]]; then
        local rcfile=$1; shift
      else
        local rcfile=${arg#*=}
      fi
      if [[ $rcfile && -f $rcfile ]]; then
        _ble_base_rcfile=$rcfile
      else
        echo "ble.sh ($arg): '$rcfile' is not a regular file." >&2
        opt_error=1
      fi ;;
    (*)
      echo "ble.sh: unrecognized argument '$arg'" >&2
      opt_error=1
    esac
  done
  if [[ ! $_ble_base_rcfile ]]; then
    { _ble_base_rcfile=$HOME/.blerc; [[ -f $rcfile ]]; } ||
      { _ble_base_rcfile=${XDG_CONFIG_HOME:-$HOME/.config}/blesh/init.sh; [[ -f $rcfile ]]; } ||
      _ble_base_rcfile=$HOME/.blerc
  fi
  [[ -s $_ble_base_rcfile ]] && source "$_ble_base_rcfile"
  case $opt_attach in
  (attach) ble-attach ;;
  (prompt) _ble_base_attach_PROMPT_COMMAND=$PROMPT_COMMAND
           _ble_base_attach_from_prompt=1
           PROMPT_COMMAND=ble/base/attach-from-PROMPT_COMMAND
           [[ $_ble_edit_detach_flag == reload ]] &&
             _ble_edit_detach_flag= ;;
  esac
  [[ ! $opt_error ]]
}
ble/base/process-blesh-arguments "$@"
IFS=$_ble_init_original_IFS
unset -v _ble_init_original_IFS
if [[ ! $_ble_attached ]]; then
  ble/base/restore-bash-options
  ble/base/restore-POSIXLY_CORRECT
fi &>/dev/null # set -x 対策 #D0930
{ return 0; } &>/dev/null # set -x 対策 #D0930
