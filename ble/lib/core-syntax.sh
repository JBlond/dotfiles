# this script is a part of blesh (https://github.com/akinomyoga/ble.sh) under BSD-3-Clause license
function ble/syntax/urange#update {
  local prefix=$1
  local p1=$2 p2=${3:-$2}
  ((0<=p1&&p1<p2)) || return
  (((${prefix}umin<0||${prefix}umin>p1)&&(${prefix}umin=p1),
    (${prefix}umax<0||${prefix}umax<p2)&&(${prefix}umax=p2)))
}
function ble/syntax/wrange#update {
  local prefix=$1
  local p1=$2 p2=${3:-$2}
  ((0<=p1&&p1<=p2)) || return
  (((${prefix}umin<0||${prefix}umin>p1)&&(${prefix}umin=p1),
    (${prefix}umax<0||${prefix}umax<p2)&&(${prefix}umax=p2)))
}
function ble/syntax/urange#shift {
  local prefix=$1
  ((${prefix}umin>=end0?(${prefix}umin+=shift):(
      ${prefix}umin>=beg&&(${prefix}umin=end)),
    ${prefix}umax>end0?(${prefix}umax+=shift):(
      ${prefix}umax>beg&&(${prefix}umax=beg)),
    ${prefix}umin>=${prefix}umax&&
      (${prefix}umin=${prefix}umax=-1)))
}
function ble/syntax/wrange#shift {
  local prefix=$1
  ((${prefix}umin>=end0?(${prefix}umin+=shift):(
       ${prefix}umin>beg&&(${prefix}umin=end)),
    ${prefix}umax>=end0?(${prefix}umax+=shift):(
      ${prefix}umax>=beg&&(${prefix}umax=beg)),
    ${prefix}umin==0&&++${prefix}umin,
    ${prefix}umin>${prefix}umax&&
      (${prefix}umin=${prefix}umax=-1)))
}
_ble_syntax_text=
_ble_syntax_lang=bash
_ble_syntax_stat=()
_ble_syntax_nest=()
_ble_syntax_tree=()
_ble_syntax_attr=()
_ble_syntax_TREE_WIDTH=5
function ble/syntax/tree-enumerate/.initialize {
  if [[ ! ${_ble_syntax_stat[iN]} ]]; then
    root= i=-1 nofs=0
    return
  fi
  local -a stat nest
  ble/string#split-words stat "${_ble_syntax_stat[iN]}"
  local wtype=${stat[2]}
  local wlen=${stat[1]}
  local nlen=${stat[3]} inest
  ((inest=nlen<0?nlen:iN-nlen))
  local tclen=${stat[4]}
  local tplen=${stat[5]}
  root=
  ((iN>0)) && root=${_ble_syntax_tree[iN-1]}
  while
    if ((wlen>=0)); then
      root="$wtype $wlen $tclen $tplen -- $root"
      tclen=0
    fi
    ((inest>=0))
  do
    ble/util/assert '[[ ${_ble_syntax_nest[inest]} ]]' "$FUNCNAME/FATAL1" || break
    ble/string#split-words nest "${_ble_syntax_nest[inest]}"
    local olen=$((iN-inest))
    tplen=${nest[4]}
    ((tplen>=0&&(tplen+=olen)))
    root="${nest[7]} $olen $tclen $tplen -- $root"
    wtype=${nest[2]} wlen=${nest[1]} nlen=${nest[3]} tclen=0 tplen=${nest[5]}
    ((wlen>=0&&(wlen+=olen),
      tplen>=0&&(tplen+=olen),
      nlen>=0&&(nlen+=olen),
      inest=nlen<0?nlen:iN-nlen))
    ble/util/assert '((nlen<0||nlen>olen))' "$FUNCNAME/FATAL2" || break
  done
  if [[ $root ]]; then
    ((i=iN))
  else
    ((i=tclen>=0?iN-tclen:tclen))
  fi
  ((nofs=0))
}
function ble/syntax/tree-enumerate/.impl {
  local islast=1
  while ((i>0)); do
    local -a node
    if ((i<iN)); then
      ble/string#split-words node "${_ble_syntax_tree[i-1]}"
    else
      ble/string#split-words node "${root:-${_ble_syntax_tree[iN-1]}}"
    fi
    ble/util/assert '((nofs<${#node[@]}))' "$FUNCNAME(i=$i,iN=$iN,nofs=$nofs,node=${node[*]},command=$@)/FATAL1" || break
    local wtype=${node[nofs]} wlen=${node[nofs+1]} tclen=${node[nofs+2]} tplen=${node[nofs+3]} attr=${node[nofs+4]}
    local wbegin=$((wlen<0?wlen:i-wlen))
    local tchild=$((tclen<0?tclen:i-tclen))
    local tprev=$((tplen<0?tplen:i-tplen))
    "$@"
    ble/util/assert '((tprev<i))' "$FUNCNAME/FATAL2" || break
    ((i=tprev,nofs=0,islast=0))
  done
}
function ble/syntax/tree-enumerate-children {
  ((0<tchild&&tchild<=i)) || return
  local nofs=$((i==tchild?nofs+_ble_syntax_TREE_WIDTH:0))
  local i=$tchild
  ble/syntax/tree-enumerate/.impl "$@"
}
function ble/syntax/tree-enumerate-break () ((tprev=-1))
function ble/syntax/tree-enumerate {
  local root i nofs
  [[ ${iN:+set} ]] || local iN=${#_ble_syntax_text}
  ble/syntax/tree-enumerate/.initialize
  ble/syntax/tree-enumerate/.impl "$@"
}
function ble/syntax/tree-enumerate-in-range {
  local beg=$1 end=$2
  local proc=$3
  local -a node
  local i nofs
  for ((i=end;i>=beg;i--)); do
    ((i>0)) && [[ ${_ble_syntax_tree[i-1]} ]] || continue
    ble/string#split-words node "${_ble_syntax_tree[i-1]}"
    local flagUpdateNode=
    for ((nofs=0;nofs<${#node[@]};nofs+=_ble_syntax_TREE_WIDTH)); do
      local wtype=${node[nofs]} wlen=${node[nofs+1]}
      local wbeg=$((wlen<0?wlen:i-wlen)) wend=$i
      "${@:3}"
    done
    [[ $flagUpdateNode ]] && _ble_syntax_tree[i-1]="${node[*]}"
  done
}
function ble/syntax/print-status/.graph {
  local char=$1
  if ble/util/isprint+ "$char"; then
    graph="'$char'"
    return
  else
    local ret
    ble/util/s2c "$char" 0
    local code=$ret
    if ((code<32)); then
      ble/util/c2s $((code+64))
      graph="$_ble_term_rev^$ret$_ble_term_sgr0"
    elif ((code==127)); then
      graph="$_ble_term_rev^?$_ble_term_sgr0"
    elif ((128<=code&&code<160)); then
      ble/util/c2s $((code-64))
      graph="${_ble_term_rev}M-^$ret$_ble_term_sgr0"
    else
      graph="'$char' ($code)"
    fi
  fi
}
function ble/syntax/print-status/.tree-prepend {
  local j=$1
  local value=$2${tree[j]}
  tree[j]=$value
  ((max_tree_width<${#value}&&(max_tree_width=${#value})))
}
function ble/syntax/print-status/.dump-arrays/.append-attr-char {
  if (($?==0)); then
    attr="${attr}$1"
  else
    attr="${attr} "
  fi
}
function ble/syntax/print-status/ctx#get-text {
  local sgr
  ble/syntax/ctx#get-name "$1"
  ret=${ret#BLE_}
  if [[ ! $ret ]]; then
    ble/color/face2sgr syntax_error
    ret="${sgr}CTX$1$_ble_term_sgr0"
  fi
}
function ble/syntax/print-status/word.get-text {
  local index=$1
  ble/string#split-words word "${_ble_syntax_tree[index]}"
  local out= ret
  if [[ $word ]]; then
    local nofs=$((${#word[@]}/_ble_syntax_TREE_WIDTH*_ble_syntax_TREE_WIDTH))
    while (((nofs-=_ble_syntax_TREE_WIDTH)>=0)); do
      local axis=$((index+1))
      local wtype=${word[nofs]}
      if [[ $wtype =~ ^[0-9]+$ ]]; then
        ble/syntax/print-status/ctx#get-text "$wtype"; wtype=$ret
      elif [[ $wtype =~ ^n* ]]; then
        wtype=$sgr_quoted\"${wtype:1}\"$_ble_term_sgr0
      else
        wtype=$sgr_error${wtype}$_ble_term_sgr0
      fi
      local b=$((axis-word[nofs+1])) e=$axis
      local _prev=${word[nofs+3]} _child=${word[nofs+2]}
      if ((_prev>=0)); then
        _prev="@$((axis-_prev-1))>"
      else
        _prev=
      fi
      if ((_child>=0)); then
        _child=">@$((axis-_child-1))"
      else
        _child=
      fi
      local wattr=${word[nofs+4]} _wattr=
      if [[ $wattr != - ]]; then
        wattr="/(wattr=$wattr)"
      else
        wattr=
      fi
      out=" word=$wtype:$_prev$b-$e$_child$wattr$out"
      for ((;b<index;b++)); do
        ble/syntax/print-status/.tree-prepend "$b" '|'
      done
      ble/syntax/print-status/.tree-prepend "$index" '+'
    done
    word=$out
  fi
}
function ble/syntax/print-status/nest.get-text {
  local index=$1
  ble/string#split-words nest "${_ble_syntax_nest[index]}"
  if [[ $nest ]]; then
    local ret
    ble/syntax/print-status/ctx#get-text "${nest[0]}"; local nctx=$ret
    local nword=-
    if ((nest[1]>=0)); then
      ble/syntax/print-status/ctx#get-text "${nest[2]}"; local swtype=$ret
      local wbegin=$((index-nest[1]))
      nword="$swtype:$wbegin-"
    fi
    local nnest=-
    ((nest[3]>=0)) && nnest="'${nest[7]}':$((index-nest[3]))-"
    local nchild=-
    if ((nest[4]>=0)); then
      local tchild=$((index-nest[4]))
      nchild='$'$tchild
      if ! ((0<tchild&&tchild<=index)) || [[ ! ${_ble_syntax_tree[tchild-1]} ]]; then
        nchild=$sgr_error$nchild$_ble_term_sgr0
      fi
    fi
    local nprev=-
    if ((nest[5]>=0)); then
      local tprev=$((index-nest[5]))
      nprev='$'$tprev
      if ! ((0<tprev&&tprev<=index)) || [[ ! ${_ble_syntax_tree[tprev-1]} ]]; then
        nprev=$sgr_error$nprev$_ble_term_sgr0
      fi
    fi
    local nparam=${nest[6]}
    if [[ $nparam == none ]]; then
      nparam=
    else
      nparam=" nparam=${nparam//$_ble_term_fs/$'\e[7m^\\\e[m'}"
    fi
    nest=" nest=($nctx w=$nword n=$nnest t=$nchild:$nprev$nparam)"
  fi
}
function ble/syntax/print-status/stat.get-text {
  local index=$1
  ble/string#split-words stat "${_ble_syntax_stat[index]}"
  if [[ $stat ]]; then
    local ret
    ble/syntax/print-status/ctx#get-text "${stat[0]}"; local stat_ctx=$ret
    local stat_word=-
    if ((stat[1]>=0)); then
      ble/syntax/print-status/ctx#get-text "${stat[2]}"; local stat_wtype=$ret
      stat_word="$stat_wtype:$((index-stat[1]))-"
    fi
    local stat_inest=-
    if ((stat[3]>=0)); then
      local inest=$((index-stat[3]))
      stat_inest="@$inest"
      if ((inest<0)) || [[ ! ${_ble_syntax_nest[inest]} ]]; then
        stat_inest=$sgr_error$stat_inest$_ble_term_sgr0
      fi
    fi
    local stat_child=-
    if ((stat[4]>=0)); then
      local tchild=$((index-stat[4]))
      stat_child='$'$tchild
      if ! ((0<tchild&&tchild<=index)) || [[ ! ${_ble_syntax_tree[tchild-1]} ]]; then
        stat_child=$sgr_error$stat_child$_ble_term_sgr0
      fi
    fi
    local stat_prev=-
    if ((stat[5]>=0)); then
      local tprev=$((index-stat[5]))
      stat_prev='$'$tprev
      if ! ((0<tprev&&tprev<=index)) || [[ ! ${_ble_syntax_tree[tprev-1]} ]]; then
        stat_prev=$sgr_error$stat_prev$_ble_term_sgr0
      fi
    fi
    local snparam=${stat[6]}
    if [[ $snparam == none ]]; then
      snparam=
    else
      snparam=" nparam=${snparam//"$_ble_term_fs"/$'\e[7m^\\\e[m'}"
    fi
    local stat_lookahead=
    ((stat[7]!=1)) && stat_lookahead=" >>${stat[7]}"
    stat=" stat=($stat_ctx w=$stat_word n=$stat_inest t=$stat_child:$stat_prev$snparam$stat_lookahead)"
  fi
}
function ble/syntax/print-status/.dump-arrays {
  local -a tree char line
  tree=()
  char=()
  line=()
  local sgr
  ble/color/face2sgr syntax_error
  local sgr_error=$sgr
  ble/color/face2sgr syntax_quoted
  local sgr_quoted=$sgr
  local i max_tree_width=0
  for ((i=0;i<=iN;i++)); do
    local attr="  ${_ble_syntax_attr[i]:-|}"
    if ((_ble_syntax_attr_umin<=i&&i<_ble_syntax_attr_umax)); then
      attr="${attr:${#attr}-2:2}*"
    else
      attr="${attr:${#attr}-2:2} "
    fi
    local ret
    [[ ${_ble_highlight_layer_syntax1_table[i]} ]] && ble/color/g2sgr "${_ble_highlight_layer_syntax1_table[i]}"
    ble/syntax/print-status/.dump-arrays/.append-attr-char "${ret}a${_ble_term_sgr0}"
    [[ ${_ble_highlight_layer_syntax2_table[i]} ]] && ble/color/g2sgr "${_ble_highlight_layer_syntax2_table[i]}"
    ble/syntax/print-status/.dump-arrays/.append-attr-char "${ret}w${_ble_term_sgr0}"
    [[ ${_ble_highlight_layer_syntax3_table[i]} ]] && ble/color/g2sgr "${_ble_highlight_layer_syntax3_table[i]}"
    ble/syntax/print-status/.dump-arrays/.append-attr-char "${ret}e${_ble_term_sgr0}"
    [[ ${_ble_syntax_stat_shift[i]} ]]
    ble/syntax/print-status/.dump-arrays/.append-attr-char s
    local index=000$i
    index=${index:${#index}-3:3}
    local word nest stat
    ble/syntax/print-status/word.get-text "$i"
    ble/syntax/print-status/nest.get-text "$i"
    ble/syntax/print-status/stat.get-text "$i"
    local graph=
    ble/syntax/print-status/.graph "${_ble_syntax_text:i:1}"
    char[i]="$attr $index $graph"
    line[i]=$word$nest$stat
  done
  resultA='_ble_syntax_attr/tree/nest/stat?'$'\n'
  ble/string#reserve-prototype "$max_tree_width"
  for ((i=0;i<=iN;i++)); do
    local t=${tree[i]}${_ble_string_prototype::max_tree_width}
    resultA="$resultA${char[i]} ${t::max_tree_width}${line[i]}"$'\n'
  done
}
function ble/syntax/print-status/.dump-tree/proc1 {
  local tip="| "; tip=${tip:islast:1}
  prefix="$prefix$tip   " ble/syntax/tree-enumerate-children ble/syntax/print-status/.dump-tree/proc1
  resultB="$prefix\_ '${_ble_syntax_text:wbegin:wlen}'$nl$resultB"
}
function ble/syntax/print-status/.dump-tree {
  resultB=
  local nl=$_ble_term_nl
  local prefix=
  ble/syntax/tree-enumerate ble/syntax/print-status/.dump-tree/proc1
}
function ble/syntax/print-status {
  local iN=${#_ble_syntax_text}
  local resultA
  ble/syntax/print-status/.dump-arrays
  local resultB
  ble/syntax/print-status/.dump-tree
  local result=$resultA$_ble_term_NL$resultB
  if [[ $1 == -v && $2 ]]; then
    local "${2%%\[*\]}" && ble/util/upvar "$2" "$result"
  else
    builtin echo "$result"
  fi
}
function ble/syntax/parse/generate-stat {
  ((ilook<=i&&(ilook=i+1)))
  _stat="$ctx $((wbegin<0?wbegin:i-wbegin)) $wtype $((inest<0?inest:i-inest)) $((tchild<0?tchild:i-tchild)) $((tprev<0?tprev:i-tprev)) ${nparam:-none} $((ilook-i))"
}
function ble/syntax/parse/set-lookahead {
  ((i+$1>ilook&&(ilook=i+$1)))
}
function ble/syntax/parse/tree-append {
  [[ $debug_p1 ]] && { ((i-1>=debug_p1)) || ble/util/stackdump "Wrong call of tree-append: Condition violation (p1=$debug_p1 i=$i iN=$iN)."; }
  local type=$1
  local beg=$2 end=$i
  local len=$((end-beg))
  ((len==0)) && return
  local tchild=$3 tprev=$4
  local ochild=-1 oprev=-1
  ((tchild>=0&&(ochild=i-tchild)))
  ((tprev>=0&&(oprev=i-tprev)))
  [[ $type =~ ^[0-9]+$ ]] && ble/syntax/parse/touch-updated-word "$i"
  _ble_syntax_tree[i-1]="$type $len $ochild $oprev - ${_ble_syntax_tree[i-1]}"
}
function ble/syntax/parse/word-push {
  wtype=$1 wbegin=$2 tprev=$tchild tchild=-1
}
function ble/syntax/parse/word-pop {
  ble/syntax/parse/tree-append "$wtype" "$wbegin" "$tchild" "$tprev"
  ((wbegin=-1,wtype=-1,tchild=i))
  ble/syntax/parse/nest-reset-tprev
}
function ble/syntax/parse/word-cancel {
  local -a word
  ble/string#split-words word "${_ble_syntax_tree[i-1]}"
  local tclen=${word[3]}
  tchild=$((tclen<0?tclen:i-tclen))
  _ble_syntax_tree[i-1]="${word[*]:_ble_syntax_TREE_WIDTH}"
}
function ble/syntax/parse/nest-push {
  local wlen=$((wbegin<0?wbegin:i-wbegin))
  local nlen=$((inest<0?inest:i-inest))
  local tclen=$((tchild<0?tchild:i-tchild))
  local tplen=$((tprev<0?tprev:i-tprev))
  _ble_syntax_nest[i]="$ctx $wlen $wtype $nlen $tclen $tplen ${nparam:-none} ${2:-none}"
  ((ctx=$1,inest=i,wbegin=-1,wtype=-1,tprev=tchild,tchild=-1))
  nparam=
}
function ble/syntax/parse/nest-pop {
  ((inest<0)) && return 1
  local -a parentNest
  ble/string#split-words parentNest "${_ble_syntax_nest[inest]}"
  local ntype=${parentNest[7]} nbeg=$inest
  ble/syntax/parse/tree-append "n$ntype" "$nbeg" "$tchild" "$tprev"
  local wlen=${parentNest[1]} nlen=${parentNest[3]} tplen=${parentNest[5]}
  ((ctx=parentNest[0]))
  ((wtype=parentNest[2]))
  ((wbegin=wlen<0?wlen:nbeg-wlen,
    inest=nlen<0?nlen:nbeg-nlen,
    tchild=i,
    tprev=tplen<0?tplen:nbeg-tplen))
  nparam=${parentNest[6]}
  [[ $nparam == none ]] && nparam=
}
function ble/syntax/parse/nest-type {
  local _var=ntype
  [[ $1 == -v ]] && _var="$2"
  if ((inest<0)); then
    eval "$_var="
    return 1
  else
    eval "$_var=\"\${_ble_syntax_nest[inest]##* }\""
  fi
}
function ble/syntax/parse/nest-ctx {
  nctx=
  ((inest>=0)) || return 1
  nctx=${_ble_syntax_nest[inest]%% *}
}
function ble/syntax/parse/nest-reset-tprev {
  if ((inest<0)); then
    tprev=-1
  else
    local -a nest
    ble/string#split-words nest "${_ble_syntax_nest[inest]}"
    local tclen=${nest[4]}
    ((tprev=tclen<0?tclen:inest-tclen))
  fi
}
function ble/syntax/parse/nest-equals {
  local parent_inest=$1
  while :; do
    ((parent_inest<i1)) && return 0 # 変更していない範囲 または -1
    ((parent_inest<i2)) && return 1 # 変更によって消えた範囲
    local _onest=${_tail_syntax_nest[parent_inest-i2]}
    local _nnest=${_ble_syntax_nest[parent_inest]}
    [[ $_onest != "$_nnest" ]] && return 1
    local -a onest; ble/string#split-words onest "$_onest"
    ((onest[3]!=0&&onest[3]<=parent_inest)) || { ble/util/stackdump "invalid nest onest[3]=${onest[3]} parent_inest=$parent_inest text=$text" && return 0; }
    ((parent_inest=onest[3]<0?onest[3]:(parent_inest-onest[3])))
  done
}
_ble_syntax_attr_umin=-1 _ble_syntax_attr_umax=-1
_ble_syntax_word_umin=-1 _ble_syntax_word_umax=-1
function ble/syntax/parse/touch-updated-attr {
  (((_ble_syntax_attr_umin<0||_ble_syntax_attr_umin>$1)&&(
      _ble_syntax_attr_umin=$1)))
}
function ble/syntax/parse/touch-updated-word {
  (($1>0)) || ble/util/stackdump "invalid word position $1"
  (((_ble_syntax_word_umin<0||_ble_syntax_word_umin>$1)&&(
      _ble_syntax_word_umin=$1)))
  (((_ble_syntax_word_umax<0||_ble_syntax_word_umax<$1)&&(
      _ble_syntax_word_umax=$1)))
}
_ble_ctx_UNSPECIFIED=0
_ble_ctx_ARGX=3
_ble_ctx_ARGX0=18
_ble_ctx_ARGI=4
_ble_ctx_ARGQ=61
_ble_ctx_CMDX=1
_ble_ctx_CMDX1=17
_ble_ctx_CMDXT=49
_ble_ctx_CMDXC=26
_ble_ctx_CMDXE=43
_ble_ctx_CMDXD0=38
_ble_ctx_CMDXD=68
_ble_ctx_CMDXV=13
_ble_ctx_CMDI=2
_ble_ctx_VRHS=11
_ble_ctx_QUOT=5
_ble_ctx_EXPR=8
_ble_attr_ERR=6
_ble_attr_VAR=7
_ble_attr_QDEL=9
_ble_attr_DEF=10
_ble_attr_DEL=12
_ble_attr_HISTX=21
_ble_attr_FUNCDEF=22
_ble_ctx_PARAM=14
_ble_ctx_PWORD=15
_ble_ctx_RDRF=19
_ble_ctx_RDRD=20
_ble_ctx_RDRS=27
_ble_ctx_VALX=23
_ble_ctx_VALI=24
_ble_ctx_VALR=65
_ble_ctx_VALQ=66
_ble_attr_COMMENT=25
_ble_ctx_ARGVX=28
_ble_ctx_ARGVI=29
_ble_ctx_ARGVR=62
_ble_ctx_CONDX=32
_ble_ctx_CONDI=33
_ble_ctx_CONDQ=67
_ble_ctx_CASE=34
_ble_ctx_PATN=30
_ble_attr_GLOB=31
_ble_ctx_BRAX=54
_ble_attr_BRACE=55
_ble_ctx_BRACE1=56
_ble_ctx_BRACE2=57
_ble_attr_TILDE=60
_ble_ctx_FARGX1=16
_ble_ctx_FARGI1=35
_ble_ctx_FARGX2=36
_ble_ctx_FARGI2=37
_ble_ctx_FARGX3=58
_ble_ctx_FARGI3=59
_ble_ctx_FARGQ3=63
_ble_ctx_SARGX1=48
_ble_ctx_CARGX1=39
_ble_ctx_CARGI1=40
_ble_ctx_CARGQ1=64
_ble_ctx_CARGX2=41
_ble_ctx_CARGI2=42
_ble_ctx_TARGX1=50
_ble_ctx_TARGI1=51
_ble_ctx_TARGX2=52
_ble_ctx_TARGI2=53
_ble_ctx_RDRH=44
_ble_ctx_RDRI=45
_ble_ctx_HERE0=46
_ble_ctx_HERE1=47
_ble_ctx_ARGEX=69
_ble_ctx_ARGEI=70
_ble_ctx_ARGER=71
_ble_attr_CMD_BOLD=101
_ble_attr_CMD_BUILTIN=102
_ble_attr_CMD_ALIAS=103
_ble_attr_CMD_FUNCTION=104
_ble_attr_CMD_FILE=105
_ble_attr_KEYWORD=106
_ble_attr_KEYWORD_BEGIN=118
_ble_attr_KEYWORD_END=119
_ble_attr_KEYWORD_MID=120
_ble_attr_CMD_JOBS=107
_ble_attr_CMD_DIR=112
_ble_attr_FILE_DIR=108
_ble_attr_FILE_STICKY=124
_ble_attr_FILE_LINK=109
_ble_attr_FILE_ORPHAN=121
_ble_attr_FILE_FILE=111
_ble_attr_FILE_SETUID=122
_ble_attr_FILE_SETGID=123
_ble_attr_FILE_EXEC=110
_ble_attr_FILE_FIFO=114
_ble_attr_FILE_CHR=115
_ble_attr_FILE_BLK=116
_ble_attr_FILE_SOCK=117
_ble_attr_FILE_WARN=113
_ble_syntax_bash_ctx_names=(
  [0]=_ble_ctx_UNSPECIFIED
  [3]=_ble_ctx_ARGX
  [18]=_ble_ctx_ARGX0
  [4]=_ble_ctx_ARGI
  [61]=_ble_ctx_ARGQ
  [1]=_ble_ctx_CMDX
  [17]=_ble_ctx_CMDX1
  [49]=_ble_ctx_CMDXT
  [26]=_ble_ctx_CMDXC
  [43]=_ble_ctx_CMDXE
  [38]=_ble_ctx_CMDXD0
  [68]=_ble_ctx_CMDXD
  [13]=_ble_ctx_CMDXV
  [2]=_ble_ctx_CMDI
  [11]=_ble_ctx_VRHS
  [5]=_ble_ctx_QUOT
  [8]=_ble_ctx_EXPR
  [6]=_ble_attr_ERR
  [7]=_ble_attr_VAR
  [9]=_ble_attr_QDEL
  [10]=_ble_attr_DEF
  [12]=_ble_attr_DEL
  [21]=_ble_attr_HISTX
  [22]=_ble_attr_FUNCDEF
  [14]=_ble_ctx_PARAM
  [15]=_ble_ctx_PWORD
  [19]=_ble_ctx_RDRF
  [20]=_ble_ctx_RDRD
  [27]=_ble_ctx_RDRS
  [23]=_ble_ctx_VALX
  [24]=_ble_ctx_VALI
  [65]=_ble_ctx_VALR
  [66]=_ble_ctx_VALQ
  [25]=_ble_attr_COMMENT
  [28]=_ble_ctx_ARGVX
  [29]=_ble_ctx_ARGVI
  [62]=_ble_ctx_ARGVR
  [32]=_ble_ctx_CONDX
  [33]=_ble_ctx_CONDI
  [67]=_ble_ctx_CONDQ
  [34]=_ble_ctx_CASE
  [30]=_ble_ctx_PATN
  [31]=_ble_attr_GLOB
  [54]=_ble_ctx_BRAX
  [55]=_ble_attr_BRACE
  [56]=_ble_ctx_BRACE1
  [57]=_ble_ctx_BRACE2
  [60]=_ble_attr_TILDE
  [16]=_ble_ctx_FARGX1
  [35]=_ble_ctx_FARGI1
  [36]=_ble_ctx_FARGX2
  [37]=_ble_ctx_FARGI2
  [58]=_ble_ctx_FARGX3
  [59]=_ble_ctx_FARGI3
  [63]=_ble_ctx_FARGQ3
  [48]=_ble_ctx_SARGX1
  [39]=_ble_ctx_CARGX1
  [40]=_ble_ctx_CARGI1
  [64]=_ble_ctx_CARGQ1
  [41]=_ble_ctx_CARGX2
  [42]=_ble_ctx_CARGI2
  [50]=_ble_ctx_TARGX1
  [51]=_ble_ctx_TARGI1
  [52]=_ble_ctx_TARGX2
  [53]=_ble_ctx_TARGI2
  [44]=_ble_ctx_RDRH
  [45]=_ble_ctx_RDRI
  [46]=_ble_ctx_HERE0
  [47]=_ble_ctx_HERE1
  [69]=_ble_ctx_ARGEX
  [70]=_ble_ctx_ARGEI
  [71]=_ble_ctx_ARGER
  [101]=_ble_attr_CMD_BOLD
  [102]=_ble_attr_CMD_BUILTIN
  [103]=_ble_attr_CMD_ALIAS
  [104]=_ble_attr_CMD_FUNCTION
  [105]=_ble_attr_CMD_FILE
  [106]=_ble_attr_KEYWORD
  [118]=_ble_attr_KEYWORD_BEGIN
  [119]=_ble_attr_KEYWORD_END
  [120]=_ble_attr_KEYWORD_MID
  [107]=_ble_attr_CMD_JOBS
  [112]=_ble_attr_CMD_DIR
  [108]=_ble_attr_FILE_DIR
  [124]=_ble_attr_FILE_STICKY
  [109]=_ble_attr_FILE_LINK
  [121]=_ble_attr_FILE_ORPHAN
  [111]=_ble_attr_FILE_FILE
  [122]=_ble_attr_FILE_SETUID
  [123]=_ble_attr_FILE_SETGID
  [110]=_ble_attr_FILE_EXEC
  [114]=_ble_attr_FILE_FIFO
  [115]=_ble_attr_FILE_CHR
  [116]=_ble_attr_FILE_BLK
  [117]=_ble_attr_FILE_SOCK
  [113]=_ble_attr_FILE_WARN
)
function ble/syntax/ctx#get-name {
  ret=${_ble_syntax_bash_ctx_names[$1]}
}
_BLE_SYNTAX_FCTX=()
_BLE_SYNTAX_FEND=()
function ble/syntax:text/ctx-unspecified {
  ((i+=${#tail}))
  return 0
}
_BLE_SYNTAX_FCTX[_ble_ctx_UNSPECIFIED]=ble/syntax:text/ctx-unspecified
function ble/syntax:text/initialize-ctx { ctx=$_ble_ctx_UNSPECIFIED; }
function ble/syntax:text/initialize-vars { :; }
_ble_syntax_bash_IFS=$' \t\n'
_ble_syntax_bash_RexSpaces=$'[ \t]+'
_ble_syntax_bash_RexIFSs="[$_ble_syntax_bash_IFS]+"
_ble_syntax_bash_RexDelimiter="[$_ble_syntax_bash_IFS;|&<>()]"
_ble_syntax_bash_RexRedirect='((\{[a-zA-Z_][a-zA-Z_0-9]+\}|[0-9]+)?(&?>>?|>[|&]|<[>&]?|<<[-<]?))[ 	]*'
_ble_syntax_bash_chars=()
_ble_syntax_bashc_seed=
function ble/syntax:bash/cclass/update/reorder {
  eval "local a=\"\${$1}\""
  [[ $a == *']'* ]] && a="]${a//]}"
  [[ $a == *'-'* ]] && a="${a//-}-"
  eval "$1=\$a"
}
function ble/syntax:bash/cclass/update {
  local seed=$_ble_syntax_bash_histc12
  shopt -q extglob && seed=${seed}x
  [[ $seed == "$_ble_syntax_bashc_seed" ]] && return 1
  _ble_syntax_bashc_seed=$seed
  local key modified=
  if [[ $_ble_syntax_bash_histc12 == '!^' ]]; then
    for key in "${!_ble_syntax_bash_charsDef[@]}"; do
      _ble_syntax_bash_chars[key]=${_ble_syntax_bash_charsDef[key]}
    done
    _ble_syntax_bashc_simple=$_ble_syntax_bash_chars_simpleDef
  else
    modified=1
    local histc1=${_ble_syntax_bash_histc12:0:1}
    local histc2=${_ble_syntax_bash_histc12:1:1}
    for key in "${!_ble_syntax_bash_charsFmt[@]}"; do
      local a=${_ble_syntax_bash_charsFmt[key]}
      a=${a//@h/$histc1}
      a=${a//@q/$histc2}
      _ble_syntax_bash_chars[key]=$a
    done
    local a=$_ble_syntax_bash_chars_simpleFmt
    a=${a//@h/$histc1}
    a=${a//@q/$histc2}
    _ble_syntax_bashc_simple=$a
  fi
  if [[ $seed == *x ]]; then
    local extglob='@+!' # *? は既に登録されている筈
    _ble_syntax_bash_chars[_ble_ctx_ARGI]=${_ble_syntax_bash_chars[_ble_ctx_ARGI]}$extglob
    _ble_syntax_bash_chars[_ble_ctx_PATN]=${_ble_syntax_bash_chars[_ble_ctx_PATN]}$extglob
  fi
  if [[ $modified ]]; then
    for key in "${!_ble_syntax_bash_chars[@]}"; do
      ble/syntax:bash/cclass/update/reorder _ble_syntax_bash_chars[key]
    done
    ble/syntax:bash/cclass/update/reorder _ble_syntax_bashc_simple
  fi
  return 0
}
_ble_syntax_bash_charsDef=()
_ble_syntax_bash_charsFmt=()
_ble_syntax_bash_chars_simpleDef=
_ble_syntax_bash_chars_simpleFmt=
function ble/syntax:bash/cclass/initialize {
  local delimiters="$_ble_syntax_bash_IFS;|&()<>"
  local expansions="\$\"\`\\'"
  local glob='[*?'
  local tilde='~:'
  _ble_syntax_bash_charsDef[_ble_ctx_ARGI]="$delimiters$expansions$glob{$tilde^!"
  _ble_syntax_bash_charsDef[_ble_ctx_PATN]="$expansions$glob(|)<>{!" # <> はプロセス置換のため。
  _ble_syntax_bash_charsDef[_ble_ctx_QUOT]="\$\"\`\\!"         # 文字列 "～" で特別な意味を持つのは $ ` \ " のみ。+履歴展開の ! も。
  _ble_syntax_bash_charsDef[_ble_ctx_EXPR]="][}()$expansions!" # ()[] は入れ子を数える為。} は ${var:ofs:len} の為。
  _ble_syntax_bash_charsDef[_ble_ctx_PWORD]="}$expansions!"    # パラメータ展開 ${～}
  _ble_syntax_bash_charsDef[_ble_ctx_RDRH]="$delimiters$expansions"
  _ble_syntax_bash_charsFmt[_ble_ctx_ARGI]="$delimiters$expansions$glob{$tilde@q@h"
  _ble_syntax_bash_charsFmt[_ble_ctx_PATN]="$expansions$glob(|)<>{@h"
  _ble_syntax_bash_charsFmt[_ble_ctx_QUOT]="\$\"\`\\@h"
  _ble_syntax_bash_charsFmt[_ble_ctx_EXPR]="][}()$expansions@h"
  _ble_syntax_bash_charsFmt[_ble_ctx_PWORD]="}$expansions@h"
  _ble_syntax_bash_charsFmt[_ble_ctx_RDRH]=${_ble_syntax_bash_charsDef[_ble_ctx_RDRH]}
  _ble_syntax_bash_chars_simpleDef="$delimiters$expansions^!"
  _ble_syntax_bash_chars_simpleFmt="$delimiters$expansions@q@h"
  _ble_syntax_bash_histc12='!^'
  ble/syntax:bash/cclass/update
}
ble/syntax:bash/cclass/initialize
_ble_syntax_bash_simple_rex_letter=
_ble_syntax_bash_simple_rex_param=
_ble_syntax_bash_simple_rex_bquot=
_ble_syntax_bash_simple_rex_squot=
_ble_syntax_bash_simple_rex_dquot=
_ble_syntax_bash_simple_rex_word=
_ble_syntax_bash_simple_rex_element=
_ble_syntax_bash_simple_rex_open_word=
_ble_syntax_bash_simple_rex_open_dquot=
_ble_syntax_bash_simple_rex_open_squot=
_ble_syntax_bash_simple_rex_incomplete_word1=
_ble_syntax_bash_simple_rex_incomplete_word2=
function ble/syntax:bash/simple-word/update {
  local q="'"
  local letter='[^'${_ble_syntax_bashc_simple}']'
  local param1='\$([-*@#?$!0_]|[1-9][0-9]*|[a-zA-Z_][a-zA-Z_0-9]*)'
  local param2='\$\{(#?[-*@#?$!0]|[#!]?([1-9][0-9]*|[a-zA-Z_][a-zA-Z_0-9]*))\}' # ${!!} ${!$} はエラーになる。履歴展開の所為?
  local param=$param1'|'$param2
  local bquot='\\.'
  local squot=$q'[^'$q']*'$q'|\$'$q'([^'$q'\]|\\.)*'$q
  local dquot='\$?"([^'${_ble_syntax_bash_chars[_ble_ctx_QUOT]}']|\\.|'$param')*"'
  _ble_syntax_bash_simple_rex_letter=$letter # 0 groups
  _ble_syntax_bash_simple_rex_param=$param   # 3 groups
  _ble_syntax_bash_simple_rex_bquot=$bquot   # 0 groups
  _ble_syntax_bash_simple_rex_squot=$squot   # 1 groups
  _ble_syntax_bash_simple_rex_dquot=$dquot   # 4 groups
  _ble_syntax_bash_simple_rex_element='('$bquot'|'$squot'|'$dquot'|'$param'|'$letter')'
  _ble_syntax_bash_simple_rex_word='^'$_ble_syntax_bash_simple_rex_element'+$'
  local open_squot=$q'[^'$q']*|\$'$q'([^'$q'\]|\\.)*'
  local open_dquot='\$?"([^'${_ble_syntax_bash_chars[_ble_ctx_QUOT]}']|\\.|'$param')*'
  _ble_syntax_bash_simple_rex_open_word='^('$_ble_syntax_bash_simple_rex_element'*)(\\|'$open_squot'|'$open_dquot')$'
  _ble_syntax_bash_simple_rex_open_squot=$open_squot
  _ble_syntax_bash_simple_rex_open_dquot=$open_dquot
  local letter1='[^{'${_ble_syntax_bashc_simple}']'
  local letter2='[^'${_ble_syntax_bashc_simple}']'
  _ble_syntax_bash_simple_rex_incomplete_word1='^('$bquot'|'$squot'|'$dquot'|'$param'|'$letter1')+'
  _ble_syntax_bash_simple_rex_incomplete_word2='^(('$bquot'|'$squot'|'$dquot'|'$param'|'$letter2')*)(\\|'$open_squot'|'$open_dquot')?$'
}
ble/syntax:bash/simple-word/update
function ble/syntax:bash/simple-word/is-simple {
  [[ $1 =~ $_ble_syntax_bash_simple_rex_word ]]
}
function ble/syntax:bash/simple-word/is-simple-or-open-simple {
  [[ $1 =~ $_ble_syntax_bash_simple_rex_word || $1 =~ $_ble_syntax_bash_simple_rex_open_word ]]
}
function ble/syntax:bash/simple-word/is-never-word {
  ble/syntax:bash/simple-word/is-simple-or-open-simple && return 1
  local rex=${_ble_syntax_bash_simple_rex_word%'$'}'[ |&;<>()]|^[ |&;<>()]'
  [[ $1 =~ $rex ]]
}
function ble/syntax:bash/simple-word/evaluate-last-brace-expansion {
  local value=$1
  local bquot=$_ble_syntax_bash_simple_rex_bquot
  local squot=$_ble_syntax_bash_simple_rex_squot
  local dquot=$_ble_syntax_bash_simple_rex_dquot
  local param=$_ble_syntax_bash_simple_rex_param
  local letter='[^{,}'${_ble_syntax_bashc_simple}']'
  local symbol='[{,}]'
  local rex_range_expansion='^(([-+]?[0-9]+)\.\.\.[-+]?[0-9]+|([a-zA-Z])\.\.[a-zA-Z])(\.\.[-+]?[0-9]+)?$'
  local rex0='^('$bquot'|'$squot'|'$dquot'|'$param'|'$letter')+'
  local stack; stack=()
  local out= comma= index=0 iopen=0 no_brace_length=0
  while [[ $value ]]; do
    if [[ $value =~ $rex0 ]]; then
      local len=${#BASH_REMATCH}
      ((index+=len,no_brace_length+=len))
      out=$out${value::len}
      value=${value:len}
    elif [[ $value == '{'* ]]; then
      ((iopen=++index,no_brace_length=0))
      value=${value:1}
      ble/array#push stack "$comma:$out"
      out= comma=
    elif ((${#stack[@]})) && [[ $value == '}'* ]]; then
      ((++index))
      value=${value:1}
      ble/array#pop stack
      local out0=${ret#*:} comma0=${ret%%:*}
      if [[ $comma ]]; then
        ((iopen=index,no_brace_length=0))
        out=$out0$out
        comma=$comma0
      elif [[ $out =~ $rex_range_expansion ]]; then
        ((iopen=index,no_brace_length=0))
        out=$out0${2#+}$3
        comma=$comma0
      else
        ((++no_brace_length))
        ble/array#push stack "$comma0:$out0" # cancel pop
        out=$out'}'
      fi
    elif ((${#stack[@]})) && [[ $value == ','* ]]; then
      ((iopen=++index,no_brace_length=0))
      value=${value:1}
      out= comma=1
    else
      ((++index,++no_brace_length))
      out=$out${value::1}
      value=${value:1}
    fi
  done
  while ((${#stack[@]})); do
    ble/array#pop stack
    local out0=${ret#*:} comma0=${ret%%:*}
    out=$out0$out
  done
  ret=$out simple_ibrace=$iopen:$((${#out}-no_brace_length))
}
function ble/syntax:bash/simple-word/reconstruct-incomplete-word {
  local word=$1
  ret= simple_flags= simple_ibrace=0:0
  [[ $word ]] || return 0
  if [[ $word =~ $_ble_syntax_bash_simple_rex_incomplete_word1 ]]; then
    ret=${word::${#BASH_REMATCH}}
    word=${word:${#BASH_REMATCH}}
    [[ $word ]] || return 0
  fi
  if [[ $word =~ $_ble_syntax_bash_simple_rex_incomplete_word2 ]]; then
    local out=$ret
    local m_brace=${BASH_REMATCH[1]}
    local m_quote=${word:${#m_brace}}
    if [[ $m_brace ]]; then
      ble/syntax:bash/simple-word/evaluate-last-brace-expansion "$m_brace"
      simple_ibrace=$((${#out}+${simple_ibrace%:*})):$((${#out}+${simple_ibrace#*:}))
      out=$out$ret
    fi
    if [[ $m_quote ]]; then
      case $m_quote in
      ('$"'*) out=$out$m_quote\" simple_flags=I ;;
      ('"'*)  out=$out$m_quote\" simple_flags=D ;;
      ("$'"*) out=$out$m_quote\' simple_flags=E ;;
      ("'"*)  out=$out$m_quote\' simple_flags=S ;;
      ('\')   simple_flags=B ;;
      (*) return 1 ;;
      esac
    fi
    ret=$out
    return
  fi
  return 1
}
function ble/syntax:bash/simple-word/extract-parameter-names {
  ret=()
  local letter=$_ble_syntax_bash_simple_rex_letter
  local bquot=$_ble_syntax_bash_simple_rex_bquot
  local squot=$_ble_syntax_bash_simple_rex_squot
  local dquot=$_ble_syntax_bash_simple_rex_dquot
  local param=$_ble_syntax_bash_simple_rex_param
  local value=$1
  local rex0='^('$letter'|'$bquot'|'$squot')+'
  local rex1='^('$dquot')'
  local rex2='^('$param')'
  while [[ $value ]]; do
    [[ $value =~ $rex0 ]] && value=${value:${#BASH_REMATCH}}
    if [[ $value =~ $rex1 ]]; then
      value=${value:${#BASH_REMATCH}}
      ble/syntax:bash/simple-word/extract-parameter-names/.process-dquot "$BASH_REMATCH"
    fi
    [[ $value =~ $rex2 ]] || break
    value=${value:${#BASH_REMATCH}}
    local var=${BASH_REMATCH[2]}${BASH_REMATCH[3]}
    [[ $var == [_a-zA-Z]* ]] && ble/array#push ret "$var"
  done
}
function ble/syntax:bash/simple-word/extract-parameter-names/.process-dquot {
  local value=$1
  if [[ $value == '$"'*'"' ]]; then
    value=${value:2:${#value}-3}
  elif [[ $value == '"'*'"' ]]; then
    value=${value:1:${#value}-2}
  else
    return
  fi
  local rex0='^([^'${_ble_syntax_bash_chars[_ble_ctx_QUOT]}']|\\.)+'
  local rex2='^('$param')'
  while [[ $value ]]; do
    [[ $value =~ $rex0 ]] && value=${value:${#BASH_REMATCH}}
    [[ $value =~ $rex2 ]] || break
    value=${value:${#BASH_REMATCH}}
    local var=${BASH_REMATCH[2]}${BASH_REMATCH[3]}
    [[ $var == [_a-zA-Z]* ]] && ble/array#push ret "$var"
  done
}
function ble/syntax:bash/simple-word/eval-noglob/.impl {
  local -a ret
  ble/syntax:bash/simple-word/extract-parameter-names "$1"
  if ((${#ret[@]})); then
    local __ble_defs
    ble/util/assign __ble_defs 'ble/util/print-global-definitions --hidden-only "${ret[@]}"'
    builtin eval -- "$__ble_defs" &>/dev/null # 読み取り専用の変数のこともある
  fi
  builtin eval -- "__ble_ret=$1"
}
function ble/syntax:bash/simple-word/eval-noglob {
  local __ble_ret
  ble/syntax:bash/simple-word/eval-noglob/.impl "$1"
  ret=$__ble_ret
}
function ble/syntax:bash/simple-word/eval/.set-result { __ble_ret=("$@"); }
function ble/syntax:bash/simple-word/eval/.impl {
  local -a ret=()
  ble/syntax:bash/simple-word/extract-parameter-names "$1"
  if ((${#ret[@]})); then
    local __ble_defs
    ble/util/assign __ble_defs 'ble/util/print-global-definitions --hidden-only "${ret[@]}"'
    builtin eval -- "$__ble_defs" &>/dev/null # 読み取り専用の変数のこともある
  fi
  __ble_ret=()
  builtin eval "ble/syntax:bash/simple-word/eval/.set-result $1" &>/dev/null; local ext=$?
  builtin eval : # Note: bash 3.1/3.2 eval バグ対策 (#D1132)
  return "$ext"
}
function ble/syntax:bash/simple-word/eval {
  local __ble_ret
  ble/syntax:bash/simple-word/eval/.impl "$1"; local ext=$?
  ret=("${__ble_ret[@]}")
  return "$ext"
}
function ble/syntax:bash/simple-word/evaluate-path-spec {
  local word=$1 sep=${2:-'/:='}
  spec=() path=()
  local param=$_ble_syntax_bash_simple_rex_param
  local bquot=$_ble_syntax_bash_simple_rex_bquot
  local squot=$_ble_syntax_bash_simple_rex_squot
  local dquot=$_ble_syntax_bash_simple_rex_dquot
  local letter1='[^'$sep$_ble_syntax_bashc_simple']'
  local rex_path_element='('$bquot'|'$squot'|'$dquot'|'$param'|'$letter1')+'
  local rex='^['$sep']?'$rex_path_element
  local tail=$word s= p=
  while [[ $tail =~ $rex ]]; do
    local rematch=$BASH_REMATCH
    ble/syntax:bash/simple-word/eval "$rematch"
    s=$s${tail::${#rematch}}
    p=$p$ret
    tail=${tail:${#rematch}}
    ble/array#push spec "$s"
    ble/array#push path "$p"
  done
  [[ ! $tail ]]
}
function ble/syntax:bash/initialize-ctx {
  ctx=$_ble_ctx_CMDX # _ble_ctx_CMDX が ble/syntax:bash の最初の文脈
}
function ble/syntax:bash/initialize-vars {
  local histc12
  if [[ ${histchars+set} ]]; then
    histc12=${histchars::2}
  else
    histc12='!^'
  fi
  _ble_syntax_bash_histc12=$histc12
  if ble/syntax:bash/cclass/update; then
    ble/syntax:bash/simple-word/update
  fi
  local histstop=$' \t\n='
  shopt -q extglob && histstop="$histstop("
  _ble_syntax_bash_histstop=$histstop
}
function ble/syntax:bash/check-dollar {
  [[ $tail == '$'* ]] || return 1
  local rex
  if [[ $tail == '${'* ]]; then
    if rex='^(\$\{[#!]?)([-*@#?$!0]|[1-9][0-9]*|[a-zA-Z_][a-zA-Z_0-9]*)(\[?)' && [[ $tail =~ $rex ]]; then
      local rematch1=${BASH_REMATCH[1]}
      local rematch2=${BASH_REMATCH[2]}
      local rematch3=${BASH_REMATCH[3]}
      local ntype='${'
      if ((ctx==_ble_ctx_QUOT)); then
        ntype='"${'
      elif ((ctx==_ble_ctx_PWORD||ctx==_ble_ctx_EXPR)); then
        local ntype2; ble/syntax/parse/nest-type -v ntype2
        [[ $ntype2 == '"${' ]] && ntype='"${'
      fi
      ble/syntax/parse/nest-push "$_ble_ctx_PARAM" "$ntype"
      ((_ble_syntax_attr[i]=ctx,
        i+=${#rematch1},
        _ble_syntax_attr[i]=_ble_attr_VAR,
        i+=${#rematch2}))
      if [[ $rematch3 ]]; then
        ble/syntax/parse/nest-push "$_ble_ctx_EXPR" 'v['
        ((_ble_syntax_attr[i]=_ble_ctx_EXPR,
          i+=${#rematch3}))
      fi
      return 0
    else
      ((_ble_syntax_attr[i]=_ble_attr_ERR,i+=2))
      return 0
    fi
  elif [[ $tail == '$(('* ]]; then
    ((_ble_syntax_attr[i]=_ble_ctx_PARAM))
    ble/syntax/parse/nest-push "$_ble_ctx_EXPR" '$(('
    ((i+=3))
    return 0
  elif [[ $tail == '$['* ]]; then
    ((_ble_syntax_attr[i]=_ble_ctx_PARAM))
    ble/syntax/parse/nest-push "$_ble_ctx_EXPR" '$['
    ((i+=2))
    return 0
  elif [[ $tail == '$('* ]]; then
    ((_ble_syntax_attr[i]=_ble_ctx_PARAM))
    ble/syntax/parse/nest-push "$_ble_ctx_CMDX" '$('
    ((i+=2))
    return 0
  elif rex='^\$([-*@#?$!0_]|[1-9][0-9]*|[a-zA-Z_][a-zA-Z_0-9]*)' && [[ $tail =~ $rex ]]; then
    ((_ble_syntax_attr[i]=_ble_ctx_PARAM,
      _ble_syntax_attr[i+1]=_ble_attr_VAR,
      i+=${#BASH_REMATCH}))
    return 0
  else
    ((_ble_syntax_attr[i++]=ctx))
    return 0
  fi
}
function ble/syntax:bash/check-quotes {
  local rex aqdel=$_ble_attr_QDEL aquot=$_ble_ctx_QUOT
  if ((ctx==_ble_ctx_EXPR)); then
    local ntype
    ble/syntax/parse/nest-type -v ntype
    if [[ $ntype == '${' || $ntype == '$[' || $ntype == '$((' || $ntype == 'NQ(' ]]; then
      ((aqdel=_ble_attr_ERR,aquot=_ble_ctx_EXPR))
    elif [[ $ntype == '"${' ]] && ! { [[ $tail == '$'[\'\"]* ]] && shopt -q extquote; }; then
      ((aqdel=_ble_attr_ERR,aquot=_ble_ctx_EXPR))
    fi
  elif ((ctx==_ble_ctx_PWORD)); then
    if [[ $tail == '$'[\'\"]* ]] && ! shopt -q extquote; then
      local ntype
      ble/syntax/parse/nest-type -v ntype
      if [[ $ntype == '"${' ]]; then
        ((aqdel=_ble_ctx_PWORD,aquot=_ble_ctx_PWORD))
      fi
    fi
  fi
  if rex='^`([^`\]|\\(.|$))*(`?)|^'\''[^'\'']*('\''?)' && [[ $tail =~ $rex ]]; then
    ((_ble_syntax_attr[i]=aqdel,
      _ble_syntax_attr[i+1]=aquot,
      i+=${#BASH_REMATCH},
      _ble_syntax_attr[i-1]=${#BASH_REMATCH[3]}||${#BASH_REMATCH[4]}?aqdel:_ble_attr_ERR))
    return 0
  fi
  if ((ctx!=_ble_ctx_QUOT)); then
    if rex='^(\$?")([^'"${_ble_syntax_bash_chars[_ble_ctx_QUOT]}"']|\\.)*("?)' && [[ $tail =~ $rex ]]; then
      local rematch1=${BASH_REMATCH[1]} # for bash-3.1 ${#arr[n]} bug
      if [[ ${BASH_REMATCH[3]} ]]; then
        ((_ble_syntax_attr[i]=aqdel,
          _ble_syntax_attr[i+${#rematch1}]=aquot,
          i+=${#BASH_REMATCH},
          _ble_syntax_attr[i-1]=aqdel))
      else
        ble/syntax/parse/nest-push "$_ble_ctx_QUOT"
        if ((ctx==_ble_ctx_PWORD&&aqdel!=_ble_attr_QDEL)); then
          ((_ble_syntax_attr[i]=aqdel,
            _ble_syntax_attr[i+${#rematch1}-1]=_ble_attr_QDEL,
            _ble_syntax_attr[i+${#rematch1}]=_ble_ctx_QUOT,
            i+=${#BASH_REMATCH}))
        else
          ((_ble_syntax_attr[i]=aqdel,
            _ble_syntax_attr[i+${#rematch1}]=_ble_ctx_QUOT,
            i+=${#BASH_REMATCH}))
        fi
      fi
      return 0
    elif rex='^\$'\''([^'\''\]|\\(.|$))*('\''?)' && [[ $tail =~ $rex ]]; then
      ((_ble_syntax_attr[i]=aqdel,
        _ble_syntax_attr[i+2]=aquot,
        i+=${#BASH_REMATCH},
        _ble_syntax_attr[i-1]=${#BASH_REMATCH[3]}?aqdel:_ble_attr_ERR))
      return 0
    fi
  fi
  return 1
}
function ble/syntax:bash/check-process-subst {
  if [[ $tail == ['<>']'('* ]]; then
    ble/syntax/parse/nest-push "$_ble_ctx_CMDX" '('
    ((_ble_syntax_attr[i]=_ble_attr_DEL,i+=2))
    return 0
  fi
  return 1
}
function ble/syntax:bash/check-comment {
  if shopt -q interactive_comments; then
    if ((wbegin<0||wbegin==i)) && local rex=$'^#[^\n]*' && [[ $tail =~ $rex ]]; then
      ((_ble_syntax_attr[i]=_ble_attr_COMMENT,
        i+=${#BASH_REMATCH}))
      return 0
    fi
  fi
  return 1
}
function ble/syntax:bash/check-glob {
  [[ $tail == ['[?*@+!()|']* ]] || return 1
  local ntype= force_attr=
  if ((ctx==_ble_ctx_VRHS||ctx==_ble_ctx_ARGVR||ctx==_ble_ctx_ARGER||ctx==_ble_ctx_VALR||ctx==_ble_ctx_RDRS)); then
    force_attr=$ctx
    ntype="glob_attr=$force_attr"
  elif ((ctx==_ble_ctx_PATN||ctx==_ble_ctx_BRAX)); then
    ble/syntax/parse/nest-type -v ntype
    local exit_attr=
    if [[ $ntype == glob_attr=* ]]; then
      force_attr=${ntype#*=}
      exit_attr=$force_attr
    elif ((ctx==_ble_ctx_BRAX)); then
      force_attr=$ctx
      ntype="glob_attr=$force_attr"
    elif ((ctx==_ble_ctx_PATN)); then
      if [[ $ntype == glob_nest ]]; then
        exit_attr=$_ble_ctx_PATN
      else
        exit_attr=$_ble_attr_GLOB
      fi
      ntype=
    else
      ntype=
    fi
  elif [[ $1 == assign ]]; then
    ntype='a['
  fi
  if [[ $tail == ['?*@+!']'('* ]] && shopt -q extglob; then
    ble/syntax/parse/nest-push "$_ble_ctx_PATN" "$ntype"
    ((_ble_syntax_attr[i]=${force_attr:-_ble_attr_GLOB},i+=2))
    return 0
  fi
  local histc1=${_ble_syntax_bash_histc12::1}
  [[ $histc1 && $tail == "$histc1"* ]] && return 1
  if [[ $tail == '['* ]]; then
    if ((ctx==_ble_ctx_BRAX)); then
      ((_ble_syntax_attr[i++]=force_attr))
      [[ $tail == '[!'* ]] && ((i++))
      return 0
    fi
    ble/syntax/parse/nest-push "$_ble_ctx_BRAX" "$ntype"
    ((_ble_syntax_attr[i++]=${force_attr:-_ble_attr_GLOB}))
    [[ $tail == '[!'* ]] && ((i++))
    if [[ ${text:i:1} == ']' ]]; then
      ((_ble_syntax_attr[i++]=${force_attr:-_ble_ctx_BRAX}))
    elif [[ ${text:i:1} == '[' ]]; then
      ((_ble_syntax_attr[i++]=${force_attr:-_ble_ctx_BRAX}))
      [[ ${text:i:1} == '!'* ]] && ((i++))
    fi
    return 0
  elif [[ $tail == ['?*']* ]]; then
    ((_ble_syntax_attr[i++]=${force_attr:-_ble_attr_GLOB}))
    return 0
  elif [[ $tail == ['@+!']* ]]; then
    ((_ble_syntax_attr[i++]=${force_attr:-ctx}))
    return 0
  elif ((ctx==_ble_ctx_PATN||ctx==_ble_ctx_BRAX)); then
    if [[ $tail == '('* ]]; then
      ble/syntax/parse/nest-push "$_ble_ctx_PATN" "${ntype:-glob_nest}"
      ((_ble_syntax_attr[i++]=${force_attr:-ctx}))
      return 0
    elif [[ $tail == ')'* ]]; then
      if ((ctx==_ble_ctx_PATN)); then
        ((_ble_syntax_attr[i++]=exit_attr))
        ble/syntax/parse/nest-pop
      else
        ((_ble_syntax_attr[i++]=${force_attr:-ctx}))
      fi
      return 0
    elif [[ $tail == '|'* ]]; then
      ((_ble_syntax_attr[i++]=${force_attr:-_ble_attr_GLOB}))
      return 0
    fi
  fi
  return 1
}
_ble_syntax_bash_histexpand_RexWord=
_ble_syntax_bash_histexpand_RexMods=
_ble_syntax_bash_histexpand_RexEventDef=
_ble_syntax_bash_histexpand_RexQuicksubDef=
_ble_syntax_bash_histexpand_RexEventFmt=
_ble_syntax_bash_histexpand_RexQuicksubFmt=
function ble/syntax:bash/check-history-expansion/.initialize {
  local spaces=$' \t\n' nl=$'\n'
  local rex_event='-?[0-9]+|[!#]|[^-$^*%:'$spaces'=?!#;&|<>()]+|\?[^?'$nl']*\??'
  _ble_syntax_bash_histexpand_RexEventDef='^!('$rex_event')'
  local rex_word1='([0-9]+|[$%^])'
  local rex_wordsA=':('$rex_word1'?-'$rex_word1'?|\*|'$rex_word1'\*?)'
  local rex_wordsB='([$%^]?-'$rex_word1'?|\*|[$^%][*-]?)'
  _ble_syntax_bash_histexpand_RexWord='('$rex_wordsA'|'$rex_wordsB')?'
  local rex_modifier=':[htrepqx]|:[gGa]?&|:[gGa]?s(/([^\/]|\\.)*){0,2}(/|$)'
  _ble_syntax_bash_histexpand_RexMods='('$rex_modifier')*'
  _ble_syntax_bash_histexpand_RexQuicksubDef='\^([^^\]|\\.)*\^([^^\]|\\.)*\^'
  _ble_syntax_bash_histexpand_RexQuicksubFmt='@A([^@C\]|\\.)*@A([^@C\]|\\.)*@A'
  _ble_syntax_bash_histexpand_RexEventFmt='^@A('$rex_event'|@A)'
}
ble/syntax:bash/check-history-expansion/.initialize
function ble/syntax:bash/check-history-expansion/.initialize-event {
  local histc1=${_ble_syntax_bash_histc12::1}
  if [[ $histc1 == '!' ]]; then
    rex_event=$_ble_syntax_bash_histexpand_RexEventDef
  else
    local A="[$histc1]"
    [[ $histc1 == '^' ]] && A='\^'
    rex_event=$_ble_syntax_bash_histexpand_RexEventFmt
    rex_event=${rex_event//@A/$A}
  fi
}
function ble/syntax:bash/check-history-expansion/.initialize-quicksub {
  local histc2=${_ble_syntax_bash_histc12:1:1}
  if [[ $histc2 == '^' ]]; then
    rex_quicksub=$_ble_syntax_bash_histexpand_RexQuicksubDef
  else
    rex_quicksub=$_ble_syntax_bash_histexpand_RexQuicksubFmt
    rex_quicksub=${rex_quicksub//@A/[$histc2]}
    rex_quicksub=${rex_quicksub//@C/$histc2}
  fi
}
function ble/syntax:bash/check-history-expansion/.check-modifiers {
  [[ ${text:i} =~ $_ble_syntax_bash_histexpand_RexMods ]] &&
    ((i+=${#BASH_REMATCH}))
  if local rex='^:[gGa]?s(.)'; [[ ${text:i} =~ $rex ]]; then
    local del=${BASH_REMATCH[1]}
    local A="[$del]" B="[^$del]"
    [[ $del == '^' || $del == ']' ]] && A='\'$del
    [[ $del != '\' ]] && B=$B'|\\.'
    local rex_substitute='^:[gGa]?s('$A'('$B')*){0,2}('$A'|$)'
    if [[ ${text:i} =~ $rex_substitute ]]; then
      ((i+=${#BASH_REMATCH}))
      ble/syntax:bash/check-history-expansion/.check-modifiers
      return
    fi
  fi
  if [[ ${text:i} == ':'[gGa]* ]]; then
    ((_ble_syntax_attr[i+1]=_ble_attr_ERR,i+=2))
  elif [[ ${text:i} == ':'* ]]; then
    ((_ble_syntax_attr[i]=_ble_attr_ERR,i++))
  fi
}
function ble/syntax:bash/check-history-expansion {
  [[ -o histexpand ]] || return 1
  local histc1=${_ble_syntax_bash_histc12:0:1}
  local histc2=${_ble_syntax_bash_histc12:1:1}
  if [[ $histc1 && $tail == "$histc1"[^"$_ble_syntax_bash_histstop"]* ]]; then
    if ((ctx==_ble_ctx_QUOT)); then
      local tail=${tail%%'"'*}
      [[ $tail == '!' ]] && return 1
    fi
    ((_ble_syntax_attr[i]=_ble_attr_HISTX))
    local rex_event
    ble/syntax:bash/check-history-expansion/.initialize-event
    if [[ $tail =~ $rex_event ]]; then
      ((i+=${#BASH_REMATCH}))
    elif [[ $tail == "$histc1"['-:0-9^$%*']* ]]; then
      ((_ble_syntax_attr[i]=_ble_attr_HISTX,i++))
    else
      ((_ble_syntax_attr[i+1]=_ble_attr_ERR,i+=2))
      return 0
    fi
    [[ ${text:i} =~ $_ble_syntax_bash_histexpand_RexWord ]] &&
      ((i+=${#BASH_REMATCH}))
    ble/syntax:bash/check-history-expansion/.check-modifiers
    return 0
  elif ((i==0)) && [[ $histc2 && $tail == "$histc2"* ]]; then
    ((_ble_syntax_attr[i]=_ble_attr_HISTX))
    local rex_quicksub
    ble/syntax:bash/check-history-expansion/.initialize-quicksub
    if [[ $tail =~ $rex_quicksub ]]; then
      ((i+=${#BASH_REMATCH}))
      ble/syntax:bash/check-history-expansion/.check-modifiers
      return 0
    else
      ((i+=${#tail}))
      return 0
    fi
  fi
  return 1
}
function ble/syntax:bash/starts-with-histchars {
  [[ $_ble_syntax_bash_histc12 && $tail == ["$_ble_syntax_bash_histc12"]* ]]
}
_BLE_SYNTAX_FCTX[_ble_ctx_QUOT]=ble/syntax:bash/ctx-quot
function ble/syntax:bash/ctx-quot {
  local rex
  if rex='^([^'"${_ble_syntax_bash_chars[_ble_ctx_QUOT]}"']|\\.)+' && [[ $tail =~ $rex ]]; then
    ((_ble_syntax_attr[i]=ctx,
      i+=${#BASH_REMATCH}))
    return 0
  elif [[ $tail == '"'* ]]; then
    ((_ble_syntax_attr[i]=_ble_attr_QDEL,
      i+=1))
    ble/syntax/parse/nest-pop
    return 0
  elif ble/syntax:bash/check-quotes; then
    return 0
  elif ble/syntax:bash/check-dollar; then
    return 0
  elif ble/syntax:bash/starts-with-histchars; then
    ble/syntax:bash/check-history-expansion ||
      ((_ble_syntax_attr[i]=ctx,i++))
    return 0
  fi
  return 1
}
_BLE_SYNTAX_FCTX[_ble_ctx_CASE]=ble/syntax:bash/ctx-case
function ble/syntax:bash/ctx-case {
  if [[ $tail =~ ^$_ble_syntax_bash_RexIFSs ]]; then
    ((_ble_syntax_attr[i]=ctx,
      i+=${#BASH_REMATCH}))
    return 0
  elif [[ $tail == '('* ]]; then
    ((ctx=_ble_ctx_CMDX))
    ble/syntax/parse/nest-push "$_ble_ctx_PATN"
    ((_ble_syntax_attr[i++]=_ble_attr_GLOB))
    return 0
  elif [[ $tail == 'esac'$_ble_syntax_bash_RexDelimiter* || $tail == 'esac' ]]; then
    ((ctx=_ble_ctx_CMDX))
    ble/syntax:bash/ctx-command
  else
    ((ctx=_ble_ctx_CMDX))
    ble/syntax/parse/nest-push "$_ble_ctx_PATN"
    ble/syntax:bash/ctx-globpat
  fi
}
_BLE_SYNTAX_FCTX[_ble_ctx_PATN]=ble/syntax:bash/ctx-globpat
function ble/syntax:bash/ctx-globpat {
  local rex
  if rex='^([^'${_ble_syntax_bash_chars[_ble_ctx_PATN]}']|\\.)+' && [[ $tail =~ $rex ]]; then
    ((_ble_syntax_attr[i]=ctx,
      i+=${#BASH_REMATCH}))
    return 0
  elif ble/syntax:bash/check-process-subst; then
    return 0
  elif [[ $tail == ['<>']* ]]; then
    ((_ble_syntax_attr[i++]=ctx))
    return 0
  elif ble/syntax:bash/check-quotes; then
    return 0
  elif ble/syntax:bash/check-dollar; then
    return 0
  elif ble/syntax:bash/check-glob; then
    return 0
  elif ble/syntax:bash/check-brace-expansion; then
    return 0
  elif ble/syntax:bash/starts-with-histchars; then
    ble/syntax:bash/check-history-expansion ||
      ((_ble_syntax_attr[i]=ctx,i++))
    return 0
  fi
  return 1
}
_BLE_SYNTAX_FCTX[_ble_ctx_BRAX]=ble/syntax:bash/ctx-bracket-expression
_BLE_SYNTAX_FEND[_ble_ctx_BRAX]=ble/syntax:bash/ctx-bracket-expression.end
function ble/syntax:bash/ctx-bracket-expression {
  local nctx; ble/syntax/parse/nest-ctx
  if ((nctx==_ble_ctx_PATN)); then
    local chars=${_ble_syntax_bash_chars[_ble_ctx_PATN]}
  else
    local chars=${_ble_syntax_bash_chars[_ble_ctx_ARGI]//'~'}
  fi
  chars="]${chars#']'}"
  local ntype; ble/syntax/parse/nest-type -v ntype
  local force_attr=; [[ $ntype == glob_attr=* ]] && force_attr=${ntype#*=}
  local rex
  if [[ $tail == ']'* ]]; then
    ((_ble_syntax_attr[i++]=${force_attr:-_ble_attr_GLOB}))
    ble/syntax/parse/nest-pop
    if [[ $ntype == 'a[' ]]; then
      local is_assign=
      if [[ $tail == ']='* ]]; then
        ((_ble_syntax_attr[i++]=ctx,is_assign=1))
      elif [[ $tail == ']+'* ]]; then
        ble/syntax/parse/set-lookahead 2
        [[ $tail == ']+=' ]] && ((_ble_syntax_attr[i]=ctx,i+=2,is_assign=1))
      fi
      if [[ $is_assign ]]; then
        ble/util/assert '[[ ${_ble_syntax_bash_command_CtxAssign[ctx]} ]]'
        ((ctx=_ble_syntax_bash_command_CtxAssign[ctx]))
        if local tail=${text:i}; [[ $tail == '~'* ]]; then
          ble/syntax:bash/check-tilde-expansion rhs
        fi
      fi
    fi
    return 0
  elif rex='^([^'$chars']|\\.)+' && [[ $tail =~ $rex ]]; then
    ((_ble_syntax_attr[i]=${force_attr:-ctx},
      i+=${#BASH_REMATCH}))
    return 0
  elif ble/syntax:bash/check-process-subst; then
    return 0
  elif ble/syntax:bash/check-quotes; then
    return 0
  elif ble/syntax:bash/check-dollar; then
    return 0
  elif ble/syntax:bash/check-glob; then
    return 0
  elif ble/syntax:bash/check-brace-expansion; then
    return 0
  elif ble/syntax:bash/check-tilde-expansion; then
    return 0
  elif ble/syntax:bash/starts-with-histchars; then
    ble/syntax:bash/check-history-expansion ||
      ((_ble_syntax_attr[i++]=${force_attr:-ctx}))
    return 0
  elif ((nctx==_ble_ctx_PATN)) && [[ $tail == ['<>']* ]]; then
    ((_ble_syntax_attr[i++]=${force_attr:-ctx}))
    return 0
  fi
  return 1
}
function ble/syntax:bash/ctx-bracket-expression.end {
  local is_end=
  local nctx; ble/syntax/parse/nest-ctx
  if ((nctx==_ble_ctx_PATN)); then
    local tail=${text:i}
    [[ ! $tail || $tail == ')'* ]] && is_end=1
  else
    ble/syntax:bash/check-word-end/is-delimiter && is_end=1
    [[ $tail == ':'* && ${_ble_syntax_bash_command_IsAssign[ctx]} ]] && is_end=1
  fi
  if [[ $is_end ]]; then
    ble/syntax/parse/nest-pop
    ble/syntax/parse/check-end
    return
  fi
  return 0
}
_BLE_SYNTAX_FCTX[_ble_ctx_PARAM]=ble/syntax:bash/ctx-param
_BLE_SYNTAX_FCTX[_ble_ctx_PWORD]=ble/syntax:bash/ctx-pword
function ble/syntax:bash/ctx-param {
  if [[ $tail == :[!-?=+]* ]]; then
    ((_ble_syntax_attr[i]=_ble_ctx_EXPR,
      ctx=_ble_ctx_EXPR,i++))
    return 0
  elif [[ $tail == '}'* ]]; then
    ((_ble_syntax_attr[i]=_ble_syntax_attr[inest]))
    ((i+=1))
    ble/syntax/parse/nest-pop
    return 0
  else
    ((ctx=_ble_ctx_PWORD))
    ble/syntax:bash/ctx-pword
    return
  fi
}
function ble/syntax:bash/ctx-pword {
  local rex
  if rex='^([^'"${_ble_syntax_bash_chars[ctx]}"']|\\.)+' && [[ $tail =~ $rex ]]; then
    ((_ble_syntax_attr[i]=ctx,
      i+=${#BASH_REMATCH}))
    return 0
  elif [[ $tail == '}'* ]]; then
    ((_ble_syntax_attr[i]=_ble_syntax_attr[inest]))
    ((i+=1))
    ble/syntax/parse/nest-pop
    return 0
  elif ble/syntax:bash/check-quotes; then
    return 0
  elif ble/syntax:bash/check-dollar; then
    return 0
  elif ble/syntax:bash/starts-with-histchars; then
    ble/syntax:bash/check-history-expansion ||
      ((_ble_syntax_attr[i]=ctx,i++))
    return 0
  fi
  return 1
}
_BLE_SYNTAX_FCTX[_ble_ctx_EXPR]=ble/syntax:bash/ctx-expr
function ble/syntax:bash/ctx-expr/.count-paren {
  if [[ $char == ')' ]]; then
    if [[ $ntype == '((' || $ntype == '$((' ]]; then
      if [[ $tail == '))'* ]]; then
        ((_ble_syntax_attr[i]=_ble_syntax_attr[inest]))
        ((i+=2))
        ble/syntax/parse/nest-pop
      else
        ((ctx=_ble_ctx_ARGX0,
          _ble_syntax_attr[i++]=_ble_syntax_attr[inest]))
      fi
      return 0
    elif [[ $ntype == '(' || $ntype == 'NQ(' ]]; then
      ((_ble_syntax_attr[i++]=ctx))
      ble/syntax/parse/nest-pop
      return 0
    fi
  elif [[ $char == '(' ]]; then
    local ntype2='('
    [[ $ntype == '$((' || $ntype == 'NQ(' ]] && ntype2='NQ('
    ble/syntax/parse/nest-push "$_ble_ctx_EXPR" "$ntype2"
    ((_ble_syntax_attr[i++]=ctx))
    return 0
  fi
  return 1
}
function ble/syntax:bash/ctx-expr/.count-bracket {
  if [[ $char == ']' ]]; then
    if [[ $ntype == '[' || $ntype == '$[' ]]; then
      ((_ble_syntax_attr[i]=_ble_syntax_attr[inest]))
      ((i++))
      ble/syntax/parse/nest-pop
      return 0
    elif [[ $ntype == [ad]'[' ]]; then
      ((_ble_syntax_attr[i++]=_ble_ctx_EXPR))
      ble/syntax/parse/nest-pop
      if [[ $tail == ']='* ]]; then
        ((i++))
        tail=${text:i} ble/syntax:bash/check-tilde-expansion rhs
      elif ((_ble_bash>=30100)) && [[ $tail == ']+'* ]]; then
        ble/syntax/parse/set-lookahead 2
        if [[ $tail == ']+='* ]]; then
          ((i+=2))
          tail=${text:i} ble/syntax:bash/check-tilde-expansion rhs
        fi
      else
        if [[ $ntype == 'a[' ]]; then
          if ((ctx==_ble_ctx_VRHS)); then
            ((ctx=_ble_ctx_CMDI,wtype=_ble_ctx_CMDI))
          elif ((ctx==_ble_ctx_ARGVR)); then
            ((ctx=_ble_ctx_ARGVI,wtype=_ble_ctx_ARGVI))
          elif ((ctx==_ble_ctx_ARGER)); then
            ((ctx=_ble_ctx_ARGEI,wtype=_ble_ctx_ARGEI))
          fi
        else # ntype == 'd['
          ((ctx=_ble_ctx_VALI,wtype=_ble_ctx_VALI))
        fi
      fi
      return 0
    elif [[ $ntype == 'v[' ]]; then
      ((_ble_syntax_attr[i++]=_ble_ctx_EXPR))
      ble/syntax/parse/nest-pop
      return 0
    fi
  elif [[ $char == '[' ]]; then
    ble/syntax/parse/nest-push "$_ble_ctx_EXPR" '['
    ((_ble_syntax_attr[i++]=ctx))
    return 0
  fi
  return 1
}
function ble/syntax:bash/ctx-expr/.count-brace {
  if [[ $char == '}' ]]; then
    ((_ble_syntax_attr[i]=_ble_syntax_attr[inest]))
    ((i++))
    ble/syntax/parse/nest-pop
    return 0
  fi
  return 1
}
function ble/syntax:bash/ctx-expr {
  local rex
  if rex='^([^'"${_ble_syntax_bash_chars[ctx]}"']|\\.)+' && [[ $tail =~ $rex ]]; then
    ((_ble_syntax_attr[i]=ctx,
      i+=${#BASH_REMATCH}))
    return 0
  elif [[ $tail == ['][()}']* ]]; then
    local char=${tail::1} ntype
    ble/syntax/parse/nest-type -v ntype
    if [[ $ntype == *'(' ]]; then
      ble/syntax:bash/ctx-expr/.count-paren && return
    elif [[ $ntype == *'[' ]]; then
      ble/syntax:bash/ctx-expr/.count-bracket && return
    elif [[ $ntype == '${' || $ntype == '"${' ]]; then
      ble/syntax:bash/ctx-expr/.count-brace && return
    else
      ble/util/stackdump "unexpected ntype=$ntype for arithmetic expression"
    fi
    ((_ble_syntax_attr[i++]=ctx))
    return 0
  elif ble/syntax:bash/check-quotes; then
    return 0
  elif ble/syntax:bash/check-dollar; then
    return 0
  elif ble/syntax:bash/starts-with-histchars; then
    ble/syntax:bash/check-history-expansion ||
      ((_ble_syntax_attr[i]=ctx,i++))
    return 0
  fi
  return 1
}
function ble/syntax:bash/check-brace-expansion {
  [[ $tail == '{'* ]] || return 1
  local rex='^\{[-+0-9a-zA-Z.]*(\}?)'
  [[ $tail =~ $rex ]]
  local str=$BASH_REMATCH
  local force_attr= inactive=
  if [[ $- != *B* ]]; then
    inactive=1
  elif ((ctx==_ble_ctx_CONDI||ctx==_ble_ctx_CONDQ||ctx==_ble_ctx_RDRS||ctx==_ble_ctx_VRHS)); then
    inactive=1
  elif ((ctx==_ble_ctx_PATN||ctx==_ble_ctx_BRAX)); then
    local ntype; ble/syntax/parse/nest-type -v ntype
    if [[ $ntype == glob_attr=* ]]; then
      force_attr=${ntype#*=}
      (((force_attr==_ble_ctx_RDRS||force_attr==_ble_ctx_VRHS||force_attr==_ble_ctx_ARGVR||force_attr==_ble_ctx_ARGER||force_attr==_ble_ctx_VALR)&&(inactive=1)))
    elif ((ctx==_ble_ctx_BRAX)); then
      local nctx; ble/syntax/parse/nest-ctx
      (((nctx==_ble_ctx_CONDI||octx==_ble_ctx_CONDQ)&&(inactive=1)))
    fi
  elif ((ctx==_ble_ctx_BRACE1||ctx==_ble_ctx_BRACE2)); then
    local ntype; ble/syntax/parse/nest-type -v ntype
    if [[ $ntype == glob_attr=* ]]; then
      force_attr=${ntype#*=}
    fi
  fi
  if [[ $inactive ]]; then
    ((_ble_syntax_attr[i]=${force_attr:-ctx},i+=${#str}))
    return 0
  fi
  [[ ${_ble_syntax_bash_command_IsAssign[ctx]} ]] &&
    ctx=${_ble_syntax_bash_command_IsAssign[ctx]}
  if rex='^\{(([-+]?[0-9]+)\.\.[-+]?[0-9]+|[a-zA-Z]\.\.[a-zA-Z])(\.\.[-+]?[0-9]+)?\}$'; [[ $str =~ $rex ]]; then
    if [[ $force_attr ]]; then
      ((_ble_syntax_attr[i]=force_attr,i+=${#str}))
    else
      local rematch1=${BASH_REMATCH[1]}
      local rematch2=${BASH_REMATCH[2]}
      local rematch3=${BASH_REMATCH[3]}
      local len2=${#rematch2}; ((len2||(len2=1)))
      local attr=$_ble_attr_BRACE
      if ((ctx==_ble_ctx_RDRF||ctx==_ble_ctx_RDRD)); then
        local lhs=${rematch1::len2} rhs=${rematch1:len2+2}
        if [[ $rematch2 ]]; then
          local lhs1=$((10#${lhs#[-+]})); [[ $lhs == -* ]] && ((lhs1=-lhs1))
          local rhs1=$((10#${rhs#[-+]})); [[ $rhs == -* ]] && ((rhs1=-rhs1))
          lhs=$lhs1 rhs=$rhs1
        fi
        [[ $lhs != "$rhs" ]] && ((attr=_ble_attr_ERR))
      fi
      ((_ble_syntax_attr[i++]=attr))
      ((_ble_syntax_attr[i]=ctx,i+=len2,
        _ble_syntax_attr[i]=_ble_attr_BRACE,i+=2,
        _ble_syntax_attr[i]=ctx,i+=${#rematch1}-len2-2))
      if [[ $rematch3 ]]; then
        ((_ble_syntax_attr[i]=_ble_attr_BRACE,i+=2,
          _ble_syntax_attr[i]=ctx,i+=${#rematch3}-2))
      fi
      ((_ble_syntax_attr[i++]=attr))
    fi
    return 0
  fi
  local ntype=
  ((ctx==_ble_ctx_RDRF||ctx==_ble_ctx_RDRD)) && force_attr=$ctx
  [[ $force_attr ]] && ntype="glob_attr=$force_attr"
  ble/syntax/parse/nest-push "$_ble_ctx_BRACE1" "$ntype"
  local len=$((${#str}-1))
  ((_ble_syntax_attr[i++]=${force_attr:-_ble_attr_BRACE},
    len&&(_ble_syntax_attr[i]=${force_attr:-ctx},i+=len)))
  return 0
}
_BLE_SYNTAX_FCTX[_ble_ctx_BRACE1]=ble/syntax:bash/ctx-brace-expansion
_BLE_SYNTAX_FCTX[_ble_ctx_BRACE2]=ble/syntax:bash/ctx-brace-expansion
_BLE_SYNTAX_FEND[_ble_ctx_BRACE1]=ble/syntax:bash/ctx-brace-expansion.end
_BLE_SYNTAX_FEND[_ble_ctx_BRACE2]=ble/syntax:bash/ctx-brace-expansion.end
function ble/syntax:bash/ctx-brace-expansion {
  if [[ $tail == '}'* ]] && ((ctx==_ble_ctx_BRACE2)); then
    local force_attr=
    local ntype; ble/syntax/parse/nest-type -v ntype
    [[ $ntype == glob_attr=* ]] && force_attr=$_ble_attr_ERR # ※${ntype#*=} ではなくエラー
    ((_ble_syntax_attr[i++]=${force_attr:-_ble_attr_BRACE}))
    ble/syntax/parse/nest-pop
    return 0
  elif [[ $tail == ','* ]]; then
    local force_attr=
    local ntype; ble/syntax/parse/nest-type -v ntype
    [[ $ntype == glob_attr=* ]] && force_attr=${ntype#*=}
    ((_ble_syntax_attr[i++]=${force_attr:-_ble_attr_BRACE}))
    ((ctx=_ble_ctx_BRACE2))
    return 0
  fi
  local chars=",${_ble_syntax_bash_chars[_ble_ctx_ARGI]//'~:'}"
  ((ctx==_ble_ctx_BRACE2)) && chars="}$chars"
  ble/syntax:bash/cclass/update/reorder chars
  if local rex='^([^'$chars']|\\.)+'; [[ $tail =~ $rex ]]; then
    ((_ble_syntax_attr[i]=ctx,
      i+=${#BASH_REMATCH}))
    return 0
  elif ble/syntax:bash/check-process-subst; then
    return 0
  elif ble/syntax:bash/check-quotes; then
    return 0
  elif ble/syntax:bash/check-dollar; then
    return 0
  elif ble/syntax:bash/check-glob; then
    return 0
  elif ble/syntax:bash/check-brace-expansion; then
    return 0
  elif ble/syntax:bash/starts-with-histchars; then
    ble/syntax:bash/check-history-expansion ||
      ((_ble_syntax_attr[i++]=ctx))
    return 0
  fi
  return 1
}
function ble/syntax:bash/ctx-brace-expansion.end {
  if ((i==${#text})) || ble/syntax:bash/check-word-end/is-delimiter; then
    ble/syntax/parse/nest-pop
    ble/syntax/parse/check-end
    return
  fi
  return 0
}
function ble/syntax:bash/check-tilde-expansion {
  [[ $tail == ['~:']* ]] || return 1
  local tilde_enabled=$((i==wbegin))
  [[ $1 == rhs ]] && tilde_enabled=1
  if [[ $tail == ':'* ]]; then
    _ble_syntax_attr[i++]=$ctx
    if ! ((tilde_enabled=_ble_syntax_bash_command_IsAssign[ctx])); then
      if ((ctx==_ble_ctx_BRAX)); then
        local nctx; ble/syntax/parse/nest-ctx
        ((tilde_enabled=_ble_syntax_bash_command_IsAssign[nctx]))
      fi
    fi
    local tail=${text:i}
    [[ $tail == '~'* ]] || return 0
  fi
  if ((tilde_enabled)); then
    local chars="${_ble_syntax_bash_chars[_ble_ctx_ARGI]}/:"
    ble/syntax:bash/cclass/update/reorder chars
    local delimiters="$_ble_syntax_bash_IFS;|&()<>"
    local rex='^(~[^'$chars']*)([^'$delimiters'/:]?)'; [[ $tail =~ $rex ]]
    local str=${BASH_REMATCH[1]}
    local path attr=$ctx
    eval "path=$str"
    if [[ ! ${BASH_REMATCH[2]} && $path != "$str" ]]; then
      ((attr=_ble_attr_TILDE))
      if ((ctx==_ble_ctx_BRAX)); then
        ble/util/assert 'ble/util/unlocal tail; [[ $tail == ":~"* ]]'
        ble/syntax/parse/nest-pop
      fi
    fi
    ((_ble_syntax_attr[i]=attr,i+=${#str}))
  else
    local chars=${_ble_syntax_bash_chars[_ble_ctx_ARGI]}
    local rex='^~([^'$chars']|\\.)*'; [[ $tail =~ $rex ]]
    ((_ble_syntax_attr[i]=ctx,i+=${#BASH_REMATCH}))
  fi
  return 0
}
_ble_syntax_bash_command_CtxAssign[_ble_ctx_CMDI]=$_ble_ctx_VRHS
_ble_syntax_bash_command_CtxAssign[_ble_ctx_ARGVI]=$_ble_ctx_ARGVR
_ble_syntax_bash_command_CtxAssign[_ble_ctx_ARGEI]=$_ble_ctx_ARGER
_ble_syntax_bash_command_CtxAssign[_ble_ctx_ARGI]=$_ble_ctx_ARGQ
_ble_syntax_bash_command_CtxAssign[_ble_ctx_FARGI3]=$_ble_ctx_FARGQ3
_ble_syntax_bash_command_CtxAssign[_ble_ctx_CARGI1]=$_ble_ctx_CARGQ1
_ble_syntax_bash_command_CtxAssign[_ble_ctx_VALI]=$_ble_ctx_VALQ
_ble_syntax_bash_command_CtxAssign[_ble_ctx_CONDI]=$_ble_ctx_CONDQ
_ble_syntax_bash_command_IsAssign[_ble_ctx_VRHS]=$_ble_ctx_CMDI
_ble_syntax_bash_command_IsAssign[_ble_ctx_ARGVR]=$_ble_ctx_ARGVI
_ble_syntax_bash_command_IsAssign[_ble_ctx_ARGER]=$_ble_ctx_ARGEI
_ble_syntax_bash_command_IsAssign[_ble_ctx_ARGQ]=$_ble_ctx_ARGI
_ble_syntax_bash_command_IsAssign[_ble_ctx_FARGQ3]=$_ble_ctx_FARGI3
_ble_syntax_bash_command_IsAssign[_ble_ctx_CARGQ1]=$_ble_ctx_CARGI1
_ble_syntax_bash_command_IsAssign[_ble_ctx_VALR]=$_ble_ctx_VALI
_ble_syntax_bash_command_IsAssign[_ble_ctx_VALQ]=$_ble_ctx_VALI
_ble_syntax_bash_command_IsAssign[_ble_ctx_CONDQ]=$_ble_ctx_CONDI
function ble/syntax:bash/check-variable-assignment {
  ((wbegin==i)) || return 1
  if ((ctx==_ble_ctx_VALI)) && [[ $tail == '['* ]]; then
    ((ctx=_ble_ctx_VALR))
    ble/syntax/parse/nest-push "$_ble_ctx_EXPR" 'd['
    ((_ble_syntax_attr[i++]=ctx))
    return 0
  fi
  [[ ${_ble_syntax_bash_command_CtxAssign[ctx]} ]] || return 1
  local suffix='=|\+=?'
  ((_ble_bash<30100)) && suffix='='
  if ((ctx==_ble_ctx_ARGVI||ctx==_ble_ctx_ARGEI)); then
    suffix="$suffix|\[?"
  else
    suffix="$suffix|\["
  fi
  local rex_assign="^[a-zA-Z_][a-zA-Z_0-9]*($suffix)"
  [[ $tail =~ $rex_assign ]] || return 1
  local rematch1=${BASH_REMATCH[1]} # for bash-3.1 ${#arr[n]} bug
  if [[ $rematch1 == '+' ]]; then
    ble/syntax/parse/set-lookahead $((${#BASH_REMATCH}+1))
    return 1
  fi
  local variable_assign=
  if ((ctx==_ble_ctx_CMDI||ctx==_ble_ctx_ARGVI||ctx==_ble_ctx_ARGEI&&${#rematch1})); then
    ((wtype=_ble_attr_VAR,
      _ble_syntax_attr[i]=_ble_attr_VAR,
      i+=${#BASH_REMATCH},
      ${#rematch1}&&(_ble_syntax_attr[i-${#rematch1}]=_ble_ctx_EXPR),
      variable_assign=1,
      ctx=_ble_syntax_bash_command_CtxAssign[ctx]))
  else
    ((_ble_syntax_attr[i]=ctx,
      i+=${#BASH_REMATCH}))
  fi
  if [[ $rematch1 == '[' ]]; then
    if [[ $variable_assign ]]; then
      i=$((i-1)) ble/syntax/parse/nest-push "$_ble_ctx_EXPR" 'a['
    else
      ((i--))
      tail=${text:i} ble/syntax:bash/check-glob assign
    fi
  elif [[ $rematch1 == *'=' ]]; then
    if [[ $variable_assign && ${text:i} == '('* ]]; then
      ble/syntax:bash/ctx-values/enter
      ((_ble_syntax_attr[i++]=_ble_attr_DEL))
    else
      [[ $variable_assign ]] || ((ctx=_ble_syntax_bash_command_CtxAssign[ctx]))
      if local tail=${text:i}; [[ $tail == '~'* ]]; then
        ble/syntax:bash/check-tilde-expansion rhs
      fi
    fi
  fi
  return 0
}
_BLE_SYNTAX_FCTX[_ble_ctx_ARGX]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_ARGX0]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_CMDX]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_CMDX1]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_CMDXT]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_CMDXC]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_CMDXE]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_CMDXD]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_CMDXD0]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_CMDXV]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_ARGI]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_ARGQ]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_CMDI]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_VRHS]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_ARGVR]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_ARGER]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FEND[_ble_ctx_CMDI]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FEND[_ble_ctx_ARGI]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FEND[_ble_ctx_ARGQ]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FEND[_ble_ctx_VRHS]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FEND[_ble_ctx_ARGVR]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FEND[_ble_ctx_ARGER]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FCTX[_ble_ctx_ARGVX]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_ARGVI]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FEND[_ble_ctx_ARGVI]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FCTX[_ble_ctx_ARGEX]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_ARGEI]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FEND[_ble_ctx_ARGEI]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FCTX[_ble_ctx_SARGX1]=ble/syntax:bash/ctx-command-compound-expect
_BLE_SYNTAX_FCTX[_ble_ctx_FARGX1]=ble/syntax:bash/ctx-command-compound-expect
_BLE_SYNTAX_FCTX[_ble_ctx_FARGX2]=ble/syntax:bash/ctx-command-compound-expect
_BLE_SYNTAX_FCTX[_ble_ctx_FARGX3]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_FARGI1]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_FARGI2]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_FARGI3]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_FARGQ3]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FEND[_ble_ctx_FARGI1]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FEND[_ble_ctx_FARGI2]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FEND[_ble_ctx_FARGI3]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FEND[_ble_ctx_FARGQ3]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FCTX[_ble_ctx_CARGX1]=ble/syntax:bash/ctx-command-compound-expect
_BLE_SYNTAX_FCTX[_ble_ctx_CARGX2]=ble/syntax:bash/ctx-command-compound-expect
_BLE_SYNTAX_FCTX[_ble_ctx_CARGI1]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_CARGQ1]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_CARGI2]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FEND[_ble_ctx_CARGI1]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FEND[_ble_ctx_CARGQ1]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FEND[_ble_ctx_CARGI2]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FCTX[_ble_ctx_TARGX1]=ble/syntax:bash/ctx-command-time-expect
_BLE_SYNTAX_FCTX[_ble_ctx_TARGX2]=ble/syntax:bash/ctx-command-time-expect
_BLE_SYNTAX_FCTX[_ble_ctx_TARGI1]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FCTX[_ble_ctx_TARGI2]=ble/syntax:bash/ctx-command
_BLE_SYNTAX_FEND[_ble_ctx_TARGI1]=ble/syntax:bash/ctx-command/check-word-end
_BLE_SYNTAX_FEND[_ble_ctx_TARGI2]=ble/syntax:bash/ctx-command/check-word-end
function ble/syntax:bash/starts-with-delimiter-or-redirect {
  local delimiters=$_ble_syntax_bash_RexDelimiter
  local redirect=$_ble_syntax_bash_RexRedirect
  [[ ( $tail =~ ^$delimiters || $wbegin -lt 0 && $tail =~ ^$redirect ) && $tail != ['<>']'('* ]]
}
function ble/syntax:bash/starts-with-delimiter {
  [[ $tail == ["$_ble_syntax_bash_IFS;|&<>()"]* && $tail != ['<>']'('* ]]
}
function ble/syntax:bash/check-word-end/is-delimiter {
  local tail=${text:i}
  if [[ $tail == [!"$_ble_syntax_bash_IFS;|&<>()"]* ]]; then
    return 1
  elif [[ $tail == ['<>']* ]]; then
    ble/syntax/parse/set-lookahead 2
    [[ $tail == ['<>']'('* ]] && return 1
  fi
  return 0
}
function ble/syntax:bash/check-here-document-from {
  local spaces=$1
  [[ $nparam && $spaces == *$'\n'* ]] || return 1
  local rex="$_ble_term_fs@([RI][QH][^$_ble_term_fs]*)(.*$)" && [[ $nparam =~ $rex ]] || return 1
  local rematch1=${BASH_REMATCH[1]}
  local rematch2=${BASH_REMATCH[2]}
  local padding=${spaces%%$'\n'*}
  ((_ble_syntax_attr[i]=ctx,i+=${#padding}))
  nparam=${nparam::${#nparam}-${#BASH_REMATCH}}${nparam:${#nparam}-${#rematch2}}
  ble/syntax/parse/nest-push "$_ble_ctx_HERE0"
  ((i++))
  nparam=$rematch1
  return 0
}
_ble_syntax_bash_command_EndCtx=()
_ble_syntax_bash_command_EndCtx[_ble_ctx_ARGI]=$_ble_ctx_ARGX
_ble_syntax_bash_command_EndCtx[_ble_ctx_ARGQ]=$_ble_ctx_ARGX
_ble_syntax_bash_command_EndCtx[_ble_ctx_ARGVI]=$_ble_ctx_ARGVX
_ble_syntax_bash_command_EndCtx[_ble_ctx_ARGVR]=$_ble_ctx_ARGVX
_ble_syntax_bash_command_EndCtx[_ble_ctx_ARGEI]=$_ble_ctx_ARGEX
_ble_syntax_bash_command_EndCtx[_ble_ctx_ARGER]=$_ble_ctx_ARGEX
_ble_syntax_bash_command_EndCtx[_ble_ctx_VRHS]=$_ble_ctx_CMDXV
_ble_syntax_bash_command_EndCtx[_ble_ctx_FARGI1]=$_ble_ctx_FARGX2
_ble_syntax_bash_command_EndCtx[_ble_ctx_FARGI2]=$_ble_ctx_FARGX3
_ble_syntax_bash_command_EndCtx[_ble_ctx_FARGI3]=$_ble_ctx_FARGX3
_ble_syntax_bash_command_EndCtx[_ble_ctx_FARGQ3]=$_ble_ctx_FARGX3
_ble_syntax_bash_command_EndCtx[_ble_ctx_CARGI1]=$_ble_ctx_CARGX2
_ble_syntax_bash_command_EndCtx[_ble_ctx_CARGQ1]=$_ble_ctx_CARGX2
_ble_syntax_bash_command_EndCtx[_ble_ctx_CARGI2]=$_ble_ctx_CASE
_ble_syntax_bash_command_EndCtx[_ble_ctx_TARGI1]=$((_ble_bash>=40200?_ble_ctx_TARGX2:_ble_ctx_CMDXT)) #1
_ble_syntax_bash_command_EndCtx[_ble_ctx_TARGI2]=$_ble_ctx_CMDXT
_ble_syntax_bash_command_EndWtype[_ble_ctx_ARGX]=$_ble_ctx_ARGI
_ble_syntax_bash_command_EndWtype[_ble_ctx_ARGX0]=$_ble_ctx_ARGI
_ble_syntax_bash_command_EndWtype[_ble_ctx_ARGVX]=$_ble_ctx_ARGVI
_ble_syntax_bash_command_EndWtype[_ble_ctx_ARGEX]=$_ble_ctx_ARGEI
_ble_syntax_bash_command_EndWtype[_ble_ctx_CMDX]=$_ble_ctx_CMDI
_ble_syntax_bash_command_EndWtype[_ble_ctx_CMDX1]=$_ble_ctx_CMDI
_ble_syntax_bash_command_EndWtype[_ble_ctx_CMDXT]=$_ble_ctx_CMDI
_ble_syntax_bash_command_EndWtype[_ble_ctx_CMDXC]=$_ble_ctx_CMDI
_ble_syntax_bash_command_EndWtype[_ble_ctx_CMDXE]=$_ble_ctx_CMDI
_ble_syntax_bash_command_EndWtype[_ble_ctx_CMDXD]=$_ble_ctx_CMDI
_ble_syntax_bash_command_EndWtype[_ble_ctx_CMDXD0]=$_ble_ctx_CMDI
_ble_syntax_bash_command_EndWtype[_ble_ctx_CMDXV]=$_ble_ctx_CMDI
_ble_syntax_bash_command_EndWtype[_ble_ctx_FARGX1]=$_ble_ctx_ARGI
_ble_syntax_bash_command_EndWtype[_ble_ctx_SARGX1]=$_ble_ctx_ARGI
_ble_syntax_bash_command_EndWtype[_ble_ctx_FARGX2]=$_ble_ctx_FARGI2 # in
_ble_syntax_bash_command_EndWtype[_ble_ctx_FARGX3]=$_ble_ctx_ARGI # in
_ble_syntax_bash_command_EndWtype[_ble_ctx_CARGX1]=$_ble_ctx_ARGI
_ble_syntax_bash_command_EndWtype[_ble_ctx_CARGX2]=$_ble_ctx_CARGI2 # in
_ble_syntax_bash_command_EndWtype[_ble_ctx_TARGX1]=$_ble_ctx_ARGI # -p
_ble_syntax_bash_command_EndWtype[_ble_ctx_TARGX2]=$_ble_ctx_ARGI # --
_ble_syntax_bash_command_Expect=()
_ble_syntax_bash_command_Expect[_ble_ctx_CMDXC]='^(\(|\{|\(\(|\[\[|for|select|case|if|while|until)$'
_ble_syntax_bash_command_Expect[_ble_ctx_CMDXE]='^(\}|fi|done|esac|then|elif|else|do)$'
_ble_syntax_bash_command_Expect[_ble_ctx_CMDXD]='^(\{|do)$'
_ble_syntax_bash_command_Expect[_ble_ctx_CMDXD0]='^(\{|do)$'
function ble/syntax:bash/ctx-command/check-word-end {
  ((wbegin<0)) && return 1
  ble/syntax:bash/check-word-end/is-delimiter || return 1
  local wbeg=$wbegin wlen=$((i-wbegin)) wend=$i
  local word=${text:wbegin:wlen}
  local wt=$wtype
  [[ ${_ble_syntax_bash_command_EndWtype[wt]} ]] &&
    wtype=${_ble_syntax_bash_command_EndWtype[wt]}
  local rex_expect_command=${_ble_syntax_bash_command_Expect[wt]}
  if [[ $rex_expect_command ]]; then
    [[ $word =~ $rex_expect_command ]] || ((wtype=_ble_attr_ERR))
  fi
  if ((wt==_ble_ctx_CMDX1)); then
    local rex='^(then|elif|else|do|\}|done|fi|esac)$'
    [[ $word =~ $rex ]] && ((wtype=_ble_attr_ERR))
  fi
  ble/syntax/parse/word-pop
  if ((ctx==_ble_ctx_CMDI)); then
    if ((wt==_ble_ctx_CMDXV)); then
      ((ctx=_ble_ctx_ARGX))
      return 0
    fi
    local word_expanded=$word
    local type; ble/util/type type "$word"
    if [[ $type == alias ]]; then
      local data; ble/util/assign data 'LANG=C alias "$word"' &>/dev/null
      [[ $data == 'alias '*=* ]] &&
        eval "word_expanded=${data#alias *=}"
    fi
    local processed=
    case "$word_expanded" in
    ('[[')
      ble/syntax/parse/touch-updated-attr "$wbeg"
      ((_ble_syntax_attr[wbeg]=_ble_attr_DEL,
        ctx=_ble_ctx_ARGX0))
      ble/syntax/parse/word-cancel # 単語 "[[" を削除
      if [[ $word == '[[' ]]; then
        ble/syntax/parse/word-cancel # 角括弧式の nest を削除
        _ble_syntax_attr[wbeg+1]= # 角括弧式として着色されているのを消去
      fi
      i=$wbeg ble/syntax/parse/nest-push "$_ble_ctx_CONDX"
      i=$wbeg ble/syntax/parse/word-push "$_ble_ctx_CMDI" "$wbeg"
      ble/syntax/parse/word-pop
      return 0 ;;
    ('time')               ((ctx=_ble_ctx_TARGX1)); processed=keyword ;;
    ('!')                  ((ctx=_ble_ctx_CMDXT)) ; processed=keyword ;;
    ('if'|'while'|'until') ((ctx=_ble_ctx_CMDX1)) ; processed=begin ;;
    ('for')                ((ctx=_ble_ctx_FARGX1)); processed=begin ;;
    ('select')             ((ctx=_ble_ctx_SARGX1)); processed=begin ;;
    ('case')               ((ctx=_ble_ctx_CARGX1)); processed=begin ;;
    ('{')              
      ((ctx=_ble_ctx_CMDX1))
      if ((wt==_ble_ctx_CMDXD||wt==_ble_ctx_CMDXD0)); then
        processed=middle # "for ...; {" などの時
      else
        processed=begin
      fi ;;
    ('then'|'elif'|'else'|'do') ((ctx=_ble_ctx_CMDX1)) ; processed=middle ;;
    ('}'|'done'|'fi'|'esac')    ((ctx=_ble_ctx_CMDXE)) ; processed=end ;;
    ('declare'|'readonly'|'typeset'|'local'|'export'|'alias')
      ((ctx=_ble_ctx_ARGVX))
      processed=builtin ;;
    ('eval')
      ((ctx=_ble_ctx_ARGEX))
      processed=builtin ;;
    ('function')
      ((ctx=_ble_ctx_ARGX))
      local isfuncsymx=$'\t\n'' "$&'\''();<>\`|' rex_space=$'[ \t]' rex
      if rex="^$rex_space+" && [[ ${text:i} =~ $rex ]]; then
        ((_ble_syntax_attr[i]=_ble_ctx_ARGX,i+=${#BASH_REMATCH},ctx=_ble_ctx_ARGX))
        if rex="^([^#$isfuncsymx][^$isfuncsymx]*)($rex_space*)(\(\(|\($rex_space*\)?)?" && [[ ${text:i} =~ $rex ]]; then
          local rematch1=${BASH_REMATCH[1]}
          local rematch2=${BASH_REMATCH[2]}
          local rematch3=${BASH_REMATCH[3]}
          ((_ble_syntax_attr[i]=_ble_attr_FUNCDEF,i+=${#rematch1},
            ${#rematch2}&&(_ble_syntax_attr[i]=_ble_ctx_CMDX1,i+=${#rematch2})))
          if [[ $rematch3 == '('*')' ]]; then
            ((_ble_syntax_attr[i]=_ble_attr_DEL,i+=${#rematch3},ctx=_ble_ctx_CMDXC))
          elif ((_ble_bash>=40200)) && [[ $rematch3 == '((' ]]; then
            ble/syntax/parse/set-lookahead 2
            ((ctx=_ble_ctx_CMDXC))
          elif [[ $rematch3 == '('* ]]; then
            ((_ble_syntax_attr[i]=_ble_attr_ERR,ctx=_ble_ctx_ARGX0))
            ble/syntax/parse/nest-push "$_ble_ctx_CMDX1" '('
            ((${#rematch3}>=2&&(_ble_syntax_attr[i+1]=_ble_ctx_CMDX1),i+=${#rematch3}))
          else
            ((ctx=_ble_ctx_CMDXC))
          fi
          processed=keyword
        fi
      fi
      [[ $processed ]] || ((_ble_syntax_attr[i-1]=_ble_attr_ERR)) ;;
    esac
    if [[ $processed ]]; then
      local attr=
      case $processed in
      (keyword) attr=$_ble_attr_KEYWORD ;;
      (begin)   attr=$_ble_attr_KEYWORD_BEGIN ;;
      (end)     attr=$_ble_attr_KEYWORD_END ;;
      (middle)  attr=$_ble_attr_KEYWORD_MID ;;
      esac
      if [[ $attr ]]; then
        ble/syntax/parse/touch-updated-attr "$wbeg"
        ((_ble_syntax_attr[wbeg]=attr))
      fi
      return 0
    fi
    ((ctx=_ble_ctx_ARGX))
    if local rex='^([ 	]*)(\([ 	]*\)?)?'; [[ ${text:i} =~ $rex && $BASH_REMATCH ]]; then
      local rematch1=${BASH_REMATCH[1]}
      local rematch2=${BASH_REMATCH[2]}
      if [[ $rematch2 == '('*')' ]]; then
        _ble_syntax_tree[i-1]="$_ble_attr_FUNCDEF ${_ble_syntax_tree[i-1]#* }"
        ((_ble_syntax_attr[i]=_ble_ctx_CMDX1,i+=${#rematch1},
          _ble_syntax_attr[i]=_ble_attr_DEL,i+=${#rematch2},
          ctx=_ble_ctx_CMDXC))
      elif [[ $rematch2 == '('* ]]; then
        ((_ble_syntax_attr[i]=_ble_ctx_ARGX0,i+=${#rematch1},
          _ble_syntax_attr[i]=_ble_attr_ERR,
          ctx=_ble_ctx_ARGX0))
        ble/syntax/parse/nest-push "$_ble_ctx_PATN"
        ((${#rematch2}>=2&&(_ble_syntax_attr[i+1]=_ble_ctx_CMDXC),
          i+=${#rematch2}))
      else
        ((_ble_syntax_attr[i]=_ble_ctx_ARGX,i+=${#rematch1}))
      fi
    fi
    return 0
  fi
  if ((ctx==_ble_ctx_FARGI2)); then
    if [[ $word == do ]]; then
      ((ctx=_ble_ctx_CMDX1))
      return 0
    fi
  fi
  if ((ctx==_ble_ctx_FARGI2||ctx==_ble_ctx_CARGI2)); then
    if [[ $word != in ]];  then
      ble/syntax/parse/touch-updated-attr "$wbeg"
      ((_ble_syntax_attr[wbeg]=_ble_attr_ERR))
    fi
  fi
  if ((_ble_syntax_bash_command_EndCtx[ctx])); then
    ((ctx=_ble_syntax_bash_command_EndCtx[ctx]))
  fi
  return 0
}
_ble_syntax_bash_command_Opt=()
_ble_syntax_bash_command_Opt[_ble_ctx_ARGX]=1
_ble_syntax_bash_command_Opt[_ble_ctx_ARGX0]=1
_ble_syntax_bash_command_Opt[_ble_ctx_ARGVX]=1
_ble_syntax_bash_command_Opt[_ble_ctx_ARGEX]=1
_ble_syntax_bash_command_Opt[_ble_ctx_CMDXV]=1
_ble_syntax_bash_command_Opt[_ble_ctx_CMDXE]=1
_ble_syntax_bash_command_Opt[_ble_ctx_CMDXD0]=1
_ble_syntax_bash_is_command_form_for=
function ble/syntax:bash/ctx-command/.check-delimiter-or-redirect {
  if [[ $tail =~ ^$_ble_syntax_bash_RexIFSs ]]; then
    local spaces=$BASH_REMATCH
    if [[ $spaces == *$'\n'* ]]; then
      ble/syntax:bash/check-here-document-from "$spaces" && return 0
      if ((ctx==_ble_ctx_ARGX||ctx==_ble_ctx_ARGX0||ctx==_ble_ctx_ARGVX||ctx==_ble_ctx_ARGEX||ctx==_ble_ctx_CMDXV||ctx==_ble_ctx_CMDXT||ctx==_ble_ctx_CMDXE)); then
        ((ctx=_ble_ctx_CMDX))
      elif ((ctx==_ble_ctx_FARGX2||ctx==_ble_ctx_FARGX3||ctx==_ble_ctx_CMDXD0)); then
        ((ctx=_ble_ctx_CMDXD))
      fi
    fi
    ((_ble_syntax_attr[i]=ctx,i+=${#spaces}))
    return 0
  elif [[ $tail =~ ^$_ble_syntax_bash_RexRedirect ]]; then
    local len=${#BASH_REMATCH}
    local rematch1=${BASH_REMATCH[1]}
    local rematch3=${BASH_REMATCH[3]}
    ((_ble_syntax_attr[i]=_ble_attr_DEL,
      ${#rematch1}<len&&(_ble_syntax_attr[i+${#rematch1}]=_ble_ctx_ARGX)))
    if ((ctx==_ble_ctx_CMDX||ctx==_ble_ctx_CMDX1||ctx==_ble_ctx_CMDXT)); then
      ((ctx=_ble_ctx_CMDXV))
    elif ((ctx==_ble_ctx_CMDXC||ctx==_ble_ctx_CMDXD||ctx==_ble_ctx_CMDXD0)); then
      ((ctx=_ble_ctx_CMDXV,
        _ble_syntax_attr[i]=_ble_attr_ERR))
    elif ((ctx==_ble_ctx_CMDXE)); then
      ((ctx=_ble_ctx_ARGX0))
    elif ((ctx==_ble_ctx_FARGX3)); then
      ((_ble_syntax_attr[i]=_ble_attr_ERR))
    fi
    if [[ ${text:i+len} != [!$'\n|&()']* ]]; then
      ((_ble_syntax_attr[i+len-1]=_ble_attr_ERR))
    else
      if [[ $rematch1 == *'&' ]]; then
        ble/syntax/parse/nest-push "$_ble_ctx_RDRD" "$rematch3"
      elif [[ $rematch1 == *'<<<' ]]; then
        ble/syntax/parse/nest-push "$_ble_ctx_RDRS" "$rematch3"
      elif [[ $rematch1 == *\<\< ]]; then
        ble/syntax/parse/nest-push "$_ble_ctx_RDRH" "$rematch3"
      elif [[ $rematch1 == *\<\<- ]]; then
        ble/syntax/parse/nest-push "$_ble_ctx_RDRI" "$rematch3"
      else
        ble/syntax/parse/nest-push "$_ble_ctx_RDRF" "$rematch3"
      fi
    fi
    ((i+=len))
    return 0
  elif local rex='^(&&|\|[|&]?)|^;(;&?|&)|^[;&]'
       ((_ble_bash<40000)) && rex='^(&&|\|\|?)|^;(;)|^[;&]'
       [[ $tail =~ $rex ]]
  then
    if [[ $BASH_REMATCH == ';' ]]; then
      if ((ctx==_ble_ctx_FARGX2||ctx==_ble_ctx_FARGX3||ctx==_ble_ctx_CMDXD0)); then
        ((_ble_syntax_attr[i++]=_ble_attr_DEL,ctx=_ble_ctx_CMDXD))
        return 0
      elif ((ctx==_ble_ctx_CMDXT)); then
        ((_ble_syntax_attr[i++]=_ble_attr_DEL,ctx=_ble_ctx_CMDXE))
        return 0
      fi
    fi
    local rematch1=${BASH_REMATCH[1]} rematch2=${BASH_REMATCH[2]}
    ((_ble_syntax_attr[i]=_ble_attr_DEL,
      (_ble_syntax_bash_command_Opt[ctx]||ctx==_ble_ctx_CMDX&&${#rematch2})||
        (_ble_syntax_attr[i]=_ble_attr_ERR)))
    ((ctx=${#rematch1}?_ble_ctx_CMDX1:(
         ${#rematch2}?_ble_ctx_CASE:
         _ble_ctx_CMDX)))
    ((i+=${#BASH_REMATCH}))
    return 0
  elif local rex='^\(\(?' && [[ $tail =~ $rex ]]; then
    local m=${BASH_REMATCH[0]}
    if ((ctx==_ble_ctx_CMDX||ctx==_ble_ctx_CMDX1||ctx==_ble_ctx_CMDXT||ctx==_ble_ctx_CMDXC)); then
      ((_ble_syntax_attr[i]=_ble_attr_DEL))
      ((ctx=_ble_ctx_ARGX0))
      [[ $_ble_syntax_bash_is_command_form_for && $tail == '(('* ]] && ((ctx=_ble_ctx_CMDXD0))
      ble/syntax/parse/nest-push $((${#m}==1?_ble_ctx_CMDX1:_ble_ctx_EXPR)) "$m"
      ((i+=${#m}))
    else
      ble/syntax/parse/nest-push "$_ble_ctx_PATN"
      ((_ble_syntax_attr[i++]=_ble_attr_ERR))
    fi
    return 0
  elif [[ $tail == ')'* ]]; then
    local ntype
    ble/syntax/parse/nest-type -v ntype
    local attr=
    if [[ $ntype == '(' || $ntype == '$(' || $ntype == '((' || $ntype == '$((' ]]; then
      ((attr=_ble_syntax_attr[inest]))
    fi
    if [[ $attr ]]; then
      ((_ble_syntax_attr[i]=(ctx==_ble_ctx_CMDX||ctx==_ble_ctx_CMDXV||ctx==_ble_ctx_CMDXE||ctx==_ble_ctx_ARGX||ctx==_ble_ctx_ARGX0||ctx==_ble_ctx_ARGVX||ctx==_ble_ctx_ARGEX)?attr:_ble_attr_ERR,
        i+=1))
      ble/syntax/parse/nest-pop
      return 0
    fi
  fi
  return 1
}
_ble_syntax_bash_command_BeginCtx=()
_ble_syntax_bash_command_BeginCtx[_ble_ctx_ARGX]=$_ble_ctx_ARGI
_ble_syntax_bash_command_BeginCtx[_ble_ctx_ARGX0]=$_ble_ctx_ARGI
_ble_syntax_bash_command_BeginCtx[_ble_ctx_ARGVX]=$_ble_ctx_ARGVI
_ble_syntax_bash_command_BeginCtx[_ble_ctx_ARGEX]=$_ble_ctx_ARGEI
_ble_syntax_bash_command_BeginCtx[_ble_ctx_CMDX]=$_ble_ctx_CMDI
_ble_syntax_bash_command_BeginCtx[_ble_ctx_CMDX1]=$_ble_ctx_CMDI
_ble_syntax_bash_command_BeginCtx[_ble_ctx_CMDXT]=$_ble_ctx_CMDI
_ble_syntax_bash_command_BeginCtx[_ble_ctx_CMDXC]=$_ble_ctx_CMDI
_ble_syntax_bash_command_BeginCtx[_ble_ctx_CMDXE]=$_ble_ctx_CMDI
_ble_syntax_bash_command_BeginCtx[_ble_ctx_CMDXD]=$_ble_ctx_CMDI
_ble_syntax_bash_command_BeginCtx[_ble_ctx_CMDXD0]=$_ble_ctx_CMDI
_ble_syntax_bash_command_BeginCtx[_ble_ctx_CMDXV]=$_ble_ctx_CMDI
_ble_syntax_bash_command_BeginCtx[_ble_ctx_FARGX1]=$_ble_ctx_FARGI1
_ble_syntax_bash_command_BeginCtx[_ble_ctx_SARGX1]=$_ble_ctx_FARGI1
_ble_syntax_bash_command_BeginCtx[_ble_ctx_FARGX2]=$_ble_ctx_FARGI2
_ble_syntax_bash_command_BeginCtx[_ble_ctx_FARGX3]=$_ble_ctx_FARGI3
_ble_syntax_bash_command_BeginCtx[_ble_ctx_CARGX1]=$_ble_ctx_CARGI1
_ble_syntax_bash_command_BeginCtx[_ble_ctx_CARGX2]=$_ble_ctx_CARGI2
_ble_syntax_bash_command_BeginCtx[_ble_ctx_TARGX1]=$_ble_ctx_TARGI1
_ble_syntax_bash_command_BeginCtx[_ble_ctx_TARGX2]=$_ble_ctx_TARGI2
_ble_syntax_bash_command_isARGI[_ble_ctx_CMDI]=1
_ble_syntax_bash_command_isARGI[_ble_ctx_VRHS]=1
_ble_syntax_bash_command_isARGI[_ble_ctx_ARGI]=1
_ble_syntax_bash_command_isARGI[_ble_ctx_ARGQ]=1
_ble_syntax_bash_command_isARGI[_ble_ctx_ARGVI]=1
_ble_syntax_bash_command_isARGI[_ble_ctx_ARGVR]=1
_ble_syntax_bash_command_isARGI[_ble_ctx_ARGEI]=1
_ble_syntax_bash_command_isARGI[_ble_ctx_ARGER]=1
_ble_syntax_bash_command_isARGI[_ble_ctx_FARGI1]=1 # var
_ble_syntax_bash_command_isARGI[_ble_ctx_FARGI2]=1 # in
_ble_syntax_bash_command_isARGI[_ble_ctx_FARGI3]=1 # args...
_ble_syntax_bash_command_isARGI[_ble_ctx_FARGQ3]=1 # args... (= の後)
_ble_syntax_bash_command_isARGI[_ble_ctx_CARGI1]=1 # value
_ble_syntax_bash_command_isARGI[_ble_ctx_CARGQ1]=1 # value (= の後)
_ble_syntax_bash_command_isARGI[_ble_ctx_CARGI2]=1 # in
_ble_syntax_bash_command_isARGI[_ble_ctx_TARGI1]=1 # -p
_ble_syntax_bash_command_isARGI[_ble_ctx_TARGI2]=1 # --
function ble/syntax:bash/ctx-command/.check-word-begin {
  if ((wbegin<0)); then
    local octx
    ((octx=ctx,
      wtype=octx,
      ctx=_ble_syntax_bash_command_BeginCtx[ctx]))
    if ((ctx==0)); then
      ((ctx=wtype=_ble_ctx_ARGI))
      ble/util/stackdump "invalid ctx=$octx at the beginning of words"
    fi
    ble/syntax/parse/word-push "$wtype" "$i"
    ((octx!=_ble_ctx_ARGX0)); return # return unexpectedWbegin
  fi
  ((_ble_syntax_bash_command_isARGI[ctx])) || ble/util/stackdump "invalid ctx=$ctx in words"
  return 0
}
function ble/syntax:bash/ctx-command {
  if ble/syntax:bash/starts-with-delimiter-or-redirect; then
    ((ctx==_ble_ctx_ARGX||ctx==_ble_ctx_ARGX0||ctx==_ble_ctx_ARGVX||ctx==_ble_ctx_ARGEX||ctx==_ble_ctx_FARGX2||ctx==_ble_ctx_FARGX3||
        ctx==_ble_ctx_CMDX||ctx==_ble_ctx_CMDX1||ctx==_ble_ctx_CMDXT||ctx==_ble_ctx_CMDXC||
        ctx==_ble_ctx_CMDXE||ctx==_ble_ctx_CMDXD||ctx==_ble_ctx_CMDXD0||ctx==_ble_ctx_CMDXV)) || ble/util/stackdump "invalid ctx=$ctx @ i=$i"
    ((wbegin<0&&wtype<0)) || ble/util/stackdump "invalid word-context (wtype=$wtype wbegin=$wbegin) on non-word char."
    ble/syntax:bash/ctx-command/.check-delimiter-or-redirect; return
  fi
  ble/syntax:bash/check-comment && return 0
  local unexpectedWbegin=-1
  ble/syntax:bash/ctx-command/.check-word-begin || ((unexpectedWbegin=i))
  local wtype0=$wtype i0=$i
  local flagConsume=0
  if ble/syntax:bash/check-variable-assignment; then
    flagConsume=1
  elif local rex='^([^'${_ble_syntax_bash_chars[_ble_ctx_ARGI]}']|\\.)+'; [[ $tail =~ $rex ]]; then
    ((_ble_syntax_attr[i]=ctx,
      i+=${#BASH_REMATCH}))
    flagConsume=1
  elif ble/syntax:bash/check-process-subst; then
    flagConsume=1
  elif ble/syntax:bash/check-quotes; then
    flagConsume=1
  elif ble/syntax:bash/check-dollar; then
    flagConsume=1
  elif ble/syntax:bash/check-glob; then
    flagConsume=1
  elif ble/syntax:bash/check-brace-expansion; then
    flagConsume=1
  elif ble/syntax:bash/check-tilde-expansion; then
    flagConsume=1
  elif ble/syntax:bash/starts-with-histchars; then
    ble/syntax:bash/check-history-expansion ||
      ((_ble_syntax_attr[i]=ctx,i++))
    flagConsume=1
  fi
  if ((flagConsume)); then
    ble/util/assert '((wtype0>=0))'
    [[ ${_ble_syntax_bash_command_Expect[wtype0]} ]] &&
      ((_ble_syntax_attr[i0]=_ble_attr_ERR))
    if ((unexpectedWbegin>=0)); then
      ble/syntax/parse/touch-updated-attr "$unexpectedWbegin"
      ((_ble_syntax_attr[unexpectedWbegin]=_ble_attr_ERR))
    fi
    return 0
  else
    return 1
  fi
}
function ble/syntax:bash/ctx-command-compound-expect {
  ble/util/assert '((ctx==_ble_ctx_FARGX1||ctx==_ble_ctx_SARGX1||ctx==_ble_ctx_CARGX1||ctx==_ble_ctx_FARGX2||ctx==_ble_ctx_CARGX2))'
  local _ble_syntax_bash_is_command_form_for=
  if ble/syntax:bash/starts-with-delimiter-or-redirect; then
    if ((ctx==_ble_ctx_FARGX2)) && [[ $tail == [$';\n']* ]]; then
      ble/syntax:bash/ctx-command
      return
    elif ((ctx==_ble_ctx_FARGX1)) && [[ $tail == '(('* ]]; then
      ((ctx=_ble_ctx_CMDX1,_ble_syntax_bash_is_command_form_for=1))
    elif [[ $tail == $'\n'* ]]; then
      if ((ctx==_ble_ctx_CARGX2)); then
        ((_ble_syntax_attr[i++]=_ble_ctx_ARGX))
      else
        ((_ble_syntax_attr[i++]=_ble_attr_ERR,ctx=_ble_ctx_ARGX))
      fi
      return 0
    elif [[ $tail =~ ^$_ble_syntax_bash_RexSpaces ]]; then
      ((_ble_syntax_attr[i]=ctx,i+=${#BASH_REMATCH}))
      return 0
    else
      local i0=$i
      ((ctx=_ble_ctx_ARGX))
      ble/syntax:bash/ctx-command/.check-delimiter-or-redirect || ((i++))
      ((_ble_syntax_attr[i0]=_ble_attr_ERR))
      return 0
    fi
  fi
  local i0=$i
  if ble/syntax:bash/check-comment; then
    if ((ctx==_ble_ctx_FARGX1||ctx==_ble_ctx_SARGX1||ctx==_ble_ctx_CARGX1)); then
      ((_ble_syntax_attr[i0]=_ble_attr_ERR))
    fi
    return 0
  fi
  ble/syntax:bash/ctx-command
}
function ble/syntax:bash/ctx-command-time-expect {
  ble/util/assert '((ctx==_ble_ctx_TARGX1||ctx==_ble_ctx_TARGX2))'
  if ble/syntax:bash/starts-with-delimiter-or-redirect; then
    ble/util/assert '((wbegin<0&&wtype<0))'
    if [[ $tail =~ ^$_ble_syntax_bash_RexSpaces ]]; then
      ((_ble_syntax_attr[i]=ctx,i+=${#BASH_REMATCH}))
      return 0
    else
      ((ctx=_ble_ctx_CMDXT))
      ble/syntax:bash/ctx-command/.check-delimiter-or-redirect; return
    fi
  fi
  local is_time_option=
  local head=-p; ((ctx==_ble_ctx_TARGX2)) && head=--
  if [[ $tail == "$head"* ]]; then
    ble/syntax/parse/set-lookahead 3
    if [[ $tail == "$head" ]] || i=$((i+2)) ble/syntax:bash/check-word-end/is-delimiter; then
      is_time_option=1
    fi
  fi
  ((is_time_option||(ctx=_ble_ctx_CMDXT)))
  ble/syntax:bash/ctx-command
}
_BLE_SYNTAX_FCTX[_ble_ctx_VALX]=ble/syntax:bash/ctx-values
_BLE_SYNTAX_FCTX[_ble_ctx_VALI]=ble/syntax:bash/ctx-values
_BLE_SYNTAX_FEND[_ble_ctx_VALI]=ble/syntax:bash/ctx-values/check-word-end
_BLE_SYNTAX_FCTX[_ble_ctx_VALR]=ble/syntax:bash/ctx-values
_BLE_SYNTAX_FEND[_ble_ctx_VALR]=ble/syntax:bash/ctx-values/check-word-end
_BLE_SYNTAX_FCTX[_ble_ctx_VALQ]=ble/syntax:bash/ctx-values
_BLE_SYNTAX_FEND[_ble_ctx_VALQ]=ble/syntax:bash/ctx-values/check-word-end
function ble/syntax:bash/ctx-values/enter {
  local outer_nparam=$nparam
  ble/syntax/parse/nest-push "$_ble_ctx_VALX"
  nparam=$outer_nparam
}
function ble/syntax:bash/ctx-values/leave {
  local inner_nparam=$nparam
  ble/syntax/parse/nest-pop
  nparam=$inner_nparam
}
function ble/syntax:bash/ctx-values/check-word-end {
  ((wbegin<0)) && return 1
  [[ ${text:i:1} == [!"$_ble_syntax_bash_IFS;|&<>()"] ]] && return 1
  local wbeg=$wbegin wlen=$((i-wbegin)) wend=$i
  local word=${text:wbegin:wlen}
  ble/syntax/parse/word-pop
  ble/util/assert '((ctx==_ble_ctx_VALI||ctx==_ble_ctx_VALR||ctx==_ble_ctx_VALQ))' 'invalid context'
  ((ctx=_ble_ctx_VALX))
  return 0
}
function ble/syntax:bash/ctx-values {
  if ble/syntax:bash/starts-with-delimiter; then
    ((ctx==_ble_ctx_VALX)) || ble/util/stackdump "invalid ctx=$ctx @ i=$i"
    ((wbegin<0&&wtype<0)) || ble/util/stackdump "invalid word-context (wtype=$wtype wbegin=$wbegin) on non-word char."
    if [[ $tail =~ ^$_ble_syntax_bash_RexIFSs ]]; then
      local spaces=$BASH_REMATCH
      ble/syntax:bash/check-here-document-from "$spaces" && return 0
      ((_ble_syntax_attr[i]=ctx,i+=${#spaces}))
      return 0
    elif [[ $tail == ')'* ]]; then
      ((_ble_syntax_attr[i++]=_ble_attr_DEL))
      ble/syntax:bash/ctx-values/leave
      return 0
    elif [[ $type == ';'* ]]; then
      ((_ble_syntax_attr[i++]=_ble_attr_ERR))
      return 0
    else
      ((_ble_syntax_attr[i++]=_ble_attr_ERR))
      return 0
    fi
  fi
  if ble/syntax:bash/check-comment; then
    return 0
  fi
  if ((wbegin<0)); then
    ((ctx=_ble_ctx_VALI))
    ble/syntax/parse/word-push "$ctx" "$i"
  fi
  ble/util/assert '((ctx==_ble_ctx_VALI||ctx==_ble_ctx_VALR||ctx==_ble_ctx_VALQ))' "invalid context ctx=$ctx"
  if ble/syntax:bash/check-variable-assignment; then
    return 0
  elif local rex='^([^'${_ble_syntax_bash_chars[_ble_ctx_ARGI]}']|\\.)+' && [[ $tail =~ $rex ]]; then
    ((_ble_syntax_attr[i]=ctx,
      i+=${#BASH_REMATCH}))
    return 0
  elif ble/syntax:bash/check-process-subst; then
    return 0
  elif ble/syntax:bash/check-quotes; then
    return 0
  elif ble/syntax:bash/check-dollar; then
    return 0
  elif ble/syntax:bash/check-glob; then
    return 0
  elif ble/syntax:bash/check-brace-expansion; then
    return 0
  elif ble/syntax:bash/check-tilde-expansion; then
    return 0
  elif ble/syntax:bash/starts-with-histchars; then
    ble/syntax:bash/check-history-expansion ||
      ((_ble_syntax_attr[i]=ctx,i++))
    return 0
  fi
  return 1
}
_BLE_SYNTAX_FCTX[_ble_ctx_CONDX]=ble/syntax:bash/ctx-conditions
_BLE_SYNTAX_FCTX[_ble_ctx_CONDI]=ble/syntax:bash/ctx-conditions
_BLE_SYNTAX_FEND[_ble_ctx_CONDI]=ble/syntax:bash/ctx-conditions/check-word-end
_BLE_SYNTAX_FCTX[_ble_ctx_CONDQ]=ble/syntax:bash/ctx-conditions
_BLE_SYNTAX_FEND[_ble_ctx_CONDQ]=ble/syntax:bash/ctx-conditions/check-word-end
function ble/syntax:bash/ctx-conditions/check-word-end {
  ((wbegin<0)) && return 1
  [[ ${text:i:1} == [!"$_ble_syntax_bash_IFS;|&<>()"] ]] && return 1
  local wbeg=$wbegin wlen=$((i-wbegin)) wend=$i
  local word=${text:wbegin:wlen}
  ble/syntax/parse/word-pop
  ble/util/assert '((ctx==_ble_ctx_CONDI||ctx==_ble_ctx_CONDQ))' 'invalid context'
  if [[ $word == ']]' ]]; then
    ble/syntax/parse/touch-updated-attr "$wbeg"
    ((_ble_syntax_attr[wbeg]=_ble_attr_DEL))
    ble/syntax/parse/nest-pop
  else
    ((ctx=_ble_ctx_CONDX))
  fi
  return 0
}
function ble/syntax:bash/ctx-conditions {
  if ble/syntax:bash/starts-with-delimiter; then
    ((ctx==_ble_ctx_CONDX)) || ble/util/stackdump "invalid ctx=$ctx @ i=$i"
    ((wbegin<0&&wtype<0)) || ble/util/stackdump "invalid word-context (wtype=$wtype wbegin=$wbegin) on non-word char."
    if [[ $tail =~ ^$_ble_syntax_bash_RexIFSs ]]; then
      ((_ble_syntax_attr[i]=ctx,i+=${#BASH_REMATCH}))
      return 0
    else
      ((_ble_syntax_attr[i++]=_ble_ctx_CONDI))
      return 0
    fi
  fi
  ble/syntax:bash/check-comment && return 0
  if ((wbegin<0)); then
    ((ctx=_ble_ctx_CONDI))
    ble/syntax/parse/word-push "$ctx" "$i"
  fi
  ble/util/assert '((ctx==_ble_ctx_CONDI||ctx==_ble_ctx_CONDQ))' "invalid context ctx=$ctx"
  if ble/syntax:bash/check-variable-assignment; then
    return 0
  elif local rex='^([^'${_ble_syntax_bash_chars[_ble_ctx_ARGI]}']|\\.)+' && [[ $tail =~ $rex ]]; then
    ((_ble_syntax_attr[i]=ctx,
      i+=${#BASH_REMATCH}))
    return 0
  elif ble/syntax:bash/check-process-subst; then
    return 0
  elif ble/syntax:bash/check-quotes; then
    return 0
  elif ble/syntax:bash/check-dollar; then
    return 0
  elif ble/syntax:bash/check-glob; then
    return 0
  elif ble/syntax:bash/check-brace-expansion; then
    return 0
  elif ble/syntax:bash/check-tilde-expansion; then
    return 0
  elif ble/syntax:bash/starts-with-histchars; then
    ble/syntax:bash/check-history-expansion ||
      ((_ble_syntax_attr[i++]=ctx))
    return 0
  else
    ((_ble_syntax_attr[i++]=ctx))
    return 0
  fi
  return 1
}
_BLE_SYNTAX_FCTX[_ble_ctx_RDRF]=ble/syntax:bash/ctx-redirect
_BLE_SYNTAX_FCTX[_ble_ctx_RDRD]=ble/syntax:bash/ctx-redirect
_BLE_SYNTAX_FCTX[_ble_ctx_RDRS]=ble/syntax:bash/ctx-redirect
_BLE_SYNTAX_FEND[_ble_ctx_RDRF]=ble/syntax:bash/ctx-redirect/check-word-end
_BLE_SYNTAX_FEND[_ble_ctx_RDRD]=ble/syntax:bash/ctx-redirect/check-word-end
_BLE_SYNTAX_FEND[_ble_ctx_RDRS]=ble/syntax:bash/ctx-redirect/check-word-end
function ble/syntax:bash/ctx-redirect/check-word-begin {
  if ((wbegin<0)); then
    ble/syntax/parse/word-push "$ctx" "$i"
    ble/syntax/parse/touch-updated-word "$i" #■これは不要では?
  fi
}
function ble/syntax:bash/ctx-redirect/check-word-end {
  ((wbegin<0)) && return 1
  ble/syntax:bash/check-word-end/is-delimiter || return 1
  ble/syntax/parse/word-pop
  ble/syntax/parse/nest-pop
  ((!_ble_syntax_bash_command_isARGI[ctx])) || ble/util/stackdump "invalid ctx=$ctx in words"
  return 0
}
function ble/syntax:bash/ctx-redirect {
  if ble/syntax:bash/starts-with-delimiter-or-redirect; then
    ((_ble_syntax_attr[i++]=_ble_attr_ERR))
    [[ ${tail:1} =~ ^$_ble_syntax_bash_RexSpaces ]] &&
      ((_ble_syntax_attr[i]=ctx,i+=${#BASH_REMATCH}))
    return 0
  fi
  if local i0=$i; ble/syntax:bash/check-comment; then
    ((_ble_syntax_attr[i0]=_ble_attr_ERR))
    return 0
  fi
  ble/syntax:bash/ctx-redirect/check-word-begin
  local rex
  if rex='^([^'${_ble_syntax_bash_chars[_ble_ctx_ARGI]}']|\\.)+' && [[ $tail =~ $rex ]]; then
    ((_ble_syntax_attr[i]=ctx,
      i+=${#BASH_REMATCH}))
    return 0
  elif ble/syntax:bash/check-process-subst; then
    return 0
  elif ble/syntax:bash/check-quotes; then
    return 0
  elif ble/syntax:bash/check-dollar; then
    return 0
  elif ble/syntax:bash/check-glob; then
    return 0
  elif ble/syntax:bash/check-brace-expansion; then
    return 0
  elif ble/syntax:bash/check-tilde-expansion; then
    return 0
  elif ble/syntax:bash/starts-with-histchars; then
    ble/syntax:bash/check-history-expansion ||
      ((_ble_syntax_attr[i]=ctx,i++))
    return 0
  fi
  return 1
}
_ble_syntax_bash_heredoc_EscSP='\040'
_ble_syntax_bash_heredoc_EscHT='\011'
_ble_syntax_bash_heredoc_EscLF='\012'
_ble_syntax_bash_heredoc_EscFS='\034'
function ble/syntax:bash/ctx-heredoc-word/initialize {
  local ret
  ble/util/s2c ' '
  ble/util/sprintf _ble_syntax_bash_heredoc_EscSP '\\%03o' "$ret"
  ble/util/s2c $'\t'
  ble/util/sprintf _ble_syntax_bash_heredoc_EscHT '\\%03o' "$ret"
  ble/util/s2c $'\n'
  ble/util/sprintf _ble_syntax_bash_heredoc_EscLF '\\%03o' "$ret"
  ble/util/s2c "$_ble_term_fs"
  ble/util/sprintf _ble_syntax_bash_heredoc_EscFS '\\%03o' "$ret"
}
ble/syntax:bash/ctx-heredoc-word/initialize
function ble/syntax:bash/ctx-heredoc-word/remove-quotes {
  local text=$1 result=
  local rex='^[^\$"'\'']+|^\$?["'\'']|^\\.?|^.'
  while [[ $text && $text =~ $rex ]]; do
    local rematch=$BASH_REMATCH
    if [[ $rematch == \" || $rematch == \$\" ]]; then
      if rex='^\$?"(([^\"]|\\.)*)(\\?$|")'; [[ $text =~ $rex ]]; then
        local str=${BASH_REMATCH[1]}
        local a b
        b='\`' a='`'; str="${str//"$b"/$a}"
        b='\"' a='"'; str="${str//"$b"/$a}"
        b='\$' a='$'; str="${str//"$b"/$a}"
        b='\\' a='\'; str="${str//"$b"/$a}"
        result=$result$str
        text=${text:${#BASH_REMATCH}}
        continue
      fi
    elif [[ $rematch == \' ]]; then
      if rex="^('[^']*)'?"; [[ $text =~ $rex ]]; then
        eval "result=\$result${BASH_REMATCH[1]}'"
        text=${text:${#BASH_REMATCH}}
        continue
      fi
    elif [[ $rematch == \$\' ]]; then
      if rex='^(\$'\''([^\'\'']|\\.)*)('\''|\\?$)'; [[ $text =~ $rex ]]; then
        eval "result=\$result${BASH_REMATCH[1]}'"
        text=${text:${#BASH_REMATCH}}
        continue
      fi
    elif [[ $rematch == \\* ]]; then
      result=$result${rematch:1}
      text=${text:${#rematch}}
      continue
    fi
    result=$result$rematch
    text=${text:${#rematch}}
  done
  delimiter=$result$text
}
function ble/syntax:bash/ctx-heredoc-word/escape-delimiter {
  local ret=$1
  if [[ $ret == *[\\\'$_ble_syntax_bash_IFS$_ble_term_fs]* ]]; then
    local a b fs=$_ble_term_fs
    a=\\   ; b="\\$a"; ret="${ret//"$a"/$b}"
    a=\'   ; b="\\$a"; ret="${ret//"$a"/$b}"
    a=' '  ; b="$_ble_syntax_bash_heredoc_EscSP"; ret="${ret//"$a"/$b}"
    a=$'\t'; b="$_ble_syntax_bash_heredoc_EscHT"; ret="${ret//"$a"/$b}"
    a=$'\n'; b="$_ble_syntax_bash_heredoc_EscLF"; ret="${ret//"$a"/$b}"
    a=$fs  ; b="$_ble_syntax_bash_heredoc_EscFS"; ret="${ret//"$a"/$b}"
  fi
  escaped=$ret
}
function ble/syntax:bash/ctx-heredoc-word/unescape-delimiter {
  eval "delimiter=\$'$1'"
}
_BLE_SYNTAX_FCTX[_ble_ctx_RDRH]=ble/syntax:bash/ctx-heredoc-word
_BLE_SYNTAX_FEND[_ble_ctx_RDRH]=ble/syntax:bash/ctx-heredoc-word/check-word-end
_BLE_SYNTAX_FCTX[_ble_ctx_RDRI]=ble/syntax:bash/ctx-heredoc-word
_BLE_SYNTAX_FEND[_ble_ctx_RDRI]=ble/syntax:bash/ctx-heredoc-word/check-word-end
function ble/syntax:bash/ctx-heredoc-word/check-word-end {
  ((wbegin<0)) && return 1
  ble/syntax:bash/check-word-end/is-delimiter || return 1
  local octx=$ctx word=${text:wbegin:i-wbegin}
  ble/syntax/parse/word-pop
  ble/syntax/parse/nest-pop
  local I
  if ((octx==_ble_ctx_RDRI)); then I=I; else I=R; fi
  local Q delimiter
  if [[ $word == *[\'\"\\]* ]]; then
    Q=Q; ble/syntax:bash/ctx-heredoc-word/remove-quotes "$word"
  else
    Q=H; delimiter=$word
  fi
  local escaped; ble/syntax:bash/ctx-heredoc-word/escape-delimiter "$delimiter"
  nparam=$nparam$_ble_term_fs@$I$Q$escaped
  return 0
}
function ble/syntax:bash/ctx-heredoc-word {
  ble/syntax:bash/ctx-redirect
}
_BLE_SYNTAX_FCTX[_ble_ctx_HERE0]=ble/syntax:bash/ctx-heredoc-content
_BLE_SYNTAX_FCTX[_ble_ctx_HERE1]=ble/syntax:bash/ctx-heredoc-content
function ble/syntax:bash/ctx-heredoc-content {
  local indented= quoted= delimiter=
  ble/syntax:bash/ctx-heredoc-word/unescape-delimiter "${nparam:2}"
  [[ ${nparam::1} == I ]] && indented=1
  [[ ${nparam:1:1} == Q ]] && quoted=1
  local rex ht=$'\t' lf=$'\n'
  if ((ctx==_ble_ctx_HERE0)); then
    rex="^${indented:+$ht*}"$'([^\n]+\n?|\n)'
    [[ $tail =~ $rex ]] || return 1
    local line=${BASH_REMATCH%"$lf"}
    local rematch1=${BASH_REMATCH[1]}
    if [[ ${rematch1%"$lf"} == "$delimiter" ]]; then
      local indent
      ((indent=${#BASH_REMATCH}-${#rematch1},
        _ble_syntax_attr[i]=_ble_ctx_HERE0,
        _ble_syntax_attr[i+indent]=_ble_ctx_RDRH,
        i+=${#line}))
      ble/syntax/parse/nest-pop
      return 0
    fi
  fi
  if [[ $quoted ]]; then
    ble/util/assert '((ctx==_ble_ctx_HERE0))'
    ((_ble_syntax_attr[i]=_ble_ctx_HERE0,i+=${#BASH_REMATCH}))
    return 0
  else
    ((ctx=_ble_ctx_HERE1))
    if rex='^([^$`\'"$lf"']|\\.)+'"$lf"'?|^'"$lf" && [[ $tail =~ $rex ]]; then
      ((_ble_syntax_attr[i]=_ble_ctx_HERE0,
        i+=${#BASH_REMATCH}))
      [[ $BASH_REMATCH == *"$lf" ]] && ((ctx=_ble_ctx_HERE0))
      return 0
    fi
    if ble/syntax:bash/check-dollar; then
      return 0
    elif [[ $tail == '`'* ]] && ble/syntax:bash/check-quotes; then
      return 0
    else
      ((_ble_syntax_attr[i]=_ble_ctx_HERE0,i++))
      return 0
    fi
  fi
}
function ble/syntax:bash/is-complete {
  local iN=${#_ble_syntax_text}
  ((iN>0)) && ((_ble_syntax_attr[iN-1]==_ble_attr_ERR)) && return 1
  local stat=${_ble_syntax_stat[iN]}
  if [[ $stat ]]; then
    stat=($stat)
    local nlen=${stat[3]}; ((nlen>=0)) && return 1
    local nparam=${stat[6]}; [[ $nparam == none ]] && nparam=
    local rex="$_ble_term_fs@([RI][QH][^$_ble_term_fs]*)(.*$)"
    [[ $nparam =~ $rex ]] && return 1
    local ctx=${stat[0]}
    ((ctx==_ble_ctx_ARGX||ctx==_ble_ctx_ARGX0||ctx==_ble_ctx_ARGVX||ctx==_ble_ctx_ARGEX||
        ctx==_ble_ctx_CMDX||ctx==_ble_ctx_CMDXT||ctx==_ble_ctx_CMDXE||ctx==_ble_ctx_CMDXV||
        ctx==_ble_ctx_TARGX1||ctx==_ble_ctx_TARGX2)) || return 1
  fi
  local attrs ret
  IFS= eval 'attrs="::${_ble_syntax_attr[*]/%/::}"'
  ble/string#count-string "$attrs" ":$_ble_attr_KEYWORD_BEGIN:"; local nbeg=$ret
  ble/string#count-string "$attrs" ":$_ble_attr_KEYWORD_END:"; local nend=$ret
  ((nbeg>nend)) && return 1
  return 0
}
function ble/syntax:bash/find-end-of-array-index {
  local beg=$1 end=$2
  ret=
  local inest0=$beg nest0
  [[ ${_ble_syntax_nest[inest0]} ]] || return 1
  local q stat1 nlen1 inest1 r=
  for ((q=inest0+1;q<end;q++)); do
    local stat1=${_ble_syntax_stat[q]}
    [[ $stat1 ]] || continue
    ble/string#split-words stat1 "$stat1"
    ((nlen1=stat1[3])) # (workaround Bash-4.2 segfault)
    ((inest1=nlen1<0?nlen1:q-nlen1))
    ((inest1<inest0)) && break
    ((r=q))
  done
  [[ ${_ble_syntax_text:r:end-r} == ']'* ]] && ret=$r
  [[ $ret ]]
}
function ble/syntax:bash/find-rhs {
  local wtype=$1 wbeg=$2 wlen=$3 opts=$4
  local text=$_ble_syntax_text
  local word=${text:wbeg:wlen} wend=$((wbeg+wlen))
  local rex=
  if ((wtype==_ble_attr_VAR)); then
    rex='^[a-zA-Z0-9_]+(\+?=|\[)'
  elif ((wtype==_ble_ctx_VALI)); then
    if [[ :$opts: == *:element-assignment:* ]]; then
      rex='^[a-zA-Z0-9_]+(\+?=|\[)|^(\[)'
    else
      rex='^(\[)'
    fi
  fi
  if [[ $rex && $word =~ $rex ]]; then
    local last_char=${BASH_REMATCH:${#BASH_REMATCH}-1}
    if [[ $last_char == '[' ]]; then
      local p1=$((wbeg+${#BASH_REMATCH}-1))
      if ble/syntax:bash/find-end-of-array-index "$p1" "$wend"; then
        local p2=$ret
        case ${text:p2:wend-p2} in
        (']='*)  ((ret=p2+2)); return 0 ;;
        (']+='*) ((ret=p2+3)); return 0 ;;
        esac
      fi
    else
      ((ret=wbeg+${#BASH_REMATCH}))
      return 0
    fi
  fi
  ret=$wbeg
  return 1
}
_ble_syntax_vanishing_word_umin=-1
_ble_syntax_vanishing_word_umax=-1
function ble/syntax/vanishing-word/register {
  local tree_array=$1 tofs=$2
  local beg=$3 end=$4 lbeg=$5 lend=$6
  (((beg<=0)&&(beg=1)))
  local node i nofs
  for ((i=end;i>=beg;i--)); do
    builtin eval "node=(\${$tree_array[tofs+i-1]})"
    ((${#node[@]})) || continue
    for ((nofs=0;nofs<${#node[@]};nofs+=_ble_syntax_TREE_WIDTH)); do
      local wtype=${node[nofs]} wlen=${node[nofs+1]}
      local wbeg=$((wlen<0?wlen:i-wlen)) wend=$i
      ((wbeg<lbeg&&(wbeg=lbeg),
        wend>lend&&(wend=lend)))
      ble/syntax/urange#update _ble_syntax_vanishing_word_ "$wbeg" "$wend"
    done
  done
}
function ble/syntax/parse/shift.stat {
  if [[ ${_ble_syntax_stat[j]} ]]; then
    local -a stat; ble/string#split-words stat "${_ble_syntax_stat[j]}"
    local k klen kbeg
    for k in 1 3 4 5; do
      (((klen=stat[k])<0)) && continue
      ((kbeg=j-klen))
      if ((kbeg<beg)); then
        ((stat[k]+=shift))
      elif ((kbeg<end0)); then
        ((stat[k]-=end0-kbeg))
      fi
    done
    _ble_syntax_stat[j]="${stat[*]}"
  fi
}
function ble/syntax/parse/shift.tree/1 {
  local k klen kbeg
  for k in 1 2 3; do
    ((klen=node[nofs+k]))
    ((klen<0||(kbeg=j-klen)>end0)) && continue
    if [[ $k == 1 && ${node[nofs]} =~ ^[0-9]$ ]]; then
      ble/syntax/parse/touch-updated-word "$j"
      node[nofs+4]='-'
    fi
    if ((kbeg<beg)); then
      ((node[nofs+k]+=shift))
    elif ((kbeg<end0)); then
      ((node[nofs+k]-=end0-kbeg))
    fi
  done
}
function ble/syntax/parse/shift.tree {
  [[ ${_ble_syntax_tree[j-1]} ]] || return
  local -a node
  ble/string#split-words node "${_ble_syntax_tree[j-1]}"
  local nofs
  if [[ $1 ]]; then
    nofs=$1 ble/syntax/parse/shift.tree/1
  else
    for ((nofs=0;nofs<${#node[@]};nofs+=_ble_syntax_TREE_WIDTH)); do
      ble/syntax/parse/shift.tree/1
    done
  fi
  _ble_syntax_tree[j-1]="${node[*]}"
}
function ble/syntax/parse/shift.nest {
  if [[ ${_ble_syntax_nest[j]} ]]; then
    local -a nest
    ble/string#split-words nest "${_ble_syntax_nest[j]}"
    local k klen kbeg
    for k in 1 3 4 5; do
      (((klen=nest[k])))
      ((klen<0||(kbeg=j-klen)<0)) && continue
      if ((kbeg<beg)); then
        ((nest[k]+=shift))
      elif ((kbeg<end0)); then
        ((nest[k]-=end0-kbeg))
      fi
    done
    _ble_syntax_nest[j]="${nest[*]}"
  fi
}
function ble/syntax/parse/shift.impl2/.shift-until {
  local limit=$1
  while ((j>=limit)); do
    [[ $ble_debug ]] && _ble_syntax_stat_shift[j+shift]=1
    ble/syntax/parse/shift.stat
    ble/syntax/parse/shift.nest
    ((j--))
  done
}
function ble/syntax/parse/shift.impl2/.proc1 {
  local j=$_shift2_j
  if ((i<j2)); then
    ((tprev=-1)) # 中断
    return
  fi
  ble/syntax/parse/shift.impl2/.shift-until $((i+1))
  ble/syntax/parse/shift.tree "$nofs"
  ((_shift2_j=j))
  if ((tprev>end0&&wbegin>end0)); then
    [[ $ble_debug ]] && _ble_syntax_stat_shift[j+shift]=1
    ble/syntax/parse/shift.stat
    ble/syntax/parse/shift.nest
    ((_shift2_j=wbegin)) # skip
  elif ((tchild>=0)); then
    ble/syntax/tree-enumerate-children ble/syntax/parse/shift.impl2/.proc1
  fi
}
function ble/syntax/parse/shift.method1 {
  local i j
  for ((i=i2,j=j2;i<=iN;i++,j++)); do
    ble/syntax/parse/shift.stat
    ((j>0))  && ble/syntax/parse/shift.tree
    ((i<iN)) && ble/syntax/parse/shift.nest
  done
}
function ble/syntax/parse/shift.method2 {
  [[ $ble_debug ]] && _ble_syntax_stat_shift=()
  local iN=${#_ble_syntax_text} # tree-enumerate 起点は (古い text の長さ) である
  local _shift2_j=$iN # proc1 に渡す変数
  ble/syntax/tree-enumerate ble/syntax/parse/shift.impl2/.proc1
  local j=$_shift2_j
  ble/syntax/parse/shift.impl2/.shift-until "$j2" # 未処理部分
}
function ble/syntax/parse/shift {
  ble/syntax/parse/shift.method2 # tree-enumerate による skip
  if ((shift!=0)); then
    ble/syntax/urange#shift _ble_syntax_attr_
    ble/syntax/wrange#shift _ble_syntax_word_
    ble/syntax/urange#shift _ble_syntax_vanishing_word_
  fi
}
_ble_syntax_dbeg=-1 _ble_syntax_dend=-1
function ble/syntax/parse/determine-parse-range {
  local flagSeekStat=0
  ((i1=_ble_syntax_dbeg,i1>=end0&&(i1+=shift),
    i2=_ble_syntax_dend,i2>=end0&&(i2+=shift),
    (i1<0||beg<i1)&&(i1=beg,flagSeekStat=1),
    (i2<0||i2<end)&&(i2=end),
    (i2>iN)&&(i2=iN),
    j2=i2-shift))
  if ((flagSeekStat)); then
    local lookahead='stat[7]'
    local -a stat
    while ((i1>0)); do
      if [[ ${_ble_syntax_stat[--i1]} ]]; then
        ble/string#split-words stat "${_ble_syntax_stat[i1]}"
        ((i1+lookahead<=beg)) && break
      fi
    done
  fi
  ((0<=i1&&i1<=beg&&end<=i2&&i2<=iN)) || ble/util/stackdump "X2 0 <= $i1 <= $beg <= $end <= $i2 <= $iN"
}
function ble/syntax/parse/check-end {
  [[ ${_BLE_SYNTAX_FEND[ctx]} ]] && "${_BLE_SYNTAX_FEND[ctx]}"
}
function ble/syntax/parse {
  local text=$1
  local beg=${2:-0} end=${3:-${#text}}
  local end0=${4:-$end}
  ((end==beg&&end0==beg&&_ble_syntax_dbeg<0)) && return
  local -r iN=${#text} shift=$((end-end0))
  if ! ((0<=beg&&beg<=end&&end<=iN&&beg<=end0)); then
    ble/util/stackdump "X1 0 <= beg:$beg <= end:$end <= iN:$iN, beg:$beg <= end0:$end0 (shift=$shift text=$text)"
    ((beg=0,end=iN))
  fi
  local i1 i2 j2
  ble/syntax/parse/determine-parse-range
  ble/syntax/vanishing-word/register _ble_syntax_tree 0 "$i1" "$j2" 0 "$i1"
  ble/syntax/parse/shift
  local ctx wbegin wtype inest tchild tprev nparam ilook
  if ((i1>0)) && [[ ${_ble_syntax_stat[i1]} ]]; then
    local -a stat
    ble/string#split-words stat "${_ble_syntax_stat[i1]}"
    local wlen=${stat[1]} nlen=${stat[3]} tclen=${stat[4]} tplen=${stat[5]}
    ctx=${stat[0]}
    wbegin=$((wlen<0?wlen:i1-wlen))
    wtype=${stat[2]}
    inest=$((nlen<0?nlen:i1-nlen))
    tchild=$((tclen<0?tclen:i1-tclen))
    tprev=$((tplen<0?tplen:i1-tplen))
    nparam=${stat[6]}; [[ $nparam == none ]] && nparam=
    ilook=$((i1+${stat[7]:-1}))
  else
    ctx=$_ble_ctx_UNSPECIFIED ##!< 現在の解析の文脈
    ble/syntax:"$_ble_syntax_lang"/initialize-ctx # ctx 初期化
    wbegin=-1       ##!< シェル単語内にいる時、シェル単語の開始位置
    wtype=-1        ##!< シェル単語内にいる時、シェル単語の種類
    inest=-1        ##!< 入れ子の時、親の開始位置
    tchild=-1
    tprev=-1
    nparam=
    ilook=1
  fi
  local -a _tail_syntax_stat _tail_syntax_tree _tail_syntax_nest _tail_syntax_attr
  _tail_syntax_stat=("${_ble_syntax_stat[@]:j2:iN-i2+1}")
  _tail_syntax_tree=("${_ble_syntax_tree[@]:j2:iN-i2}")
  _tail_syntax_nest=("${_ble_syntax_nest[@]:j2:iN-i2}")
  _tail_syntax_attr=("${_ble_syntax_attr[@]:j2:iN-i2}")
  ble/array#reserve-prototype "$iN"
  _ble_syntax_stat=("${_ble_syntax_stat[@]::i1}" "${_ble_array_prototype[@]:i1:iN-i1}") # 再開用データ
  _ble_syntax_tree=("${_ble_syntax_tree[@]::i1}" "${_ble_array_prototype[@]:i1:iN-i1}") # 単語
  _ble_syntax_nest=("${_ble_syntax_nest[@]::i1}" "${_ble_array_prototype[@]:i1:iN-i1}") # 入れ子の親
  _ble_syntax_attr=("${_ble_syntax_attr[@]::i1}" "${_ble_array_prototype[@]:i1:iN-i1}") # 文脈・色とか
  ble/syntax:"$_ble_syntax_lang"/initialize-vars
  _ble_syntax_text=$text
  local i _stat tail
  local debug_p1
  for ((i=i1;i<iN;)); do
    ble/syntax/parse/generate-stat
    if ((i>=i2)) && [[ ${_tail_syntax_stat[i-i2]} == "$_stat" ]]; then
      if ble/syntax/parse/nest-equals "$inest"; then
        _ble_syntax_stat=("${_ble_syntax_stat[@]::i}" "${_tail_syntax_stat[@]:i-i2}")
        _ble_syntax_tree=("${_ble_syntax_tree[@]::i}" "${_tail_syntax_tree[@]:i-i2}")
        _ble_syntax_nest=("${_ble_syntax_nest[@]::i}" "${_tail_syntax_nest[@]:i-i2}")
        _ble_syntax_attr=("${_ble_syntax_attr[@]::i}" "${_tail_syntax_attr[@]:i-i2}")
        break
      fi
    fi
    _ble_syntax_stat[i]=$_stat
    tail=${text:i}
    debug_p1=$i
    "${_BLE_SYNTAX_FCTX[ctx]}" || ((_ble_syntax_attr[i]=_ble_attr_ERR,i++))
    ble/syntax/parse/check-end
  done
  unset -v debug_p1
  ble/syntax/vanishing-word/register _tail_syntax_tree $((-i2)) $((i2+1)) "$i" 0 "$i"
  ble/syntax/urange#update _ble_syntax_attr_ "$i1" "$i"
  (((i>=i2)?(
      _ble_syntax_dbeg=_ble_syntax_dend=-1
    ):(
      _ble_syntax_dbeg=i,_ble_syntax_dend=i2)))
  if ((i>=iN)); then
    ((i=iN))
    ble/syntax/parse/generate-stat
    _ble_syntax_stat[i]=$_stat
    if ((inest>0)); then
      ((_ble_syntax_attr[iN-1]=_ble_attr_ERR))
      while ((inest>=0)); do
        ((i=inest))
        ble/syntax/parse/nest-pop
        ((inest>=i&&(inest=i-1)))
      done
    fi
  fi
  ((${#_ble_syntax_stat[@]}==iN+1)) ||
    ble/util/stackdump "unexpected array length #arr=${#_ble_syntax_stat[@]} (expected to be $iN), #proto=${#_ble_array_prototype[@]} should be >= $iN"
}
function ble/syntax/completion-context/.add {
  local source=$1
  local comp1=$2
  ble/util/assert '[[ $source && comp1 -ge 0 ]]'
  sources[${#sources[*]}]="$source $comp1"
}
function ble/syntax/completion-context/.check/parameter-expansion {
  local rex_paramx='^(\$(\{[!#]?)?)([a-zA-Z_][a-zA-Z_0-9]*)?$'
  if [[ ${text:istat:index-istat} =~ $rex_paramx ]]; then
    local rematch1=${BASH_REMATCH[1]}
    local source=variable
    [[ $rematch1 == '${'* ]] && source=variable:b
    ble/syntax/completion-context/.add "$source" $((istat+${#rematch1}))
  fi
}
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CMDI]=inside-command
function ble/syntax/completion-context/.check-prefix/ctx:inside-command {
  if ((wlen>=0)); then
    ble/syntax/completion-context/.add command "$wbeg"
    if [[ ${text:wbeg:index-wbeg} =~ $rex_param ]]; then
      ble/syntax/completion-context/.add variable:= "$wbeg"
    fi
  fi
  ble/syntax/completion-context/.check/parameter-expansion
}
_ble_syntax_bash_complete_check_prefix[_ble_ctx_ARGI]='inside-argument argument'
_ble_syntax_bash_complete_check_prefix[_ble_ctx_ARGQ]='inside-argument argument'
_ble_syntax_bash_complete_check_prefix[_ble_ctx_FARGI1]='inside-argument variable:w'
_ble_syntax_bash_complete_check_prefix[_ble_ctx_FARGI3]='inside-argument argument'
_ble_syntax_bash_complete_check_prefix[_ble_ctx_FARGQ3]='inside-argument argument'
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CARGI1]='inside-argument argument'
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CARGQ1]='inside-argument argument'
_ble_syntax_bash_complete_check_prefix[_ble_ctx_VALI]='inside-argument file'
_ble_syntax_bash_complete_check_prefix[_ble_ctx_VALQ]='inside-argument file'
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CONDI]='inside-argument file'
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CONDQ]='inside-argument file'
_ble_syntax_bash_complete_check_prefix[_ble_ctx_ARGVI]='inside-argument variable:='
_ble_syntax_bash_complete_check_prefix[_ble_ctx_ARGEI]='inside-argument variable:= command file'
function ble/syntax/completion-context/.check-prefix/ctx:inside-argument {
  if ((wlen>=0)); then
    local source
    for source; do
      ble/syntax/completion-context/.add "$source" "$wbeg"
      if [[ $source != argument ]]; then
        local sub=${text:wbeg:index-wbeg}
        if [[ $sub == *[=:]* ]]; then
          sub=${sub##*[=:]}
          ble/syntax/completion-context/.add "$source" $((index-${#sub}))
        fi
      fi
    done
  fi
  ble/syntax/completion-context/.check/parameter-expansion
}
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CMDX]=next-command
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CMDX1]=next-command
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CMDXT]=next-command
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CMDXV]=next-command
function ble/syntax/completion-context/.check-prefix/ctx:next-command {
  local word=${text:istat:index-istat}
  if ble/syntax:bash/simple-word/is-simple-or-open-simple "$word"; then
    ble/syntax/completion-context/.add command "$istat"
    if local rex='^[a-zA-Z_][a-zA-Z_0-9]*(\+?=)?$' && [[ $word =~ $rex ]]; then
      if [[ $word == *= ]]; then
        if ((_ble_bash>=30100)) || [[ $word != *+= ]]; then
          ble/syntax/completion-context/.add argument "$index"
        fi
      else
        ble/syntax/completion-context/.add variable:= "$istat"
      fi
    fi
  elif [[ $word =~ ^$_ble_syntax_bash_RexSpaces$ ]]; then
    shopt -q no_empty_cmd_completion ||
      ble/syntax/completion-context/.add command "$index"
  fi
  ble/syntax/completion-context/.check/parameter-expansion
}
_ble_syntax_bash_complete_check_prefix[_ble_ctx_ARGX]=next-argument
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CARGX1]=next-argument
_ble_syntax_bash_complete_check_prefix[_ble_ctx_FARGX3]=next-argument
_ble_syntax_bash_complete_check_prefix[_ble_ctx_ARGVX]=next-argument
_ble_syntax_bash_complete_check_prefix[_ble_ctx_ARGEX]=next-argument
_ble_syntax_bash_complete_check_prefix[_ble_ctx_VALX]=next-argument
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CONDX]=next-argument
_ble_syntax_bash_complete_check_prefix[_ble_ctx_RDRS]=next-argument
function ble/syntax/completion-context/.check-prefix/ctx:next-argument {
  local source
  if ((ctx==_ble_ctx_ARGX||ctx==_ble_ctx_CARGX1||ctx==_ble_ctx_FARGX3)); then
    source=(argument)
  elif ((ctx==_ble_ctx_ARGVX)); then
    source=(variable:=)
  elif ((ctx==_ble_ctx_ARGEX)); then
    source=(variable:= command file)
  else
    source=(file)
  fi
  local word=${text:istat:index-istat}
  if ble/syntax:bash/simple-word/is-simple-or-open-simple "$word"; then
    local src
    for src in "${source[@]}"; do
      ble/syntax/completion-context/.add "$src" "$istat"
      if [[ $src != argument ]]; then
        local rex="^([^'\"\$\\]|\\.)*="
        if [[ $word =~ $rex ]]; then
          word=${word:${#BASH_REMATCH}}
          ble/syntax/completion-context/.add "$src" $((index-${#word}))
        fi
      fi
    done
  elif [[ $word =~ ^$_ble_syntax_bash_RexSpaces$ ]]; then
    local src
    for src in "${source[@]}"; do
      ble/syntax/completion-context/.add "$src" "$index"
    done
  fi
  ble/syntax/completion-context/.check/parameter-expansion
}
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CMDXC]=next-compound
function ble/syntax/completion-context/.check-prefix/ctx:next-compound {
  local rex word=${text:istat:index-istat}
  if [[ ${text:istat:index-istat} =~ $rex_param ]]; then
    ble/syntax/completion-context/.add wordlist:-r:'for:select:case:if:while:until' "$istat"
  elif rex='^[[({]+$'; [[ $word =~ $rex ]]; then
    ble/syntax/completion-context/.add wordlist:-r:'(:{:((:[[' "$istat"
  fi
}
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CMDXE]="next-identifier wordlist:-r:'fi:done:esac:then:elif:else:do'"
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CMDXD0]="next-identifier wordlist:-r:';:{:do'"
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CMDXD]="next-identifier wordlist:-r:'{:do'"
_ble_syntax_bash_complete_check_prefix[_ble_ctx_FARGX1]="next-identifier variable:w" # _ble_ctx_FARGX1 → (( でなければ 変数名
_ble_syntax_bash_complete_check_prefix[_ble_ctx_SARGX1]="next-identifier variable:w"
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CARGX2]="next-identifier wordlist:-r:'in'"
_ble_syntax_bash_complete_check_prefix[_ble_ctx_CARGI2]="next-identifier wordlist:-r:'in'"
_ble_syntax_bash_complete_check_prefix[_ble_ctx_FARGX2]="next-identifier wordlist:-r:'in:do'"
_ble_syntax_bash_complete_check_prefix[_ble_ctx_FARGI2]="next-identifier wordlist:-r:'in:do'"
function ble/syntax/completion-context/.check-prefix/ctx:next-identifier {
  local source=$1
  if [[ ${text:istat:index-istat} =~ $rex_param ]]; then
    ble/syntax/completion-context/.add "$source" "$istat"
  fi
}
_ble_syntax_bash_complete_check_prefix[_ble_ctx_TARGX1]=time-argument
_ble_syntax_bash_complete_check_prefix[_ble_ctx_TARGI1]=time-argument
_ble_syntax_bash_complete_check_prefix[_ble_ctx_TARGX2]=time-argument
_ble_syntax_bash_complete_check_prefix[_ble_ctx_TARGI2]=time-argument
function ble/syntax/completion-context/.check-prefix/ctx:time-argument {
  ble/syntax/completion-context/.add command "$istat"
  if ((ctx==_ble_ctx_TARGX1)); then
    local rex='^-p?$'
    [[ ${text:istat:index-istat} =~ $rex ]] &&
      ble/syntax/completion-context/.add wordlist:--:'-p' "$istat"
  elif ((ctx==_ble_ctx_TARGX2)); then
    local rex='^--?$'
    [[ ${text:istat:index-istat} =~ $rex ]] &&
      ble/syntax/completion-context/.add wordlist:--:'--' "$istat"
  fi
}
_ble_syntax_bash_complete_check_prefix[_ble_ctx_QUOT]=quote
function ble/syntax/completion-context/.check-prefix/ctx:quote {
  ble/syntax/completion-context/.check/parameter-expansion
  ble/syntax/completion-context/.check-prefix/ctx:quote/.check-container-word
}
function ble/syntax/completion-context/.check-prefix/ctx:quote/.check-container-word {
  local nlen=${stat[3]}; ((nlen>=0)) || return
  local inest=$((nlen<0?nlen:istat-nlen))
  local nest; ble/string#split-words nest "${_ble_syntax_nest[inest]}"
  [[ ${nest[0]} ]] || return
  local wlen2=${nest[1]}; ((wlen2>=0)) || return
  local wbeg2=$((wlen2<0?wlen2:inest-wlen2))
  if ble/syntax:bash/simple-word/is-simple-or-open-simple "${text:wbeg2:index-wbeg2}"; then
    ble/syntax/completion-context/.add argument "$wbeg2"
  fi
}
_ble_syntax_bash_complete_check_prefix[_ble_ctx_RDRF]=redirection
function ble/syntax/completion-context/.check-prefix/ctx:redirection {
  local p=$((wlen>=0?wbeg:istat))
  if ble/syntax:bash/simple-word/is-simple-or-open-simple "${text:p:index-p}"; then
    ble/syntax/completion-context/.add file "$p"
  fi
}
_ble_syntax_bash_complete_check_prefix[_ble_ctx_VRHS]=rhs
_ble_syntax_bash_complete_check_prefix[_ble_ctx_ARGVR]=rhs
_ble_syntax_bash_complete_check_prefix[_ble_ctx_ARGER]=rhs
_ble_syntax_bash_complete_check_prefix[_ble_ctx_VALR]=rhs
function ble/syntax/completion-context/.check-prefix/ctx:rhs {
  if ((wlen>=0)); then
    local p=$wbeg
    local rex='^[a-zA-Z0-9_]+(\+?=|\[)'
    ((ctx==_ble_ctx_VALR)) && rex='^(\[)'
    if [[ ${text:p:index-p} =~ $rex ]]; then
      if [[ ${BASH_REMATCH[1]} == '[' ]]; then
        local p1=$((wbeg+${#BASH_REMATCH}-1))
        if local ret; ble/syntax:bash/find-end-of-array-index "$p1" "$index"; then
          local p2=$ret
          case ${_ble_syntax_text:p2:index-p2} in
          (']='*)  ((p=p2+2)) ;;
          (']+='*) ((p=p2+3)) ;;
          (']+')
            ble/syntax/completion-context/.add wordlist:-rW:'+=' $((p2+1))
            p= ;;
          esac
        fi
      else
        ((p+=${#BASH_REMATCH}))
      fi
    fi
  else
    local p=$istat
  fi
  if [[ $p ]] && ble/syntax:bash/simple-word/is-simple-or-open-simple "${text:p:index-p}"; then
    ble/syntax/completion-context/.add rhs "$p"
  fi
}
_ble_syntax_bash_complete_check_prefix[_ble_ctx_PARAM]=param
function ble/syntax/completion-context/.check-prefix/ctx:param {
  local tail=${text:istat:index-istat}
  if [[ $tail == : ]]; then
    return
  elif [[ $tail == '}'* ]]; then
    local nlen=${stat[3]}
    local inest=$((nlen<0?nlen:istat-nlen))
    ((0<=inest&&inest<istat)) &&
      ble/syntax/completion-context/.check-prefix "$inest"
    return
  else
    return
  fi
}
_ble_syntax_bash_complete_check_prefix[_ble_ctx_EXPR]=expr
function ble/syntax/completion-context/.check-prefix/ctx:expr {
  local tail=${text:istat:index-istat} rex='[a-zA-Z_]+$'
  if [[ $tail =~ $rex ]]; then
    local p=$((index-${#BASH_REMATCH}))
    ble/syntax/completion-context/.add variable:a "$p"
    return
  elif [[ $tail == ']'* ]]; then
    local inest=... ntype
    local nlen=${stat[3]}; ((nlen>=0)) || return
    local inest=$((istat-nlen))
    ble/syntax/parse/nest-type -v ntype # ([in] inest; [out] ntype)
    if [[ $ntype == [ad]'[' ]]; then
      if [[ $tail == ']' ]]; then
        ble/syntax/completion-context/.add wordlist:-rW:'=' $((istat+1))
      elif ((_ble_bash>=30100)) && [[ $tail == ']+' ]]; then
        ble/syntax/completion-context/.add wordlist:-rW:'+=' $((istat+1))
      elif [[ $tail == ']=' || _ble_bash -ge 30100 && $tail == ']+=' ]]; then
        ble/syntax/completion-context/.add rhs "$index"
      fi
    fi
  fi
}
_ble_syntax_bash_complete_check_prefix[_ble_ctx_BRACE1]=brace
_ble_syntax_bash_complete_check_prefix[_ble_ctx_BRACE2]=brace
function ble/syntax/completion-context/.check-prefix/ctx:brace {
  local ctx1=$ctx istat1=$istat nlen1=${stat[3]}
  ((nlen1>=0)) || return 1
  local inest1=$((istat1-nlen1))
  while :; do
    local nest=${_ble_syntax_nest[inest1]}
    [[ $nest ]] || return 1
    ble/string#split-words nest "$nest"
    ctx1=${nest[0]}
    ((ctx1==_ble_ctx_BRACE1||ctx1==_ble_ctx_BRACE2)) || break
    inest1=${nest[3]}
    ((inest1>=0)) || return 1
  done
  for ((istat1=inest1;1;istat1--)); do
    ((istat1>=0)) || return 1
    [[ ${_ble_syntax_stat[istat1]} ]] && break
  done
  local stat1
  ble/string#split-words stat1 "${_ble_syntax_stat[istat1]}"
  local wlen=${stat1[1]}
  local wbeg=$((wlen>=0?istat1-wlen:istat1))
  ble/syntax/completion-context/.add argument "$wbeg"
}
function ble/syntax/completion-context/.search-last-istat {
  local index=$1 istat
  for ((istat=index;istat>=0;istat--)); do
    if [[ ${_ble_syntax_stat[istat]} ]]; then
      ret=$istat
      return 0
    fi
  done
  ret=
  return 1
}
function ble/syntax/completion-context/.check-prefix {
  local rex_param='^[a-zA-Z_][a-zA-Z_0-9]*$'
  local from=${1:-$((index-1))}
  local ret
  ble/syntax/completion-context/.search-last-istat "$from" || return
  local istat=$ret stat
  ble/string#split-words stat "${_ble_syntax_stat[istat]}"
  [[ ${stat[0]} ]] || return
  local ctx=${stat[0]} wlen=${stat[1]}
  local wbeg=$((wlen<0?wlen:istat-wlen))
  local name=${_ble_syntax_bash_complete_check_prefix[ctx]}
  if [[ $name ]]; then
    builtin eval "ble/syntax/completion-context/.check-prefix/ctx:$name"
  fi
}
function ble/syntax/completion-context/.check-here {
  ((${#sources[*]})) && return
  local -a stat
  ble/string#split-words stat "${_ble_syntax_stat[index]}"
  if [[ ${stat[0]} ]]; then
    local ctx=${stat[0]}
    if ((ctx==_ble_ctx_CMDX||ctx==_ble_ctx_CMDXV||ctx==_ble_ctx_CMDX1||ctx==_ble_ctx_CMDXT)); then
      if ! shopt -q no_empty_cmd_completion; then
        ble/syntax/completion-context/.add command "$index"
        ble/syntax/completion-context/.add variable:= "$index"
      fi
    elif ((ctx==_ble_ctx_CMDXC)); then
      ble/syntax/completion-context/.add wordlist:-r:'(:{:((:[[:for:select:case:if:while:until' "$index"
    elif ((ctx==_ble_ctx_CMDXE)); then
      ble/syntax/completion-context/.add wordlist:-r:'}:fi:done:esac:then:elif:else:do' "$index"
    elif ((ctx==_ble_ctx_CMDXD0)); then
      ble/syntax/completion-context/.add wordlist:-r:';:{:do' "$index"
    elif ((ctx==_ble_ctx_CMDXD)); then
      ble/syntax/completion-context/.add wordlist:-r:'{:do' "$index"
    elif ((ctx==_ble_ctx_ARGX||ctx==_ble_ctx_CARGX1||ctx==_ble_ctx_FARGX3)); then
      ble/syntax/completion-context/.add argument "$index"
    elif ((ctx==_ble_ctx_FARGX1||ctx==_ble_ctx_SARGX1)); then
      ble/syntax/completion-context/.add variable:w "$index"
    elif ((ctx==_ble_ctx_CARGX2)); then
      ble/syntax/completion-context/.add wordlist:-r:'in' "$index"
    elif ((ctx==_ble_ctx_FARGX2)); then
      ble/syntax/completion-context/.add wordlist:-r:'in:do' "$index"
    elif ((ctx==_ble_ctx_TARGX1)); then
      ble/syntax/completion-context/.add command "$index"
      ble/syntax/completion-context/.add wordlist:--:'-p' "$index"
    elif ((ctx==_ble_ctx_TARGX2)); then
      ble/syntax/completion-context/.add command "$index"
      ble/syntax/completion-context/.add wordlist:--:'--' "$index"
    elif ((ctx==_ble_ctx_RDRF||ctx==_ble_ctx_RDRS)); then
      ble/syntax/completion-context/.add file "$index"
    elif ((ctx==_ble_ctx_VRHS||ctx==_ble_ctx_ARGVR||ctx==_ble_ctx_ARGER||ctx==_ble_ctx_VALR)); then
      ble/syntax/completion-context/.add rhs "$index"
    fi
  fi
}
function ble/syntax/completion-context/generate {
  local text=$1 index=$2
  sources=()
  ((index<0&&(index=0)))
  ble/syntax/completion-context/.check-prefix
  ble/syntax/completion-context/.check-here
}
function ble/syntax:bash/extract-command/.register-word {
  local wtxt=${_ble_syntax_text:wbegin:wlen}
  if [[ ! $comp_cword ]] && ((wbegin<=pos)); then
    if ((pos<=wbegin+wlen)); then
      comp_cword=${#comp_words[@]}
      comp_point=$((${#comp_line}+wbegin+wlen-pos))
      comp_line="$wtxt$comp_line"
      ble/array#push comp_words "$wtxt"
    else
      comp_cword=${#comp_words[@]}
      comp_point=${#comp_line}
      comp_line="$wtxt $comp_line"
      ble/array#push comp_words "" "$wtxt"
    fi
  else
    comp_line="$wtxt$comp_line"
    ble/array#push comp_words "$wtxt"
  fi
}
function ble/syntax:bash/extract-command/.construct-proc {
  if [[ $wtype =~ ^[0-9]+$ ]]; then
    if ((wtype==_ble_ctx_CMDI)); then
      if ((pos<wbegin)); then
        comp_line= comp_point= comp_cword= comp_words=()
      else
        ble/syntax:bash/extract-command/.register-word
        ble/syntax/tree-enumerate-break
        extract_command_found=1
        return
      fi
    elif ((wtype==_ble_ctx_ARGI||wtype==_ble_ctx_ARGVI||wtype==_ble_ctx_ARGEI)); then
      ble/syntax:bash/extract-command/.register-word
      comp_line=" $comp_line"
    fi
  fi
}
function ble/syntax:bash/extract-command/.construct {
  comp_line= comp_point= comp_cword= comp_words=()
  if [[ $1 == nested ]]; then
    ble/syntax/tree-enumerate-children \
      ble/syntax:bash/extract-command/.construct-proc
  else
    ble/syntax/tree-enumerate \
      ble/syntax:bash/extract-command/.construct-proc
  fi
  ble/array#reverse comp_words
  ((comp_cword=${#comp_words[@]}-1-comp_cword,
    comp_point=${#comp_line}-comp_point))
}
function ble/syntax:bash/extract-command/.scan {
  ((pos<wbegin)) && return
  if ((wbegin+wlen<pos)); then
    ble/syntax/tree-enumerate-break
  else
    local extract_has_word=
    ble/syntax/tree-enumerate-children \
      ble/syntax:bash/extract-command/.scan
    local has_word=$extract_has_word
    ble/util/unlocal extract_has_word
    if [[ $has_word && ! $extract_command_found ]]; then
      ble/syntax:bash/extract-command/.construct nested
      ble/syntax/tree-enumerate-break
    fi
  fi
  if [[ $wtype =~ ^[0-9]+$ && ! $extract_has_word ]]; then
    extract_has_word=$wtype
    return
  fi
}
function ble/syntax:bash/extract-command {
  local pos=$1
  local extract_command_found=
  local extract_has_word=
  ble/syntax/tree-enumerate \
    ble/syntax:bash/extract-command/.scan
  if [[ ! $extract_command_found && $extract_has_word ]]; then
    ble/syntax:bash/extract-command/.construct
  fi
  [[ $extract_command_found ]]
}
_ble_syntax_attr2iface=()
function ble/syntax/attr2g { ble/color/initialize-faces && ble/syntax/attr2g "$@"; }
function ble/syntax/faces-onload-hook {
  function ble/syntax/attr2iface/.define {
    ((_ble_syntax_attr2iface[$1]=_ble_faces__$2))
  }
  function ble/syntax/attr2g {
    local iface=${_ble_syntax_attr2iface[$1]:-_ble_faces__syntax_default}
    g=${_ble_faces[iface]}
  }
  ble/color/defface syntax_default           none
  ble/color/defface syntax_command           fg=brown
  ble/color/defface syntax_quoted            fg=green
  ble/color/defface syntax_quotation         fg=green,bold
  ble/color/defface syntax_expr              fg=26
  ble/color/defface syntax_error             bg=203,fg=231 # bg=224
  ble/color/defface syntax_varname           fg=202
  ble/color/defface syntax_delimiter         bold
  ble/color/defface syntax_param_expansion   fg=purple
  ble/color/defface syntax_history_expansion bg=94,fg=231
  ble/color/defface syntax_function_name     fg=92,bold # fg=purple
  ble/color/defface syntax_comment           fg=242
  ble/color/defface syntax_glob              fg=198,bold
  ble/color/defface syntax_brace             fg=37,bold
  ble/color/defface syntax_tilde             fg=navy,bold
  ble/color/defface syntax_document          fg=94
  ble/color/defface syntax_document_begin    fg=94,bold
  ble/color/defface command_builtin_dot fg=red,bold
  ble/color/defface command_builtin     fg=red
  ble/color/defface command_alias       fg=teal
  ble/color/defface command_function    fg=92 # fg=purple
  ble/color/defface command_file        fg=green
  ble/color/defface command_keyword     fg=blue
  ble/color/defface command_jobs        fg=red
  ble/color/defface command_directory   fg=26,underline
  ble/color/defface filename_directory        underline,fg=26
  ble/color/defface filename_directory_sticky underline,fg=white,bg=26
  ble/color/defface filename_link             underline,fg=teal
  ble/color/defface filename_orphan           underline,fg=teal,bg=224
  ble/color/defface filename_setuid           underline,fg=black,bg=220
  ble/color/defface filename_setgid           underline,fg=black,bg=191
  ble/color/defface filename_executable       underline,fg=green
  ble/color/defface filename_other            underline
  ble/color/defface filename_socket           underline,fg=cyan,bg=black
  ble/color/defface filename_pipe             underline,fg=lime,bg=black
  ble/color/defface filename_character        underline,fg=white,bg=black
  ble/color/defface filename_block            underline,fg=yellow,bg=black
  ble/color/defface filename_warning          underline,fg=red
  ble/color/defface filename_ls_colors        underline
  ble/syntax/attr2iface/.define _ble_ctx_ARGX     syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_ARGX0    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_ARGI     syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_ARGQ     syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_ARGVX    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_ARGVI    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_ARGVR    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_ARGEX    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_ARGEI    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_ARGER    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CMDX     syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CMDX1    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CMDXT    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CMDXC    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CMDXE    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CMDXD    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CMDXD0   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CMDXV    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CMDI     syntax_command
  ble/syntax/attr2iface/.define _ble_ctx_VRHS     syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_QUOT     syntax_quoted
  ble/syntax/attr2iface/.define _ble_ctx_EXPR     syntax_expr
  ble/syntax/attr2iface/.define _ble_attr_ERR     syntax_error
  ble/syntax/attr2iface/.define _ble_attr_VAR     syntax_varname
  ble/syntax/attr2iface/.define _ble_attr_QDEL    syntax_quotation
  ble/syntax/attr2iface/.define _ble_attr_DEF     syntax_default
  ble/syntax/attr2iface/.define _ble_attr_DEL     syntax_delimiter
  ble/syntax/attr2iface/.define _ble_ctx_PARAM    syntax_param_expansion
  ble/syntax/attr2iface/.define _ble_ctx_PWORD    syntax_default
  ble/syntax/attr2iface/.define _ble_attr_HISTX   syntax_history_expansion
  ble/syntax/attr2iface/.define _ble_attr_FUNCDEF syntax_function_name
  ble/syntax/attr2iface/.define _ble_ctx_VALX     syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_VALI     syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_VALR     syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_VALQ     syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CONDX    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CONDI    syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CONDQ    syntax_default
  ble/syntax/attr2iface/.define _ble_attr_COMMENT syntax_comment
  ble/syntax/attr2iface/.define _ble_ctx_CASE     syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_PATN     syntax_default
  ble/syntax/attr2iface/.define _ble_attr_GLOB    syntax_glob
  ble/syntax/attr2iface/.define _ble_ctx_BRAX     syntax_default
  ble/syntax/attr2iface/.define _ble_attr_BRACE   syntax_brace
  ble/syntax/attr2iface/.define _ble_ctx_BRACE1   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_BRACE2   syntax_default
  ble/syntax/attr2iface/.define _ble_attr_TILDE   syntax_tilde
  ble/syntax/attr2iface/.define _ble_ctx_SARGX1   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_FARGX1   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_FARGX2   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_FARGX3   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_FARGI1   syntax_varname
  ble/syntax/attr2iface/.define _ble_ctx_FARGI2   command_keyword
  ble/syntax/attr2iface/.define _ble_ctx_FARGI3   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_FARGQ3   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CARGX1   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CARGX2   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CARGI1   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CARGQ1   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_CARGI2   command_keyword
  ble/syntax/attr2iface/.define _ble_ctx_TARGX1   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_TARGX2   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_TARGI1   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_TARGI2   syntax_default
  ble/syntax/attr2iface/.define _ble_ctx_RDRH    syntax_document_begin
  ble/syntax/attr2iface/.define _ble_ctx_RDRI    syntax_document_begin
  ble/syntax/attr2iface/.define _ble_ctx_HERE0   syntax_document
  ble/syntax/attr2iface/.define _ble_ctx_HERE1   syntax_document
  ble/syntax/attr2iface/.define _ble_attr_CMD_BOLD      command_builtin_dot
  ble/syntax/attr2iface/.define _ble_attr_CMD_BUILTIN   command_builtin
  ble/syntax/attr2iface/.define _ble_attr_CMD_ALIAS     command_alias
  ble/syntax/attr2iface/.define _ble_attr_CMD_FUNCTION  command_function
  ble/syntax/attr2iface/.define _ble_attr_CMD_FILE      command_file
  ble/syntax/attr2iface/.define _ble_attr_CMD_JOBS      command_jobs
  ble/syntax/attr2iface/.define _ble_attr_CMD_DIR       command_directory
  ble/syntax/attr2iface/.define _ble_attr_KEYWORD       command_keyword
  ble/syntax/attr2iface/.define _ble_attr_KEYWORD_BEGIN command_keyword
  ble/syntax/attr2iface/.define _ble_attr_KEYWORD_END   command_keyword
  ble/syntax/attr2iface/.define _ble_attr_KEYWORD_MID   command_keyword
  ble/syntax/attr2iface/.define _ble_attr_FILE_DIR      filename_directory
  ble/syntax/attr2iface/.define _ble_attr_FILE_STICKY   filename_directory_sticky
  ble/syntax/attr2iface/.define _ble_attr_FILE_LINK     filename_link
  ble/syntax/attr2iface/.define _ble_attr_FILE_ORPHAN   filename_orphan
  ble/syntax/attr2iface/.define _ble_attr_FILE_FILE     filename_other
  ble/syntax/attr2iface/.define _ble_attr_FILE_SETUID   filename_setuid
  ble/syntax/attr2iface/.define _ble_attr_FILE_SETGID   filename_setgid
  ble/syntax/attr2iface/.define _ble_attr_FILE_EXEC     filename_executable
  ble/syntax/attr2iface/.define _ble_attr_FILE_WARN     filename_warning
  ble/syntax/attr2iface/.define _ble_attr_FILE_FIFO     filename_pipe
  ble/syntax/attr2iface/.define _ble_attr_FILE_SOCK     filename_socket
  ble/syntax/attr2iface/.define _ble_attr_FILE_BLK      filename_block
  ble/syntax/attr2iface/.define _ble_attr_FILE_CHR      filename_character
}
ble/array#push _ble_color_faces_defface_hook ble/syntax/faces-onload-hook
function ble/syntax/highlight/cmdtype1 {
  type=$1
  local cmd=$2
  case "$type:$cmd" in
  (builtin::|builtin:.)
    ((type=_ble_attr_CMD_BOLD)) ;;
  (builtin:*)
    ((type=_ble_attr_CMD_BUILTIN)) ;;
  (alias:*)
    ((type=_ble_attr_CMD_ALIAS)) ;;
  (function:*)
    ((type=_ble_attr_CMD_FUNCTION)) ;;
  (file:*)
    ((type=_ble_attr_CMD_FILE)) ;;
  (keyword:*)
    ((type=_ble_attr_KEYWORD)) ;;
  (*:%*)
    ble/util/joblist.check
    if jobs -- "$cmd" &>/dev/null; then
      ((type=_ble_attr_CMD_JOBS))
    else
      ((type=_ble_attr_ERR))
    fi ;;
  (*)
    if [[ -d "$cmd" ]] && shopt -q autocd &>/dev/null; then
      ((type=_ble_attr_CMD_DIR))
    else
      ((type=_ble_attr_ERR))
    fi ;;
  esac
}
function ble/syntax/highlight/cmdtype/.impl {
  local cmd=$1 _0=$2
  local btype; ble/util/type btype "$cmd"
  ble/syntax/highlight/cmdtype1 "$btype" "$cmd"
  if [[ $type == "$_ble_attr_CMD_ALIAS" && $cmd != "$_0" ]]; then
    type=$(
      unalias "$cmd"
      ble/util/type btype "$cmd"
      ble/syntax/highlight/cmdtype1 "$btype" "$cmd"
      builtin echo -n "$type")
  elif [[ $type == "$_ble_attr_KEYWORD" ]]; then
    ble/util/joblist.check
    if [[ ! ${cmd##%*} ]] && jobs -- "$cmd" &>/dev/null; then
      ((type=_ble_attr_CMD_JOBS))
    elif ble/is-function "$cmd"; then
      ((type=_ble_attr_CMD_FUNCTION))
    elif enable -p | ble/bin/grep -q -F -x "enable $cmd" &>/dev/null; then
      ((type=_ble_attr_CMD_BUILTIN))
    elif type -P -- "$cmd" &>/dev/null; then
      ((type=_ble_attr_CMD_FILE))
    else
      ((type=_ble_attr_ERR))
    fi
  fi
}
if ((_ble_bash>=40200||_ble_bash>=40000&&!_ble_bash_loaded_in_function)); then
  _ble_syntax_highlight_filetype_version=-1
  function ble/syntax/highlight/cmdtype {
    local cmd=$1 _0=$2
    if ((_ble_syntax_highlight_filetype_version!=_ble_edit_LINENO)); then
      _ble_syntax_highlight_filetype=()
      ((_ble_syntax_highlight_filetype_version=_ble_edit_LINENO))
    fi
    type=${_ble_syntax_highlight_filetype[x$_0]}
    [[ $type ]] && return
    ble/syntax/highlight/cmdtype/.impl "$cmd" "$_0"
    _ble_syntax_highlight_filetype["x$_0"]=$type
  }
else
  _ble_syntax_highlight_filetype=()
  _ble_syntax_highlight_filetype_version=-1
  function ble/syntax/highlight/cmdtype {
    local cmd=$1 _0=$2
    if ((_ble_syntax_highlight_filetype_version!=_ble_edit_LINENO)); then
      _ble_syntax_highlight_filetype=()
      ((_ble_syntax_highlight_filetype_version=_ble_edit_LINENO))
    fi
    local i iN
    for ((i=0,iN=${#_ble_syntax_highlight_filetype[@]}/2;i<iN;i++)); do
      if [[ ${_ble_syntax_highlight_filetype[2*i]} == x"$_0" ]]; then
        type=${_ble_syntax_highlight_filetype[2*i+1]}
        return
      fi
    done
    ble/syntax/highlight/cmdtype/.impl "$cmd" "$_0"
    _ble_syntax_highlight_filetype[2*iN]=x$_0
    _ble_syntax_highlight_filetype[2*iN+1]=$type
  }
fi
function ble/syntax/highlight/filetype {
  local file=$1
  type=
  if [[ -h $file ]]; then
    if [[ -e $file ]]; then
      ((type=_ble_attr_FILE_LINK))
    else
      ((type=_ble_attr_FILE_ORPHAN))
    fi
  elif [[ -e $file ]]; then
    if [[ -d $file ]]; then
      if [[ -k $file ]]; then
        ((type=_ble_attr_FILE_STICKY))
      else
        ((type=_ble_attr_FILE_DIR))
      fi
    elif [[ -f $file ]]; then
      if [[ -u $file ]]; then
        ((type=_ble_attr_FILE_SETUID))
      elif [[ -g $file ]]; then
        ((type=_ble_attr_FILE_SETGID))
      elif [[ -x $file ]]; then
        ((type=_ble_attr_FILE_EXEC))
      else
        ((type=_ble_attr_FILE_FILE))
      fi
    elif [[ -c $file ]]; then
      ((type=_ble_attr_FILE_CHR))
    elif [[ -p $file ]]; then
      ((type=_ble_attr_FILE_FIFO))
    elif [[ -S $file ]]; then
      ((type=_ble_attr_FILE_SOCK))
    elif [[ -b $file ]]; then
      ((type=_ble_attr_FILE_BLK))
    fi
  fi
}
function ble/syntax/highlight/ls_colors/.clear {
  _ble_syntax_highlight_lscolors=()
  _ble_syntax_highlight_lscolors_ext=()
}
if ((_ble_bash>=40200||_ble_bash>=40000&&!_ble_bash_loaded_in_function)); then
  function ble/syntax/highlight/ls_colors/.register-extension {
    local key=$1 value=$2
    _ble_syntax_highlight_lscolors_ext[$key]=$value
  }
  function ble/syntax/highlight/ls_colors/.read-extension {
    ret=${_ble_syntax_highlight_lscolors_ext[$1]}
    [[ $ret ]]
  }
else
  function ble/syntax/highlight/ls_colors/.find-extension {
    local key=$1
    local i N=${#_ble_syntax_highlight_lscolors_ext[@]}
    for ((i=0;i<N;i+=2)); do
      [[ ${_ble_syntax_highlight_lscolors_ext[i]} == "$key" ]] && break
    done
    ret=$i
  }
  function ble/syntax/highlight/ls_colors/.register-extension {
    local key=$1 value=$2 ret
    ble/syntax/highlight/ls_colors/.find-extension "$key"
    _ble_syntax_highlight_lscolors_ext[ret]=$key
    _ble_syntax_highlight_lscolors_ext[ret+1]=$value
  }
  function ble/syntax/highlight/ls_colors/.read-extension {
    local key=$1
    ble/syntax/highlight/ls_colors/.find-extension "$key"
    ret=${_ble_syntax_highlight_lscolors_ext[ret+1]}
    [[ $ret ]]
  }
fi
function ble/syntax/highlight/ls_colors/.parse {
  ble/syntax/highlight/ls_colors/.clear
  local fields field
  ble/string#split fields : "$1"
  for field in "${fields[@]}"; do
    [[ $field == *=* ]] || continue
    local lhs=${field%%=*}
    local ret; ble/color/sgrspec2g "${field#*=}"; local rhs=$ret
    case $lhs in
    ('di') _ble_syntax_highlight_lscolors[_ble_attr_FILE_DIR]=$rhs  ;;
    ('st') _ble_syntax_highlight_lscolors[_ble_attr_FILE_STICKY]=$rhs  ;;
    ('ln') _ble_syntax_highlight_lscolors[_ble_attr_FILE_LINK]=$rhs ;;
    ('or') _ble_syntax_highlight_lscolors[_ble_attr_FILE_ORPHAN]=$rhs ;;
    ('fi') _ble_syntax_highlight_lscolors[_ble_attr_FILE_FILE]=$rhs ;;
    ('su') _ble_syntax_highlight_lscolors[_ble_attr_FILE_SETUID]=$rhs ;;
    ('sg') _ble_syntax_highlight_lscolors[_ble_attr_FILE_SETGID]=$rhs ;;
    ('ex') _ble_syntax_highlight_lscolors[_ble_attr_FILE_EXEC]=$rhs ;;
    ('cd') _ble_syntax_highlight_lscolors[_ble_attr_FILE_CHR]=$rhs  ;;
    ('pi') _ble_syntax_highlight_lscolors[_ble_attr_FILE_FIFO]=$rhs ;;
    ('so') _ble_syntax_highlight_lscolors[_ble_attr_FILE_SOCK]=$rhs ;;
    ('bd') _ble_syntax_highlight_lscolors[_ble_attr_FILE_BLK]=$rhs  ;;
    (\*.*)
      ble/syntax/highlight/ls_colors/.register-extension "${lhs:2}" "$rhs" ;;
    esac
  done
}
function ble/syntax/highlight/ls_colors {
  local file=$1
  if ((type==_ble_attr_FILE_FILE)); then
    local ext=${file##*/} ret=
    while [[ $ext == *.* ]]; do
      ext=${ext#*.}
      [[ $ext ]] || break
      if ble/syntax/highlight/ls_colors/.read-extension "$ext"; then
        type=g:$ret
        return 0
      fi
    done
  fi
  local g=${_ble_syntax_highlight_lscolors[type]}
  if [[ $g ]]; then
    type=g:$g
    return 0
  fi
  return 1
}
function ble/syntax/highlight/getg-from-filename {
  local filename=$1 type=
  ble/syntax/highlight/filetype "$filename"
  if [[ $bleopt_filename_ls_colors ]]; then
    if ble/syntax/highlight/ls_colors "$filename" && [[ $type == g:* ]]; then
      ble/color/face2g filename_ls_colors
      ((g|=${type:2}))
      return
    fi
  fi
  if [[ $type ]]; then
    ble/syntax/attr2g "$type"
  else
    g=
  fi
}
function bleopt/check:filename_ls_colors {
  ble/syntax/highlight/ls_colors/.parse "$value"
}
value=$bleopt_filename_ls_colors bleopt/check:filename_ls_colors
function ble/highlight/layer:syntax/touch-range {
  ble/syntax/urange#update '' "$@"
}
function ble/highlight/layer:syntax/fill {
  local _i _arr=$1 _i1=$2 _i2=$3 _v=$4
  for ((_i=_i1;_i<_i2;_i++)); do
    eval "$_arr[_i]=\"\$_v\""
  done
}
_ble_highlight_layer_syntax_buff=()
_ble_highlight_layer_syntax1_table=()
_ble_highlight_layer_syntax2_table=()
_ble_highlight_layer_syntax3_list=()
_ble_highlight_layer_syntax3_table=() # errors
function ble/highlight/layer:syntax/update-attribute-table {
  ble/highlight/layer/update/shift _ble_highlight_layer_syntax1_table
  if ((_ble_syntax_attr_umin>=0)); then
    ble/highlight/layer:syntax/touch-range _ble_syntax_attr_umin _ble_syntax_attr_umax
    local i g=0
    ((_ble_syntax_attr_umin>0)) &&
      ((g=_ble_highlight_layer_syntax1_table[_ble_syntax_attr_umin-1]))
    for ((i=_ble_syntax_attr_umin;i<_ble_syntax_attr_umax;i++)); do
      if ((${_ble_syntax_attr[i]})); then
        ble/syntax/attr2g "${_ble_syntax_attr[i]}"
      fi
      _ble_highlight_layer_syntax1_table[i]=$g
    done
    _ble_syntax_attr_umin=-1 _ble_syntax_attr_umax=-1
  fi
}
function ble/highlight/layer:syntax/word/.update-attributes/.proc {
  [[ ${node[nofs]} =~ ^[0-9]+$ ]] || return
  [[ ${node[nofs+4]} == - ]] || return
  ble/syntax/urange#update color_ "$wbeg" "$wend"
  local p0=$wbeg p1=$((wbeg+wlen))
  if ((wtype==_ble_attr_VAR||wtype==_ble_ctx_VALI)); then
    local ret
    ble/syntax:bash/find-rhs "$wtype" "$wbeg" "$wlen" element-assignment && p0=$ret
  fi
  local type=
  if ((wtype==_ble_ctx_RDRH||wtype==_ble_ctx_RDRI)); then
    ((type=wtype))
  elif local wtxt=${text:p0:p1-p0}; ble/syntax:bash/simple-word/is-simple "$wtxt"; then
    local ret
    if ((wtype==_ble_ctx_RDRS||wtype==_ble_attr_VAR||wtype==_ble_ctx_VALI&&wbeg<p0)); then
      ble/syntax:bash/simple-word/eval-noglob "$wtxt"; local ext=$? value=$ret
    else
      ble/syntax:bash/simple-word/eval "$wtxt"; local ext=$?
      local -a value; value=("${ret[@]}")
    fi
    if ((ext&&(wtype==_ble_ctx_CMDI||wtype==_ble_ctx_ARGI||wtype==_ble_ctx_RDRF||wtype==_ble_ctx_RDRS||wtype==_ble_ctx_VALI))); then
      type=$_ble_attr_ERR
    elif (((wtype==_ble_ctx_RDRF||wtype==_ble_ctx_RDRD)&&${#value[@]}>=2)); then
      type=$_ble_attr_ERR
    elif ((wtype==_ble_ctx_CMDI)); then
      local attr=${_ble_syntax_attr[wbeg]}
      if ((attr!=_ble_attr_KEYWORD&&attr!=_ble_attr_KEYWORD_BEGIN&&attr!=_ble_attr_KEYWORD_END&&attr!=_ble_attr_KEYWORD_MID&&attr!=_ble_attr_DEL)); then
        ble/syntax/highlight/cmdtype "$value" "$wtxt"
      fi
    elif ((wtype==_ble_attr_FUNCDEF||wtype==_ble_attr_ERR)); then
      ((type=wtype))
    elif ((wtype==_ble_ctx_ARGI||wtype==_ble_ctx_RDRF||wtype==_ble_ctx_RDRS||wtype==_ble_attr_VAR||wtype==_ble_ctx_VALI)); then
      ble/syntax/highlight/filetype "$value"
      if ((wtype==_ble_ctx_RDRF)); then
        if ((type==_ble_attr_FILE_DIR)); then
          type=$_ble_attr_ERR
        elif ((_ble_syntax_TREE_WIDTH<=nofs)); then
          local redirect_ntype=${node[nofs-_ble_syntax_TREE_WIDTH]:1}
          if [[ ( $redirect_ntype == *'>' || $redirect_ntype == '>|' ) ]]; then
            if [[ -e $value || -h $value ]]; then
              if [[ -d $value || ! -w $value ]]; then
                type=$_ble_attr_ERR
              elif [[ ( $redirect_ntype == [\<\&]'>' || $redirect_ntype == '>' ) && -f $value ]]; then
                if [[ -o noclobber ]]; then
                  type=$_ble_attr_ERR
                else
                  type=$_ble_attr_FILE_WARN
                fi
              fi
            elif [[ $value == */* && ! -w ${value%/*}/ || $value != */* && ! -w ./ ]]; then
              type=$_ble_attr_ERR
            fi
          elif [[ $redirect_ntype == '<' && ! -r $value ]]; then
            type=$_ble_attr_ERR
          fi
        fi
      fi
      if [[ $bleopt_filename_ls_colors ]]; then
        if ble/syntax/highlight/ls_colors "$value" && [[ $type == g:* ]]; then
          local g; ble/color/face2g filename_ls_colors
          type=g:$((${type:2}|g))
        fi
      fi
    fi
  fi
  if [[ $type ]]; then
    if [[ $type == g:* ]]; then
      local g=${type:2}
    else
      local g; ble/syntax/attr2g "$type"
    fi
    if ((wbeg<p0)); then
      node[nofs+4]=m$((p0-wbeg)):d,\$:$g
    else
      node[nofs+4]=${g:-d}
    fi
  else
    node[nofs+4]='d'
  fi
  flagUpdateNode=1
}
function ble/highlight/layer:syntax/word/.update-attributes {
  ((_ble_syntax_word_umin>=0)) || return
  ble/syntax/tree-enumerate-in-range "$_ble_syntax_word_umin" "$_ble_syntax_word_umax" \
    ble/highlight/layer:syntax/word/.update-attributes/.proc
}
function ble/highlight/layer:syntax/word/.apply-attribute {
  local wbeg=$1 wend=$2 wattr=$3
  ((wbeg<color_umin&&(wbeg=color_umin),
    wend>color_umax&&(wend=color_umax),
    wbeg<wend)) || return
  if [[ $wattr =~ ^[0-9]+$ ]]; then
    ble/highlight/layer:syntax/fill _ble_highlight_layer_syntax2_table "$wbeg" "$wend" "$wattr"
  elif [[ $wattr == m* ]]; then
    local ranges; ble/string#split ranges , "${wattr:1}"
    local i=$wbeg j range
    for range in "${ranges[@]}"; do
      local len=${range%%:*} sub_wattr=${range#*:}
      if [[ $len == '$' ]]; then
        j=$wend
      else
        ((j=i+len,j>wend&&(j=wend)))
      fi
      ble/highlight/layer:syntax/word/.apply-attribute "$i" "$j" "$sub_wattr"
      (((i=j)<wend)) || break
    done
  elif [[ $wattr == d ]]; then
    ble/highlight/layer:syntax/fill _ble_highlight_layer_syntax2_table "$wbeg" "$wend" ''
  fi
}
function ble/highlight/layer:syntax/word/.proc-childnode {
  if [[ $wtype =~ ^[0-9]+$ ]]; then
    local wbeg=$wbegin wend=$i
    ble/highlight/layer:syntax/word/.apply-attribute "$wbeg" "$wend" "$attr"
  fi
  ((tchild>=0)) && ble/syntax/tree-enumerate-children "$proc_children"
}
function ble/highlight/layer:syntax/update-word-table {
  local color_umin=-1 color_umax=-1 iN=${#_ble_syntax_text}
  ble/highlight/layer:syntax/word/.update-attributes
  ble/highlight/layer/update/shift _ble_highlight_layer_syntax2_table
  ble/syntax/wrange#update _ble_syntax_word_ "$_ble_syntax_vanishing_word_umin" "$_ble_syntax_vanishing_word_umax"
  ble/syntax/wrange#update color_ "$_ble_syntax_vanishing_word_umin" "$_ble_syntax_vanishing_word_umax"
  _ble_syntax_vanishing_word_umin=-1 _ble_syntax_vanishing_word_umax=-1
  ble/highlight/layer:syntax/word/.apply-attribute 0 "$iN" d # clear word color
  local i
  for ((i=_ble_syntax_word_umax;i>=_ble_syntax_word_umin;)); do
    if ((i>0)) && [[ ${_ble_syntax_tree[i-1]} ]]; then
      local -a node
      ble/string#split-words node "${_ble_syntax_tree[i-1]}"
      local wlen=${node[1]}
      local wbeg=$((i-wlen)) wend=$i
      if [[ ${node[0]} =~ ^[0-9]+$ ]]; then
        local attr=${node[4]}
        ble/highlight/layer:syntax/word/.apply-attribute "$wbeg" "$wend" "$attr"
      fi
      local tclen=${node[2]}
      if ((tclen>=0)); then
        local tchild=$((i-tclen))
        local tree= nofs=0 proc_children=ble/highlight/layer:syntax/word/.proc-childnode
        ble/syntax/tree-enumerate-children "$proc_children"
      fi
      ((i=wbeg))
    else
      ((i--))
    fi
  done
  ((color_umin>=0)) && ble/highlight/layer:syntax/touch-range "$color_umin" "$color_umax"
  _ble_syntax_word_umin=-1 _ble_syntax_word_umax=-1
}
function ble/highlight/layer:syntax/update-error-table/set {
  local i1=$1 i2=$2 g=$3
  if ((i1<i2)); then
    ble/highlight/layer:syntax/touch-range "$i1" "$i2"
    ble/highlight/layer:syntax/fill _ble_highlight_layer_syntax3_table "$i1" "$i2" "$g"
    _ble_highlight_layer_syntax3_list[${#_ble_highlight_layer_syntax3_list[@]}]="$i1 $i2"
  fi
}
function ble/highlight/layer:syntax/update-error-table {
  ble/highlight/layer/update/shift _ble_highlight_layer_syntax3_table
  local j=0 jN=${#_ble_highlight_layer_syntax3_list[*]}
  if ((jN)); then
    for ((j=0;j<jN;j++)); do
      local -a range
      range=(${_ble_highlight_layer_syntax3_list[j]})
      local a=${range[0]} b=${range[1]}
      ((a>=DMAX0?(a+=DMAX-DMAX0):(a>=DMIN&&(a=DMIN)),
        b>=DMAX0?(b+=DMAX-DMAX0):(b>=DMIN&&(b=DMIN))))
      if ((a<b)); then
        ble/highlight/layer:syntax/fill _ble_highlight_layer_syntax3_table "$a" "$b" ''
        ble/highlight/layer:syntax/touch-range "$a" "$b"
      fi
    done
    _ble_highlight_layer_syntax3_list=()
  fi
  if ((iN>0)) && [[ ${_ble_syntax_stat[iN]} ]]; then
    local g; ble/color/face2g syntax_error
    local -a stat
    ble/string#split-words stat "${_ble_syntax_stat[iN]}"
    local ctx=${stat[0]} nlen=${stat[3]} nparam=${stat[6]}
    [[ $nparam == none ]] && nparam=
    local i inest
    if ((nlen>0)) || [[ $nparam ]]; then
      ble/highlight/layer:syntax/update-error-table/set $((iN-1)) "$iN" "$g"
      if ((nlen>0)); then
        ((inest=iN-nlen))
        while ((inest>=0)); do
          local inest2
          for((inest2=inest+1;inest2<iN;inest2++)); do
            [[ ${_ble_syntax_attr[inest2]} ]] && break
          done
          ble/highlight/layer:syntax/update-error-table/set "$inest" "$inest2" "$g"
          ((i=inest))
          local wtype wbegin tchild tprev
          ble/syntax/parse/nest-pop
          ((inest>=i&&(inest=i-1)))
        done
      fi
    fi
    if ((ctx==_ble_ctx_CMDX1||ctx==_ble_ctx_CMDXC||ctx==_ble_ctx_FARGX1||ctx==_ble_ctx_SARGX1||ctx==_ble_ctx_FARGX2||ctx==_ble_ctx_CARGX1||ctx==_ble_ctx_CARGX2)); then
      ble/highlight/layer:syntax/update-error-table/set $((iN-1)) "$iN" "$g"
    fi
  fi
}
function ble/highlight/layer:syntax/update {
  local text=$1 player=$2
  local i iN=${#text}
  ble-edit/content/update-syntax
  local umin=-1 umax=-1
  ((DMIN>=0)) && umin=$DMIN umax=$DMAX
  if [[ $ble_debug ]]; then
    local debug_attr_umin=$_ble_syntax_attr_umin
    local debug_attr_uend=$_ble_syntax_attr_umax
  fi
  ble/highlight/layer:syntax/update-attribute-table
  ble/highlight/layer:syntax/update-word-table
  ble/highlight/layer:syntax/update-error-table
  if ((DMIN>=0)); then
    ble/highlight/layer/update/shift _ble_highlight_layer_syntax_buff
    if ((DMAX>0)); then
      local g sgr ch ret
      ble/highlight/layer:syntax/getg "$DMAX"
      ble/color/g2sgr "$g"; sgr=$ret
      ch=${_ble_highlight_layer_plain_buff[DMAX]}
      _ble_highlight_layer_syntax_buff[DMAX]=$sgr$ch
    fi
  fi
  local i j g gprev=0
  if ((umin>0)); then
    ble/highlight/layer:syntax/getg $((umin-1))
    gprev=$g
  fi
  if ((umin>=0)); then
    local ret
    for ((i=umin;i<=umax;i++)); do
      local ch=${_ble_highlight_layer_plain_buff[i]}
      ble/highlight/layer:syntax/getg "$i"
      [[ $g ]] || ble/highlight/layer/update/getg "$i"
      if ((gprev!=g)); then
        ble/color/g2sgr "$g"
        ch=$ret$ch
        ((gprev=g))
      fi
      _ble_highlight_layer_syntax_buff[i]=$ch
    done
  fi
  PREV_UMIN=$umin PREV_UMAX=$umax
  PREV_BUFF=_ble_highlight_layer_syntax_buff
  if [[ $ble_debug ]]; then
    local status buff= nl=$'\n'
    _ble_syntax_attr_umin=$debug_attr_umin _ble_syntax_attr_umax=$debug_attr_uend ble/syntax/print-status -v status
    ble/util/assign buff 'declare -p _ble_highlight_layer_plain_buff _ble_highlight_layer_syntax_buff | ble/bin/cat -A'; status="$status${buff%$nl}$nl"
    ble/util/assign buff 'declare -p _ble_highlight_layer_disabled_buff _ble_highlight_layer_region_buff _ble_highlight_layer_overwrite_mode_buff | ble/bin/cat -A'; status="$status${buff%$nl}$nl"
    ble-edit/info/show ansi "$status"
  fi
}
function ble/highlight/layer:syntax/getg {
  local i=$1
  if [[ ${_ble_highlight_layer_syntax3_table[i]} ]]; then
    g=${_ble_highlight_layer_syntax3_table[i]}
  elif [[ ${_ble_highlight_layer_syntax2_table[i]} ]]; then
    g=${_ble_highlight_layer_syntax2_table[i]}
  elif [[ ${_ble_highlight_layer_syntax1_table[i]} ]]; then
    g=${_ble_highlight_layer_syntax1_table[i]}
  else
    g=
  fi
}
function ble/syntax/import { :; }
ble/function#try ble/textarea#invalidate str
