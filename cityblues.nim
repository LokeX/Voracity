import cityscape
import cityvista
import cityplay
import strutils

const
  mbx = 1550
  mby = 60

let
  bluePile = newAreaHandle("bluepile",850,500,110,180)
  planbg = newImageHandle((
    "planbg", 
    readImage("pics\\planbg2.jpg")),
    460,
    280
  )

var
  miniBlues:seq[ImageHandle]

proc newMiniBlues(): seq[ImageHandle] =
  let miniBlue = readImage("pics\\miniplanbg.jpg")
  for i in 0..11:
    result.add(
      newImageHandle(
        ("miniblues"&i.intToStr,miniBlue.copy()),
        mbx+(((i+2) mod 2)*95),
        mby+((i div 2)*145)
      )
    )
    addImage(result[i])
    addMouseHandle(newMouseHandle(result[i]))

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune
  else:
    echo k.button

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    if mouseOn() == "bluepile" and nrOfUndrawnBlueCards > 0:
      drawBlueCard()
      echo $turn.player.color&" has cards:"
      for card in turn.player.cards:
        echo card.title
    echo "pos: ",m.pos

proc draw (b:var Boxy) =
  b.drawImage("planbg",vec2(planbg.area.x.toFloat,planbg.area.y.toFloat))
  b.drawAreaShadow(planbg.area,7,color(255,255,255,100))
  for blue in miniBlues:
    b.drawImage(blue.img.name,vec2(blue.area.x.toFloat,blue.area.y.toFloat))
  
proc initCityBlues*() =
  miniBlues = newMiniBlues()
  addMouseHandle(newMouseHandle(bluePile))
  addImage(planbg)
  addCall(newCall("cityblues",keyboard,mouse,draw))
