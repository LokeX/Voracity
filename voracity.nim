import cityscape
import citytext
import cityvista
import cityplay
import cityblues
import cityai
import sequtils
import os

let
  bg = ("bg", readImage("pics\\bggreen.png"))

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune
  else:
    echo k.button

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    echo "pos: ",m.pos

proc draw (b:var Boxy) =
  b.drawImage("bg", rect = rect(vec2(0, 0), window.size.vec2))

proc initVoracity() =
  addImage(bg)
  addCall(newCall("voracity",keyboard,mouse,draw,nil))
  initCityText()
  initCityVista()
  initCityBlues()
  initCityai()
  window.visible = true

initVoracity()
while not window.closeRequested:
  sleep(30)
  pollEvents()
  for call in calls.filterIt(it.cycle != nil): call.cycle()
playerKindsToFile()
