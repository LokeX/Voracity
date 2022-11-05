import cityview
import citytext
import citydice
import os
import times

let
  board: ImageName = (name:"board", image:readImage("engboard.jpg"))
  bg: ImageName = ("bg", readImage("bggreen.png"))
addImage(bg)
addImage(board)

proc keyboard (k:KeyEvent) =
  echo "Voracity keyboard:"
  echo k.keyState
  echo k.button
#  echo k.rune
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if isMouseKeyEvent(m.keyState):
    echo "mouse clicked:"
    echo m.keyState
    echo m.button
#[   if not isMouseKeyEvent(m.keyState):
    echo "mouse moved: ",m.pos.x,",",m.pos.y
 ]#
proc draw (b:var Boxy) =
  b.drawImage("bg", rect = rect(vec2(0, 0), window.size.vec2))
  b.drawText("main-image",100,100,"Current time:")
  b.drawText("main-image2",500,100,now().format("hh:mm:ss"))
  b.drawImage("board", pos = vec2(200, 200))
  b.drawRect(rect(vec2(300,300),vec2(500,500)),color(255,255,255,150))

addCall(newCall(keyboard,mouse,draw))
initDice()
echo ("nr of modes: ", calls.len())

while not window.closeRequested:
  sleep(30)
  pollEvents()