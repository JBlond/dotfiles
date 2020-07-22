# this script is a part of blesh (https://github.com/akinomyoga/ble.sh) under BSD-3-Clause license
function ble/init:cmap/bind-keypad-key {
  local Ft=$1 name=$2
  ble-bind --csi "$Ft" "$name"
  (($3&1)) && ble-bind -k "ESC O $Ft" "$name"
  (($3&2)) && ble-bind -k "ESC ? $Ft" "$name"
}
function ble/init:cmap/initialize {
  ble-edit/info/immediate-show text "ble/lib/init-cmap.sh: updating key sequences..."
  ble-decode-kbd/generate-keycode insert
  ble-decode-kbd/generate-keycode home
  ble-decode-kbd/generate-keycode prior
  ble-decode-kbd/generate-keycode delete
  ble-decode-kbd/generate-keycode end
  ble-decode-kbd/generate-keycode next
  local kend; ble/util/assign kend 'tput @7 2>/dev/null || tput kend 2>/dev/null'
  if [[ $kend == $'\e[5~' ]]; then
    ble-bind --csi '1~' insert
    ble-bind --csi '2~' home
    ble-bind --csi '3~' prior
    ble-bind --csi '4~' delete
    ble-bind --csi '5~' end
    ble-bind --csi '6~' next
  else
    ble-bind --csi '1~' home
    ble-bind --csi '2~' insert
    ble-bind --csi '3~' delete
    ble-bind --csi '4~' end
    ble-bind --csi '5~' prior
    ble-bind --csi '6~' next
  fi
  ble-bind --csi '7~' home
  ble-bind --csi '8~' end
  ble-bind --csi '11~' f1
  ble-bind --csi '12~' f2
  ble-bind --csi '13~' f3
  ble-bind --csi '14~' f4
  ble-bind --csi '15~' f5
  ble-bind --csi '17~' f6
  ble-bind --csi '18~' f7
  ble-bind --csi '19~' f8
  ble-bind --csi '20~' f9
  ble-bind --csi '21~' f10
  ble-bind --csi '23~' f11
  ble-bind --csi '24~' f12
  ble-bind --csi '25~' f13
  ble-bind --csi '26~' f14
  ble-bind --csi '28~' f15
  ble-bind --csi '29~' f16
  ble-bind --csi '31~' f17
  ble-bind --csi '32~' f18
  ble-bind --csi '33~' f19
  ble-bind --csi '34~' f20
  ble-bind --csi '200~' paste_begin
  ble-bind --csi '201~' paste_end
  ble-bind -k 'ESC ? SP' SP # kpspace
  ble-bind -k 'ESC O SP' SP # kpspace
  ble/init:cmap/bind-keypad-key 'A' up    1
  ble/init:cmap/bind-keypad-key 'B' down  1
  ble/init:cmap/bind-keypad-key 'C' right 1
  ble/init:cmap/bind-keypad-key 'D' left  1
  ble/init:cmap/bind-keypad-key 'E' begin 1
  ble/init:cmap/bind-keypad-key 'F' end   1
  ble/init:cmap/bind-keypad-key 'H' home  1
  ble/init:cmap/bind-keypad-key 'I' TAB   3 # kptab
  ble/init:cmap/bind-keypad-key 'M' RET   3 # kpent
  ble/init:cmap/bind-keypad-key 'P' f1    1 # kpf1 # Note: 普通の f1-f4
  ble/init:cmap/bind-keypad-key 'Q' f2    1 # kpf2 #   に対してこれらの
  ble/init:cmap/bind-keypad-key 'R' f3    1 # kpf3 #   シーケンスを送る
  ble/init:cmap/bind-keypad-key 'S' f4    1 # kpf4 #   端末もある。
  ble/init:cmap/bind-keypad-key 'j' '*'   3 # kpmul
  ble/init:cmap/bind-keypad-key 'k' '+'   3 # kpadd
  ble/init:cmap/bind-keypad-key 'l' ','   3 # kpsep
  ble/init:cmap/bind-keypad-key 'm' '-'   3 # kpsub
  ble/init:cmap/bind-keypad-key 'n' '.'   3 # kpdec
  ble/init:cmap/bind-keypad-key 'o' '/'   3 # kpdiv
  ble/init:cmap/bind-keypad-key 'p' '0'   3 # kp0
  ble/init:cmap/bind-keypad-key 'q' '1'   3 # kp1
  ble/init:cmap/bind-keypad-key 'r' '2'   3 # kp2
  ble/init:cmap/bind-keypad-key 's' '3'   3 # kp3
  ble/init:cmap/bind-keypad-key 't' '4'   3 # kp4
  ble/init:cmap/bind-keypad-key 'u' '5'   3 # kp5
  ble/init:cmap/bind-keypad-key 'v' '6'   3 # kp6
  ble/init:cmap/bind-keypad-key 'w' '7'   3 # kp7
  ble/init:cmap/bind-keypad-key 'x' '8'   3 # kp8
  ble/init:cmap/bind-keypad-key 'y' '9'   3 # kp9
  ble/init:cmap/bind-keypad-key 'X' '='   3 # kpeq
  ble-bind -k 'ESC [ Z'     S-TAB
  ble-bind -k 'ESC O a'     C-up
  ble-bind -k 'ESC [ a'     S-up
  ble-bind -k 'ESC O b'     C-down
  ble-bind -k 'ESC [ b'     S-down
  ble-bind -k 'ESC O c'     C-right
  ble-bind -k 'ESC [ c'     S-right
  ble-bind -k 'ESC O d'     C-left
  ble-bind -k 'ESC [ d'     S-left
  ble-bind -k 'ESC [ 2 $'   S-insert # ECMA-48 違反
  ble-bind -k 'ESC [ 3 $'   S-delete # ECMA-48 違反
  ble-bind -k 'ESC [ 5 $'   S-prior  # ECMA-48 違反
  ble-bind -k 'ESC [ 6 $'   S-next   # ECMA-48 違反
  ble-bind -k 'ESC [ 7 $'   S-home   # ECMA-48 違反
  ble-bind -k 'ESC [ 8 $'   S-end    # ECMA-48 違反
  ble-bind -k 'ESC [ 2 3 $' S-f11    # ECMA-48 違反
  ble-bind -k 'ESC [ 2 4 $' S-f12    # ECMA-48 違反
  ble-bind -k 'ESC [ 2 5 $' S-f13    # ECMA-48 違反
  ble-bind -k 'ESC [ 2 6 $' S-f14    # ECMA-48 違反
  ble-bind -k 'ESC [ 2 8 $' S-f15    # ECMA-48 違反
  ble-bind -k 'ESC [ 2 9 $' S-f16    # ECMA-48 違反
  ble-bind -k 'ESC [ 3 1 $' S-f17    # ECMA-48 違反
  ble-bind -k 'ESC [ 3 2 $' S-f18    # ECMA-48 違反
  ble-bind -k 'ESC [ 3 3 $' S-f19    # ECMA-48 違反
  ble-bind -k 'ESC [ 3 4 $' S-f20    # ECMA-48 違反
  ble-bind -k 'ESC [ [ A' f1
  ble-bind -k 'ESC [ [ B' f2
  ble-bind -k 'ESC [ [ C' f3
  ble-bind -k 'ESC [ [ D' f4
  ble-bind -k 'ESC [ [ E' f5
  ble-edit/info/immediate-show text "ble/lib/init-cmap.sh: updating key sequences... done"
}
ble/init:cmap/initialize
