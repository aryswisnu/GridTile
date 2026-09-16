# GridTile

Ctrl+Opt+Cmd+T tiles every visible window on the display under the mouse into an auto grid.

- 1 window: full screen. 2: side by side. 4: 2x2. 7: 3+3+1 (last row stretched). 12: 4x3.
- Only windows on the current Space and display. Minimized and hidden windows are ignored.

## Install

    ./build.sh
    open /Applications/GridTile.app

Grant Accessibility when prompted (System Settings > Privacy & Security > Accessibility).
Re-grant after every rebuild (ad-hoc signature changes).

## Test

    swift test
