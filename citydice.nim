import cityview

let
  dieFaces* = loadImages("pics\\diefaces\\*.gif")

addImages(dieFaces)

proc keyboard (k:KeyEvent) =
  echo "dice keyboard:"
  echo k.keyState
  echo k.button
#  echo k.rune
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  echo "dice mouse:"
  echo m.keyState
  echo m.button
  if not isMouseKeyEvent(m.keyState):
    echo "mouse moved: ",m.pos.x,",",m.pos.y

proc draw (b:var Boxy) =
  b.drawImage("2", pos = vec2(100, 200)) 
  b.drawImage("1",pos = vec2(100, 300))
  
proc initDice*() =
  addCall(newCall(keyboard,mouse,draw))
  echo ("nr of modes: ", calls.len())