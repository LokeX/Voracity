import cityvista
#import citydice
import cityplay
import os

let
  bg = ("bg", readImage("pics\\bggreen.png"))

addImage(bg)

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    echo "pos: ",m.pos

proc draw (b:var Boxy) =
  b.drawImage("bg", rect = rect(vec2(0, 0), window.size.vec2))
#  b.drawRect(rect(vec2(300,300),vec2(500,500)),color(255,255,255,150))

addCall(newCall("voracity",keyboard,mouse,draw))
#initCityDice()
initCityPlay()
echo "nr of recievers: ",calls.len()
echo "nr of mouse handles:",mouseHandles.len()

while not window.closeRequested:
  sleep(15)
  pollEvents()