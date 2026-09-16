#!/bin/bash
# Records a demo GIF: scattered windows on a clean desktop, then ⌃⌥⌘T tiles them.
# Run this from an iTerm window: that window is part of the demo.
# Needs: GridTile running with Accessibility granted, Screen Recording for iTerm, ffmpeg. Output: assets/demo.gif
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build

# Main display 1920x1080 assumed. AppleScript bounds are {left, top, right, bottom}.
osascript <<'APPLESCRIPT'
-- Clean stage: hide everything except the demo apps.
tell application "System Events"
  set names to name of every process whose visible is true
  repeat with n in names
    if (n as text) is not in {"Finder", "TextEdit", "iTerm2"} then
      try
        set visible of process (n as text) to false
      end try
    end if
  end repeat
end tell
tell application "Finder"
  close every window
end tell
tell application "TextEdit"
  activate
  close every window saving no
  set titles to {"standup notes", "meeting agenda", "ideas"}
  set b to {{60, 80, 760, 560}, {300, 400, 1000, 900}, {1100, 500, 1850, 1000}}
  repeat with i from 1 to 3
    set d to make new document
    set text of d to (item i of titles) & return & return & "GridTile demo, window " & i
  end repeat
  repeat with i from 1 to 3
    set bounds of window i to item i of b
  end repeat
end tell
tell application "iTerm"
  activate
  set bounds of current window to {900, 120, 1700, 640}
end tell
tell application "Finder"
  activate
  set w to make new Finder window to home
  set bounds of w to {40, 620, 640, 1040}
end tell
APPLESCRIPT

# Put the cursor on the main display so GridTile targets it.
swift -e 'import CoreGraphics; CGWarpMouseCursorPosition(CGPoint(x: 960, y: 540))' 2>/dev/null || true
sleep 2

rm -f build/demo.mov
echo "recording 7s. Press ⌃⌥⌘T when you hear the beep."
screencapture -v -D 1 -V 7 build/demo.mov &
REC=$!
sleep 3
afplay /System/Library/Sounds/Glass.aiff &
echo ">>> PRESS ⌃⌥⌘T NOW (keep the mouse on the main display)"
wait $REC

ffmpeg -y -loglevel error -i build/demo.mov \
  -vf "fps=12,scale=960:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" \
  assets/demo.gif
ls -la assets/demo.gif
echo "done: assets/demo.gif"
