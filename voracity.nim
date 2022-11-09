import cityview
import citytext
import citydice
import os
import times

let
  board: ImageName = ("board", readImage("engboard.jpg"))
  bg: ImageName = ("bg", readImage("bggreen.png"))
  boardMouse = newMouseHandle(board,200,100)

addImage(bg)
addImage(board)
addMouseHandle(boardMouse)

proc keyboard (k:KeyEvent) =
  echo "Voracity keyboard:"
  echo k.keyState
  echo k.button
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
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
#[   b.drawText("text1",100,100,"Current time:")
  b.drawText("text2",500,100,now().format("hh:mm:ss")) ]#
  b.drawText("text3",800,25,mouseOn())
  b.drawImage("board", pos = vec2(200, 100))
  b.drawRect(rect(vec2(300,300),vec2(500,500)),color(255,255,255,150))

addCall(newCall("voracity",keyboard,mouse,draw))
initDice()
echo "nr of recievers: ",calls.len()
echo "nr of mouse handles:",mouseHandles.len()

while not window.closeRequested:
  sleep(30)
  pollEvents()