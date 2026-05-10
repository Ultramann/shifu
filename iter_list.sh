delim="#=|=#"
append_list() {
    _append_list "${1}_LIST" "$2"
}

_append_list() {
    # eval "$1=\"\${$1:-}\${$1:+$delim}$2\""
    eval "$1=\"\${$1:-}$2${delim}\""
}

iter_list() {
    if ! [ "${LIST_TEMP+set}" ]; then
        eval "LIST_TEMP=\$$1_LIST"
    fi
    if [ -z "$LIST_TEMP" ]; then
        unset LIST_TEMP
        return 1
    fi
    LIST_TAIL="${LIST_TEMP#*${delim}}"
    eval "$1=\"\${LIST_TEMP%\${delim}\${LIST_TAIL}}\""
    LIST_TEMP="$LIST_TAIL"
}

# append_list LIST "Hello world!!"
# append_list LIST "Hi there!!!!!"
# append_list LIST "Yay it works!"

while iter_list LIST; do
    echo $LIST
done
