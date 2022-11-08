import cityview

let
  dieFaces* = loadImages("pics\\diefaces\\*.gif")
addImages(dieFaces)
let
  dieFace1 = newMouseHandle(dieFaces[0],100,200)
  dieFace2 = newMouseHandle(dieFaces[1],100,265)
addMouseHandle(dieFace1)
addMouseHandle(dieFace2)

proc keyboard (k:KeyEvent) =
  echo "dice keyboard:"
  echo k.keyState
  echo k.button
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
  b.drawImage("1", pos = vec2(100, 200)) 
  b.drawImage("2",pos = vec2(100, 265))
  
proc initDice*() =
  addCall(newCall(keyboard,mouse,draw))
  echo ("nr of modes: ", calls.len())