import cityview
export cityview
import os

proc keyPressed (button:Button) =
  echo "live mouse"

addKeyListener(newListener(keyPressed))
echo ("nr of listeners: ", listeners.len())

while not window.closeRequested:
  sleep(30)
  pollEvents()