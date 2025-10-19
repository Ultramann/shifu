# VHS tape file for generating demo gif. Run from repo root with
#    vhs assets/tab_demo.tape
# https://github.com/charmbracelet/vhs

Output assets/tab_demo.gif

Set Shell "bash"
Set FontSize 22
Set Width 1200
Set Height 500
Set Padding 50
Set CursorBlink false
Set Framerate 40
Set TypingSpeed 50ms

Env PS1 "$(tput setaf 39)\$ $(tput sgr0)"

Hide
Type 'eval "$(examples/tab --tab-completion bash)"'
Enter
Ctrl+l
Show

Type "examples/tab -h"
Sleep 200ms
Enter
Sleep 3000ms

Ctrl+l

Type "examples/tab "
Sleep 500ms
Tab
Sleep 500ms
Type "-o "
Tab 2
Sleep 500ms
Type "m"
Sleep 300ms
Tab
Sleep 300ms
Tab 2
Sleep 500ms
Type "e"
Sleep 300ms
Tab
Sleep 1500ms
