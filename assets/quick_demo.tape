# VHS tape file for generating demo gif. Run from repo root with
#    vhs assets/quick_demo.tape
# https://github.com/charmbracelet/vhs

Output assets/quick_demo.gif

Set Shell "bash"
Set FontSize 22
Set Width 1200
Set Height 1000
Set Padding 50
Set CursorBlink false
Set Framerate 40
Set TypingSpeed 50ms

Env PS1 "$(tput setaf 39)\$ $(tput sgr0)"

Type "examples/quick -h"
Sleep 200ms
Enter
Sleep 3000ms

Ctrl+l

Type "examples/quick hello"
Sleep 200ms
Enter
Sleep 500ms

Type "examples/quick hello -h"
Sleep 200ms
Enter
Sleep 500ms

Type "examples/quick hello -g -n World"
Sleep 200ms
Enter
Sleep 3000ms

Ctrl+l

Type "examples/quick start -h"
Sleep 250ms
Enter
Sleep 1500ms

Type "examples/quick start example"
Sleep 200ms
Enter
Sleep 500ms

Type "examples/quick start -g -d 'not default' \"
Enter
Type "--nullable 'not null' example"
Sleep 200ms
Enter
Sleep 3000ms
