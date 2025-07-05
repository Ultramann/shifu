Output assets/demo.gif

Set Shell "bash"
Set FontSize 32
Set Width 1200
Set Height 1500
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

Type "examples/quick hello -n World"
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

Type "examples/quick start -g \"
Enter
Type "-d 'not default' \"
Enter
Type "--nullable 'not null' \"
Enter
Type "example"
Sleep 200ms
Enter
Sleep 3000ms
