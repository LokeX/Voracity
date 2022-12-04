import cityscape
import cityvista
import cityplay

let
  bluePile = newAreaHandle("bluepile",850,500,110,180)
  planbg = newImageHandle((
    "planbg", 
    readImage("pics\\planbg2.jpg")),
    460,
    280
  )

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune
  else:
    echo k.button

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    if mouseOn() == "bluepile" and nrOfUndrawnBlueCards > 0:
      let card = drawBlueCard()
      echo card.title
    echo "pos: ",m.pos

proc draw (b:var Boxy) =
  b.drawImage("planbg",vec2(planbg.area.x.toFloat,planbg.area.y.toFloat))
  b.drawAreaShadow(planbg.area,7,color(255,255,255,100))
  
proc initCityBlues*() =
  addMouseHandle(newMouseHandle(bluePile))
  addImage(planbg)
  addCall(newCall("cityblues",keyboard,mouse,draw))
