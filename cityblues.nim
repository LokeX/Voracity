import cityscape
import cityvista

let
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
    echo "pos: ",m.pos

proc draw (b:var Boxy) =
  b.drawImage("planbg",vec2(planbg.area.x.toFloat,planbg.area.y.toFloat))
  b.drawAreaShadow(planbg.area,7,color(255,255,255,100))
  
proc initCityBlues*() =
  addImage(planbg)
  addCall(newCall("cityblues",keyboard,mouse,draw))
