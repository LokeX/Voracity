import cityscape
import cityplay
import citytext
import times
import strutils
import sequtils

const
  bh = 100
  (wx,wy) = (25,25)
  (bx,by) = (wx,wy+bh+25)
  sqOff = 43
  (tbxo,lryo) = (220,172)
  (tyo,byo) = (70,690)
  (lxo,rxo) = (70,1030)

  die1Pos = (x:1225+wx,y:wy)
  die2Pos = (x:1225+wx,y:wy+60)

  selColor = color(255,255,255,100)

  playerColors*:array[PlayerColors,Color] = [
    color(1,0,0),color(0,1,0),
    color(0,0,1),color(1,1,0),
    color(255,255,255),color(1,1,1)
  ]
  batchFontColors:array[PlayerColors,Color] = [
    color(1,1,1),
    color(255,255,255),
    color(1,1,1),
    color(255,255,255),
    color(1,1,1),
    color(255,255,255),
  ]
  
let
  aovel = readTypeface("fonts\\AovelSansRounded-rdDL.ttf")
  cabal = readTypeface("fonts\\Cabal-w5j3.ttf")
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
  playerBatches:array[1..6,AreaHandle]
  removePieceOnSquare = 0

proc newPlayerBatches(): array[1..6,AreaHandle] =
  for index in 1..6:
    result[index] = newAreaHandle(
      "playerbatch"&index.intToStr,
      15+bx+((index-1)*200),wy,170,bh
    )
    addMouseHandle(newMouseHandle(result[index]))

proc wirePlayerBatches() =
  var count = 1
  for player in players:
    if player.kind != none:
      player.batch = playerBatches[count]
      inc count

proc newGame() =
  players = newPlayers(playerKinds)
  wirePlayerBatches()
#  board = putPiecesOnBoard()
  nextPlayerTurn()

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

func offsetArea(a:Area,offset:int): Area = (a.x+offset,a.y+offset,a.w,a.h)

proc initSquareHandles() =
  for areaHandle in squares:
    addMouseHandle(newMouseHandle(areaHandle))

proc mouseOnSquareNr*(): int =
  for i,square in squares:
    if mouseOn() == square.name:
      return i

proc pieceOn(player:Player,squareNr:int): Area =
  var
    (x,y,w,h) = squares[squareNr].area
  if w == 35:
    result = (x+5,y+6+(player.color.ord*15),w-10,12)
  else:
    result = (x+6+(player.color.ord*15),y+5,12,h-10)

proc areaShadows(area:Area,offset:int): tuple[shadowRight:Area,shadowBottom:Area] =
  ((area.x+area.w,area.y+offset,offset,area.h),
  (area.x+offset,area.y+area.h,area.w-offset,offset))

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

proc drawAreaShadow(b:var Boxy,area:Area,offset:int,color:Color) =
  let areaShadows = area.areaShadows(offset)
  b.drawRect(areaShadows.shadowRight.toRect,color)
  b.drawRect(areaShadows.shadowBottom.toRect,color)

proc drawBatch(b:var Boxy,player:Player) =
  b.drawRect(player.batch.area.toRect,player.getColor)
  b.drawAreaShadow(player.batch.area,10,color(255,255,255,100))

proc drawPlayerKind(b:var Boxy,player:Player) =
  let offset = [45,25,55]
  b.drawText(
    "kind"&player.nr.intToStr,
    (player.batch.area.x+offset[playerKinds[player.nr].ord]).toFloat,
    (player.batch.area.y+30).toFloat,
    $playerKinds[player.nr],
    fontFace(aovel,30,batchFontColors[player.color])
  )

proc drawConfirmDialog(b:var Boxy) =
  let 
    dialog:Area = (bx+650,by+250,300,100)
    yes:Area = (dialog.x+90,dialog.y+50,50,30)
    no:Area = (dialog.x+160,dialog.y+50,50,30)
    normal = color(0,0,1)
    select = color(1,0,0)
    yesbg = if mouseOn(yes):select else:normal
    nobg = if mouseOn(no):select else:normal
    strColor = $opponentPlayerOn(removePieceOnSquare).color
  
  b.drawRect(dialog.toRect,color(255,255,255))
  b.drawRect(yes.toRect,yesbg)
  b.drawRect(no.toRect,nobg)
  b.drawAreaShadow(dialog,10,color(255,255,255,100))
  b.drawText(
    "confirmdialog",
    (dialog.x+15).toFloat,
    (dialog.y+10).toFloat,
    "Remove "&strColor&" piece on square nr. "&removePieceOnSquare.intToStr&"?",
    fontFace(roboto,16,color(1,1,0))
  )
  b.drawText(
    "dialogyes",
    (yes.x+12).toFloat,
    (yes.y+5).toFloat,
    "Yes",
    fontFace(roboto,16,color(1,1,1))
  )
  b.drawText(
    "dialogno",
    (no.x+16).toFloat,
    (no.y+5).toFloat,
    "No",
    fontFace(roboto,16,color(1,1,1))
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
      if nrOfPiecesOnSquare(clickedSquareNr) == 1:
        removePieceOnSquare = clickedSquareNr
        echo "kill piece on: ",clickedSquareNr
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
#  if turn != nil:
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
  if removePieceOnSquare > 0: b.drawConfirmDialog()
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
  playerBatches = newPlayerBatches()
  wirePlayerBatches()
  addCall(newCall("cityvista",keyboard,mouse,draw))
