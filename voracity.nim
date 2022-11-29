import cityscape
import citytext
import cityvista
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

addCall(newCall("voracity",keyboard,mouse,draw))
initCityText()
initCityVista()
window.visible = true
echo "nr of recievers: ",calls.len()
echo "nr of mouse handles:",mouseHandles.len()

while not window.closeRequested:
  sleep(15)
  pollEvents()