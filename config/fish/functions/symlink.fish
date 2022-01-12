function symlink --argument _from _to
    if test -z "$from"; or test -z  "$_to"
      echo "symlink: must provide from and to arguments"
      return 1
    end

    set abs_to (realpath "$_to")

    if test -d $_to && not test -d $_from
        set to "$abs_to/"(basename $_from)
    else
        set to "$abs_to"
    end

    set from (realpath "$_from")

    ln -s $from $to
end
