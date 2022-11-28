import cityscape
import cityplay
import citytext
import times
import strutils
import sequtils

const
  sqOff = 43
  (tbxo,lryo) = (220,172)
  (tyo,byo) = (70,690)
  (lxo,rxo) = (70,1030)

  die1Pos = (x:100,y:200)
  die2Pos = (x:100,y:265)
  
let
  ibmB = readTypeface("fonts\\IBMPlexMono-Bold.ttf")
  roboto = readTypeface("fonts\\Roboto-Regular_1.ttf")
  boardImage = newImageHandle(("board", readImage("pics\\engboard.jpg")),bx,by)
  dieFaceImages = loadImages("pics\\diefaces\\*.gif")
  dieFace1 = newImageHandle(dieFaceImages[0],die1Pos.x,die1Pos.y)
  dieFace2 = newImageHandle(dieFaceImages[1],die2Pos.x,die2Pos.y)

var
  moveSquares:seq[int]
  moveFromSquare:int
  oldTime = cpuTime()
  squares:array[1..60,AreaHandle]

proc squareNames(filePath:string): seq[string] =
  var 
    nr = 0
    text = open(filePath,fmRead)
  while not endOfFile(text):
    inc nr
    result.add(text.readLine&" Nr. "&nr.intToStr)
  close(text)

func zipToAreaHandles(names:seq[string],areas:openArray[Area]): array[1..60,AreaHandle] =
  for i,square in zip(names,areas):
    result[i+1] = newAreaHandle(square)

func squareAreas(): array[1..60,Area] =
  for i in 0..17:
    result[37+i] = (bx+tbxo+(i*sqOff),by+tyo,35,100)
    result[24-i] = (bx+tbxo+(i*sqOff),by+byo,35,100)
    if i < 12:
      result[36-i] = (bx+lxo,by+lryo+(i*sqOff),100,35)
      if i < 6:
        result[55+i] = (bx+rxo,by+lryo+(i*sqOff),100,35)
      else:
        result[1+(i-6)] = (bx+rxo,by+lryo+(i*sqOff),100,35)

proc getColor(player:Player): Color = playerColors[player.color]

proc showFonts(b:var Boxy) =
  b.drawText("font1",1500,50,"This is font: cabalB20Black",cabalB20Black)
  b.drawText("font2",1500,100,"This is font: cabal30White",cabal30White)
  b.drawText("font3",1500,150,"This is font: confes40Black",confes40Black)
  b.drawText("font4",1500,200,"This is font: aovel30White",aovel30White)
  b.drawText("font5",1500,250,"This is font: roboto20White",roboto20White)
  b.drawText("font6",1500,300,"This is font: ibm20White",ibm20White)

func offsetArea(a:Area,offset:int): Area = (a.x+offset,a.y+offset,a.w,a.h)

proc initSquareHandles() =
  for areaHandle in squares:
    addMouseHandle(newMouseHandle(areaHandle))

proc mouseOnSquareNr*(): int =
  for i,square in squares:
    if mouseOn() == square.name:
      return i

proc pieceOn*(player:Player,squareNr:int): Area =
  var
    (x,y,w,h) = squares[squareNr].area
  if w == 35:
    result = (x+5,y+6+(player.color.ord*15),w-10,12)
  else:
    result = (x+6+(player.color.ord*15),y+5,12,h-10)

proc drawBatchText(b:var Boxy,player:Player) =
  let
    offset = offsetArea(player.batch.area,5)    
    lines = [
      "Turn: "&player.turnNr.intToStr,
      "Cash: "&player.cash.intToStr.insertSep(sep='.')
    ]
  for i,line in lines:
    b.drawText(
      "batch"&player.nr.intToStr&i.intToStr,
      offset.x.toFloat,
      offset.y.toFloat+(i.toFloat*20),
      line,
      fontFace(roboto,20,batchFontColors[player.color])
    )

proc drawTurnCursor(b:var Boxy,player:Player) =
  let (x,y,w,_) = player.batch.area
  if player.nr == turn.player.nr:
    let time = cpuTime() - oldTime
    if time > 0 and time < 1:
      b.drawRect((x+w-20,y+5,15,15).toRect,batchFontColors[player.color])
    elif time >= 2:
      oldTime = cpuTime()

proc drawBatch(b:var Boxy,player:Player) =
  b.drawRect(offsetArea(player.batch.area,5).toRect,color(255,255,255,150))
  b.drawRect(player.batch.area.toRect,player.getColor)

proc drawPlayerKind(b:var Boxy,player:Player) =
  let offset = [45,25,55]
  b.drawText(
    "kind"&player.nr.intToStr,
    (player.batch.area.x+offset[playerKinds[player.nr].ord]).toFloat,
    (player.batch.area.y+30).toFloat,
    $playerKinds[player.nr],
    fontFace(ibmB,25,batchFontColors[player.color])
  )

proc mouseRightClicked() =
  if moveSquares.len > 0: 
    moveSquares = @[]
  else:
    playSound("carhorn-1")
    oldTime = cpuTime()
    if turn == nil:
      newGame()
    else:
      nextPlayerTurn()

