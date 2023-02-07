import cityscape
import cityvista
import cityplay
import citytext
import strutils
import sequtils

const
  mbx = bx+1300
  mby = by

let
  miniBlue = readImage("pics\\miniplanbg.jpg")
  bluePile = newAreaHandle("bluepile",bx+630,by+440,110,180)
  usedPile = newImageHandle(("usedpile",miniBlue),bx+805,by+440)
  planbg = newImageHandle((
    "planbg", 
    readImage("pics\\planbg2.jpg")),
    bx+240,
    by+220
  )

var
  miniBlues:seq[ImageHandle]

proc newMiniBlues(): seq[ImageHandle] =
  for i in 0..7:
    result.add(
      newImageHandle(
        ("miniblues"&i.intToStr,miniBlue),
        mbx+(((i+2) mod 2)*(miniBlue.width+20)),
        mby+((i div 2)*(miniBlue.height+20))
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
    if turn.player.kind == human and m.button == MouseLeft:
      let mo = mouseOnMiniBlueNr()
      if mo > -1 and mo < turn.player.cards.len: 
        discardCard(mo)
        sortBlues()
      if mouseOn() == "bluepile" and nrOfUndrawnBlueCards > 0:

#[         echo "bluePile:"
        for card in blueCards: echo card.title
        echo "usedPile:"
        for card in usedCards: echo card.title
 ]#
        echo "undrawn blue cards: ",nrOfUndrawnBlueCards
        echo "nrOfCards: ",blueCards.len
        echo "nrOfUsedCards: ",usedCards.len

#[         echo "dublets: "
        echo dublets()
 ]#
        drawBlueCard()
        echo $turn.player.color&" draws blue card: ",turn.player.cards[^1].title
        playSound("page-flip-2")
        if cashInPlans() > 0:
          playSound("coins-to-table-2")
        sortBlues()
        echo $turn.player.color&" has cards:"
        for card in turn.player.cards:
          echo card.title
        echo "Undrawn blue cards left: ",nrOfUndrawnBlueCards

proc drawUndrawnCardsNr(b:var Boxy) =
  if nrOfUndrawnBlueCards > 0 and turn.player.kind == human:
    b.drawText(
      "undrawncardsnr",
      (bluePile.area.x+12).toFloat,
      (bluePile.area.y+8).toFloat,
      nrOfUndrawnBlueCards.intToStr,
      fontFace(roboto,150,color(0,1,0))
    )

proc squaredPlans(plan:BlueCard): seq[string] =
  let (s,p) = requiredCardSquares(plan)
  toSeq(0..s.len-1).mapIt(p[it].intToStr&" piece on: "&squares[s[it]].name)

proc drawBigBlue(b:var Boxy,bigBlue:BlueCard) =
  b.drawImage("planbg",imagePos(planbg))
  b.drawAreaShadow(planbg.area,7,color(255,255,255,100))
  b.drawText(
    "bigcardTitle",
    (planbg.area.x+10).toFloat,
    planbg.area.y.toFloat,
    bigBlue.title,
    fontFace(point,48,color(0,0,1))
  )
  var sp = squaredPlans(bigBlue)
  if bigBlue.squares.oneInMoreRequired.len > 0:
    sp.add "1 piece on any "&bigBlue.oneInMoreCardSquaresTitle()
  sp.add("Cash reward: "&bigBlue.cash.intToStr.insertSep(sep='.'))
  let
    a:Area = (planbg.area.x+10,planbg.area.y+90,planbg.area.w-20,(sp.len+1)*20)
    (ps,_) = requiredCardSquares(bigBlue)
  for s in ps:
    b.drawRect(squares[s].area.toRect(),playerColorsTrans[turn.player.color])
  for square in bigBlue.squares.oneInMoreRequired:
    b.drawRect(squares[square].area.toRect(),playerColorsTrans[turn.player.color])
  b.drawRect(a.toRect,color(1,1,1))
  b.drawAreaShadow(a,2,color(0,0,0,150))
  for i,text in sp:
    b.drawText(
      "planedSquares"&i.intToStr,
      (planbg.area.x+20).toFloat,
      (planbg.area.y+100+(i*20)).toFloat,
      text,
      fontFace(roboto,15,color(0,0,0))
    )

proc drawBigBlue(b:var Boxy) =
  if turn.player.cards.len > 0:
    let mo = mouseOnMiniBlueNr()
    if mo > -1 and mo < turn.player.cards.len:
      b.drawBigBlue(turn.player.cards[mo])

proc drawMiniBlue(b:var Boxy,miniBlue:BlueCard,ih:ImageHandle) =
  b.drawImage(ih.img.name,imagePos(ih))
  b.drawAreaShadow(ih.area,3,color(255,255,255,150))
  b.drawText(
    miniBlue.title,
    (ih.area.x+5).toFloat,
    (ih.area.y).toFloat,
    miniBlue.title,
    fontFace(point,18,color(0,0,1))
  )

proc drawUsedPile(b:var Boxy) =
  if turn != nil and usedCards.len > 0:
    b.drawMiniBlue(usedCards[^1],usedPile)
    b.drawAreaShadow(usedPile.area,3,color(255,255,255,150))

proc drawMiniBlues(b:var Boxy) =
  for i,blue in turn.player.cards:
    b.drawMiniBlue(blue,miniBlues[i])

proc drawUsedPileBigBlue(b:var Boxy) =
  if mouseOn() == "usedpile" and usedCards.len > 0:
    b.drawBigBlue(usedCards[^1])

proc draw (b:var Boxy) =
  if turn != nil:
    b.drawUndrawnCardsNr()
    b.drawBigBlue()
    b.drawMiniBlues()
    b.drawUsedPile()
    b.drawUsedPileBigBlue()
  
proc initCityBlues*() =
  miniBlues = newMiniBlues()
  addMouseHandle(newMouseHandle(bluePile))
  addImage(usedPile)
  addMouseHandle(newMouseHandle(usedPile))
  addImage(planbg)
  addCall(newCall("cityblues",keyboard,mouse,draw,nil))
