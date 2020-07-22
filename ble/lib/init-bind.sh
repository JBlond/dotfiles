# this script is a part of blesh (https://github.com/akinomyoga/ble.sh) under BSD-3-Clause license
function ble/init:bind/append {
  local xarg="\"$1\":ble-decode/.hook $2; builtin eval \"\$_ble_decode_bind_hook\""
  local rarg=$1 condition=$3
  echo "$condition${condition:+ && }builtin bind -x '${xarg//$apos/$APOS}'" >> "$fbind1"
  echo "$condition${condition:+ && }builtin bind -r '${rarg//$apos/$APOS}'" >> "$fbind2"
}
function ble/init:bind/bind-s {
  local sarg="$1"
  echo "builtin bind '${sarg//$apos/$APOS}'" >> "$fbind1"
}
function ble/init:bind/bind-r {
  local rarg="$1"
  echo "builtin bind -r '${rarg//$apos/$APOS}'" >> "$fbind2"
}
function ble/init:bind/generate-binder {
  local fbind1=$_ble_base_cache/ble-decode-bind.$_ble_bash.$bleopt_input_encoding.bind
  local fbind2=$_ble_base_cache/ble-decode-bind.$_ble_bash.$bleopt_input_encoding.unbind
  ble-edit/info/show text "ble.sh: updating binders..."
  : >| "$fbind1"
  : >| "$fbind2"
  local apos=\' APOS="'\\''"
  local esc00=$((_ble_bash>=40300))
  local bind18XX=$((_ble_bash<40300||40400<=_ble_bash&&_ble_bash<50000))
  local esc1B=3
  local esc1B5B=1 bindAllSeq=0
  local esc1B1B=$((40100<=_ble_bash&&_ble_bash<40300))
  local i
  for i in {128..255} {0..127}; do
    local ret; ble-decode-bind/c2dqs "$i"
    if ((i==0)); then
      if ((esc00)); then
        ble/init:bind/bind-s '"\C-@":"\xC0\x80"'
        ble/init:bind/bind-r '\C-@'
      else
        ble/init:bind/append "$ret" "$i"
      fi
    elif ((i==24)); then
      if ((bind18XX)); then
        ble/init:bind/append "$ret" "$i" '[[ ! -o emacs ]]'
      else
        ble/init:bind/append "$ret" "$i"
      fi
    elif ((i==27)); then
      if ((esc1B==0)); then
        ble/init:bind/append "$ret" "$i"
      elif ((esc1B==2)); then
        ble/init:bind/bind-s '"\e":"\xC0\x9B"'
        ble/init:bind/bind-r '\e'
      elif ((esc1B==3)); then
        ble/init:bind/bind-s '"\e":"\xDF\xBF"' # C-[
        ble/init:bind/bind-r '\e'
      fi
    else
      ((i==28&&_ble_bash>=50000)) && ret='\x1C'
      ble/init:bind/append "$ret" "$i"
    fi
    ((bind18XX)) && ble/init:bind/append "$ret" "24 $i" '[[ -o emacs ]]'
    if ((esc1B==3)); then
      ble/init:bind/bind-s '"\e'"$ret"'":"\xC0\x9B'"$ret"'"'
      ble/init:bind/bind-r '\e'"$ret"
    else
      if ((esc1B==1)); then
        if ((i==91&&esc1B5B)); then
          ble/init:bind/bind-s '"\e[":"\xC0\x9B["'
          ble/init:bind/bind-r '\e['
        else
          ble/init:bind/append "\\e$ret" "27 $i"
        fi
      fi
      if ((i==27&&esc1B1B)); then
        ble/init:bind/bind-s '"\e\e":"\e[^"'
        echo "ble-bind -k 'ESC [ ^' __esc__"                >> "$fbind1"
        echo "ble-bind -f __esc__ '.ble-decode-char 27 27'" >> "$fbind1"
        ble/init:bind/bind-r '\e\e'
      fi
    fi
  done
  if ((bindAllSeq)); then
    echo 'source "$_ble_decode_bind_fbinder.bind"' >> "$fbind1"
    echo 'source "$_ble_decode_bind_fbinder.unbind"' >> "$fbind2"
  fi
  ble/function#try ble/encoding:"$bleopt_input_encoding"/generate-binder
  ble-edit/info/immediate-show text "ble.sh: updating binders... done"
}
ble/init:bind/generate-binder
