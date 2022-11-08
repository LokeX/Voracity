import cityview
import citytext
import citydice
import os
import times

let
  board: ImageName = ("board", readImage("engboard.jpg"))
  bg: ImageName = ("bg", readImage("bggreen.png"))
addImage(bg)
addImage(board)
let
  boardMouse = newMouseHandle(board,200,200)
addMouseHandle(boardMouse)
#echoMouseHandles()

proc keyboard (k:KeyEvent) =
  echo "Voracity keyboard:"
  echo k.keyState
  echo k.button
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if isMouseKeyEvent(m.keyState):
    echo "mouse clicked:"
    echo m.keyState
    echo m.button
    if mouseOn(board):
      playSound("carstart-1")
#[   if not isMouseKeyEvent(m.keyState):
    echo "mouse moved: ",m.pos.x,",",m.pos.y
 ]#
proc draw (b:var Boxy) =
  b.drawImage("bg", rect = rect(vec2(0, 0), window.size.vec2))
  b.drawText("text1",100,100,"Current time:")
  b.drawText("text2",500,100,now().format("hh:mm:ss"))
  b.drawText("text3",800,100,mouseOnHandle())
  b.drawImage("board", pos = vec2(200, 200))
  b.drawRect(rect(vec2(300,300),vec2(500,500)),color(255,255,255,150))

addCall(newCall(keyboard,mouse,draw))
initDice()
echo ("nr of modes: ", calls.len())
echo "handles:",mouseHandles.len()
#[ for handle in mouseHandles: 
  echo (handle.name)
 ]#
while not window.closeRequested:
  sleep(30)
  pollEvents()