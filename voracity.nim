import cityview
import os

proc keyboard (k:KeyEvent) =
  echo "live keyboard"

proc mouse (m:MouseEvent) =
  echo "live mouse"

proc draw (b:var Boxy) =
  echo ""

addCall(newCall(keyboard,mouse,draw))
echo ("nr of modes: ", calls.len())

while not window.closeRequested:
  sleep(30)
  pollEvents()