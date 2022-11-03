import cityview
import citytext
import os
import times

proc keyboard (k:KeyEvent) =
  echo "live keyboard"

proc mouse (m:MouseEvent) =
  echo "live mouse"

proc draw (b:var Boxy) =
  if not b.contains("bg"): b.addImage("bg", readImage("bggreen.png"))
  b.drawImage("bg", rect = rect(vec2(0, 0), window.size.vec2))
  b.drawText("main-image",100,100,"Current time:")
  b.drawText("main-image2",500,100,now().format("hh:mm:ss"))

proc windowSize*(): Vec2 = winSize().vec2

addCall(newCall(keyboard,mouse,draw))
echo ("nr of modes: ", calls.len())

while not window.closeRequested:
  sleep(30)
  pollEvents()