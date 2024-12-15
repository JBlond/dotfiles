function busy --wraps='cat /dev/urandom | hexdump -C | grep "ca fe"' --description 'alias busy=cat /dev/urandom | hexdump -C | grep "ca fe"'
  cat /dev/urandom | hexdump -C | grep "ca fe" $argv
        
end
