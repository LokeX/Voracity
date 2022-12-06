import cityscape
import cityvista
import cityplay
import citytext
import strutils
import sequtils

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

proc mouseOnMiniBlueNr(): int =
  for i,blue in miniBlues:
    if mouseOn(blue):
      return i
  return -1

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune
  else:
    echo k.button

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState) and turn != nil and removePieceDialog == nil:
    if m.button == MouseLeft:
      let mo = mouseOnMiniBlueNr()
      if mo > -1 and mo < turn.player.cards.len: discardCard(mo)
      if mouseOn() == "bluepile" and nrOfUndrawnBlueCards > 0:
        drawBlueCard()
        playSound("page-flip-2")
        echo $turn.player.color&" has cards:"
        for card in turn.player.cards:
          echo card.title
    echo "pos: ",m.pos

proc drawUndrawnCardsNr(b:var Boxy) =
  if nrOfUndrawnBlueCards > 0:
    b.drawText(
      "undrawncardsnr",
      (bluePile.area.x+12).toFloat,
      (bluePile.area.y+8).toFloat,
      nrOfUndrawnBlueCards.intToStr,
      fontFace(roboto,150,color(0,1,0))
    )

proc squaredPlans(plan:BlueCard): seq[string] =
  let (s,p) = planedSquares(plan)
#  echo s,p
  toSeq(0..s.len-1).mapIt(p[it].intToStr&" piece on: "&squares[s[it]].name)

proc drawBigBlue(b:var Boxy) =
  if turn.player.cards.len > 0:
    let mo = mouseOnMiniBlueNr()
    if mo > -1 and mo < turn.player.cards.len:
      b.drawImage("planbg",vec2(planbg.area.x.toFloat,planbg.area.y.toFloat))
      b.drawAreaShadow(planbg.area,7,color(255,255,255,100))
      b.drawText(
        "bigcardTitle",
        (planbg.area.x+10).toFloat,
        planbg.area.y.toFloat,
        turn.player.cards[mo].title,
        fontFace(point,48,color(0,0,1))
      )
      let sp = squaredPlans(turn.player.cards[mo])
      let a:Area = (planbg.area.x+10,planbg.area.y+90,planbg.area.w-20,(sp.len+1)*20)
      b.drawRect(a.toRect,color(1,1,1))
      #b.drawAreaShadow(a,2,color(0,0,0,150))
      for i,text in sp:
        b.drawText(
          "planedSquares"&i.intToStr,
          (planbg.area.x+20).toFloat,
          (planbg.area.y+100+(i*20)).toFloat,
          text,
          fontFace(roboto,15,color(0,0,0))
        )

proc drawMiniBlues(b:var Boxy) =
  for i,blue in turn.player.cards:
    b.drawImage(miniBlues[i].img.name,imagePos(miniBlues[i]))
    b.drawAreaShadow(miniBlues[i].area,3,color(255,255,255,150))
    b.drawText(
      "title"&i.intToStr,
      (miniBlues[i].area.x+5).toFloat,
      (miniBlues[i].area.y).toFloat,
      blue.title,
      fontFace(point,18,color(0,0,1))
    )

proc draw (b:var Boxy) =
  if turn != nil:
    b.drawUndrawnCardsNr()
    b.drawBigBlue()
    b.drawMiniBlues()
  
proc initCityBlues*() =
  miniBlues = newMiniBlues()
  addMouseHandle(newMouseHandle(bluePile))
  addImage(planbg)
  addCall(newCall("cityblues",keyboard,mouse,draw))
