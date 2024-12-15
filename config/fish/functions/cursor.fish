function cursor --wraps=echo\ -ne\ \"\\e\[3\ q\" --description alias\ cursor=echo\ -ne\ \"\\e\[3\ q\"
  echo -ne "\e[3 q" $argv
        
end
