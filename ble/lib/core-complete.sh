# this script is a part of blesh (https://github.com/akinomyoga/ble.sh) under BSD-3-Clause license
ble/util/import "$_ble_base/lib/core-syntax.sh"
function ble/complete/string#search-longest-suffix-in {
  local needle=$1 haystack=$2
  local l=0 u=${#needle}
  while ((l<u)); do
    local m=$(((l+u)/2))
    if [[ $haystack == *"${needle:m}"* ]]; then
      u=$m
    else
      l=$((m+1))
    fi
  done
  ret=${needle:l}
}
function ble/complete/string#common-suffix-prefix {
  local lhs=$1 rhs=$2
  if ((${#lhs}<${#rhs})); then
    local i n=${#lhs}
    for ((i=0;i<n;i++)); do
      ret=${lhs:i}
      [[ $rhs == "$ret"* ]] && return
    done
    ret=
  else
    local j m=${#rhs}
    for ((j=m;j>0;j--)); do
      ret=${rhs::j}
      [[ $lhs == *"$ret" ]] && return
    done
    ret=
  fi
}
function ble/complete/check-cancel {
  [[ :$comp_type: != *:sync:* ]] && ble-decode/has-input
}
function ble/complete/string#escape-for-completion-context {
  local str=$1
  case $comps_flags in
  (*S*)    ble/string#escape-for-bash-single-quote "$str"  ;;
  (*E*)    ble/string#escape-for-bash-escape-string "$str" ;;
  (*[DI]*) ble/string#escape-for-bash-double-quote "$str"  ;;
  (*)
    if [[ $comps_fixed ]]; then
      ble/string#escape-for-bash-specialchars-in-brace "$str"
    else
      ble/string#escape-for-bash-specialchars "$str"
    fi ;;
  esac
}
function ble/complete/action/util/complete.addtail {
  suffix=$suffix$1
}
function ble/complete/action/util/complete.mark-directory {
  [[ :$comp_type: == *:markdir:* && $CAND != */ ]] &&
    [[ :$comp_type: == *:marksymdir:* || ! -h $CAND ]] &&
    ble/complete/action/util/complete.addtail /
}
function ble/complete/action/util/complete.close-quotation {
  case $comps_flags in
  (*[SE]*) ble/complete/action/util/complete.addtail \' ;;
  (*[DI]*) ble/complete/action/util/complete.addtail \" ;;
  esac
}
function ble/complete/action/util/quote-insert {
  if [[ $comps_flags == *v* && $CAND == "$COMPV"* ]]; then
    local ins=${CAND:${#COMPV}} ret
    ble/complete/string#escape-for-completion-context "$ins"; ins=$ret
    if [[ $comps_flags == *p* && $ins == [a-zA-Z_0-9]* ]]; then
      case $comps_flags in
      (*[DI]*)
        if [[ $COMPS =~ $rex_raw_paramx ]]; then
          local rematch1=${BASH_REMATCH[1]}
          INSERT=$rematch1'${'${COMPS:${#rematch1}+1}'}'$ins
          return
        else
          ins='""'$ins
        fi ;;
      (*) ins='\'$ins ;;
      esac
    fi
    [[ $comps_flags == *B* && $COMPS == *'\' && $ins == '\'* ]] && ins=${ins:1}
    INSERT=$COMPS$ins
  elif [[ $comps_fixed && $CAND == "${comps_fixed#*:}"* ]]; then
    local comps_fixed_part=${COMPS::${comps_fixed%%:*}}
    local compv_fixed_part=${comps_fixed#*:}
    local ins=${CAND:${#compv_fixed_part}}
    local ret; ble/string#escape-for-bash-specialchars-in-brace "$ins"
    INSERT=$comps_fixed_part$ret
  else
    local ret
    ble/string#escape-for-bash-specialchars "$CAND"; INSERT=$ret
  fi
}
function ble/complete/action/inherit-from {
  local dst=$1 src=$2
  local member srcfunc dstfunc
  for member in initialize complete getg get-desc; do
    srcfunc=ble/complete/action:$src/$member
    dstfunc=ble/complete/action:$dst/$member
    ble/is-function "$srcfunc" && eval "function $dstfunc { $srcfunc; }"
  done
}
function ble/complete/action:plain/initialize {
  ble/complete/action/util/quote-insert
}
function ble/complete/action:plain/complete { :; }
function ble/complete/action:word/initialize {
  ble/complete/action/util/quote-insert
}
function ble/complete/action:word/complete {
  ble/complete/action/util/complete.close-quotation
  if [[ $comps_flags == *x* ]]; then
    ble/complete/action/util/complete.addtail ','
  else
    ble/complete/action/util/complete.addtail ' '
  fi
}
function ble/complete/action:word/get-desc {
  [[ $DATA ]] && desc=$DATA
}
function ble/complete/action:literal-substr/initialize { :; }
function ble/complete/action:literal-substr/complete { :; }
function ble/complete/action:literal-word/initialize { :; }
function ble/complete/action:literal-word/complete { ble/complete/action:word/complete; }
function ble/complete/action:substr/initialize { ble/complete/action:word/initialize; }
function ble/complete/action:substr/complete { :; }
function ble/complete/action:file/initialize {
  ble/complete/action/util/quote-insert
}
function ble/complete/action:file/complete {
  if [[ -e $CAND || -h $CAND ]]; then
    if [[ -d $CAND ]]; then
      ble/complete/action/util/complete.mark-directory
    else
      ble/complete/action:word/complete
    fi
  fi
}
function ble/complete/action:file/init-menu-item {
  ble/syntax/highlight/getg-from-filename "$CAND"
  [[ $g ]] || ble/color/face2g filename_warning
  if [[ :$comp_type: == *:vstat:* ]]; then
    if [[ -h $CAND ]]; then
      suffix='@'
    elif [[ -d $CAND ]]; then
      suffix='/'
    elif [[ -x $CAND ]]; then
      suffix='*'
    fi
  fi
}
_ble_complete_action_file_desc[_ble_attr_FILE_LINK]='symbolic link'
_ble_complete_action_file_desc[_ble_attr_FILE_ORPHAN]='symbolic link (orphan)'
_ble_complete_action_file_desc[_ble_attr_FILE_DIR]='directory'
_ble_complete_action_file_desc[_ble_attr_FILE_STICKY]='directory (sticky)'
_ble_complete_action_file_desc[_ble_attr_FILE_SETUID]='file (setuid)'
_ble_complete_action_file_desc[_ble_attr_FILE_SETGID]='file (setgid)'
_ble_complete_action_file_desc[_ble_attr_FILE_EXEC]='file (executable)'
_ble_complete_action_file_desc[_ble_attr_FILE_FILE]='file'
_ble_complete_action_file_desc[_ble_attr_FILE_CHR]='character device'
_ble_complete_action_file_desc[_ble_attr_FILE_FIFO]='named pipe'
_ble_complete_action_file_desc[_ble_attr_FILE_SOCK]='socket'
_ble_complete_action_file_desc[_ble_attr_FILE_BLK]='block device'
function ble/complete/action:file/get-desc {
  local type; ble/syntax/highlight/filetype "$CAND"
  desc=${_ble_complete_action_file_desc[type]:-'file (???)'}
}
function ble/complete/action:tilde/initialize {
  CAND=${CAND#\~} ble/complete/action/util/quote-insert
  INSERT=\~$INSERT
}
function ble/complete/action:tilde/complete {
  ble/complete/action/util/complete.mark-directory
}
function ble/complete/action:tilde/init-menu-item {
  ble/color/face2g filename_directory
}
function ble/complete/action:tilde/get-desc {
  desc='directory (tilde expansion)'
}
function ble/complete/action:progcomp/initialize {
  [[ $DATA == *:noquote:* ]] && return
  [[ $DATA == *:nospace:* && $CAND == *' ' && ! -f $CAND ]] && return
  ble/complete/action/util/quote-insert
}
function ble/complete/action:progcomp/complete {
  if [[ $DATA == *:filenames:* ]]; then
    ble/complete/action:file/complete
  else
    if [[ -d $CAND ]]; then
      ble/complete/action/util/complete.mark-directory
    else
      ble/complete/action:word/complete
    fi
  fi
  [[ $DATA == *:nospace:* ]] && suffix=${suffix%' '}
}
function ble/complete/action:progcomp/init-menu-item {
  if [[ $DATA == *:filenames:* ]]; then
    ble/complete/action:file/init-menu-item
  fi
}
function ble/complete/action:progcomp/get-desc {
  if [[ $DATA == *:filenames:* ]]; then
    ble/complete/action:file/get-desc
  fi
}
function ble/complete/action:command/initialize {
  ble/complete/action/util/quote-insert
}
function ble/complete/action:command/complete {
  if [[ -d $CAND ]]; then
    ble/complete/action/util/complete.mark-directory
  elif ! type "$CAND" &>/dev/null; then
    if [[ $CAND == */ ]]; then
      insert_flags=${insert_flags}n
    fi
  else
    ble/complete/action:word/complete
  fi
}
function ble/complete/action:command/init-menu-item {
  if [[ -d $CAND ]]; then
    ble/color/face2g filename_directory
  else
    local type; ble/util/type type "$CAND"
    ble/syntax/highlight/cmdtype1 "$type" "$CAND"
    if [[ $CAND == */ ]] && ((type==_ble_attr_ERR)); then
      type=_ble_attr_CMD_FUNCTION
    fi
    ble/syntax/attr2g "$type"
  fi
}
_ble_complete_action_command_desc[_ble_attr_CMD_BOLD]=builtin
_ble_complete_action_command_desc[_ble_attr_CMD_BUILTIN]=builtin
_ble_complete_action_command_desc[_ble_attr_CMD_ALIAS]=alias
_ble_complete_action_command_desc[_ble_attr_CMD_FUNCTION]=function
_ble_complete_action_command_desc[_ble_attr_CMD_FILE]=file
_ble_complete_action_command_desc[_ble_attr_KEYWORD]=keyword
_ble_complete_action_command_desc[_ble_attr_CMD_JOBS]=job
_ble_complete_action_command_desc[_ble_attr_ERR]='???'
_ble_complete_action_command_desc[_ble_attr_CMD_DIR]=directory
function ble/complete/action:command/get-desc {
  if [[ -d $CAND ]]; then
    desc=directory
  else
    local type; ble/util/type type "$CAND"
    ble/syntax/highlight/cmdtype1 "$type" "$CAND"
    if [[ $CAND == */ ]] && ((type==_ble_attr_ERR)); then
      type=_ble_attr_CMD_FUNCTION
    fi
    desc=${_ble_complete_action_command_desc[type]:-'???'}
  fi
}
function ble/complete/action:variable/initialize { ble/complete/action/util/quote-insert; }
function ble/complete/action:variable/complete {
  case $DATA in
  (assignment) 
    ble/complete/action/util/complete.addtail '=' ;;
  (braced)
    ble/complete/action/util/complete.addtail '}' ;;
  (word)       ble/complete/action:word/complete ;;
  (arithmetic) ;; # do nothing
  esac
}
function ble/complete/action:variable/init-menu-item {
  ble/color/face2g syntax_varname
}
function ble/complete/cand/yield {
  local ACTION=$1 CAND=$2 DATA="${*:3}"
  [[ $flag_force_fignore ]] && ! ble/complete/.fignore/filter "$CAND" && return
  local PREFIX_LEN=0
  [[ $CAND == "$COMP_PREFIX"* ]] && PREFIX_LEN=${#COMP_PREFIX}
  local INSERT=$CAND
  ble/complete/action:"$ACTION"/initialize
  local icand
  ((icand=cand_count++))
  cand_cand[icand]=$CAND
  cand_word[icand]=$INSERT
  cand_pack[icand]=$ACTION:${#CAND},${#INSERT},$PREFIX_LEN:$CAND$INSERT$DATA
}
_ble_complete_cand_varnames=(ACTION CAND INSERT DATA PREFIX_LEN)
function ble/complete/cand/unpack {
  local pack=$1
  ACTION=${pack%%:*} pack=${pack#*:}
  local text=${pack#*:}
  IFS=, eval 'pack=(${pack%%:*})'
  CAND=${text::pack[0]}
  INSERT=${text:pack[0]:pack[1]}
  DATA=${text:pack[0]+pack[1]}
  PREFIX_LEN=${pack[2]}
}
function ble/complete/source:wordlist {
  [[ $comps_flags == *v* ]] || return 1
  case :$comp_type: in
  (*:a:*)    local COMPS=${COMPS::1} COMPV=${COMPV::1} ;;
  (*:[mA]:*) local COMPS= COMPV= ;;
  esac
  [[ $COMPV =~ ^.+/ ]] && COMP_PREFIX=${BASH_REMATCH[0]}
  local opt_raw= opt_noword=
  while (($#)) && [[ $1 == -* ]]; do
    local arg=$1; shift
    case $arg in
    (--) break ;;
    (--*) ;; # ignore
    (-*)
      local i iN=${#arg}
      for ((i=1;i<iN;i++)); do
        case ${arg:i:1} in
        (r) opt_raw=1 ;;
        (W) opt_noword=1 ;;
        (*) ;; # ignore
        esac
      done ;;
    esac
  done
  local action=word
  [[ $opt_noword ]] && action=substr
  [[ $opt_raw ]] && action=literal-$action
  local cand
  for cand; do
    [[ $cand == "$COMPV"* ]] && ble/complete/cand/yield "$action" "$cand"
  done
}
function ble/complete/source:command/.contract-by-slashes {
  local slashes=${COMPV//[!'/']}
  ble/bin/awk -F / -v baseNF=${#slashes} '
    function initialize_common() {
      common_NF = NF;
      for (i = 1; i <= NF; i++) common[i] = $i;
      common_degeneracy = 1;
      common0_NF = NF;
      common0_str = $0;
    }
    function print_common(_, output) {
      if (!common_NF) return;
      if (common_degeneracy == 1) {
        print common0_str;
        common_NF = 0;
        return;
      }
      output = common[1];
      for (i = 2; i <= common_NF; i++)
        output = output "/" common[i];
      if (common_NF == common0_NF) print output;
      print output "/";
      common_NF = 0;
    }
    {
      if (NF <= baseNF + 1) {
        print_common();
        print $0;
      } else if (!common_NF) {
        initialize_common();
      } else {
        n = common_NF < NF ? common_NF : NF;
        for (i = baseNF + 1; i <= n; i++)
          if (common[i] != $i) break;
        matched_length = i - 1;
        if (matched_length <= baseNF) {
          print_common();
          initialize_common();
        } else {
          common_NF = matched_length;
          common_degeneracy++;
        }
      }
    }
    END { print_common(); }
  '
}
function ble/complete/source:command/gen.1 {
  case :$comp_type: in
  (*:a:*)    local COMPS=${COMPS::1} COMPV=${COMPV::1} ;;
  (*:[mA]:*) local COMPS= COMPV= ;;
  esac
  if [[ ! $COMPV ]]; then
    shopt -q no_empty_cmd_completion && return
    ble/util/conditional-sync \
      'compgen -c -- "$COMPV"' \
      '! ble/complete/check-cancel' 128 progressive-weight
  else
    compgen -c -- "$COMPV"
  fi
  if [[ $COMPV == */* ]]; then
    local q="'" Q="'\''"
    local compv_quoted="'${COMPV//$q/$Q}'"
    compgen -A function -- "$compv_quoted"
  fi
}
function ble/complete/source:command/gen {
  if [[ :$comp_type: != *:[amA]:* && $bleopt_complete_contract_function_names ]]; then
    ble/complete/source:command/gen.1 |
      ble/complete/source:command/.contract-by-slashes
  else
    ble/complete/source:command/gen.1
  fi
  local ret
  ble/complete/source:file/.construct-pathname-pattern "$COMPV"
  ble/complete/util/eval-pathname-expansion "$ret/"
  ((${#ret[@]})) && printf '%s\n' "${ret[@]}"
}
function ble/complete/source:command {
  [[ $comps_flags == *v* ]] || return 1
  [[ ! $COMPV ]] && shopt -q no_empty_cmd_completion && return 1
  [[ $COMPV =~ ^.+/ ]] && COMP_PREFIX=${BASH_REMATCH[0]}
  if ((_ble_bash>=50000)); then
    ble/complete/candidates/filter:"$comp_filter_type"/filter
    (($?==148)) && return 148
    local old_cand_count=$cand_count
    local comp_opts=:
    ble/complete/source:argument/.generate-user-defined-completion initial; local ext=$?
    ((ext==148)) && return "$ext"
    if ((ext==0)); then
      ble/complete/candidates/filter:"$comp_filter_type"/filter
      (($?==148)) && return 148
      ((cand_count>old_cand_count)) && return "$ext"
    fi
  fi
  local cand arr i=0
  local compgen
  ble/util/assign compgen 'ble/complete/source:command/gen'
  [[ $compgen ]] || return 1
  ble/util/assign-array arr 'sort -u <<< "$compgen"' # 1 fork/exec
  for cand in "${arr[@]}"; do
    ((i++%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && return 148
    [[ $cand != */ && -d $cand ]] && ! type "$cand" &>/dev/null && continue
    ble/complete/cand/yield command "$cand"
  done
}
function ble/complete/util/eval-pathname-expansion {
  local pattern=$1
  local -a dtor=()
  if [[ -o noglob ]]; then
    set +f
    ble/array#push dtor 'set -f'
  fi
  if ! shopt -q nullglob; then
    shopt -s nullglob
    ble/array#push dtor 'shopt -u nullglob'
  fi
  if [[ :$comp_type: == *:i:* ]]; then
    if ! shopt -q nocaseglob; then
      shopt -s nocaseglob
      ble/array#push dtor 'shopt -u nocaseglob'
    fi
  else
    if shopt -q nocaseglob; then
      shopt -u nocaseglob
      ble/array#push dtor 'shopt -s nocaseglob'
    fi
  fi
  IFS= GLOBIGNORE= eval 'ret=(); ret=($pattern)' 2>/dev/null
  ble/util/invoke-hook dtor
}
function ble/complete/source:file/.construct-ambiguous-pathname-pattern {
  local path=$1 fixlen=${2:-1}
  local pattern= i=0 j
  local names; ble/string#split names / "$1"
  local name
  for name in "${names[@]}"; do
    ((i++)) && pattern=$pattern/
    if [[ $name ]]; then
      ble/string#escape-for-bash-glob "${name::fixlen}"
      pattern=$pattern$ret*
      for ((j=fixlen;j<${#name};j++)); do
        ble/string#escape-for-bash-glob "${name:j:1}"
        pattern=$pattern$ret*
      done
    fi
  done
  [[ $pattern ]] || pattern="*"
  ret=$pattern
}
function ble/complete/source:file/.construct-pathname-pattern {
  local path=$1
  if [[ :$comp_type: == *:a:* ]]; then
    ble/complete/source:file/.construct-ambiguous-pathname-pattern "$path"; local pattern=$ret
  elif [[ :$comp_type: == *:[mA]:* ]]; then
    ble/complete/source:file/.construct-ambiguous-pathname-pattern "$path" 0; local pattern=$ret
  else
    ble/string#escape-for-bash-glob "$path"; local pattern=$ret*
  fi
  ret=$pattern
}
function ble/complete/source:file/.impl {
  local opts=$1
  [[ $comps_flags == *v* ]] || return 1
  [[ :$comp_type: != *:[amA]:* && $COMPV =~ ^.+/ ]] && COMP_PREFIX=${BASH_REMATCH[0]}
  local -a candidates=()
  local action=file
  if local rex='^~[^/'\''"$`\!:]*$'; [[ $COMPS =~ $rex ]]; then
    local pattern=${COMPS#\~}
    [[ :$comp_type: == *:[amA]:* ]] && pattern=
    ble/util/assign-array candidates 'compgen -P \~ -u -- "$pattern"'
    ((${#candidates[@]})) && action=tilde
  fi
  if ((!${#candidates[@]})); then
    local ret
    ble/complete/source:file/.construct-pathname-pattern "$COMPV"
    [[ :$opts: == *:directory:* ]] && ret=$ret/
    ble/complete/util/eval-pathname-expansion "$ret"
    candidates=()
    local cand
    if [[ :$opts: == *:directory:* ]]; then
      for cand in "${ret[@]}"; do
        [[ -d $cand ]] || continue
        [[ $cand == / ]] || cand=${cand%/}
        ble/array#push candidates "$cand"
      done
    else
      for cand in "${ret[@]}"; do
        [[ -e $cand || -h $cand ]] || continue
        ble/array#push candidates "$cand"
      done
    fi
  fi
  local rex_hidden=
  [[ :$comp_type: != *:match-hidden:* ]] &&
    rex_hidden=${COMPV:+'.{'${#COMPV}'}'}'(^|/)\.[^/]*$'
  local cand i=0
  for cand in "${candidates[@]}"; do
    ((i++%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && return 148
    [[ $rex_hidden && $cand =~ $rex_hidden ]] && continue
    [[ $FIGNORE ]] && ! ble/complete/.fignore/filter "$cand" && continue
    ble/complete/cand/yield "$action" "$cand"
  done
}
function ble/complete/source:file {
  ble/complete/source:file/.impl
}
function ble/complete/source:dir {
  ble/complete/source:file/.impl directory
}
function ble/complete/source:rhs { ble/complete/source:file; }
function ble/complete/source:argument/.compvar-initialize-wordbreaks {
  local ifs=$' \t\n' q=\'\" delim=';&|<>()' glob='[*?' hist='!^{' esc='`$\'
  local escaped=$ifs$q$delim$glob$hist$esc
  wordbreaks=${COMP_WORDBREAKS//[$escaped]} # =:
}
function ble/complete/source:argument/.compvar-perform-wordbreaks {
  local word=$1
  if [[ ! $word ]]; then
    ret=('')
    return
  fi
  ret=()
  while local head=${word%%["$wordbreaks"]*}; [[ $head != $word ]]; do
    ble/array#push ret "$head" "${word:${#head}:1}"
    word=${word:${#head}+1}
  done
  [[ $word ]] && ble/array#push ret "$word"
}
function ble/complete/source:argument/.compvar-generate-subwords {
  local word1=$1 ret simple_flags simple_ibrace
  if [[ ! $word1 ]]; then
    flag_evaluated=1
    words=('')
  elif ble/syntax:bash/simple-word/reconstruct-incomplete-word "$word1"; then
    ble/syntax:bash/simple-word/eval "$ret"; local value1=$ret
    if [[ $point ]]; then
      if ((point==${#word1})); then
        point=${#value1}
      elif ble/syntax:bash/simple-word/reconstruct-incomplete-word "${word1::point}"; then
        ble/syntax:bash/simple-word/eval "$ret"
        point=${#ret}
      fi
    fi
    flag_evaluated=1
    ble/complete/source:argument/.compvar-perform-wordbreaks "$value1"; words=("${ret[@]}")
  else
    ble/complete/source:argument/.compvar-perform-wordbreaks "$word1"; words=("${ret[@]}")
  fi
}
function ble/complete/source:argument/.compvar-quote-subword {
  local word=$1 to_quote= is_evaluated= is_quoted=
  if [[ $flag_evaluated ]]; then
    to_quote=1
  elif ble/syntax:bash/simple-word/reconstruct-incomplete-word "$word"; then
    is_evaluated=1
    ble/syntax:bash/simple-word/eval "$ret"; word=$ret
    to_quote=1
  fi
  if [[ $to_quote ]]; then
    local shell_specialchars=']\ ["'\''`$|&;<>()*?{}!^'$'\n\t' q="'" Q="'\''" qq="''"
    if ((index>0)) && [[ $word == *["$shell_specialchars"]* ]]; then
      is_quoted=1
      word="'${w//$q/$Q}'" word=${word#"$qq"} word=${word%"$qq"}
    fi
  fi
  if [[ $p && $word != "$1" ]]; then
    if ((p==${#1})); then
      p=${#word}
    else
      local left=${word::p}
      if [[ $is_evaluated ]]; then
        if ble/syntax:bash/simple-word/reconstruct-incomplete-word "$left"; then
          ble/syntax:bash/simple-word/eval "$ret"; left=$ret
        fi
      fi
      if [[ $is_quoted ]]; then
        left="'${left//$q/$Q}" left=${left#"$qq"}
      fi
      p=${#left}
    fi
  fi
  ret=$word
}
function ble/complete/source:argument/.compvar-initialize {
  COMP_TYPE=9
  COMP_KEY=${KEYS[${#KEYS[@]}-1]:-9} # KEYS defined in ble-decode/widget/.call-keyseq
  local wordbreaks
  ble/complete/source:argument/.compvar-initialize-wordbreaks
  progcomp_prefix=
  COMP_CWORD=
  COMP_POINT=
  COMP_LINE=
  COMP_WORDS=()
  local ret simple_flags simple_ibrace
  local word1 index=0 offset=0 sep=
  for word1 in "${comp_words[@]}"; do
    local point=$((comp_point-offset))
    ((0<=point&&point<=${#word1})) || point=
    ((offset+=${#word1}))
    local words flag_evaluated=
    ble/complete/source:argument/.compvar-generate-subwords "$word1"
    local w wq o=0 p
    for w in "${words[@]}"; do
      p=
      if [[ $point ]]; then
        ((p=point-o))
        ((p<=${#w})) || p=
        ((o+=${#w}))
      fi
      [[ $p ]] && point=
      [[ $point ]] && progcomp_prefix=$progcomp_prefix$w
      ble/complete/source:argument/.compvar-quote-subword "$w"; local wq=$ret
      if [[ $p ]]; then
        COMP_CWORD=${#COMP_WORDS[*]}
        ((COMP_POINT=${#COMP_LINE}+${#sep}+p))
      fi
      ble/array#push COMP_WORDS "$wq"
      COMP_LINE=$COMP_LINE$sep$wq
      sep=
    done
    sep=' '
    ((offset++))
    ((index++))
  done
}
function ble/complete/source:argument/.progcomp-helper-prog {
  if [[ $comp_prog ]]; then
    local COMP_WORDS COMP_CWORD
    local -x COMP_LINE COMP_POINT COMP_TYPE COMP_KEY
    ble/complete/source:argument/.compvar-initialize
    local cmd=${comp_words[0]} cur=${comp_words[comp_cword]} prev=${comp_words[comp_cword-1]}
    "$comp_prog" "$cmd" "$cur" "$prev" </dev/null
  fi
}
function ble/complete/source:argument/.progcomp-helper-func {
  [[ $comp_func ]] || return
  local -a COMP_WORDS
  local COMP_LINE COMP_POINT COMP_CWORD COMP_TYPE COMP_KEY
  ble/complete/source:argument/.compvar-initialize
  local fDefault=
  function compopt {
    local ext=0
    local -a ospec
    while (($#)); do
      local arg=$1; shift
      case "$arg" in
      (-*)
        local ic c
        for ((ic=1;ic<${#arg};ic++)); do
          c=${arg:ic:1}
          case "$c" in
          (o)    ospec[${#ospec[@]}]="-$1"; shift ;;
          ([DE]) fDefault=1; break 2 ;;
          (*)    ((ext==0&&(ext=1))) ;;
          esac
        done ;;
      (+o) ospec[${#ospec[@]}]="+$1"; shift ;;
      (*)
        return "$ext" ;;
      esac
    done
    local s
    for s in "${ospec[@]}"; do
      case "$s" in
      (-*) comp_opts=${comp_opts//:"${s:1}":/:}${s:1}: ;;
      (+*) comp_opts=${comp_opts//:"${s:1}":/:} ;;
      esac
    done
    return "$ext"
  }
  local cmd=${comp_words[0]} cur=${comp_words[comp_cword]} prev=${comp_words[comp_cword-1]}
  eval '"$comp_func" "$cmd" "$cur" "$prev"' </dev/null; local ret=$?
  unset -f compopt
  if [[ $is_default_completion && $ret == 124 ]]; then
    is_default_completion=retry
  fi
}
function ble/complete/source:argument/.progcomp {
  shopt -q progcomp || return 1
  local opts=$1
  local comp_prog= comp_func=
  local cmd=${comp_words[0]} compcmd= is_default_completion= is_special_completion=
  if [[ :$opts: == *:initial:* ]]; then
    is_special_completion=1
    compcmd='-I'
  else
    if complete -p "$cmd" &>/dev/null; then
      compcmd=$cmd
    elif [[ $cmd == */?* ]] && complete -p "${cmd##*/}" &>/dev/null; then
      compcmd=${cmd##*/}
    elif complete -p -D &>/dev/null; then
      is_special_completion=1
      is_default_completion=1
      compcmd='-D'
    fi
  fi
  [[ $compcmd ]] || return 1
  local -a compargs compoptions flag_noquote=
  local ret iarg=1
  if [[ $is_special_completion ]]; then
    ble/util/assign ret 'complete -p "$compcmd" 2>/dev/null'
  else
    ble/util/assign ret 'complete -p -- "$compcmd" 2>/dev/null'
  fi
  ble/string#split-words compargs "$ret"
  while ((iarg<${#compargs[@]})); do
    local arg=${compargs[iarg++]}
    case "$arg" in
    (-*)
      local ic c
      for ((ic=1;ic<${#arg};ic++)); do
        c=${arg:ic:1}
        case "$c" in
        ([abcdefgjksuvE])
          case $c in
          (c) flag_noquote=1 ;;
          (d) ((_ble_bash>=40300)) && flag_noquote=1 ;;
          (f) ((40000<=_ble_bash&&_ble_bash<40200)) && flag_noquote=1 ;;
          esac
          ble/array#push compoptions "-$c" ;;
        ([pr])
          ;; # 無視 (-p 表示 -r 削除)
        ([AGWXPS])
          if [[ $c == A ]]; then
            case ${compargs[iarg]} in
            (command) flag_noquote=1 ;;
            (directory) ((_ble_bash>=40300)) && flag_noquote=1 ;;
            (file) ((40000<=_ble_bash&&_ble_bash<40200)) && flag_noquote=1 ;;
            esac
          fi
          ble/array#push compoptions "-$c" "${compargs[iarg++]}" ;;
        (o)
          local o=${compargs[iarg++]}
          comp_opts=${comp_opts//:"$o":/:}$o:
          ble/array#push compoptions "-$c" "$o" ;;
        (F)
          comp_func=${compargs[iarg++]}
          ble/array#push compoptions "-$c" ble/complete/source:argument/.progcomp-helper-func ;;
        (C)
          comp_prog=${compargs[iarg++]}
          ble/array#push compoptions "-$c" ble/complete/source:argument/.progcomp-helper-prog ;;
        (*)
        esac
      done ;;
    (*)
      ;; # 無視
    esac
  done
  ble/complete/check-cancel && return 148
  local compgen compgen_compv=$COMPV
  if [[ ! $flag_noquote ]]; then
    local q="'" Q="'\''"
    compgen_compv="'${compgen_compv//$q/$Q}'"
  fi
  local progcomp_prefix=
  ble/util/assign compgen 'compgen "${compoptions[@]}" -- "$compgen_compv" 2>/dev/null'
  if [[ $is_default_completion == retry && ! $_ble_complete_retry_guard ]]; then
    local _ble_complete_retry_guard=1
    ble/complete/source:argument/.progcomp "$@"
    return
  fi
  [[ $compgen ]] || return 1
  local use_workaround_for_git=
  if [[ $comp_func == __git* && $comp_opts == *:nospace:* ]]; then
    use_workaround_for_git=1
    comp_opts=${comp_opts//:nospace:/:}
  fi
  local arr
  {
    local compgen2=
    if [[ $comp_opts == *:filter_by_prefix:* ]]; then
      local ret; ble/string#escape-for-sed-regex "$COMPV"; local rex_compv=$ret
      ble/util/assign compgen2 'ble/bin/sed -n "/^\$/d;/^$rex_compv/p" <<< "$compgen"'
    fi
    [[ $compgen2 ]] || ble/util/assign compgen2 'ble/bin/sed "/^\$/d" <<< "$compgen"'
    local compgen3=$compgen2
    [[ $use_workaround_for_git ]] &&
      ble/util/assign compgen3 'ble/bin/sed "s/[[:space:]]\{1,\}\$//" <<< "$compgen2"'
    if [[ $comp_opts == *:nosort:* ]]; then
      ble/util/assign-array arr 'ble/bin/awk "!a[\$0]++" <<< "$compgen3"'
    else
      ble/util/assign-array arr 'ble/bin/sort -u <<< "$compgen3"'
    fi
  } 2>/dev/null
  local action=progcomp
  [[ $comp_opts == *:filenames:* && $COMPV == */* ]] && COMP_PREFIX=${COMPV%/*}/
  local old_cand_count=$cand_count
  local cand i=0
  for cand in "${arr[@]}"; do
    ((i++%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && return 148
    ble/complete/cand/yield "$action" "$progcomp_prefix$cand" "$comp_opts"
  done
  [[ $comp_opts == *:plusdirs:* ]] && ble/complete/source:dir
  ((cand_count!=old_cand_count))
}
function ble/complete/source:argument/.generate-user-defined-completion {
  case :$comp_type: in
  (*:a:*)    local COMPS=${COMPS::1} COMPV=${COMPV::1} COMP2=$((COMP1+1)) ;;
  (*:[mA]:*) local COMPS= COMPV= COMP2=$COMP1 ;;
  esac
  local comp_words comp_line comp_point comp_cword
  ble/syntax:bash/extract-command "$COMP2" || return 1
  if
    local forward_words=
    ((comp_cword)) && IFS=' ' eval 'forward_words="${comp_words[*]::comp_cword} "'
    local point=$((comp_point-${#forward_words}))
    local comp1=$((point-(COMP2-COMP1)))
    ((comp1>0))
  then
    local w=${comp_words[comp_cword]}
    comp_words=("${comp_words[@]::comp_cword}" "${w::comp1}" "${w:comp1}" "${comp_words[@]:comp_cword+1}")
    IFS=' ' eval 'comp_line="${comp_words[*]}"'
    ((comp_cword++,comp_point++))
  fi
  local opts=$1
  if [[ :$opts: == *:initial:* ]]; then
    ble/complete/source:argument/.progcomp "$opts"
  else
    local cmd=${comp_words[0]}
    if ble/is-function "ble/cmdinfo/complete:$cmd"; then
      "ble/cmdinfo/complete:$cmd"
    elif [[ $cmd == */?* ]] && ble/is-function "ble/cmdinfo/complete:${cmd##*/}"; then
      "ble/cmdinfo/complete:${cmd##*/}"
    else
      ble/complete/source:argument/.progcomp
    fi
  fi
}
function ble/complete/source:argument {
  local comp_opts=:
  ble/complete/source:sabbrev
  ble/complete/candidates/filter:"$comp_filter_type"/filter
  (($?==148)) && return 148
  local old_cand_count=$cand_count
  ble/complete/source:argument/.generate-user-defined-completion; local ext=$?
  ((ext==148)) && return "$ext"
  if ((ext==0)); then
    ble/complete/candidates/filter:"$comp_filter_type"/filter
    (($?==148)) && return 148
    ((cand_count>old_cand_count)) && return "$ext"
  fi
  if [[ $comp_opts == *:dirnames:* ]]; then
    ble/complete/source:dir
  else
    ble/complete/source:file
  fi
  if ((cand_count<=old_cand_count)); then
    if local rex='^/?[-a-zA-Z_]+[:=]'; [[ $COMPV =~ $rex ]]; then
      local prefix=$BASH_REMATCH value=${COMPV:${#BASH_REMATCH}}
      local COMP_PREFIX=$prefix
      [[ :$comp_type: != *:[amA]:* && $value =~ ^.+/ ]] &&
        COMP_PREFIX=$prefix${BASH_REMATCH[0]}
      local ret cand
      ble/complete/source:file/.construct-pathname-pattern "$value"
      ble/complete/util/eval-pathname-expansion "$ret"
      for cand in "${ret[@]}"; do
        [[ -e $cand || -h $cand ]] || continue
        [[ $FIGNORE ]] && ! ble/complete/.fignore/filter "$cand" && continue
        ble/complete/cand/yield file "$prefix$cand"
      done
    fi
  fi
}
function ble/complete/source/compgen {
  [[ $comps_flags == *v* ]] || return 1
  case :$comp_type: in
  (*:a:*)    local COMPS=${COMPS::1} COMPV=${COMPV::1} ;;
  (*:[mA]:*) local COMPS= COMPV= ;;
  esac
  local compgen_action=$1
  local action=$2
  local data=$3
  local q="'" Q="'\''"
  local compv_quoted="'${COMPV//$q/$Q}'"
  local cand arr
  ble/util/assign-array arr 'compgen -A "$compgen_action" -- "$compv_quoted"'
  [[ $1 != '=' && ${#arr[@]} == 1 && $arr == "$COMPV" ]] && return
  local i=0
  for cand in "${arr[@]}"; do
    ((i++%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && return 148
    ble/complete/cand/yield "$action" "$cand" "$data"
  done
}
function ble/complete/source:variable {
  local data=
  case $1 in
  ('=') data=assignment ;;
  ('b') data=braced ;;
  ('a') data=arithmetic ;;
  ('w'|*) data=word ;;
  esac
  ble/complete/source/compgen variable variable "$data"
}
function ble/complete/source:user {
  ble/complete/source/compgen user word
}
function ble/complete/source:hostname {
  ble/complete/source/compgen hostname word
}
function ble/complete/complete/determine-context-from-opts {
  local opts=$1
  context=syntax
  if local rex=':context=([^:]+):'; [[ :$opts: =~ $rex ]]; then
    local rematch1=${BASH_REMATCH[1]}
    if ble/is-function ble/complete/context:"$rematch1"/generate-sources; then
      context=$rematch1
    else
      echo "ble/widget/complete: unknown context '$rematch1'" >&2
    fi
  fi
}
function ble/complete/context/filter-prefix-sources {
  local -a filtered_sources=()
  local src asrc
  for src in "${sources[@]}"; do
    ble/string#split-words asrc "$src"
    local comp1=${asrc[1]}
    ((comp1<comp_index)) &&
      ble/array#push filtered_sources "$src"
  done
  sources=("${filtered_sources[@]}")
  ((${#sources[@]}))
}
function ble/complete/context/overwrite-sources {
  local source_name=$1
  local -a new_sources=()
  local src asrc mark
  for src in "${sources[@]}"; do
    ble/string#split-words asrc "$src"
    [[ ${mark[asrc[1]]} ]] && continue
    ble/array#push new_sources "$source_name ${asrc[1]}"
    mark[asrc[1]]=1
  done
  ((${#new_sources[@]})) ||
    ble/array#push new_sources "$source_name $comp_index"
  sources=("${new_sources[@]}")
}
function ble/complete/context:syntax/generate-sources {
  ble/syntax/import
  ble-edit/content/update-syntax
  ble/syntax/completion-context/generate "$comp_text" "$comp_index"
  ((${#sources[@]}))
}
function ble/complete/context:filename/generate-sources {
  ble/complete/context:syntax/generate-sources || return
  ble/complete/context/overwrite-sources file
}
function ble/complete/context:command/generate-sources {
  ble/complete/context:syntax/generate-sources || return
  ble/complete/context/overwrite-sources command
}
function ble/complete/context:variable/generate-sources {
  ble/complete/context:syntax/generate-sources || return
  ble/complete/context/overwrite-sources variable
}
function ble/complete/context:username/generate-sources {
  ble/complete/context:syntax/generate-sources || return
  ble/complete/context/overwrite-sources user
}
function ble/complete/context:hostname/generate-sources {
  ble/complete/context:syntax/generate-sources || return
  ble/complete/context/overwrite-sources hostname
}
function ble/complete/context:glob/generate-sources {
  comp_type=$comp_type:raw
  ble/complete/context:syntax/generate-sources || return
  ble/complete/context/overwrite-sources glob
}
function ble/complete/source:glob {
  [[ $comps_flags == *v* ]] || return 1
  [[ :$comp_type: == *:[amA]:* ]] && return 1
  local pattern=$COMPV
  local ret; ble/syntax:bash/simple-word/eval "$pattern"
  if ((!${#ret[@]})) && [[ $pattern != *'*' ]]; then
    ble/syntax:bash/simple-word/eval "$pattern*"
  fi
  local cand action=file
  for cand in "${ret[@]}"; do
    ((i++%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && return 148
    ble/complete/cand/yield "$action" "$cand"
  done
}
function ble/complete/util/construct-ambiguous-regex {
  local text=$1 fixlen=${2:-1}
  local opt_icase=; [[ :$comp_type: == *:i:* ]] && opt_icase=1
  local -a buff=()
  local i=0 n=${#text} c=
  for ((i=0;i<n;i++)); do
    ((i>=fixlen)) && ble/array#push buff '.*'
    ch=${text:i:1}
    if [[ $ch == [a-zA-Z] ]]; then
      if [[ $opt_icase ]]; then
        ble/string#toggle-case "$ch"
        ch=[$ch$ret]
      fi
    else
      ble/string#escape-for-extended-regex "$ch"; ch=$ret
    fi
    ble/array#push buff "$ch"
  done
  IFS= eval 'ret="${buff[*]}"'
}
function ble/complete/util/construct-glob-pattern {
  local text=$1
  if [[ :$comp_type: == *:i:* ]]; then
    local i n=${#text} c
    local -a buff=()
    for ((i=0;i<n;i++)); do
      c=${text:i:1}
      if [[ $c == [a-zA-Z] ]]; then
        ble/string#toggle-case "$c"
        c=[$c$ret]
      else
        ble/string#escape-for-bash-glob "$c"; c=$ret
      fi
      ble/array#push buff "$c"
    done
    IFS= eval 'ret="${buff[*]}"'
  else
    ble/string#escape-for-bash-glob "$1"
  fi
}
function ble/complete/.fignore/prepare {
  _fignore=()
  local i=0 leaf tmp
  ble/string#split tmp ':' "$FIGNORE"
  for leaf in "${tmp[@]}"; do
    [[ $leaf ]] && _fignore[i++]="$leaf"
  done
}
function ble/complete/.fignore/filter {
  local pat
  for pat in "${_fignore[@]}"; do
    [[ $1 == *"$pat" ]] && return 1
  done
}
function ble/complete/candidates/.pick-nearest-sources {
  COMP1= COMP2=$comp_index
  nearest_sources=()
  local -a unused_sources=()
  local src asrc
  for src in "${remaining_sources[@]}"; do
    ble/string#split-words asrc "$src"
    if ((COMP1<asrc[1])); then
      COMP1=${asrc[1]}
      ble/array#push unused_sources "${nearest_sources[@]}"
      nearest_sources=("$src")
    elif ((COMP1==asrc[1])); then
      ble/array#push nearest_sources "$src"
    else
      ble/array#push unused_sources "$src"
    fi
  done
  remaining_sources=("${unused_sources[@]}")
  COMPS=${comp_text:COMP1:COMP2-COMP1}
  comps_flags=
  comps_fixed=
  if [[ ! $COMPS ]]; then
    comps_flags=${comps_flags}v COMPV=
  elif local ret simple_flags simple_ibrace; ble/syntax:bash/simple-word/reconstruct-incomplete-word "$COMPS"; then
    local reconstructed=$ret
    if [[ :$comp_type: == *:raw:* ]]; then
      if ((${simple_ibrace%:*})); then
        COMPV=
      else
        comps_flags=$comps_flags${simple_flags}v
        COMPV=$reconstructed
      fi
    else
      comps_flags=$comps_flags${simple_flags}v
      ble/syntax:bash/simple-word/eval "$reconstructed"; COMPV=("${ret[@]}")
      if ((${simple_ibrace%:*})); then
        ble/syntax:bash/simple-word/eval "${reconstructed::${simple_ibrace#*:}}"
        comps_fixed=${simple_ibrace%:*}:$ret
        comps_flags=${comps_flags}x
      fi
    fi
    [[ $COMPS =~ $rex_raw_paramx ]] && comps_flags=${comps_flags}p
  else
    COMPV=
  fi
}
function ble/complete/candidates/.filter-by-regex {
  local rex_filter=$1
  local i j=0
  local -a prop=() cand=() word=() show=() data=()
  for ((i=0;i<cand_count;i++)); do
    ((i%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && return 148
    [[ ${cand_cand[i]} =~ $rex_filter ]] || continue
    cand[j]=${cand_cand[i]}
    word[j]=${cand_word[i]}
    data[j]=${cand_pack[i]}
    ((j++))
  done
  cand_count=$j
  cand_cand=("${cand[@]}")
  cand_word=("${word[@]}")
  cand_pack=("${data[@]}")
}
function ble/complete/candidates/.filter-word-by-prefix {
  local prefix=$1
  local i j=0
  local -a prop=() cand=() word=() show=() data=()
  for ((i=0;i<cand_count;i++)); do
    ((i%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && return 148
    [[ ${cand_word[i]} == "$prefix"* ]] || continue
    cand[j]=${cand_cand[i]}
    word[j]=${cand_word[i]}
    data[j]=${cand_pack[i]}
    ((j++))
  done
  cand_count=$j
  cand_cand=("${cand[@]}")
  cand_word=("${word[@]}")
  cand_pack=("${data[@]}")
}
function ble/complete/candidates/.filter-by-command {
  local command=$1
  local i j=0
  local -a prop=() cand=() word=() show=() data=()
  for ((i=0;i<cand_count;i++)); do
    ((i%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && return 148
    eval "$command" || continue
    cand[j]=${cand_cand[i]}
    word[j]=${cand_word[i]}
    data[j]=${cand_pack[i]}
    ((j++))
  done
  cand_count=$j
  cand_cand=("${cand[@]}")
  cand_word=("${word[@]}")
  cand_pack=("${data[@]}")
}
function ble/complete/candidates/.initialize-rex_raw_paramx {
  local element=$_ble_syntax_bash_simple_rex_element
  local open_dquot=$_ble_syntax_bash_simple_rex_open_dquot
  rex_raw_paramx='^('$element'*('$open_dquot')?)\$[a-zA-Z_][a-zA-Z_0-9]*$'
}
function ble/complete/candidates/filter:head/init {
  local ret; ble/complete/util/construct-glob-pattern "$1"
  comps_filter_pattern=$ret*
}
function ble/complete/candidates/filter:head/filter { :; }
function ble/complete/candidates/filter:head/count-match-chars { # unused but for completeness
  local value=$1 compv=$COMPV
  if [[ :$comp_type: == *:i:* ]]; then
    ble/string#tolower "$value"; value=$ret
    ble/string#tolower "$compv"; compv=$ret
  fi
  if [[ $value == "$compv"* ]]; then
    ret=${#compv}
  elif [[ $compv == "$value"* ]]; then
    ret=${#value}
  else
    ret=0
  fi
}
function ble/complete/candidates/filter:head/test { [[ $1 == $comps_filter_pattern ]]; }
function ble/complete/candidates/filter:head/match {
  local needle=$1 text=$2
  if [[ :$comp_type: == *:i:* ]]; then
    ble/string#tolower "$needle"; needle=$ret
    ble/string#tolower "$text"; text=$ret
  fi
  if [[ ! $needle || ! $text ]]; then
    ret=()
  elif [[ $text == "$needle"* ]]; then
    ret=(0 ${#needle})
    return
  elif [[ $text == "${needle::${#text}}" ]]; then
    ret=(0 ${#text})
    return
  else
    ret=()
    return 1
  fi
}
function ble/complete/candidates/filter:substr/init {
  local ret; ble/complete/util/construct-glob-pattern "$1"
  comps_filter_pattern=*$ret*
}
function ble/complete/candidates/filter:substr/filter {
  ble/complete/candidates/.filter-by-command '[[ ${cand_cand[i]} == $comps_filter_pattern ]]'
}
function ble/complete/candidates/filter:substr/count-match-chars {
  local value=$1 compv=$COMPV
  if [[ :$comp_type: == *:i:* ]]; then
    ble/string#tolower "$value"; value=$ret
    ble/string#tolower "$compv"; compv=$ret
  fi
  if [[ $value == *"$compv"* ]]; then
    ret=${#compv}
    return
  fi
  ble/complete/string#common-suffix-prefix "$value" "$compv"
  ret=${#ret}
}
function ble/complete/candidates/filter:substr/test { [[ $1 == $comps_filter_pattern ]]; }
function ble/complete/candidates/filter:substr/match {
  local needle=$1 text=$2
  if [[ :$comp_type: == *:i:* ]]; then
    ble/string#tolower "$needle"; needle=$ret
    ble/string#tolower "$text"; text=$ret
  fi
  if [[ ! $needle ]]; then
    ret=()
  elif [[ $text == *"$needle"* ]]; then
    text=${text%%"$needle"*}
    local beg=${#text}
    local end=$((beg+${#needle}))
    ret=("$beg" "$end")
  elif ble/complete/string#common-suffix-prefix "$text" "$needle"; ((${#ret})); then
    local end=${#text}
    local beg=$((end-${#ret}))
    ret=("$beg" "$end")
  else
    ret=()
  fi
}
function ble/complete/candidates/filter:hsubseq/.determine-fixlen {
  fixlen=${1:-1}
  if [[ $comps_fixed ]]; then
    local compv_fixed_part=${comps_fixed#*:}
    [[ $compv_fixed_part ]] && fixlen=${#compv_fixed_part}
  fi
}
function ble/complete/candidates/filter:hsubseq/init {
  local fixlen; ble/complete/candidates/filter:hsubseq/.determine-fixlen "$2"
  local ret; ble/complete/util/construct-ambiguous-regex "$1" "$fixlen"
  comps_filter_pattern=^$ret
}
function ble/complete/candidates/filter:hsubseq/filter {
  ble/complete/candidates/.filter-by-regex "$comps_filter_pattern"
}
function ble/complete/candidates/filter:hsubseq/count-match-chars {
  local value=$1 compv=$COMPV
  if [[ :$comp_type: == *:i:* ]]; then
    ble/string#tolower "$value"; value=$ret
    ble/string#tolower "$compv"; compv=$ret
  fi
  local fixlen
  ble/complete/candidates/filter:hsubseq/.determine-fixlen "$2"
  [[ $value == "${compv::fixlen}"* ]] || return 1
  value=${value:fixlen}
  local i n=${#COMPV}
  for ((i=fixlen;i<n;i++)); do
    local a=${value%%"${compv:i:1}"*}
    [[ $a == "$value" ]] && { ret=$i; return; }
    value=${value:${#a}+1}
  done
  ret=$n
}
function ble/complete/candidates/filter:hsubseq/test { [[ $1 =~ $comps_filter_pattern ]]; }
function ble/complete/candidates/filter:hsubseq/match {
  local needle=$1 text=$2
  if [[ :$comp_type: == *:i:* ]]; then
    ble/string#tolower "$needle"; needle=$ret
    ble/string#tolower "$text"; text=$ret
  fi
  local fixlen; ble/complete/candidates/filter:hsubseq/.determine-fixlen "$3"
  local prefix=${needle::fixlen}
  if [[ $text != "$prefix"* ]]; then
    if [[ $text && $text == "${prefix::${#text}}" ]]; then
      ret=(0 ${#text})
    else
      ret=()
    fi
    return
  fi
  local pN=${#text} iN=${#needle}
  local first=1
  ret=()
  while :; do
    if [[ $first ]]; then
      first=
      local p0=0 p=${#prefix} i=${#prefix}
    else
      ((i<iN)) || return 0
      while ((p<pN)) && [[ ${text:p:1} != "${needle:i:1}" ]]; do
        ((p++))
      done
      ((p<pN)) || return 1
      p0=$p
    fi
    while ((i<iN&&p<pN)) && [[ ${text:p:1} == "${needle:i:1}" ]]; do
      ((p++,i++))
    done
    ((p0<p)) && ble/array#push ret "$p0" "$p"
  done
}
function ble/complete/candidates/filter:subseq/init {
  [[ $comps_fixed ]] && return 1
  ble/complete/candidates/filter:hsubseq/init "$1" 0
}
function ble/complete/candidates/filter:subseq/filter {
  ble/complete/candidates/filter:hsubseq/filter
}
function ble/complete/candidates/filter:subseq/count-match-chars {
  ble/complete/candidates/filter:hsubseq/count-match-chars "$1" 0
}
function ble/complete/candidates/filter:subseq/test { [[ $1 =~ $comps_filter_pattern ]]; }
function ble/complete/candidates/filter:subseq/match {
  ble/complete/candidates/filter:hsubseq/match "$1" "$2" 0
}
function ble/complete/candidates/generate-with-filter {
  local comp_filter_type=$1
  local -a remaining_sources nearest_sources
  remaining_sources=("${sources[@]}")
  local src asrc source
  while ((${#remaining_sources[@]})); do
    nearest_sources=()
    ble/complete/candidates/.pick-nearest-sources
    ble/complete/candidates/filter:"$comp_filter_type"/init "$COMPV" || continue
    for src in "${nearest_sources[@]}"; do
      ble/string#split-words asrc "$src"
      ble/string#split source : "${asrc[0]}"
      local COMP_PREFIX= # 既定値 (yield-candidate で参照)
      ble/complete/source:"${source[@]}"
      ble/complete/check-cancel && return 148
    done
    ble/complete/candidates/filter:"$comp_filter_type"/filter
    (($?==148)) && return 148
    [[ $comps_fixed ]] &&
      ble/complete/candidates/.filter-word-by-prefix "${COMPS::${comps_fixed%%:*}}"
    ((cand_count)) && return 0
  done
  return 0
}
function ble/complete/candidates/comp_type#read-rl-variables {
  ble/util/test-rl-variable completion-ignore-case 0 && comp_type=${comp_type}:i
  ble/util/test-rl-variable visible-stats 0 && comp_type=${comp_type}:vstat
  ble/util/test-rl-variable mark-directories 1 && comp_type=${comp_type}:markdir
  ble/util/test-rl-variable mark-symlinked-directories 1 && comp_type=${comp_type}:marksymdir
  ble/util/test-rl-variable match-hidden-files 1 && comp_type=${comp_type}:match-hidden
  ble/util/test-rl-variable menu-complete-display-prefix 0 && comp_type=${comp_type}:menu-show-prefix
  comp_type=$comp_type:menu-color:menu-color-match
}
function ble/complete/candidates/generate {
  local flag_force_fignore=
  local -a _fignore=()
  if [[ $FIGNORE ]]; then
    ble/complete/.fignore/prepare
    ((${#_fignore[@]})) && shopt -q force_fignore && flag_force_fignore=1
  fi
  local rex_raw_paramx
  ble/complete/candidates/.initialize-rex_raw_paramx
  ble/complete/candidates/comp_type#read-rl-variables
  cand_count=0
  cand_cand=() # 候補文字列
  cand_word=() # 挿入文字列 (～ エスケープされた候補文字列)
  cand_pack=() # 候補の詳細データ
  ble/complete/candidates/generate-with-filter head || return
  ((cand_count)) && return 0
  if [[ $bleopt_complete_ambiguous && $COMPV ]]; then
    local original_comp_type=$comp_type
    comp_type=${original_comp_type}:m
    ble/complete/candidates/generate-with-filter substr || return
    ((cand_count)) && return 0
    comp_type=${original_comp_type}:a
    ble/complete/candidates/generate-with-filter hsubseq || return
    ((cand_count)) && return 0
    comp_type=${original_comp_type}:A
    ble/complete/candidates/generate-with-filter subseq || return
    ((cand_count)) && return 0
    comp_type=$original_comp_type
  fi
  return 0
}
function ble/complete/candidates/determine-common-prefix/.apply-partial-comps {
  local word0=$COMPS word1=$common fixed=
  if [[ $comps_fixed ]]; then
    local fixlen=${comps_fixed%%:*}
    fixed=${word0::fixlen}
    word0=${word0:fixlen}
    word1=${word1:fixlen}
  fi
  local ret spec path spec0 path0 spec1 path1
  ble/syntax:bash/simple-word/evaluate-path-spec "$word0"; spec0=("${spec[@]}") path0=("${path[@]}")
  ble/syntax:bash/simple-word/evaluate-path-spec "$word1"; spec1=("${spec[@]}") path1=("${path[@]}")
  local i=${#path1[@]}
  while ((i--)); do
    if ble/array#last-index path0 "${path1[i]}"; then
      local elem=${spec1[i]} # workaround bash-3.1 ${#arr[i]} bug
      word1=${spec0[ret]}${word1:${#elem}}
      break
    fi
  done
  common=$fixed$word1
}
function ble/complete/candidates/determine-common-prefix {
  local common=${cand_word[0]}
  local clen=${#common}
  if ((cand_count>1)); then
    local unset_nocasematch= flag_tolower=
    if [[ :$comp_type: == *:i:* ]]; then
      if ((_ble_bash<30100)); then
        flag_tolower=1
        ble/string#tolower "$common"; common=$ret
      else
        unset_nocasematch=1
        shopt -s nocasematch
      fi
    fi
    local word loop=0
    for word in "${cand_word[@]:1}"; do
      ((loop++%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && break
      if [[ $flag_tolower ]]; then
        ble/string#tolower "$word"; word=$ret
      fi
      ((clen>${#word}&&(clen=${#word})))
      while [[ ${word::clen} != "${common::clen}" ]]; do
        ((clen--))
      done
      common=${common::clen}
    done
    [[ $unset_nocasematch ]] && shopt -u nocasematch
    ble/complete/check-cancel && return 148
    [[ $flag_tolower ]] && common=${cand_word[0]::${#common}}
  fi
  if [[ :$comp_type: == *:[amAi]:* && $common != "$COMPS"* ]]; then
    ble/complete/candidates/determine-common-prefix/.apply-partial-comps
    local common0=$common
    common=$COMPS
    local simple_flags simple_ibrace
    if ble/syntax:bash/simple-word/reconstruct-incomplete-word "$common0" &&
      ble/syntax:bash/simple-word/eval "$ret"; then
      local value=$ret filter_type=head
      case :$comp_type: in
      (*:m:*) filter_type=substr ;;
      (*:a:*) filter_type=hsubseq ;;
      (*:A:*) filter_type=subseq ;;
      esac
      if [[ $filter_type ]] && ble/complete/candidates/filter:"$filter_type"/count-match-chars "$value"; then
        if ((ret)); then
          ble/string#escape-for-bash-specialchars "${COMPV:ret}"
          common=$common0$ret
        else
          common=$common0$COMPS
        fi
      fi
    fi
  elif ((cand_count!=1)) && [[ $common != "$COMPS"* ]]; then
    ble/syntax:bash/simple-word/is-simple-or-open-simple "$common" ||
      common=$COMPS
  fi
  ret=$common
}
_ble_complete_menu_active=
_ble_complete_menu_style=
_ble_complete_menu0_beg=
_ble_complete_menu0_end=
_ble_complete_menu0_str=
_ble_complete_menu_common_part=
_ble_complete_menu0_comp=()
_ble_complete_menu0_pack=()
_ble_complete_menu_selected=-1
_ble_complete_menu_comp=()
_ble_complete_menu_ipage=
_ble_complete_menu_offset=
_ble_complete_menu_items=()
_ble_complete_menu_info_data=()
function ble/complete/menu/construct-single-entry {
  local opts=$2
  if [[ :$opts: == *:selected:* ]]; then
    local COMP1=${_ble_complete_menu_comp[0]}
    local COMP2=${_ble_complete_menu_comp[1]}
    local COMPS=${_ble_complete_menu_comp[2]}
    local COMPV=${_ble_complete_menu_comp[3]}
    local comp_type=${_ble_complete_menu_comp[4]}
    local comps_flags=${_ble_complete_menu0_comp[5]}
    local comps_fixed=${_ble_complete_menu0_comp[6]}
    local menu_common_part=$_ble_complete_menu_common_part
  fi
  if [[ :$opts: != *:use_vars:* ]]; then
    local "${_ble_complete_cand_varnames[@]}"
    ble/complete/cand/unpack "$1"
  fi
  local prefix_len=$PREFIX_LEN
  [[ :$comp_type: == *:menu-show-prefix:* ]] && prefix_len=0
  local filter_target=${CAND:prefix_len}
  if [[ ! $filter_target ]]; then
    ret=
    return
  fi
  local g=0 show=$filter_target suffix= prefix=
  ble/function#try ble/complete/action:"$ACTION"/init-menu-item
  local g0=$g; [[ :$comp_type: == *:menu-color:* ]] || g0=0
  local m
  if [[ :$comp_type: == *:menu-color-match:* && $menu_common_part && $show == *"$filter_target"* ]]; then
    local comp_filter_type=head
    case :$comp_type: in
    (*:m:*) comp_filter_type=substr ;;
    (*:a:*) comp_filter_type=hsubseq ;;
    (*:A:*) comp_filter_type=subseq ;;
    esac
    local needle=${menu_common_part:prefix_len}
    ble/complete/candidates/filter:"$comp_filter_type"/match "$needle" "$filter_target"; m=("${ret[@]}")
    if [[ $show != "$filter_target" ]]; then
      local show_prefix=${show%%"$filter_target"*}
      local offset=${#show_prefix}
      local i n=${#m[@]}
      for ((i=0;i<n;i++)); do ((m[i]+=offset)); done
    fi
  else
    m=()
  fi
  local sgrN0= sgrN1= sgrB0= sgrB1=
  [[ :$opts: == *:selected:* ]] && ((g0|=_ble_color_gflags_Revert))
  ret=${_ble_color_g2sgr[g=g0]}
  [[ $ret ]] || ble/color/g2sgr "$g"; sgrN0=$ret
  ret=${_ble_color_g2sgr[g=g0|_ble_color_gflags_Revert]}
  [[ $ret ]] || ble/color/g2sgr "$g"; sgrN1=$ret
  if ((${#m[@]})); then
    ret=${_ble_color_g2sgr[g=g0|_ble_color_gflags_Bold]}
    [[ $ret ]] || ble/color/g2sgr "$g"; sgrB0=$ret
    ret=${_ble_color_g2sgr[g=g0|_ble_color_gflags_Bold|_ble_color_gflags_Revert]}
    [[ $ret ]] || ble/color/g2sgr "$g"; sgrB1=$ret
  fi
  local out= flag_overflow= p0=0
  if [[ $prefix ]]; then
    ble/canvas/trace-text "$prefix" nonewline || flag_overflow=1
    out=$out$_ble_term_sgr0$ret
  fi
  if ((${#m[@]})); then
    local i iN=${#m[@]} p p0=0 out=
    for ((i=0;i<iN;i++)); do
      ((p=m[i]))
      if ((p0<p)); then
        if ((i%2==0)); then
          local sgr0=$sgrN0 sgr1=$sgrN1
        else
          local sgr0=$sgrB0 sgr1=$sgrB1
        fi
        ble/canvas/trace-text "${show:p0:p-p0}" nonewline:external-sgr || flag_overflow=1
        out=$out$sgr0$ret
      fi
      p0=$p
    done
  fi
  if ((p0<${#show})); then
    local sgr0=$sgrN0 sgr1=$sgrN1
    ble/canvas/trace-text "${show:p0}" nonewline:external-sgr || flag_overflow=1
    out=$out$sgr0$ret
  fi
  if [[ $suffix ]]; then
    ble/canvas/trace-text "$suffix" nonewline || flag_overflow=1
    out=$out$_ble_term_sgr0$ret
  fi
  ret=$out$_ble_term_sgr0
  [[ ! $flag_overflow ]]
}
function bleopt/check:complete_menu_style {
  if ! ble/is-function "ble/complete/menu/style:$value/construct-page"; then
    echo "bleopt: Invalid value complete_menu_style='$value'. A function 'ble/complete/menu/style:$value/construct' is not defined." >&2
    return 1
  fi
}
_ble_complete_menu_style_version=
_ble_complete_menu_style_measure=()
_ble_complete_menu_style_items=()
_ble_complete_menu_style_pages=()
function ble/complete/menu/style:align/construct/.measure-candidates-in-page {
  local max_wcell=$bleopt_complete_menu_align; ((max_wcell>cols&&(max_wcell=cols)))
  wcell=2
  local ncell=0 index=$begin
  local pack ret esc1 w
  for pack in "${cand_pack[@]:begin}"; do
    ((iloop++%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && return 148
    local wcell_old=$wcell
    local w=${_ble_complete_menu_style_measure[index]%%:*}
    if [[ ! $w ]]; then
      local x=0 y=0
      ble/complete/menu/construct-single-entry "$pack"; esc1=$ret
      local w=$((y*cols+x))
      _ble_complete_menu_style_measure[index]=$w:${#pack}:$pack$esc1
    fi  
    local wcell_request=$((w++,w<=max_wcell?w:max_wcell))
    ((wcell<wcell_request)) && wcell=$wcell_request
    local line_ncell=$((cols/wcell))
    local cand_ncell=$(((w+wcell-1)/wcell))
    if [[ $menu_style == align-nowrap ]]; then
      local x1=$((ncell%line_ncell*wcell))
      local ncell_eol=$(((ncell+line_ncell-1)/line_ncell*line_ncell))
      if ((x1>0&&x1+w>=cols)); then
        ((ncell=ncell_eol+cand_ncell))
      elif ((x1+w<cols)); then
        ((ncell+=cand_ncell))
        ((ncell>ncell_eol&&(ncell=ncell_eol)))
      else
        ((ncell+=cand_ncell))
      fi
    else
      ((ncell+=cand_ncell))
    fi
    local max_ncell=$((line_ncell*lines))
    ((index&&ncell>max_ncell)) && { wcell=$wcell_old; break; }
    ((index++))
  done
  end=$index
}
function ble/complete/menu/style:align/construct-page {
  x=0 y=0 esc=
  local wcell=2
  ble/complete/menu/style:align/construct/.measure-candidates-in-page
  (($?==148)) && return 148
  local ncell=$((cols/wcell))
  local index=$begin entry
  for entry in "${_ble_complete_menu_style_measure[@]:begin:end-begin}"; do
    ((iloop++%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && return 148
    local w=${entry%%:*}; entry=${entry#*:}
    local s=${entry%%:*}; entry=${entry#*:}
    local pack=${entry::s} esc1=${entry:s}
    local x0=$x y0=$y
    if ((x==0||x+w<cols)); then
      ((x+=w%cols,y+=w/cols))
      ((y>=lines&&(x=x0,y=y0,1))) && break
    else
      if [[ $menu_style == align-nowrap ]]; then
        ((y+1>=lines)) && break
        esc=$esc$'\n'
        ((x0=x=0,y0=++y))
        ((x=w%cols,y+=w/cols))
        ((y>=lines&&(x=x0,y=y0,1))) && break
      else
        ble/complete/menu/construct-single-entry "$pack" ||
          ((begin==index)) || # [Note: 少なくとも1個ははみ出ても表示する]
          { x=$x0 y=$y0; break; }; esc1=$ret
      fi
    fi
    _ble_complete_menu_style_items[index]=$x0,$y0,$x,$y,${#pack},${#esc1}:$pack$esc1
    esc=$esc$esc1
    if ((++index<end)); then
      local icell=$((x==0?0:(x+wcell)/wcell))
      if ((icell<ncell)); then
        local pad=$((icell*wcell-x))
        ble/string#reserve-prototype "$pad"
        esc=$esc${_ble_string_prototype::pad}
        ((x=icell*wcell))
      else
        ((y+1>=lines)) && break
        esc=$esc$'\n'
        ((x=0,++y))
      fi
    fi
  done
  end=$index
}
function ble/complete/menu/style:align-nowrap/construct-page {
  ble/complete/menu/style:align/construct-page "$@"
}
_ble_complete_menu_style_version=
_ble_complete_menu_style_items=()
_ble_complete_menu_style_pages=()
function ble/complete/menu/style:dense/construct-page {
  x=0 y=0 esc=
  local pack index=$begin N=${#cand_pack[@]}
  for pack in "${cand_pack[@]:begin}"; do
    ((iloop++%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && return 148
    local x0=$x y0=$y esc1
    ble/complete/menu/construct-single-entry "$pack" ||
      ((index==begin)) ||
      { x=$x0 y=$y0; break; }; esc1=$ret
    if [[ $menu_style == dense-nowrap ]]; then
      if ((y>y0&&x>0)); then
        ((++y0>=lines)) && break
        esc=$esc$'\n'
        ((y=y0,x=x0=0))
        ble/complete/menu/construct-single-entry "$pack" ||
          ((begin==index)) ||
          { x=$x0 y=$y0; break; }; esc1=$ret
      fi
    fi
    _ble_complete_menu_style_items[index]=$x0,$y0,$x,$y,${#pack},${#esc1}:$pack$esc1
    esc=$esc$esc1
    if ((++index<N)); then
      if [[ $menu_style == nowrap ]] && ((x==0)); then
        : skip
      elif ((x+1<cols)); then
        esc=$esc' '
        ((x++))
      else
        ((y+1>=lines)) && break
        esc=$esc$'\n'
        ((x=0,++y))
      fi
    fi
  done
  end=$index
}
function ble/complete/menu/style:dense-nowrap/construct-page {
  ble/complete/menu/style:dense/construct-page "$@"
}
function ble/complete/menu/style:desc/construct-page {
  local opts=$1 ret
  local opt_raw=; [[ $menu_style == desc-raw ]] && opt_raw=1
  local measure; measure=()
  local max_cand_width=$(((cols+1)/2))
  ((max_cand_width<10&&(max_cand_width=cols)))
  local pack w esc1 max_width=0
  for pack in "${cand_pack[@]:begin:lines}"; do
    ((iloop++%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && return 148
    x=0 y=0
    lines=1 cols=$max_cand_width ble/complete/menu/construct-single-entry "$pack"; esc1=$ret
    ((w=y*cols+x,w>max_width&&(max_width=w)))
    ble/array#push measure "$w:${#pack}:$pack$esc1"
  done
  local cand_width=$max_width
  local desc_x=$((max_width+1)); ((desc_x>cols&&(desc_x=cols)))
  local desc_prefix=; ((cols-desc_x>30)) && desc_prefix='| '
  end=$begin x=0 y=0 esc=
  local entry w s pack esc1 x0 y0 pad index=$begin
  for entry in "${measure[@]}"; do
    ((iloop++%bleopt_complete_polling_cycle==0)) && ble/complete/check-cancel && return 148
    w=${entry%%:*} entry=${entry#*:}
    s=${entry%%:*} entry=${entry#*:}
    pack=${entry::s} esc1=${entry:s}
    ((x0=x,y0=y,x+=w))
    _ble_complete_menu_style_items[index]=$x0,$y0,$x,$y,${#pack},${#esc1}:$pack$esc1
    ((index++))
    esc=$esc$esc1
    ble/string#reserve-prototype $((pad=desc_x-x))
    esc=$esc${_ble_string_prototype::pad}$desc_prefix
    ((x+=pad+${#desc_prefix}))
    local "${_ble_complete_cand_varnames[@]}"
    ble/complete/cand/unpack "$pack"
    local desc="(action: $ACTION)"
    ble/function#try ble/complete/action:"$ACTION"/get-desc
    if [[ $opt_raw ]]; then
      y=0 g=0 lc=0 lg=0 LINES=1 COLUMNS=$cols ble/canvas/trace "$desc" truncate:relative:ellipsis
    else
      y=0 lines=1 ble/canvas/trace-text "$desc" nonewline
    fi
    esc=$esc$ret
    ((y+1>=lines)) && break
    ((x=0,++y))
    esc=$esc$'\n'
  done
  end=$index
}
function ble/complete/menu/style:desc/guess {
  ((ipage=scroll/lines,
    begin=ipage*lines,
    end=begin))
}
function ble/complete/menu/style:desc-raw/construct-page {
  ble/complete/menu/style:desc/construct-page "$@"
}
function ble/complete/menu/style:desc-raw/guess {
  ble/complete/menu/style:desc/guess
}
function ble/complete/menu/construct {
  local iloop=0 opts=$1
  local cand_count=${#cand_pack[@]}
  local version=$cand_count:$lines:$cols
  local scroll=0 rex=':scroll=([0-9]+):' use_cache=
  if [[ :$opts: =~ $rex ]]; then
    scroll=${BASH_REMATCH[1]}
    ((${#cand_pack[@]}&&(scroll%=cand_count)))
    [[ $_ble_complete_menu_style_version == $version ]] && use_cache=1
  fi
  if [[ ! $use_cache ]]; then
    _ble_complete_menu_style_measure=()
    _ble_complete_menu_style_items=()
    _ble_complete_menu_style_pages=()
  fi
  local begin=0 end=0 ipage=0
  ble/function#try ble/complete/menu/style:"$menu_style"/guess
  while ((end<cand_count)); do
    ((scroll<begin)) && return 1
    local page_data=${_ble_complete_menu_style_pages[ipage]}
    if [[ $page_data ]]; then
      local fields; ble/string#split fields , "${page_data%%:*}"
      begin=${fields[0]} end=${fields[1]}
      if ((begin<=scroll&&scroll<end)); then
        x=${fields[2]} y=${fields[3]} esc=${page_data#*:}
        break
      fi
    else
      ble/complete/menu/style:"$menu_style"/construct-page "$opts" || return
      _ble_complete_menu_style_pages[ipage]=$begin,$end,$x,$y:$esc
      ((begin<=scroll&&scroll<end)) && break
    fi
    begin=$end
    ((ipage++))
  done
  _ble_complete_menu_style_version=$version
  menu_items=("${_ble_complete_menu_style_items[@]:begin:end-begin}")
  menu_ipage=$ipage
  menu_offset=$begin
  return 0
}
function ble/complete/menu/clear {
  if [[ $_ble_complete_menu_active ]]; then
    _ble_complete_menu_active=
    ble-edit/info/immediate-clear
    [[ $_ble_highlight_layer_menu_filter_beg ]] &&
      ble/textarea#invalidate str # layer:menu_filter 解除 (#D0995)
  fi
}
ble/array#push _ble_widget_bell_hook ble/complete/menu/clear
function ble/complete/menu/get-footprint {
  footprint=$_ble_edit_ind:$_ble_edit_mark_active:${_ble_edit_mark_active:+$_ble_edit_mark}:$_ble_edit_overwrite_mode:$_ble_edit_str
}
function ble/complete/menu/show {
  local opts=$1
  local menu_style=$bleopt_complete_menu_style
  [[ :$opts: == *:filter:* && $_ble_complete_menu_style ]] &&
    menu_style=$_ble_complete_menu_style
  if [[ :$opts: == *:load-filtered-data:* ]]; then
    local COMP1=${_ble_complete_menu_comp[0]}
    local COMP2=${_ble_complete_menu_comp[1]}
    local COMPS=${_ble_complete_menu_comp[2]}
    local COMPV=${_ble_complete_menu_comp[3]}
    local comp_type=${_ble_complete_menu_comp[4]}
    local comps_flags=${_ble_complete_menu0_comp[5]}
    local comps_fixed=${_ble_complete_menu0_comp[6]}
    local cand_pack; cand_pack=("${_ble_complete_menu_pack[@]}")
    local menu_common_part=$_ble_complete_menu_common_part
  fi
  local cols lines
  ble-edit/info/.initialize-size
  if ((${#cand_pack[@]})); then
    local x y esc menu_items menu_offset=0 menu_ipage=
    ble/complete/menu/construct "$opts" || return
    local info_data
    info_data=(store "$x" "$y" "$esc")
  else
    local menu_items info_data menu_offset=0 menu_ipage=
    menu_items=()
    info_data=(ansi $'\e[38;5;242m(no candidates)\e[m')
  fi
  ble-edit/info/immediate-show "${info_data[@]}"
  _ble_complete_menu_ipage=$menu_ipage
  _ble_complete_menu_offset=$menu_offset
  _ble_complete_menu_common_part=$menu_common_part
  _ble_complete_menu_pack=("${cand_pack[@]}")
  _ble_complete_menu_items=("${menu_items[@]}")
  _ble_complete_menu_info_data=("${info_data[@]}")
  if [[ :$opts: == *:menu-source:* ]]; then
    local left0=${_ble_complete_menu0_str::_ble_complete_menu0_end}
    local left1=${_ble_edit_str::_ble_edit_ind}
    local ret; ble/string#common-prefix "$left0" "$left1"; left0=$ret
    local right0=${_ble_complete_menu0_str:_ble_complete_menu0_end}
    local right1=${_ble_edit_str:_ble_edit_ind}
    local ret; ble/string#common-suffix "$right0" "$right1"; right0=$ret
    local footprint; ble/complete/menu/get-footprint
    _ble_complete_menu0_str=$left0$right0
    _ble_complete_menu0_end=${#left0}
    _ble_complete_menu_footprint=$footprint
  elif [[ :$opts: != *:filter:* ]]; then
    local beg=$COMP1 end=$_ble_edit_ind # COMP2 でなく補完挿入後の位置
    local footprint; ble/complete/menu/get-footprint
    _ble_complete_menu_active=1
    _ble_complete_menu_style=$menu_style
    _ble_complete_menu0_beg=$beg
    _ble_complete_menu0_end=$end
    _ble_complete_menu0_str=$_ble_edit_str
    _ble_complete_menu0_comp=("$COMP1" "$COMP2" "$COMPS" "$COMPV" "$comp_type" "$comps_flags" "$comps_fixed")
    _ble_complete_menu0_pack=("${cand_pack[@]}")
    _ble_complete_menu_selected=-1
    _ble_complete_menu_comp=("$COMP1" "$COMP2" "$COMPS" "$COMPV" "$comp_type")
    _ble_complete_menu_footprint=$footprint
  fi
  return 0
}
function ble/complete/menu/redraw {
  if [[ $_ble_complete_menu_active ]]; then
    ble-edit/info/immediate-show "${_ble_complete_menu_info_data[@]}"
  fi
}
function ble/complete/menu/get-active-range {
  [[ $_ble_complete_menu_active ]] || return 1
  local str=${1-$_ble_edit_str} ind=${2-$_ble_edit_ind}
  local mbeg=$_ble_complete_menu0_beg
  local mend=$_ble_complete_menu0_end
  local left=${_ble_complete_menu0_str::mend}
  local right=${_ble_complete_menu0_str:mend}
  if [[ ${str::_ble_edit_ind} == "$left"* && ${str:_ble_edit_ind} == *"$right" ]]; then
    ((beg=mbeg,end=${#str}-${#right}))
    return 0
  else
    ble/complete/menu/clear
    return 1
  fi
}
function ble/complete/menu/generate-candidates-from-menu {
  COMP1=${_ble_complete_menu_comp[0]}
  COMP2=${_ble_complete_menu_comp[1]}
  COMPS=${_ble_complete_menu_comp[2]}
  COMPV=${_ble_complete_menu_comp[3]}
  comp_type=${_ble_complete_menu_comp[4]}
  comps_flags=${_ble_complete_menu0_comp[5]}
  comps_fixed=${_ble_complete_menu0_comp[6]}
  comps_filter_pattern= # これは source が使うだけなので使われない筈…
  cand_count=${#_ble_complete_menu_pack[@]}
  cand_cand=() cand_word=() cand_pack=()
  local pack "${_ble_complete_cand_varnames[@]}"
  for pack in "${_ble_complete_menu_pack[@]}"; do
    ble/complete/cand/unpack "$pack"
    ble/array#push cand_cand "$CAND"
    ble/array#push cand_word "$INSERT"
    ble/array#push cand_pack "$pack"
  done
  ((cand_count))
}
function ble/complete/generate-candidates-from-opts {
  local opts=$1
  local context; ble/complete/complete/determine-context-from-opts "$opts"
  comp_type=
  local comp_text=$_ble_edit_str comp_index=$_ble_edit_ind
  local sources
  ble/complete/context:"$context"/generate-sources "$comp_text" "$comp_index" || return 1
  ble/complete/candidates/generate
}
function ble/complete/insert {
  local insert_beg=$1 insert_end=$2
  local insert=$3 suffix=$4
  local original_text=${_ble_edit_str:insert_beg:insert_end-insert_beg}
  local ret
  local insert_replace=
  if [[ $insert == "$original_text"* ]]; then
    insert=${insert:insert_end-insert_beg}
    ((insert_beg=insert_end))
  else
    ble/string#common-prefix "$insert" "$original_text"
    if [[ $ret ]]; then
      insert=${insert:${#ret}}
      ((insert_beg+=${#ret}))
    fi
  fi
  if ble/util/test-rl-variable skip-completed-text; then
    if [[ $insert ]]; then
      local right_text=${_ble_edit_str:insert_end}
      right_text=${right_text%%[$IFS]*}
      if ble/string#common-prefix "$insert" "$right_text"; [[ $ret ]]; then
        ((insert_end+=${#ret}))
      elif ble/complete/string#common-suffix-prefix "$insert" "$right_text"; [[ $ret ]]; then
        ((insert_end+=${#ret}))
      fi
    fi
    if [[ $suffix ]]; then
      local right_text=${_ble_edit_str:insert_end}
      if ble/string#common-prefix "$suffix" "$right_text"; [[ $ret ]]; then
        ((insert_end+=${#ret}))
      elif ble/complete/string#common-suffix-prefix "$suffix" "$right_text"; [[ $ret ]]; then
        ((insert_end+=${#ret}))
      fi
    fi
  fi
  local ins=$insert$suffix
  ble/widget/.replace-range "$insert_beg" "$insert_end" "$ins" 1
  ((_ble_edit_ind=insert_beg+${#ins},
    _ble_edit_ind>${#_ble_edit_str}&&
      (_ble_edit_ind=${#_ble_edit_str})))
}
_ble_complete_state=
function ble/widget/complete {
  local opts=$1
  ble-edit/content/clear-arg
  local state=$_ble_complete_state
  _ble_complete_state=start
  local menu_show_opts=
  if [[ :$opts: == *:enter_menu:* ]]; then
    [[ $_ble_complete_menu_active && :$opts: != *:context=*:* ]] &&
      ble/complete/menu-complete/enter && return
  elif [[ $bleopt_complete_menu_complete ]]; then
    if [[ $_ble_complete_menu_active && :$opts: != *:context=*:* && :$opts: != *:insert_all:* ]]; then
      local footprint; ble/complete/menu/get-footprint
      [[ $footprint == "$_ble_complete_menu_footprint" ]] &&
        ble/complete/menu-complete/enter && return
    fi
    [[ $WIDGET == "$LASTWIDGET" && $state != complete ]] && opts=$opts:enter_menu
  fi
  local COMP1 COMP2 COMPS COMPV
  local comp_type comps_flags comps_fixed
  local comps_filter_pattern
  local cand_count=0
  local -a cand_cand cand_word cand_pack
  if [[ $_ble_complete_menu_active && :$opts: != *:regenerate:* &&
          :$opts: != *:context=*:* && ${#_ble_complete_menu_items[@]} -gt 0 ]]
  then
    if [[ $_ble_complete_menu_filter_enabled ]] || {
         ble/complete/menu-filter; local ext=$?
         ((ext==148)) && return 148
         ((ext==0)); }; then
      ble/complete/menu/generate-candidates-from-menu; local ext=$?
      ((ext==148)) && return 148
      if ((ext==0&&cand_count)); then
        local bleopt_complete_menu_style=$_ble_complete_menu_style
        menu_show_opts=$menu_show_opts:menu-source # 既存の filter 前候補を保持する
      fi
    fi
  fi
  if ((cand_count==0)); then
    ble/complete/generate-candidates-from-opts "$opts"; local ext=$?
    if ((ext==148)); then
      return 148
    elif ((ext!=0)); then
      ble/widget/.bell
      ble-edit/info/clear
      return 1
    fi
  fi
  if [[ :$opts: == *:insert_all:* ]]; then
    local "${_ble_complete_cand_varnames[@]}"
    local pack beg=$COMP1 end=$COMP2 insert= suffix= index=0
    for pack in "${cand_pack[@]}"; do
      ble/complete/cand/unpack "$pack"
      insert=$INSERT suffix=
      if ble/is-function ble/complete/action:"$ACTION"/complete; then
        ble/complete/action:"$ACTION"/complete
        (($?==148)) && return 148
      fi
      [[ $suffix != *' ' ]] && suffix="$suffix "
      ble/complete/insert "$beg" "$end" "$insert" "$suffix"
      ble/util/invoke-hook _ble_complete_insert_hook
      beg=$_ble_edit_ind end=$_ble_edit_ind
      ((index++))
    done
    _ble_complete_state=complete
    ble/complete/menu/clear
    return
  elif [[ :$opts: == *:enter_menu:* ]]; then
    local menu_common_part=$COMPV
    ble/complete/menu/show "$menu_show_opts" || return
    ble/complete/menu-complete/enter; local ext=$?
    ((ext==148)) && return 148
    ((ext)) && ble/widget/.bell
    return
  elif [[ :$opts: == *:show_menu:* ]]; then
    local menu_common_part=$COMPV
    ble/complete/menu/show "$menu_show_opts"
    return # exit status of ble/complete/menu/show
  fi
  local ret
  ble/complete/candidates/determine-common-prefix; local insert=$ret suffix=
  local insert_beg=$COMP1 insert_end=$COMP2
  local insert_flags=
  [[ $insert == "$COMPS"* ]] || insert_flags=r
  if ((cand_count==1)); then
    local ACTION=${cand_pack[0]%%:*}
    if ble/is-function ble/complete/action:"$ACTION"/complete; then
      local "${_ble_complete_cand_varnames[@]}"
      ble/complete/cand/unpack "${cand_pack[0]}"
      ble/complete/action:"$ACTION"/complete
      (($?==148)) && return 148
    fi
  else
    insert_flags=${insert_flags}m
  fi
  local do_insert=1
  if ((cand_count>1)) && [[ $insert_flags == *r* ]]; then
    if [[ :$comp_type: != *:[amAi]:* ]]; then
      do_insert=
    fi
  elif [[ $insert$suffix == "$COMPS" ]]; then
    do_insert=
  fi
  if [[ $do_insert ]]; then
    ble/complete/insert "$insert_beg" "$insert_end" "$insert" "$suffix"
    ble/util/invoke-hook _ble_complete_insert_hook
  fi
  if [[ $insert_flags == *m* ]]; then
    local menu_common_part=$COMPV
    local ret simple_flags simple_ibrace
    if ble/syntax:bash/simple-word/reconstruct-incomplete-word "$insert"; then
      ble/syntax:bash/simple-word/eval "$ret"
      menu_common_part=$ret
    fi
    ble/complete/menu/show "$menu_show_opts" || return
  elif [[ $insert_flags == *n* ]]; then
    ble/widget/complete show_menu:regenerate || return
  else
    _ble_complete_state=complete
    ble/complete/menu/clear
  fi
  return 0
}
function ble/widget/complete-insert {
  local original=$1 insert=$2 suffix=$3
  [[ ${_ble_edit_str::_ble_edit_ind} == *"$original" ]] || return 1
  local insert_beg=$((_ble_edit_ind-${#original}))
  local insert_end=$_ble_edit_ind
  ble/complete/insert "$insert_beg" "$insert_end" "$insert" "$suffix"
}
function ble/widget/menu-complete {
  local opts=$1
  ble/widget/complete enter_menu:$opts
}
function ble/complete/menu-filter/.filter-candidates {
  cand_pack=()
  local iloop=0 interval=$bleopt_complete_polling_cycle
  local filter_type pack "${_ble_complete_cand_varnames[@]}"
  local comps_filter_pattern
  for filter_type in head substr hsubseq subseq; do
    ble/path#remove-glob comp_type '[amA]'
    case $filter_type in
    (substr)  comp_type=${comp_type}:m ;;
    (hsubseq) comp_type=${comp_type}:a ;;
    (subseq)  comp_type=${comp_type}:A ;;
    esac
    ble/function#try ble/complete/candidates/filter:"$filter_type"/init "$COMPV"
    for pack in "${_ble_complete_menu0_pack[@]}"; do
      ((iloop++%interval==0)) && ble/complete/check-cancel && return 148
      ble/complete/cand/unpack "$pack"
      ble/complete/candidates/filter:"$filter_type"/test "$CAND" &&
        ble/array#push cand_pack "$pack"
    done
    ((${#cand_pack[@]}!=0)) && break
  done
}
function ble/complete/menu-filter/.get-filter-target {
  if [[ $_ble_decode_keymap == emacs || $_ble_decode_keymap == vi_[ic]map ]]; then
    ret=$_ble_edit_str
  elif [[ $_ble_decode_keymap == auto_complete ]]; then
    ret=${_ble_edit_str::_ble_edit_ind}${_ble_edit_str:_ble_edit_mark}
  else
    return 1
  fi
}
function ble/complete/menu-filter {
  [[ $_ble_decode_keymap == menu_complete ]] && return 0
  local ret; ble/complete/menu-filter/.get-filter-target || return 1; local str=$ret
  local beg end; ble/complete/menu/get-active-range "$str" "$_ble_edit_ind" || return 1
  local input=${str:beg:end-beg}
  [[ $input == "${_ble_complete_menu_comp[2]}" ]] && return 0
  local simple_flags simple_ibrace
  if ! ble/syntax:bash/simple-word/reconstruct-incomplete-word "$input"; then
    ble/syntax:bash/simple-word/is-never-word "$input" && return 1
    return 0
  fi
  [[ $simple_ibrace ]] && ((${simple_ibrace%%:*}>10#${_ble_complete_menu0_comp[6]%%:*})) && return 1 # 別のブレース展開要素に入った時
  ble/syntax:bash/simple-word/eval "$ret"
  local COMPV=$ret
  local comp_type=${_ble_complete_menu0_comp[4]} cand_pack
  ble/complete/menu-filter/.filter-candidates
  local menu_common_part=$COMPV
  ble/complete/menu/show filter || return
  _ble_complete_menu_comp=("$beg" "$end" "$input" "$COMPV" "$comp_type")
  return 0
}
function ble/complete/menu-filter.idle {
  ble/util/idle.wait-user-input
  [[ $bleopt_complete_menu_filter ]] || return
  [[ $_ble_complete_menu_active ]] || return
  ble/complete/menu-filter; local ext=$?
  ((ext==148)) && return 148
  ((ext)) && ble/complete/menu/clear
}
function ble/highlight/layer/buff#operate-gflags {
  local BUFF=$1 beg=$2 end=$3 mask=$4 gflags=$5
  ((beg<end)) || return
  if [[ $mask == auto ]]; then
    mask=0
    (((gflags&_ble_color_gflags_ForeColor)&&(mask|=0xFF<<_ble_color_gflags_ShiftFg)))
    (((gflags&_ble_color_gflags_BackColor)&&(mask|=0xFF<<_ble_color_gflags_ShiftBg)))
  fi
  local i g ret
  for ((i=beg;i<end;i++)); do
    ble/highlight/layer/update/getg "$i"
    ((g=g&~mask|gflags))
    ble/color/g2sgr "$g"
    builtin eval "$BUFF[$i]=\$ret\${_ble_highlight_layer_plain_buff[$i]}"
  done
}
function ble/highlight/layer/buff#set-explicit-sgr {
  local BUFF=$1 index=$2
  builtin eval "((index<\${#$BUFF[@]}))" || return
  local g; ble/highlight/layer/update/getg "$index"
  local ret; ble/color/g2sgr "$g"
  builtin eval "$BUFF[index]=\$ret\${_ble_highlight_layer_plain_buff[index]}"
}
ble/color/defface menu_filter_fixed bold
ble/color/defface menu_filter_input fg=16,bg=229
_ble_highlight_layer_menu_filter_buff=()
_ble_highlight_layer_menu_filter_beg=
_ble_highlight_layer_menu_filter_end=
function ble/highlight/layer:menu_filter/update {
  local text=$1 player=$2
  local obeg=$_ble_highlight_layer_menu_filter_beg
  local oend=$_ble_highlight_layer_menu_filter_end
  if [[ $obeg ]] && ((DMIN>=0)); then
    ((DMAX0<=obeg?(obeg+=DMAX-DMAX0):(DMIN<obeg&&(obeg=DMIN)),
      DMAX0<=oend?(oend+=DMAX-DMAX0):(DMIN<oend&&(oend=DMIN))))
  fi
  _ble_highlight_layer_menu_filter_beg=$obeg
  _ble_highlight_layer_menu_filter_end=$oend
  local beg= end= ret
  if [[ $_ble_complete_menu_active && ${#_ble_complete_menu_items[@]} -gt 0 ]]; then
    ble/complete/menu-filter/.get-filter-target && local str=$ret &&
      ble/complete/menu/get-active-range "$str" "$_ble_edit_ind" &&
      [[ ${str:beg:end-beg} != "${_ble_complete_menu0_comp[2]}" ]] || beg= end=
  fi
  [[ ! $obeg && ! $beg ]] && return
  ((PREV_UMIN<0)) && [[ $beg == "$obeg" && $end == "$oend" ]] &&
    PREV_BUFF=_ble_highlight_layer_menu_filter_buff && return
  local umin=$PREV_UMIN umax=$PREV_UMAX
  if [[ $beg ]]; then
    local g
    ble/color/face2g menu_filter_fixed; local gF=$g
    ble/color/face2g menu_filter_input; local gI=$g
    local mid=$_ble_complete_menu0_end
    ((mid<beg?(mid=beg):(end<mid&&(mid=end))))
    local buff_name=_ble_highlight_layer_menu_filter_buff
    builtin eval "$buff_name=(\"\${$PREV_BUFF[@]}\")"
    ble/highlight/layer/buff#operate-gflags "$buff_name" "$beg" "$mid" auto "$gF"
    ble/highlight/layer/buff#operate-gflags "$buff_name" "$mid" "$end" auto "$gI"
    ble/highlight/layer/buff#set-explicit-sgr "$buff_name" "$end"
    PREV_BUFF=$buff_name
    if [[ $obeg ]]; then :
      ble/highlight/layer:region/.update-dirty-range "$beg" "$obeg"
      ble/highlight/layer:region/.update-dirty-range "$end" "$oend"
    else
      ble/highlight/layer:region/.update-dirty-range "$beg" "$end"
    fi
  else
    if [[ $obeg ]]; then
      ble/highlight/layer:region/.update-dirty-range "$obeg" "$oend"
    fi
  fi
  _ble_highlight_layer_menu_filter_beg=$beg
  _ble_highlight_layer_menu_filter_end=$end
  ((PREV_UMIN=umin,PREV_UMAX=umax))
}
function ble/highlight/layer:menu_filter/getg {
  local index=$1
  local obeg=$_ble_highlight_layer_menu_filter_beg
  local oend=$_ble_highlight_layer_menu_filter_end
  local mid=$_ble_complete_menu0_end
  if [[ $obeg ]] && ((obeg<=index&&index<oend)); then
    if ((index<mid)); then
      ble/color/face2g menu_filter_fixed; local g0=$g
    else
      ble/color/face2g menu_filter_input; local g0=$g
    fi
    ble/highlight/layer/update/getg "$index"
    (((g0&_ble_color_gflags_ForeColor)&&(g&=~_ble_color_gflags_MaskFg)))
    (((g0&_ble_color_gflags_BackColor)&&(g&=~_ble_color_gflags_MaskBg)))
    ((g|=g0))
  fi
}
_ble_complete_menu_filter_enabled=
if ble/is-function ble/util/idle.push-background; then
  _ble_complete_menu_filter_enabled=1
  ble/util/idle.push-background ble/complete/menu-filter.idle
  ble/array#insert-before _ble_highlight_layer__list region menu_filter
fi
_ble_complete_menu_original=
function ble/highlight/layer:region/mark:menu_complete/get-face {
  face=menu_complete
}
function ble/complete/menu-complete/select {
  local osel=$_ble_complete_menu_selected nsel=$1 opts=$2
  local ncand=${#_ble_complete_menu_pack[@]}
  ((0<=osel&&osel<ncand)) || osel=-1
  ((0<=nsel&&nsel<ncand)) || nsel=-1
  ((osel==nsel)) && return
  local infox infoy
  ble/canvas/panel#get-origin "$_ble_edit_info_panel" --prefix=info
  local visible_beg=$_ble_complete_menu_offset
  local visible_end=$((visible_beg+${#_ble_complete_menu_items[@]}))
  if ((nsel>=0&&!(visible_beg<=nsel&&nsel<visible_end))); then
    local cols lines ret
    ble-edit/info/.initialize-size
    ble/complete/menu/show filter:load-filtered-data:scroll="$nsel"; local ext=$?
    ((ext)) && return "$ext"
    if [[ $_ble_complete_menu_ipage ]]; then
      local ipage=$_ble_complete_menu_ipage
      ble/term/visible-bell "menu-complete: Page $((ipage+1))" persistent
    else
      ble/term/visible-bell "menu-complete: Offset $_ble_complete_menu_offset/$ncand" persistent
    fi
    visible_beg=$_ble_complete_menu_offset
    visible_end=$((visible_beg+${#_ble_complete_menu_items[@]}))
    ((visible_end<=nsel&&(nsel=visible_end-1)))
    ((nsel<=visible_beg&&(nsel=visible_beg)))
    ((visible_beg<=osel&&osel<visible_end)) || osel=-1
  fi
  local -a DRAW_BUFF=()
  local x0=$_ble_canvas_x y0=$_ble_canvas_y
  if ((osel>=0)); then
    local entry=${_ble_complete_menu_items[osel-visible_beg]}
    local fields text=${entry#*:}
    ble/string#split fields , "${entry%%:*}"
    if ((fields[3]<_ble_canvas_panel_height[_ble_edit_info_panel])); then
      ble/canvas/panel#goto.draw "$_ble_edit_info_panel" "${fields[@]::2}"
      ble/canvas/put.draw "${text:fields[4]}"
      _ble_canvas_x=${fields[2]} _ble_canvas_y=$((infoy+fields[3]))
    fi
  fi
  local value=
  if ((nsel>=0)); then
    [[ :$opts: == *:goto-page-top:* ]] && nsel=$visible_beg
    local entry=${_ble_complete_menu_items[nsel-visible_beg]}
    local fields text=${entry#*:}
    ble/string#split fields , "${entry%%:*}"
    local x=${fields[0]} y=${fields[1]}
    local "${_ble_complete_cand_varnames[@]}"
    ble/complete/cand/unpack "${text::fields[4]}"
    value=$INSERT
    local ret cols lines menu_common_part
    ble-edit/info/.initialize-size
    menu_common_part=$_ble_complete_menu_common_part
    ble/complete/menu/construct-single-entry - selected:use_vars
    if ((y<_ble_canvas_panel_height[_ble_edit_info_panel])); then
      ble/canvas/panel#goto.draw "$_ble_edit_info_panel" "${fields[@]::2}"
      ble/canvas/put.draw "$ret"
      _ble_canvas_x=$x _ble_canvas_y=$((infoy+y))
    fi
    _ble_complete_menu_selected=$nsel
  else
    _ble_complete_menu_selected=-1
    value=$_ble_complete_menu_original
  fi
  ble/canvas/goto.draw "$x0" "$y0"
  ble/canvas/bflush.draw
  ble-edit/content/replace "$_ble_complete_menu0_beg" "$_ble_edit_ind" "$value"
  ((_ble_edit_ind=_ble_complete_menu0_beg+${#value}))
}
function ble/complete/menu-complete/enter {
  [[ ${#_ble_complete_menu_items[@]} -ge 1 ]] || return 1
  local beg end; ble/complete/menu/get-active-range || return 1
  _ble_edit_mark=$beg
  _ble_edit_ind=$end
  local comps_fixed=${_ble_complete_menu0_comp[6]}
  if [[ $comps_fixed ]]; then
    local comps_fixed_length=${comps_fixed%%:*}
    ((_ble_edit_mark+=comps_fixed_length))
  fi
  _ble_complete_menu_original=${_ble_edit_str:beg:end-beg}
  ble/complete/menu/redraw
  ble/complete/menu-complete/select 0
  _ble_edit_mark_active=menu_complete
  ble-decode/keymap/push menu_complete
  return 0
}
function ble/widget/menu_complete/forward {
  local opts=$1
  local nsel=$((_ble_complete_menu_selected+1))
  local ncand=${#_ble_complete_menu_pack[@]}
  if ((nsel>=ncand)); then
    if [[ :$opts: == *:cyclic:* ]] && ((ncand>=2)); then
      nsel=0
    else
      ble/widget/.bell "menu-complete: no more candidates"
      return 1
    fi
  fi
  ble/complete/menu-complete/select "$nsel"
}
function ble/widget/menu_complete/backward {
  local opts=$1
  local nsel=$((_ble_complete_menu_selected-1))
  if ((nsel<0)); then
    local ncand=${#_ble_complete_menu_pack[@]}
    if [[ :$opts: == *:cyclic:* ]] && ((ncand>=2)); then
      ((nsel=ncand-1))
    else
      ble/widget/.bell "menu-complete: no more candidates"
      return 1
    fi
  fi
  ble/complete/menu-complete/select "$nsel"
}
function ble/widget/menu_complete/forward-line {
  local offset=$_ble_complete_menu_offset
  local osel=$_ble_complete_menu_selected
  ((osel>=0)) || return
  local entry=${_ble_complete_menu_items[osel-offset]}
  local fields; ble/string#split fields , "${entry%%:*}"
  local ox=${fields[0]} oy=${fields[1]}
  local i=$osel nsel=-1
  for entry in "${_ble_complete_menu_items[@]:osel+1-offset}"; do
    ble/string#split fields , "${entry%%:*}"
    local x=${fields[0]} y=${fields[1]}
    ((y<=oy||y==oy+1&&x<=ox||nsel<0)) || break
    ((++i,y>oy&&(nsel=i)))
  done
  ((nsel<0&&(nsel=offset+${#_ble_complete_menu_items[@]})))
  local ncand=${#_ble_complete_menu_pack[@]}
  if ((0<=nsel&&nsel<ncand)); then
    ble/complete/menu-complete/select "$nsel"
  else
    ble/widget/.bell 'menu-complete: no more candidates'
    return 1
  fi
}
function ble/widget/menu_complete/backward-line {
  local offset=$_ble_complete_menu_offset
  local osel=$_ble_complete_menu_selected
  ((osel>=0)) || return
  local entry=${_ble_complete_menu_items[osel-offset]}
  local fields; ble/string#split fields , "${entry%%:*}"
  local ox=${fields[0]} oy=${fields[1]}
  local i=$((offset-1)) nsel=$((offset-1))
  for entry in "${_ble_complete_menu_items[@]::osel-offset}"; do
    ble/string#split fields , "${entry%%:*}"
    local x=${fields[0]} y=${fields[1]}
    ((y<oy-1||y==oy-1&&x<=ox||y<oy&&nsel<0)) || break
    ((++i,nsel=i))
  done
  if ((nsel>=0)); then
    ble/complete/menu-complete/select "$nsel"
  else
    ble/widget/.bell 'menu-complete: no more candidates'
    return 1
  fi
}
function ble/widget/menu_complete/backward-page {
  if ((_ble_complete_menu_offset>0)); then
    ble/complete/menu-complete/select $((_ble_complete_menu_offset-1)) goto-page-top
  else
    ble/widget/.bell "menu-complete: this is the first page."
    return 1
  fi
}
function ble/widget/menu_complete/forward-page {
  local next=$((_ble_complete_menu_offset+${#_ble_complete_menu_items[@]}))
  if ((next<${#_ble_complete_menu_pack[@]})); then
    ble/complete/menu-complete/select "$next"
  else
    ble/widget/.bell "menu-complete: this is the last page."
    return 1
  fi
}
function ble/widget/menu_complete/beginning-of-page {
  ble/complete/menu-complete/select "$_ble_complete_menu_offset"
}
function ble/widget/menu_complete/end-of-page {
  local nitem=${#_ble_complete_menu_items[@]}
  ((nitem)) && ble/complete/menu-complete/select $((_ble_complete_menu_offset+nitem-1))
}
function ble/widget/menu_complete/exit {
  local opts=$1
  ble-decode/keymap/pop
  if ((_ble_complete_menu_selected>=0)); then
    local new=${_ble_edit_str:_ble_complete_menu0_beg:_ble_edit_ind-_ble_complete_menu0_beg}
    local old=$_ble_complete_menu_original
    local comp_text=${_ble_edit_str::_ble_complete_menu0_beg}$old${_ble_edit_str:_ble_edit_ind}
    local insert_beg=$_ble_complete_menu0_beg
    local insert_end=$((_ble_complete_menu0_beg+${#old}))
    local insert=$new
    local insert_flags=
    local suffix=
    if [[ :$opts: == *:complete:* ]]; then
      local item=${_ble_complete_menu_items[_ble_complete_menu_selected-_ble_complete_menu_offset]}
      local item_data=${item#*:} item_fields
      ble/string#split item_fields , "${item%%:*}"
      local pack=${item_data::item_fields[4]}
      local ACTION=${pack%%:*}
      if ble/is-function ble/complete/action:"$ACTION"/complete; then
        local COMP1=${_ble_complete_menu0_comp[0]}
        local COMP2=${_ble_complete_menu0_comp[1]}
        local COMPS=${_ble_complete_menu0_comp[2]}
        local COMPV=${_ble_complete_menu0_comp[3]}
        local comp_type=${_ble_complete_menu0_comp[4]}
        local comps_flags=${_ble_complete_menu0_comp[5]}
        local comps_fixed=${_ble_complete_menu0_comp[6]}
        local "${_ble_complete_cand_varnames[@]}"
        ble/complete/cand/unpack "$pack"
        ble/complete/action:"$ACTION"/complete
      fi
      ble/complete/insert "$_ble_complete_menu0_beg" "$_ble_edit_ind" "$insert" "$suffix"
    fi
    ble/util/invoke-hook _ble_complete_insert_hook
  fi
  ble/complete/menu/clear
  _ble_edit_mark_active=
}
function ble/widget/menu_complete/cancel {
  ble-decode/keymap/pop
  ble/complete/menu-complete/select -1
  _ble_edit_mark_active=
}
function ble/widget/menu_complete/exit-default {
  ble/widget/menu_complete/exit
  ble-decode-key "${KEYS[@]}"
}
function ble-decode/keymap:menu_complete/define {
  local ble_bind_keymap=menu_complete
  ble-bind -f __default__ 'menu_complete/exit-default'
  ble-bind -f C-m         'menu_complete/exit complete'
  ble-bind -f RET         'menu_complete/exit complete'
  ble-bind -f C-g         'menu_complete/cancel'
  ble-bind -f 'C-x C-g'   'menu_complete/cancel'
  ble-bind -f 'C-M-g'     'menu_complete/cancel'
  ble-bind -f C-f         'menu_complete/forward'
  ble-bind -f right       'menu_complete/forward'
  ble-bind -f C-i         'menu_complete/forward cyclic'
  ble-bind -f TAB         'menu_complete/forward cyclic'
  ble-bind -f C-b         'menu_complete/backward'
  ble-bind -f left        'menu_complete/backward'
  ble-bind -f C-S-i       'menu_complete/backward cyclic'
  ble-bind -f S-TAB       'menu_complete/backward cyclic'
  ble-bind -f C-n         'menu_complete/forward-line'
  ble-bind -f down        'menu_complete/forward-line'
  ble-bind -f C-p         'menu_complete/backward-line'
  ble-bind -f up          'menu_complete/backward-line'
  ble-bind -f prior       'menu_complete/backward-page'
  ble-bind -f next        'menu_complete/forward-page'
  ble-bind -f home        'menu_complete/beginning-of-page'
  ble-bind -f end         'menu_complete/end-of-page'
}
function ble/complete/auto-complete/initialize {
  local ret
  ble-decode-kbd/generate-keycode auto_complete_enter
  _ble_complete_KCODE_ENTER=$ret
}
ble/complete/auto-complete/initialize
function ble/highlight/layer:region/mark:auto_complete/get-face {
  face=auto_complete
}
_ble_complete_ac_type=
_ble_complete_ac_comp1=
_ble_complete_ac_cand=
_ble_complete_ac_word=
_ble_complete_ac_insert=
_ble_complete_ac_suffix=
function ble/complete/auto-complete/.search-history-light {
  [[ $_ble_edit_history_prefix ]] && return 1
  local text=$1
  [[ ! $text ]] && return 1
  local wordbreaks="<>();&|:$_ble_term_IFS"
  local word=
  if [[ $text != [-0-9#?!]* ]]; then
    word=${text%%[$wordbreaks]*}
    local expand
    BASH_COMMAND='!'$word ble/util/assign expand 'ble/edit/hist_expanded/.core' &>/dev/null || return 1
    if [[ $expand == "$text"* ]]; then
      ret=$expand
      return 0
    fi
  fi
  if [[ $word != "$text" ]]; then
    local fragments; ble/string#split fragments '?' "$text"
    local frag longest_fragments len=0; longest_fragments=('')
    for frag in "${fragments[@]}"; do
      local len1=${#frag}
      ((len1>len&&(len=len1))) && longest_fragments=()
      ((len1==len)) && ble/array#push longest_fragments "$frag"
    done
    for frag in "${longest_fragments[@]}"; do
      BASH_COMMAND='!?'$frag ble/util/assign expand 'ble/edit/hist_expanded/.core' &>/dev/null || return 1
      [[ $expand == "$text"* ]] || continue
      ret=$expand
      return 0
    done
  fi
  return 1
}
_ble_complete_ac_history_needle=
_ble_complete_ac_history_index=
_ble_complete_ac_history_start=
function ble/complete/auto-complete/.search-history-heavy {
  local text=$1
  local count; ble-edit/history/get-count -v count
  local start=$((count-1))
  local index=$((count-1))
  local needle=$text
  ((start==_ble_complete_ac_history_start)) &&
    [[ $needle == "$_ble_complete_ac_history_needle"* ]] &&
    index=$_ble_complete_ac_history_index
  local isearch_time=0 isearch_ntask=1
  local isearch_opts=head
  [[ :$comp_type: == *:sync:* ]] || isearch_opts=$isearch_opts:stop_check
  ble-edit/isearch/backward-search-history-blockwise "$isearch_opts"; local ext=$?
  _ble_complete_ac_history_start=$start
  _ble_complete_ac_history_index=$index
  _ble_complete_ac_history_needle=$needle
  ((ext)) && return "$ext"
  ble-edit/history/get-editted-entry -v ret "$index"
  return 0
}
function ble/complete/auto-complete/.setup-auto-complete-mode {
  _ble_complete_ac_type=$type
  _ble_complete_ac_comp1=$COMP1
  _ble_complete_ac_cand=$cand
  _ble_complete_ac_word=$word
  _ble_complete_ac_insert=$insert
  _ble_complete_ac_suffix=$suffix
  _ble_edit_mark_active=auto_complete
  ble-decode/keymap/push auto_complete
  ble-decode-key "$_ble_complete_KCODE_ENTER" # dummy key input to record keyboard macros
}
function ble/complete/auto-complete/.check-history {
  local opts=$1
  local searcher=.search-history-heavy
  [[ :$opts: == *:light:*  ]] && searcher=.search-history-light
  local ret
  ((_ble_edit_ind==${#_ble_edit_str})) || return 1
  ble/complete/auto-complete/"$searcher" "$_ble_edit_str" || return # 0, 1 or 148
  local word=$ret cand=
  local COMP1=0 COMPS=$_ble_edit_str
  [[ $word == "$COMPS" ]] && return 1
  local insert=$word suffix=
  local type=h
  local ins=${insert:${#COMPS}}
  ble-edit/content/replace "$_ble_edit_ind" "$_ble_edit_ind" "$ins"
  ((_ble_edit_mark=_ble_edit_ind+${#ins}))
  ble/complete/auto-complete/.setup-auto-complete-mode
  return 0
}
function ble/complete/auto-complete/.check-context {
  local sources
  ble/complete/context:syntax/generate-sources "$comp_text" "$comp_index" &&
    ble/complete/context/filter-prefix-sources || return 1
  local bleopt_complete_contract_function_names=
  ((bleopt_complete_polling_cycle>25)) &&
    local bleopt_complete_polling_cycle=25
  local COMP1 COMP2 COMPS COMPV
  local comps_flags comps_fixed
  local comps_filter_pattern
  local cand_count
  local -a cand_cand cand_word cand_pack
  ble/complete/candidates/generate; local ext=$?
  [[ $COMPV ]] || return 1
  ((ext)) && return "$ext"
  ((cand_count)) || return
  local word=${cand_word[0]} cand=${cand_cand[0]}
  [[ $word == "$COMPS" ]] && return 1
  local insert=$word suffix=
  local ACTION=${cand_pack[0]%%:*}
  if ble/is-function ble/complete/action:"$ACTION"/complete; then
    local "${_ble_complete_cand_varnames[@]}"
    ble/complete/cand/unpack "${cand_pack[0]}"
    ble/complete/action:"$ACTION"/complete
  fi
  local type=
  if [[ $word == "$COMPS"* ]]; then
    [[ ${comp_text:COMP1} == "$word"* ]] && return 1
    type=c
    local ins=${insert:${#COMPS}}
    ble-edit/content/replace "$_ble_edit_ind" "$_ble_edit_ind" "$ins"
    ((_ble_edit_mark=_ble_edit_ind+${#ins}))
  else
    case :$comp_type: in
    (*:a:*) type=a ;;
    (*:m:*) type=m ;;
    (*:A:*) type=A ;;
    (*)   type=r ;;
    esac
    ble-edit/content/replace "$_ble_edit_ind" "$_ble_edit_ind" " [$insert] "
    ((_ble_edit_mark=_ble_edit_ind+4+${#insert}))
  fi
  ble/complete/auto-complete/.setup-auto-complete-mode
  return 0
}
function ble/complete/auto-complete.impl {
  local opts=$1
  local comp_type=
  [[ :$opts: == *:sync:* ]] && comp_type=${comp_type}:sync
  local comp_text=$_ble_edit_str comp_index=$_ble_edit_ind
  [[ $comp_text ]] || return 0
  if local beg end; ble/complete/menu/get-active-range "$_ble_edit_str" "$_ble_edit_ind"; then
    ((_ble_edit_ind<end)) && return 0
  fi
  if [[ $bleopt_complete_auto_history ]]; then
    ble/complete/auto-complete/.check-history light; local ext=$?
    ((ext==0||ext==148)) && return "$ext"
    [[ $_ble_edit_history_prefix || $_ble_edit_history_loaded ]] &&
      ble/complete/auto-complete/.check-history; local ext=$?
    ((ext==0||ext==148)) && return "$ext"
  fi
  ble/complete/auto-complete/.check-context
}
function ble/complete/auto-complete.idle {
  ble/util/idle.wait-user-input
  [[ $bleopt_complete_auto_complete ]] || return
  [[ $_ble_decode_keymap == emacs || $_ble_decode_keymap == vi_[ic]map ]] || return 0
  case $_ble_decode_widget_last in
  (ble/widget/self-insert) ;;
  (ble/widget/complete) ;;
  (ble/widget/vi_imap/complete) ;;
  (*) return 0 ;;
  esac
  [[ $_ble_edit_str ]] || return 0
  local rest_delay=$((bleopt_complete_auto_delay-ble_util_idle_elapsed))
  if ((rest_delay>0)); then
    ble/util/idle.sleep "$rest_delay"
    return
  fi
  ble/complete/auto-complete.impl
}
ble/function#try ble/util/idle.push-background ble/complete/auto-complete.idle
function ble/widget/auto-complete-enter {
  ble/complete/auto-complete.impl sync
}
function ble/widget/auto_complete/cancel {
  ble-decode/keymap/pop
  ble-edit/content/replace "$_ble_edit_ind" "$_ble_edit_mark" ''
  _ble_edit_mark=$_ble_edit_ind
  _ble_edit_mark_active=
  _ble_complete_ac_insert=
  _ble_complete_ac_suffix=
}
function ble/widget/auto_complete/insert {
  ble-decode/keymap/pop
  ble-edit/content/replace "$_ble_edit_ind" "$_ble_edit_mark" ''
  _ble_edit_mark=$_ble_edit_ind
  local comp_text=$_ble_edit_str
  local insert_beg=$_ble_complete_ac_comp1
  local insert_end=$_ble_edit_ind
  local insert=$_ble_complete_ac_insert
  local suffix=$_ble_complete_ac_suffix
  ble/complete/insert "$insert_beg" "$insert_end" "$insert" "$suffix"
  ble/util/invoke-hook _ble_complete_insert_hook
  _ble_edit_mark_active=
  _ble_complete_ac_insert=
  _ble_complete_ac_suffix=
  ble/complete/menu/clear
  ble-edit/content/clear-arg
}
function ble/widget/auto_complete/cancel-default {
  ble/widget/auto_complete/cancel
  ble-decode-key "${KEYS[@]}"
}
function ble/widget/auto_complete/self-insert {
  local code=$((KEYS[0]&_ble_decode_MaskChar))
  ((code==0)) && return
  local ret
  ble/util/c2s "$code"; local ins=$ret
  local comps_cur=${_ble_edit_str:_ble_complete_ac_comp1:_ble_edit_ind-_ble_complete_ac_comp1}
  local comps_new=$comps_cur$ins
  local processed=
  if [[ $_ble_complete_ac_type == [ch] ]]; then
    if [[ $_ble_complete_ac_word == "$comps_new"* ]]; then
      ((_ble_edit_ind+=${#ins}))
      [[ ! $_ble_complete_ac_word ]] && ble/widget/auto_complete/cancel
      processed=1
    fi
  elif [[ $_ble_complete_ac_type == [ra] && $ins != [{,}] ]]; then
    if local ret simple_flags simple_ibrace; ble/syntax:bash/simple-word/reconstruct-incomplete-word "$comps_new"; then
      ble/syntax:bash/simple-word/eval "$ret"; local compv_new=$ret
      if [[ $_ble_complete_ac_type == [rmaA] ]]; then
        local comp_filter_type=head
        case $_ble_complete_ac_type in
        (*m*) comp_filter_type=substr  ;;
        (*a*) comp_filter_type=hsubseq ;;
        (*A*) comp_filter_type=subseq  ;;
        esac
        local comps_fixed= comps_filter_pattern
        ble/complete/candidates/filter:"$comp_filter_type"/init "$compv_new"
        if ble/complete/candidates/filter:"$comp_filter_type"/test "$_ble_complete_ac_cand"; then
          ble-edit/content/replace "$_ble_edit_ind" "$_ble_edit_ind" "$ins"
          ((_ble_edit_ind+=${#ins},_ble_edit_mark+=${#ins}))
          [[ $_ble_complete_ac_cand == "$compv_new" ]] &&
            ble/widget/auto_complete/cancel
          processed=1
        fi
      fi
    fi
  fi
  if [[ $processed ]]; then
    local comp_text= insert_beg=0 insert_end=0 insert=$ins suffix=
    ble/util/invoke-hook _ble_complete_insert_hook
    return 0
  else
    ble/widget/auto_complete/cancel
    ble-decode-key "${KEYS[@]}"
  fi
}
function ble/widget/auto_complete/insert-on-end {
  if ((_ble_edit_mark==${#_ble_edit_str})); then
    ble/widget/auto_complete/insert
  else
    ble/widget/auto_complete/cancel-default
  fi
}
function ble/widget/auto_complete/insert-word {
  local rex='^['$_ble_term_IFS']*([^'$_ble_term_IFS']+['$_ble_term_IFS']*)?'
  if [[ $_ble_complete_ac_type == [ch] ]]; then
    local ins=${_ble_edit_str:_ble_edit_ind:_ble_edit_mark-_ble_edit_ind}
    [[ $ins =~ $rex ]]
    if [[ $BASH_REMATCH == "$ins" ]]; then
      ble/widget/auto_complete/insert
      return
    else
      local ins=$BASH_REMATCH
      ((_ble_edit_ind+=${#ins}))
      local comp_text=$_ble_edit_str
      local insert_beg=$_ble_complete_ac_comp1
      local insert_end=$_ble_edit_ind
      local insert=${_ble_edit_str:insert_beg:insert_end-insert_beg}$ins
      local suffix=
      ble/util/invoke-hook _ble_complete_insert_hook
      return 0
    fi
  elif [[ $_ble_complete_ac_type == [ra] ]]; then
    local ins=$_ble_complete_ac_insert
    [[ $ins =~ $rex ]]
    if [[ $BASH_REMATCH == "$ins" ]]; then
      ble/widget/auto_complete/insert
      return
    else
      local ins=$BASH_REMATCH
      _ble_complete_ac_type=c
      ble-edit/content/replace "$_ble_complete_ac_comp1" "$_ble_edit_mark" "$_ble_complete_ac_insert"
      ((_ble_edit_ind=_ble_complete_ac_comp1+${#ins},
        _ble_edit_mark=_ble_complete_ac_comp1+${#_ble_complete_ac_insert}))
      local comp_text=$_ble_edit_str
      local insert_beg=$_ble_complete_ac_comp1
      local insert_end=$_ble_edit_ind
      local insert=$ins
      local suffix=
      ble/util/invoke-hook _ble_complete_insert_hook
      return 0
    fi
  fi
  return 1
}
function ble/widget/auto_complete/accept-line {
  ble/widget/auto_complete/insert
  ble-decode-key 13
}
function ble-decode/keymap:auto_complete/define {
  local ble_bind_keymap=auto_complete
  ble-bind -f __defchar__ auto_complete/self-insert
  ble-bind -f __default__ auto_complete/cancel-default
  ble-bind -f 'C-g'       auto_complete/cancel
  ble-bind -f 'C-x C-g'   auto_complete/cancel
  ble-bind -f 'C-M-g'     auto_complete/cancel
  ble-bind -f S-RET       auto_complete/insert
  ble-bind -f S-C-m       auto_complete/insert
  ble-bind -f C-f         auto_complete/insert-on-end
  ble-bind -f right       auto_complete/insert-on-end
  ble-bind -f end         auto_complete/insert-on-end
  ble-bind -f M-f         auto_complete/insert-word
  ble-bind -f M-right     auto_complete/insert-word
  ble-bind -f C-j         auto_complete/accept-line
  ble-bind -f C-RET       auto_complete/accept-line
  ble-bind -f auto_complete_enter nop
}
function ble/complete/sabbrev/.print-definition {
  local key=$1 type=${2%%:*} value=${2#*:}
  local flags=
  [[ $type == m ]] && flags='-m '
  local q=\' Q="'\''" shell_specialchars=$' \n\t&|;<>()''\$`"'\''[]*?!~'
  if [[ $key == *["$shell_specialchars"]* ]]; then
    printf "ble-sabbrev %s'%s=%s'\n" "$flags" "${key//$q/$Q}" "${value//$q/$Q}"
  else
    printf "ble-sabbrev %s%s='%s'\n" "$flags" "$key" "${value//$q/$Q}"
  fi
}
if ((_ble_bash>=40200||_ble_bash>=40000&&!_ble_bash_loaded_in_function)); then
  function ble/complete/sabbrev/register {
    local key=$1 value=$2
    _ble_complete_sabbrev[$key]=$value
  }
  function ble/complete/sabbrev/list {
    local key
    for key in "${!_ble_complete_sabbrev[@]}"; do
      local value=${_ble_complete_sabbrev[$key]}
      ble/complete/sabbrev/.print-definition "$key" "$value"
    done
  }
  function ble/complete/sabbrev/get {
    local key=$1
    ret=${_ble_complete_sabbrev[$key]}
    [[ $ret ]]
  }
  function ble/complete/sabbrev/get-keys {
    keys=("${!_ble_complete_sabbrev[@]}")
  }
else
  if ! ble/is-array _ble_complete_sabbrev_keys; then # reload #D0875
    _ble_complete_sabbrev_keys=()
    _ble_complete_sabbrev_values=()
  fi
  function ble/complete/sabbrev/register {
    local key=$1 value=$2 i=0
    for key2 in "${_ble_complete_sabbrev_keys[@]}"; do
      [[ $key2 == "$key" ]] && break
      ((i++))
    done
    _ble_complete_sabbrev_keys[i]=$key
    _ble_complete_sabbrev_values[i]=$value
  }
  function ble/complete/sabbrev/list {
    local shell_specialchars=$' \n\t&|;<>()''\$`"'\''[]*?!~'
    local i N=${#_ble_complete_sabbrev_keys[@]} q=\' Q="'\''"
    for ((i=0;i<N;i++)); do
      local key=${_ble_complete_sabbrev_keys[i]}
      local value=${_ble_complete_sabbrev_values[i]}
      ble/complete/sabbrev/.print-definition "$key" "$value"
    done
  }
  function ble/complete/sabbrev/get {
    ret=
    local key=$1 value=$2 i=0
    for key in "${_ble_complete_sabbrev_keys[@]}"; do
      if [[ $key == "$1" ]]; then
        ret=${_ble_complete_sabbrev_values[i]}
        break
      fi
      ((i++))
    done
    [[ $ret ]]
  }
  function ble/complete/sabbrev/get-keys {
    keys=("${_ble_complete_sabbrev_keys[@]}")
  }
fi
function ble/complete/sabbrev/read-arguments {
  while (($#)); do
    local arg=$1; shift
    if [[ $arg == ?*=* ]]; then
      ble/array#push specs "s:$arg"
    else
      case $arg in
      (--help) flag_help=1 ;;
      (-*)
        local i n=${#arg} c
        for ((i=1;i<n;i++)); do
          c=${arg:i:1}
          case $c in
          (m)
            if ((!$#)); then
              echo "ble-sabbrev: option argument for '-$c' is missing" >&2
              flag_error=1
            elif [[ $1 != ?*=* ]]; then
              echo "ble-sabbrev: invalid option argument '-$c $1' (expected form: '-c key=value')" >&2
              flag_error=1
            else
              ble/array#push specs "$c:$1"; shift
            fi ;;
          (*)
            echo "ble-sabbrev: unknown option '-$c'." >&2
            flag_error=1 ;;
          esac
        done ;;
      (*)
        echo "ble-sabbrev: unrecognized argument '$arg'." >&2
        flag_error=1 ;;
      esac
    fi
  done
}
function ble-sabbrev {
  if (($#)); then
    local -a specs=()
    local flag_help= flag_error=
    ble/complete/sabbrev/read-arguments "$@"
    if [[ $flag_help || $flag_error ]]; then
      [[ $flag_error ]] && echo
      printf '%s\n' \
             'usage: ble-sabbrev key=value' \
             'usage: ble-sabbrev -m key=function' \
             'usage: ble-sabbrev --help' \
             'Register sabbrev expansion.'
      [[ ! $flag_error ]]; return
    fi
    local spec key type value
    for spec in "${specs[@]}"; do
      type=${spec::1} spec=${spec:2}
      key=${spec%%=*} value=${spec#*=}
      ble/complete/sabbrev/register "$key" "$type:$value"
    done
  else
    ble/complete/sabbrev/list
  fi
}
function ble/complete/sabbrev/expand {
  local sources comp_index=$_ble_edit_ind comp_text=$_ble_edit_str
  ble/complete/context:syntax/generate-sources
  local src asrc pos=$comp_index
  for src in "${sources[@]}"; do
    ble/string#split-words asrc "$src"
    case ${asrc[0]} in
    (file|command|argument|variable:w)
      ((asrc[1]<pos)) && pos=${asrc[1]} ;;
    esac
  done
  ((pos<comp_index)) || return 1
  local key=${_ble_edit_str:pos:comp_index-pos}
  local ret; ble/complete/sabbrev/get "$key" || return 1
  local type=${ret%%:*} value=${ret#*:}
  case $type in
  (s)
    ble/widget/.replace-range "$pos" "$comp_index" "$value"
    ((_ble_edit_ind=pos+${#value})) ;;
  (m)
    local comp_type= comps_flags= comps_fixed=
    local COMP1=$pos COMP2=$pos COMPS=$key COMPV=
    ble/complete/candidates/comp_type#read-rl-variables
    local cand_count=0
    local -a cand_cand=() cand_word=() cand_pack=()
    local cand COMP_PREFIX=
    local bleopt_sabbrev_menu_style=$bleopt_complete_menu_style
    local bleopt_sabbrev_menu_opts=
    local -a COMPREPLY=()
    eval "$value"
    for cand in "${COMPREPLY[@]}"; do
      ble/complete/cand/yield word "$cand" ""
    done
    if ((cand_count==0)); then
      return 1
    elif ((cand_count==1)); then
      local value=${cand_word[0]}
      ble/widget/.replace-range "$pos" "$comp_index" "$value"
      ((_ble_edit_ind=pos+${#value}))
      return 0
    fi
    ble/widget/.replace-range "$pos" "$comp_index" ''
    local bleopt_complete_menu_style=$bleopt_sabbrev_menu_style
    local menu_common_part=
    ble/complete/menu/show || return
    [[ :$bleopt_sabbrev_menu_opts: == *:enter_menu:* ]] &&
      ble/complete/menu-complete/enter
    return 148 ;;
  (*) return 1 ;;
  esac
  return 0
}
function ble/widget/sabbrev-expand {
  if ! ble/complete/sabbrev/expand; then
    ble/widget/.bell
    return 1
  fi
}
function ble/complete/action:sabbrev/initialize { CAND=$value; }
function ble/complete/action:sabbrev/complete { :; }
function ble/complete/action:sabbrev/init-menu-item {
  ble/color/face2g command_alias
  show=$INSERT
}
function ble/complete/action:sabbrev/get-desc {
  local ret; ble/complete/sabbrev/get "$INSERT"
  desc="(sabbrev expansion) $ret"
}
function ble/complete/source:sabbrev {
  local keys; ble/complete/sabbrev/get-keys
  local key cand
  local comps_fixed= comps_filter_pattern=
  ble/complete/candidates/filter:"$comp_filter_type"/init "$COMPS"
  for cand in "${keys[@]}"; do
    ble/complete/candidates/filter:"$comp_filter_type"/test "$cand" || continue
    local ret simple_flags simple_ibrace
    ble/syntax:bash/simple-word/reconstruct-incomplete-word "$cand" &&
      ble/syntax:bash/simple-word/eval "$ret" || continue
    local value=$ret
    ble/complete/cand/yield sabbrev "$cand"
  done
}
_ble_complete_dabbrev_original=
_ble_complete_dabbrev_regex1=
_ble_complete_dabbrev_regex2=
_ble_complete_dabbrev_index=
_ble_complete_dabbrev_pos=
_ble_complete_dabbrev_stack=()
function ble/complete/dabbrev/.show-status.fib {
  local index='!'$((_ble_complete_dabbrev_index+1))
  local nmatch=${#_ble_complete_dabbrev_stack[@]}
  local needle=$_ble_complete_dabbrev_original
  local text="(dabbrev#$nmatch: << $index) \`$needle'"
  local pos=$1
  if [[ $pos ]]; then
    local count; ble-edit/history/get-count
    local percentage=$((count?pos*1000/count:1000))
    text="$text searching... @$pos ($((percentage/10)).$((percentage%10))%)"
  fi
  ((fib_ntask)) && text="$text *$fib_ntask"
  ble-edit/info/show text "$text"
}
function ble/complete/dabbrev/show-status {
  local fib_ntask=${#_ble_util_fiberchain[@]}
  ble/complete/dabbrev/.show-status.fib
}
function ble/complete/dabbrev/erase-status {
  ble-edit/info/default
}
function ble/complete/dabbrev/initialize-variables {
  local wordbreaks=$_ble_term_IFS$COMP_WORDBREAKS
  [[ $wordbreaks == *'('* ]] && wordbreaks=${wordbreaks//['()']}'()'
  [[ $wordbreaks == *']'* ]] && wordbreaks=']'${wordbreaks//']'}
  [[ $wordbreaks == *'-'* ]] && wordbreaks=${wordbreaks//'-'}'-'
  _ble_complete_dabbrev_wordbreaks=$wordbreaks
  local left=${_ble_edit_str::_ble_edit_ind}
  local original=${left##*[$wordbreaks]}
  local p1=$((_ble_edit_ind-${#original})) p2=$_ble_edit_ind
  _ble_edit_mark=$p1
  _ble_edit_ind=$p2
  _ble_complete_dabbrev_original=$original
  local ret; ble/string#escape-for-extended-regex "$original"
  local needle='(^|['$wordbreaks'])'$ret
  _ble_complete_dabbrev_regex1=$needle
  _ble_complete_dabbrev_regex2='('$needle'[^'$wordbreaks']*).*'
  local index; ble-edit/history/get-index
  _ble_complete_dabbrev_index=$index
  _ble_complete_dabbrev_pos=${#_ble_edit_str}
  _ble_complete_dabbrev_stack=()
}
function ble/complete/dabbrev/reset {
  local original=$_ble_complete_dabbrev_original
  ble-edit/content/replace "$_ble_edit_mark" "$_ble_edit_ind" "$original"
  ((_ble_edit_ind=_ble_edit_mark+${#original}))
  _ble_edit_mark_active=
}
function ble/complete/dabbrev/search-in-history-entry {
  local line=$1 index=$2
  local index_editing; ble-edit/history/get-index -v index_editing
  if ((index!=index_editing)); then
    local pos=$dabbrev_pos
    while [[ ${line:pos} && ${line:pos} =~ $_ble_complete_dabbrev_regex2 ]]; do
      local rematch1=${BASH_REMATCH[1]} rematch2=${BASH_REMATCH[2]}
      local match=${rematch1:${#rematch2}}
      if [[ $match && $match != "$dabbrev_current_match" ]]; then
        dabbrev_match=$match
        dabbrev_match_pos=$((${#line}-${#BASH_REMATCH}+${#match}))
        return 0
      else
        ((pos++))
      fi
    done
  fi
  return 1
}
function ble/complete/dabbrev/.search.fib {
  if [[ ! $fib_suspend ]]; then
    local start=$_ble_complete_dabbrev_index
    local index=$_ble_complete_dabbrev_index
    local pos=$_ble_complete_dabbrev_pos
    ((--start>=0)) || ble-edit/history/get-count -v start
  else
    local start index pos; eval "$fib_suspend"
    fib_suspend=
  fi
  local dabbrev_match=
  local dabbrev_pos=$pos
  local dabbrev_current_match=${_ble_edit_str:_ble_edit_mark:_ble_edit_ind-_ble_edit_mark}
  local line; ble-edit/history/get-editted-entry -v line "$index"
  if ! ble/complete/dabbrev/search-in-history-entry "$line" "$index"; then
    ((index--,dabbrev_pos=0))
    local isearch_time=0
    local isearch_opts=stop_check:cyclic
    isearch_opts=$isearch_opts:condition
    local dabbrev_original=$_ble_complete_dabbrev_original
    local dabbrev_regex1=$_ble_complete_dabbrev_regex1
    local needle='[[ $LINE =~ $dabbrev_regex1 ]] && ble/complete/dabbrev/search-in-history-entry "$LINE" "$INDEX"'
    [[ $dabbrev_original ]] && needle='[[ $LINE == *"$dabbrev_original"* ]] && '$needle
    isearch_opts=$isearch_opts:progress
    local isearch_progress_callback=ble/complete/dabbrev/.show-status.fib
    ble-edit/isearch/backward-search-history-blockwise "$isearch_opts"; local ext=$?
    ((ext==148)) && fib_suspend="start=$start index=$index pos=$pos"
    if ((ext)); then
      if ((${#_ble_complete_dabbrev_stack[@]})); then
        ble/widget/.bell # 周回したので鳴らす
        return 0
      else
        return "$ext"
      fi
    fi
  fi
  local rec=$_ble_complete_dabbrev_index,$_ble_complete_dabbrev_pos,$_ble_edit_ind,$_ble_edit_mark
  ble/array#push _ble_complete_dabbrev_stack "$rec:$_ble_edit_str"
  ble-edit/content/replace "$_ble_edit_mark" "$_ble_edit_ind" "$dabbrev_match"
  ((_ble_edit_ind=_ble_edit_mark+${#dabbrev_match}))
  ((index>_ble_complete_dabbrev_index)) &&
    ble/widget/.bell # 周回
  _ble_complete_dabbrev_index=$index
  _ble_complete_dabbrev_pos=$dabbrev_match_pos
  ble/textarea#redraw
}
function ble/complete/dabbrev/next.fib {
  ble/complete/dabbrev/.search.fib; local ext=$?
  if ((ext==0)); then
    _ble_edit_mark_active=menu_complete
    ble/complete/dabbrev/.show-status.fib
  elif ((ext==148)); then
    ble/complete/dabbrev/.show-status.fib
  else
    ble/widget/.bell
    ble/widget/dabbrev/exit
    ble/complete/dabbrev/reset
    fib_kill=1
  fi
  return "$ext"
}
function ble/widget/dabbrev-expand {
  ble/complete/dabbrev/initialize-variables
  ble-decode/keymap/push dabbrev
  ble/util/fiberchain#initialize ble/complete/dabbrev
  ble/util/fiberchain#push next
  ble/util/fiberchain#resume
}
function ble/widget/dabbrev/next {
  ble/util/fiberchain#push next
  ble/util/fiberchain#resume
}
function ble/widget/dabbrev/prev {
  if ((${#_ble_util_fiberchain[@]})); then
    local ret; ble/array#pop _ble_util_fiberchain
    if ((${#_ble_util_fiberchain[@]})); then
      ble/util/fiberchain#resume
    else
      ble/complete/dabbrev/show-status
    fi
  elif ((${#_ble_complete_dabbrev_stack[@]})); then
    local ret; ble/array#pop _ble_complete_dabbrev_stack
    local rec str=${ret#*:}
    ble/string#split rec , "${ret%%:*}"
    ble-edit/content/reset-and-check-dirty "$str"
    _ble_edit_ind=${rec[2]}
    _ble_edit_mark=${rec[3]}
    _ble_complete_dabbrev_index=${rec[0]}
    _ble_complete_dabbrev_pos=${rec[1]}
    ble/complete/dabbrev/show-status
  else
    ble/widget/.bell
    return 1
  fi
}
function ble/widget/dabbrev/cancel {
  if ((${#_ble_util_fiberchain[@]})); then
    ble/util/fiberchain#clear
    ble/complete/dabbrev/show-status
  else
    ble/widget/dabbrev/exit
    ble/complete/dabbrev/reset
  fi
}
function ble/widget/dabbrev/exit {
  ble-decode/keymap/pop
  _ble_edit_mark_active=
  ble/complete/dabbrev/erase-status
}
function ble/widget/dabbrev/exit-default {
  ble/widget/dabbrev/exit
  ble-decode-key "${KEYS[@]}"
}
function ble/widget/dabbrev/accept-line {
  ble/widget/dabbrev/exit
  ble-decode-key 13
}
function ble-decode/keymap:dabbrev/define {
  local ble_bind_keymap=dabbrev
  ble-bind -f __default__ 'dabbrev/exit-default'
  ble-bind -f 'C-g'       'dabbrev/cancel'
  ble-bind -f 'C-x C-g'   'dabbrev/cancel'
  ble-bind -f 'C-M-g'     'dabbrev/cancel'
  ble-bind -f C-r         'dabbrev/next'
  ble-bind -f C-s         'dabbrev/prev'
  ble-bind -f RET         'dabbrev/exit'
  ble-bind -f C-m         'dabbrev/exit'
  ble-bind -f C-RET       'dabbrev/accept-line'
  ble-bind -f C-j         'dabbrev/accept-line'
}
function ble/cmdinfo/complete:cd/.impl {
  local type=$1
  [[ $comps_flags == *v* ]] || return 1
  if [[ $COMPV == -* ]]; then
    local action=word
    case $type in
    (pushd)
      if [[ $COMPV == - || $COMPV == -n ]]; then
        ble/complete/cand/yield "$action" -n
      fi ;;
    (*)
      COMP_PREFIX=$COMPV
      local -a list=()
      [[ $COMPV == -* ]] && ble/complete/cand/yield "$action" "${COMPV}"
      [[ $COMPV != *L* ]] && ble/complete/cand/yield "$action" "${COMPV}L"
      [[ $COMPV != *P* ]] && ble/complete/cand/yield "$action" "${COMPV}P"
      ((_ble_bash>=40200)) && [[ $COMPV != *e* ]] && ble/complete/cand/yield "$action" "${COMPV}e"
      ((_ble_bash>=40300)) && [[ $COMPV != *@* ]] && ble/complete/cand/yield "$action" "${COMPV}@" ;;
    esac
    return
  fi
  [[ $COMPV =~ ^.+/ ]] && COMP_PREFIX=${BASH_REMATCH[0]}
  ble/complete/source:dir
  if [[ $CDPATH ]]; then
    local names; ble/string#split names : "$CDPATH"
    local name
    for name in "${names[@]}"; do
      [[ $name ]] || continue
      name=${name%/}/
      local ret cand
      ble/complete/source:file/.construct-pathname-pattern "$COMPV"
      ble/complete/util/eval-pathname-expansion "$name/$ret"
      for cand in "${ret[@]}"; do
        [[ $cand && -d $cand ]] || continue
        [[ $cand == / ]] || cand=${cand%/}
        cand=${cand#"$name"/}
        [[ $FIGNORE ]] && ! ble/complete/.fignore/filter "$cand" && continue
        ble/complete/cand/yield file "$cand"
      done
    done
  fi
}
function ble/cmdinfo/complete:cd {
  ble/cmdinfo/complete:cd/.impl cd
}
function ble/cmdinfo/complete:pushd {
  ble/cmdinfo/complete:cd/.impl pushd
}
ble/util/invoke-hook _ble_complete_load_hook
