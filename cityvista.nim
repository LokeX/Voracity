import cityscape
import cityplay
import citytext
import times
import strutils
import sequtils

type 
  Dialog = ref object
    area,yesArea,noArea:Area
    yes,no:MouseHandle
    normal,select,bgYes,bgNo:Color
    str:string

const
  bh = 100
  bw = 170
  (wx,wy) = (15,60)
  (bx*,by*) = (wx+205,wy)
  sqOff = 43
  (tbxo,lryo) = (220,172)
  (tyo,byo) = (70,690)
  (lxo,rxo) = (70,1030)

  die1Pos = (x:1225+bx,y:by)
  die2Pos = (x:1225+bx,y:by+60)

  selColor = color(255,255,255,100)

  playerColors*:array[PlayerColors,Color] = [
    color(50,0,0),color(0,50,0),
    color(0,0,50),color(50,50,0),
    color(255,255,255),color(1,1,1)
  ]
  contrastColors:array[PlayerColors,Color] = [
    color(1,1,1),
    color(255,255,255),
    color(1,1,1),
    color(255,255,255),
    color(1,1,1),
    color(255,255,255),
  ]
  
let
  aovel* = readTypeface("fonts\\AovelSansRounded-rdDL.ttf")
  cabal* = readTypeface("fonts\\Cabal-w5j3.ttf")
  ibmB* = readTypeface("fonts\\IBMPlexMono-Bold.ttf")
  roboto* = readTypeface("fonts\\Roboto-Regular_1.ttf")
  point* = readTypeface("fonts\\ToThePointRegular-n9y4.ttf")

  boardImage = newImageHandle(("board", readImage("pics\\engboard.jpg")),bx,by)
  dieFaceImages = loadImages("pics\\diefaces\\*.gif")
  dieFace1 = newImageHandle(dieFaceImages[0],die1Pos.x,die1Pos.y)
  dieFace2 = newImageHandle(dieFaceImages[1],die2Pos.x,die2Pos.y)

var
  moveSquares:seq[int]
  selectedSquare:int = -1
  oldTime = cpuTime()
  squares*:array[0..60,AreaHandle]
  playerBatches:array[1..6,AreaHandle]
  removePieceDialog*:Dialog

proc newPlayerBatches(): array[1..6,AreaHandle] =
  for index in 1..6:
    result[index] = newAreaHandle(
      "playerbatch"&index.intToStr,
      wx,
      wy+((index-1)*(bh+50)),
      bw,
      bh
    )
    addMouseHandle(newMouseHandle(result[index]))

proc wirePlayerBatches() =
  var count = 1
  for player in players:
    if player.kind != none or turn == nil:
      player.batch = playerBatches[count]
      inc count

proc newGame() =
  players = newPlayers(playerKinds)
  nextPlayerTurn()
  wirePlayerBatches()
  shuffleBlueCards()

proc newGameSetup*() =
  turn = nil
  players = newDefaultPlayers()
  wirePlayerBatches()

proc squareNames(filePath:string): seq[string] =
  var 
    nr = 0
    text = open(filePath,fmRead)
  result.add("removedpieces")
  while not endOfFile(text):
    inc nr
    result.add(text.readLine&" Nr. "&nr.intToStr)
  close(text)

func zipToAreaHandles(names:seq[string],areas:openArray[Area]): array[0..60,AreaHandle] =
  for i,square in zip(names,areas):
    result[i] = newAreaHandle(square)

func squareAreas(): array[0..60,Area] =
  result[0] = (bx+1225,by+150,35,100)
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
  let mo = mouseOn()
  for i,square in squares:
    if mo == square.name:
      return i
  return -1

proc pieceOn(player:Player,squareNr:int): Area =
  let (x,y,w,h) = squares[squareNr].area
  if squareNr == 0:
    result = (x+5,y+6+(player.color.ord*15),w-10,12)
  else:
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
      "Plans: "&player.cards.len.intToStr,
      "Cash: "&player.cash.intToStr.insertSep(sep='.')
    ]
  for i,line in lines:
    b.drawText(
      "batch"&player.nr.intToStr&i.intToStr,
      offset.x.toFloat,
      offset.y.toFloat+(i.toFloat*20),
      line,
      fontFace(roboto,20,contrastColors[player.color])
    )

proc drawTurnCursor(b:var Boxy,player:Player) =
  let (x,y,w,_) = player.batch.area
  if player.nr == turn.player.nr:
    let time = cpuTime() - oldTime
    if time > 0 and time < 1:
      b.drawRect((x+w-20,y+5,15,15).toRect,contrastColors[player.color])
    elif time >= 2:
      oldTime = cpuTime()

