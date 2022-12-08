import cityscape
import cityplay

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune
  else:
    echo k.button

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    echo "pos: ",m.pos

proc draw (b:var Boxy) =
  let a = 0

proc cycle() =
  if turn != nil and turn.player.kind == computer:
    echo "ai online"

proc initCityai*() =
  addCall(newCall("cityai",keyboard,mouse,draw,cycle))