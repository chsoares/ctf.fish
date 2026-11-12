# Update or append "set -gx VAR value" in a fish env file.
function ctf_env_write_var --argument-names file var value
    test -f "$file"; or return 1

    set -l line "set -gx $var "(string escape -- "$value")
    set -l tmp (mktemp)
    set -l found 0

    while read -l current
        if string match -q "set -gx $var *" -- $current
            printf '%s\n' $line >> $tmp
            set found 1
        else
            printf '%s\n' $current >> $tmp
        end
    end < "$file"

    if test $found -eq 0
        printf '%s\n' $line >> $tmp
    end
    mv $tmp $file
end