proc drawAreaShadow*(b:var Boxy,area:Area,offset:int,color:Color) =
  let areaShadows = area.areaShadows(offset)
  b.drawRect(areaShadows.shadowRight.toRect,color)
  b.drawRect(areaShadows.shadowBottom.toRect,color)

proc drawBatch*(b:var Boxy,player:Player) =
  b.drawRect(player.batch.area.toRect,player.getColor)
  b.drawAreaShadow(player.batch.area,10,color(255,255,255,100))

proc drawPlayerKind(b:var Boxy,player:Player) =
  let offset = [45,25,55]
  b.drawText(
    "kind"&player.nr.intToStr,
    (player.batch.area.x+offset[playerKinds[player.nr].ord]).toFloat,
    (player.batch.area.y+30).toFloat,
    $playerKinds[player.nr],
    fontFace(aovel,30,contrastColors[player.color])
  )

proc newRemovePieceDialog(removePieceOnSquare:int): Dialog =
  let 
    area:Area = (bx+650,by+250,300,100)
    yesArea:Area = (area.x+90,area.y+50,50,30)
    noArea:Area = (area.x+160,area.y+50,50,30)
    yes:MouseHandle = newMouseHandle(newAreaHandle ("yes",yesArea))
    no:MouseHandle = newMouseHandle(newAreaHandle ("no",noArea))
  var str = $removePiece.player.color
  str = "Remove "&str&" piece on square nr. "&removePieceOnSquare.intToStr&"?"
  addMouseHandle(yes)
  addMouseHandle(no)
  Dialog(
    area:area,
    yes:yes,
    no:no,
    yesArea:yesArea,
    noArea:noArea,
    normal:color(0,0,1),
    select:color(1,0,0),
    str:str,
  )

proc endDialog(dialog:var Dialog) = 
  removeMouseHandle(dialog.no.name)
  removeMouseHandle(dialog.yes.name)
  dialog = nil

proc drawDialog(b:var Boxy,dialog:Dialog,key:string) =
  if dialog != nil and key.len > 0:
    dialog.bgYes = if mouseOn() == dialog.yes.name: dialog.select else:dialog.normal
    dialog.bgNo = if mouseOn() == dialog.no.name: dialog.select else:dialog.normal
    b.drawRect(dialog.area.toRect,color(255,255,255))
    b.drawRect(dialog.yesArea.toRect,dialog.bgYes)
    b.drawRect(dialog.noArea.toRect,dialog.bgNo)
    b.drawAreaShadow(dialog.area,10,color(255,255,255,100))
    b.drawText(
      "dialog:"&key,
      (dialog.area.x+15).toFloat,
      (dialog.area.y+10).toFloat,
      dialog.str,
      fontFace(roboto,16,color(1,1,0))
    )
    b.drawText(
      "dialogyes:"&key,
      (dialog.yesArea.x+12).toFloat,
      (dialog.yesArea.y+5).toFloat,
      "Yes",
      fontFace(roboto,16,color(1,1,1))
    )
    b.drawText(
      "dialogno:"&key,
      (dialog.noArea.x+16).toFloat,
      (dialog.noArea.y+5).toFloat,
      "No",
      fontFace(roboto,16,color(1,1,1))
    )

proc eraseSquareSelection() =
  selectedSquare = -1
  moveSquares = @[]

proc mouseRightClicked() =
  if removePieceDialog != nil:
    endDialog(removePieceDialog)
  elif moveSquares.len > 0: 
    eraseSquareSelection()
  else:
    playSound("carhorn-1")
    oldTime = cpuTime()
    if turn == nil:
      newGame()
    elif gameWon():
      newGameSetup()
    else:
      nextPlayerTurn()

proc mouseOnPlayer(): Player =
  let mo = mouseOn() 
  for player in players:
    if player.batch != nil and player.batch.name == mo:
      return player

proc togglePlayerKind() =
  if turn == nil:
    let pl = mouseOnPlayer()
    if pl != nil: 
      playerKinds[pl.nr] = playerKinds[pl.nr].toggleKind()
      playSound("Blop-Mark_DiAngelo")

proc moveReady(): bool = 
  turn != nil and not isRollingDice()

proc setDiceMoved(square:int) =
  if not turn.diceMoved:
    turn.diceMoved = not (
      square in gasStations and 
      selectedSquare in highways or
      selectedSquare == 0
    )

proc moveSelectedPieceTo(toSquare:int) =
  movePiece(selectedSquare,toSquare)
  setDiceMoved(toSquare)
  if selectedSquare == 0: turn.player.cash -= piecePrice
  if toSquare in bars: 
    inc nrOfUndrawnBlueCards
    playSound("can-open-1")
  if cashInPlans() > 0:
    playSound("coins-to-table-2")
  echo "undrawn cards: ",nrOfUndrawnBlueCards
  eraseSquareSelection()
  playSound("driveBy")
  if gameWon(): playSound("applause-2")

