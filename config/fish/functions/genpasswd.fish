function genpasswd --wraps=echo\ `env\ LC_CTYPE=C\ tr\ -dc\ \"a-zA-Z0-9-_\\\$\\\?\"\ \<\ /dev/urandom\ \|\ head\ -c\ 20` --description alias\ genpasswd=echo\ `env\ LC_CTYPE=C\ tr\ -dc\ \"a-zA-Z0-9-_\\\$\\\?\"\ \<\ /dev/urandom\ \|\ head\ -c\ 20`
  echo `env LC_CTYPE=C tr -dc "a-zA-Z0-9-_\$\?" < /dev/urandom | head -c 20` $argv
        
end
