# VHS tape file for generating demo gif. Run from repo root with
#    vhs assets/dispatch_demo_dark.tape
# https://github.com/charmbracelet/vhs

Output assets/dispatch_demo_dark.gif

Set Shell "bash"
Set FontSize 22
Set Width 1200
Set Height 1000
Set Padding 50
Set CursorBlink false
Set Framerate 40
Set TypingSpeed 50ms
Set Theme {
  "background": "#161b22",
  "foreground": "#f1f6fb",
  "cursor": "#f1f6fb",
  "red": "#ee8377"
}

Env PS1 "\[$(tput setaf 1)\]\$ \[$(tput sgr0)\]"

Type "examples/dispatch -h"
Sleep 200ms
Enter
Sleep 3000ms

Ctrl+l

Type "examples/dispatch hello"
Sleep 200ms
Enter
Sleep 500ms

Type "examples/dispatch hello -h"
Sleep 200ms
Enter
Sleep 500ms

Type "examples/dispatch hello -Dn World"
Sleep 200ms
Enter
Sleep 3000ms

Ctrl+l

Type "examples/dispatch echo -h"
Sleep 250ms
Enter
Sleep 1500ms

Type "examples/dispatch echo --required 'provided' example"
Sleep 200ms
Enter
Sleep 500ms

Type "examples/dispatch echo -Dd 'not default' -r 'provided' example"
Sleep 200ms
Enter
Sleep 3000ms