proc checkRemovePieceOn(square:int) =
  if nrOfPiecesOn(square) == 1 and not square in highways and not square in gasStations:
    setRemovePieceOn(square)
    removePieceDialog = newRemovePieceDialog(square)

proc selectPieceOn(square:int) =
  selectedSquare = square
  moveSquares = moveToSquares(square)
  playSound("carstart-1")

proc isRemovedPiece(square:int): bool =
  square == 0 and turn.player.cash >= piecePrice

proc selectablePieceOn(square:int): bool = 
  moveSquares.len == 0 and turn.player.hasPieceOn(square) and
  (not turn.diceMoved or square in highways or isRemovedPiece(square))

proc pieceSelectAndMove() =
  let square = mouseOnSquareNr()
  if moveReady() and square in 0..60:
    if selectablePieceOn(square):
      selectPieceOn(square)
    elif square in moveSquares:
      checkRemovePieceOn(square)
      moveSelectedPieceTo(square)
  else: 
    selectedSquare = -1
    moveSquares = @[]

proc mouseOnDice(): bool =
  mouseOn(dieFace1) or mouseOn(dieFace2)

proc diceRoll() =
  if mouseOnDice() and isDouble(): startDiceRoll()

proc dialog() =
  if mouseOn() == removePieceDialog.yes.name:
    removePlayersPiece()
    endDialog(removePieceDialog)
    playSound("Deanscream-2")
  else:
    if mouseOn() == removePieceDialog.no.name:
      endDialog(removePieceDialog)

proc mouseLeftClicked() =
  if removePieceDialog != nil:
    dialog()
  else:
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

func imagePos*(image:ImageHandle): Vec2 =
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
      for square in player.piecesOnSquares.deduplicate():
        let 
          (x,y,w,h) = player.pieceOn(square)
          nrOfplayersPiecesOnSquare = player.piecesOnSquare(square)
        b.drawRect((x,y,w,h).toRect,player.getColor)
        if turn != nil and player.nr == turn.player.nr and square == selectedSquare:
          b.drawRect((x+3,y+3,w-6,h-6).toRect,contrastColors[player.color])
        if nrOfplayersPiecesOnSquare > 1:
          b.drawText(
            $player.color&"nrofpieceson"&square.intToStr,
            x.toFloat+2,
            y.toFloat,
            nrOfplayersPiecesOnSquare.intToStr,
            fontFace(ibmB,10,color(1,1,1))
          )

proc drawTopBar(b:var Boxy) =
  b.drawRect((0,0,windowWidth(),40).toRect,color(75,150,240))
  b.drawText(
    "togglecash",
    10,5,
    "(c)ash to win: "&cashAmountToWin().intToStr,
    fontFace(ibmB,20,color(1,1,1))
  )
  if turn != nil:
    b.drawText(
      "newgame",
      320,5,
      "(n)ew game",
      fontFace(ibmB,20,color(1,1,1))
    )
    b.drawText(
      "dice##",
      500,5,
      "(d)ice(##)set",
      fontFace(ibmB,20,color(1,1,1))
    )
#[   b.drawRect((0,0,windowWidth(),40).toRect,color(75,150,240))
  b.drawText("text7",10,5,mouseOn(),fontFace(ibmB,20,color(1,1,1)))
  b.drawText(
    "text9",
    300,5,
    $(if mouseOnPlayer()!=nil:mouseOnPlayer() else:players[1]).color,
    fontFace(ibmB,20,color(1,1,1))
  )
  b.drawText(
    "text8",
    400,5,
    "Square nr: "&(if mouseOnSquareNr() == 0: "n/a" else: mouseOnSquareNr().intToStr),
    fontFace(ibmB,20,color(1,1,1))
  )
 ]#
proc draw (b:var Boxy) =
  b.drawDice()
  b.drawBoard()
  b.drawPlayerBatches()
  b.drawMoveSquares()
  b.drawPiecesOnSquares()
  if removePieceDialog != nil: 
    b.drawDialog(removePieceDialog,"removepiece")
  b.drawTopBar()
#  b.showFonts()

var 
  dieEdit:int
  lastButton:Button

proc keyboard (k:KeyEvent) =
  if k.button == KeyN:
    playSound("carhorn-1")
    newGameSetup()
  if k.button == KeyC:
    toggleCashToWin()
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
  lastButton = k.button

proc mouse (m:MouseEvent) =
#  if removePieceDialog != nil: removePieceDialog.mouseOver()
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
