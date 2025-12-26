function dusort
    find . -mindepth 1 -maxdepth 1 -print0 | xargs -0 du -hs | sort -rh
end