proc mouseOnPlayer(): Player = 
  for player in players:
    if player.batch != nil and player.batch.name == mouseOn():
      return player

proc togglePlayerKind() =
  if turn == nil:
    let pl = mouseOnPlayer()
    if pl != nil: 
      playerKinds[pl.nr] = playerKinds[pl.nr].toggleKind()
      playSound("Blop-Mark_DiAngelo")

proc pieceSelectAndMove() =
  let clickedSquareNr = mouseOnSquareNr()
  if clickedSquareNr > 0 and turn != nil and not isRollingDice():
    if moveSquares.len == 0 or not (clickedSquareNr in moveSquares):
      moveFromSquare = clickedSquareNr
      if moveablePieceOn(moveFromSquare):
        moveSquares = moveToSquares(moveFromSquare)
        playSound("carstart-1")
    elif clickedSquareNr in moveSquares:
      movePiece(moveFromSquare,clickedSquareNr)
      if not turn.diceMoved:
        turn.diceMoved = not (
          clickedSquareNr in gasStations and 
          moveFromSquare in highways
        )
      moveSquares = @[]
      playSound("driveBy")

proc mouseOnDice(): bool =
  mouseOn(dieFace1) or mouseOn(dieFace2)

proc diceRoll() =
  if mouseOnDice() and isDouble(): startDiceRoll()

proc mouseLeftClicked() =
  diceRoll()
  togglePlayerKind()
  pieceSelectAndMove()

proc rotateDie(b:var Boxy,die:ImageHandle) =
  var (x,y,w,h) = die.area
  b.drawImage(
    dice[die.img.name.parseInt].intToStr,
    center = vec2((x.toFloat+(w/2)),y.toFloat+(h/2)),
    angle = (dieRollFrame*9).toFloat,
    tint = color(1,1,1,41-dieRollFrame.toFloat)
  )

func imagePos(image:ImageHandle): Vec2 =
  vec2(image.area.x.toFloat,image.area.y.toFloat)

proc drawDice(b:var Boxy) =
  if turn != nil:
    if not isRollingDice():
      b.drawImage(dice[1].intToStr,pos = imagePos(dieFace1)) 
      b.drawImage(dice[2].intToStr,pos = imagePos(dieFace2))
    else:
      rollDice()
      b.rotateDie(dieFace1)
      b.rotateDie(dieFace2)
      inc dieRollFrame

proc drawBoard(b:var Boxy) =
  b.drawImage("board",vec2(bx.toFloat,by.toFloat))

proc drawPlayerBatches(b:var Boxy) =
  for player in players:
    if player.kind != none or turn == nil:
      b.drawBatch(player)
      if turn != nil:
        b.drawBatchText(player)
        b.drawTurnCursor(player)
      else:
        b.drawPlayerKind(player)

proc drawMoveSquares(b:var Boxy) =
  for moveSquare in moveSquares:
    b.drawRect(squares[moveSquare].area.toRect,selColor)

proc drawPiecesOnSquares(b:var Boxy) =
  for i,player in players:
    if (turn == nil and playerKinds[i] != none) or (turn != nil and player.kind != none):
      for square in player.piecesOnSquares:
        b.drawRect(player.pieceOn(square).toRect,player.getColor)

proc drawMisc(b:var Boxy) =
  b.drawText("text7",800,1025,mouseOn(),aovel60White)
  b.drawText("text9",1400,1025,$(if mouseOnPlayer()!=nil:mouseOnPlayer() else:players[1]).color,aovel60White)
  b.drawText("text8",400,1025,
    "Square nr: "&(if mouseOnSquareNr() == 0: "n/a" else: mouseOnSquareNr().intToStr),
    aovel60White
  )

proc draw (b:var Boxy) =
  b.drawDice()
  b.drawBoard()
  b.drawPlayerBatches()
  b.drawMoveSquares()
  b.drawPiecesOnSquares()
  b.drawMisc()
#  b.showFonts()

var dieEdit:int

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown and not isRollingDice():
    let c = k.rune.toUTF8
    var i:int
    try: i = c.parseInt except ValueError: i = 0
    if c.toUpper == "D":
      dieEdit = 1 
    elif dieEdit > 0 and i in 1..6:
      dice[dieEdit] = i
      inc dieEdit
      if dieEdit > 2:
        dieEdit = 0
    else:
      dieEdit = 0

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState) and not isRollingDice():
    if m.button == MouseRight:
      mouseRightClicked()
    elif m.button == MouseLeft:
      mouseLeftClicked()

proc initCityVista*() =
  addImages(dieFaceImages)
  addMouseHandle(newMouseHandle(dieFace1))
  addMouseHandle(newMouseHandle(dieFace2))
  addImage(boardImage)
  addMouseHandle(newMouseHandle(boardImage))
  squares = zipToAreaHandles(squareNames("dat\\board.txt"),squareAreas())  
  initSquareHandles()
  addCall(newCall("cityvista",keyboard,mouse,draw))
