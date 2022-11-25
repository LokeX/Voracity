import cityview
import citytext
import citydice
import strutils
import sequtils
import random
import sugar

type
  PlayerKind = enum
    human,computer,none
  PlayerColors = enum
    red,green,blue,yellow,black,white
  Player = ref object
    nr:int
    color:PlayerColors
    kind:PlayerKind
    batch:AreaHandle
    piecesOnSquares:array[5,int]
    cash:int
  Turn = ref object
    nr:int
    player:Player
    diceMoved:bool
    pieceMoved:bool
    undrawnCards:int
  Square = tuple
    evals:seq[tuple[evalDesc:string,eval:int]]
    nrOfPlayerPieces:array[6,int]
  Board = array[1..60,Square]

const
  sqOff = 43
  (bx,by) = (200,150)
  (tbxo,lryo) = (220,172)
  (tyo,byo) = (70,690)
  (lxo,rxo) = (70,1030)

  selColor = color(255,255,255,100)
  playerColors:array[PlayerColors,Color] = [
    color(1,0,0),color(0,1,0),
    color(0,0,1),color(1,1,0),
    color(255,255,255),color(1,1,1)
  ]
  highways = [5,17,29,41,53]
  gasStations = [2,15,27,37,47]
  bars = [1,16,18,20,28,35,40,46,51,54]

let
  boardImage = newImageHandle(("board", readImage("pics\\engboard.jpg")),bx,by)

addImage(boardImage)
addMouseHandle(newMouseHandle(boardImage))

proc squareNames (filePath:string): seq[string] =
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

var
  turn:Turn = nil
  squares = zipToAreaHandles(squareNames("dat\\board.txt"),squareAreas())
  players:array[1..6,Player]
  playerBatches:array[1..6,AreaHandle]
  board:Board
  moveSquares:seq[int]
  moveFromSquare:int

let
  roboto = readTypeface("fonts\\Roboto-Regular_1.ttf")
  playerFonts:array[PlayerColors,Font] = [
    fontFace(roboto,20,color(1,1,1)),
    fontFace(roboto,20,color(255,255,255)),
    fontFace(roboto,20,color(1,1,1)),
    fontFace(roboto,20,color(255,255,255)),
    fontFace(roboto,20,color(1,1,1)),
    fontFace(roboto,20,color(255,255,255)),
  ]

proc newPlayerBatches(): array[1..6,AreaHandle] =
  for index in 1..6:
    result[index] = newAreaHandle(
      "playerbatch"&index.intToStr,
      15+bx+((index-1)*200),25,170,100
    )
    addMouseHandle(newMouseHandle(result[index]))

proc wirePlayerBatches() =
  var count = 1
  for player in players:
    if player.kind != none:
      player.batch = playerBatches[count]
      inc count

proc printPlayers() =
  for player in players:
    echo "player"
    echo player.nr
    echo player.color
    echo player.kind
    echo player.piecesOnSquares
    echo player.cash

proc printBoard() =
  for i in 1..60:
    echo i,": ",board[i]

func piecesOnSquare(player:Player,square:int): int =
  if player.kind != none:
    player.piecesOnSquares.count(square)
  else:
    return 0

proc playersPiecesOnSquare(square:int): array[1..6,int] =
  for i,player in players:
    result[i] = player.piecesOnSquare(square)

proc nrOfPiecesOnSquare(square:int): int =
  playersPiecesOnSquare(square).sum

proc putPiecesOnBoard(): Board =
  for player in players:
    if player.kind != none:
      for square in player.piecesOnSquares:
        inc result[square].nrOfPlayerPieces[player.nr]

proc nextPlayer(): int =
  result = turn.player.nr+1
  while result < 6 and players[result].kind == none:
    inc result

proc nextPlayerTurn() =
  if turn == nil:
    turn = Turn(nr:1,player:players[1])
  elif nextPlayer() < 6:
    turn = Turn(nr:turn.nr,player:players[nextPlayer()])
  else:
    turn = Turn(nr:turn.nr+1,player:players[1])

proc mouseOnSquareNr(): int =
  for i,square in squares:
    if mouseOn() == square.name:
      return i

proc turnPlayerHasPieceOn(square:int): bool =
  turn.player.piecesOnSquares
  .filter(p => p != 0)
  .any(p => p == square)

proc hasLegalMove(square:int): bool =
  square in highways or not turn.diceMoved

proc moveablePieceOn(square:int): bool =
  turnPlayerHasPieceOn(square) and 
  hasLegalMove(square)

proc initSquareHandles() =
  for areaHandle in squares:
    addMouseHandle(newMouseHandle(areaHandle))

proc newPlayers(kind:array[6,PlayerKind]): array[6,Player] =
  randomize()
  var randomPosition = rand(0..5)
  for color in PlayerColors:
    while result[randomPosition] != nil: 
      randomPosition = rand(0..5)
    result[randomPosition] = Player(
      nr:randomPosition,
      color:color,
      kind:kind[color.ord],
      piecesOnSquares:highways,
      cash:250000
    )

proc showFonts(b:var Boxy) =
  b.drawText("font1",1500,50,"This is font: cabalB20Black",cabalB20Black)
  b.drawText("font2",1500,100,"This is font: cabal30White",cabal30White)
  b.drawText("font3",1500,150,"This is font: confes40Black",confes40Black)
  b.drawText("font4",1500,200,"This is font: aovel30White",aovel30White)
  b.drawText("font5",1500,250,"This is font: roboto20White",roboto20White)
  b.drawText("font6",1500,300,"This is font: ibm20White",ibm20White)

proc pieceOn(player:Player,squareNr:int): Area =
  var
    (x,y,w,h) = squares[squareNr].area
  if w == 35:
    result = (x+5,y+6+(player.color.ord*15),w-10,12)
  else:
    result = (x+6+(player.color.ord*15),y+5,12,h-10)

func moveToSquare(fromSquare:int,die:int): int =
  result = fromSquare+die
  if result > 60: result -= 60

proc moveToSquares(fromSquare:int,dice:array[2,int]): seq[int] =
  if fromSquare > 0 and fromSquare <= 60:
    if fromSquare in highways: result.add(gasStations)
    for die in dice:
      result.add(moveToSquare(fromSquare,die))
      if fromSquare in highways:
        result.add(gasStations.map(gasStation => moveToSquare(gasStation,die)))
  else:
    return @[]

proc moveToSquares(fromSquare:int): seq[int] = moveToSquares(fromSquare,dice)

proc movePiece(fromSquare,toSquare:int) =
  var pieceNr = turn.player.piecesOnSquares.find(fromSquare)
  if pieceNr > -1: turn.player.piecesOnSquares[pieceNr] = toSquare

proc getColor(player:Player): Color = playerColors[player.color]

func offsetArea(a:Area,offset:int): Area = (a.x+offset,a.y+offset,a.w,a.h)

proc drawBatchText(b:var Boxy,player:Player) =
  let
    offset = offsetArea(player.batch.area,5)    
    lines = [
      "Turn: "&turn.nr.intToStr,
      "Cash: "&player.cash.intToStr
    ]
  for i,line in lines:
    b.drawText(
      "batch"&player.nr.intToStr&i.intToStr,
      offset.x.toFloat,
      offset.y.toFloat+(i.toFloat*20),
      line,
      playerFonts[player.color]
    )

proc drawBatch(b:var Boxy,player:Player) =
  let offset = offsetArea(player.batch.area,5)
  b.drawRect(offset.toRect,color(255,255,255,150))
  b.drawRect(player.batch.area.toRect,player.getColor)

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    var clickedSquareNr = mouseOnSquareNr()
    if m.button == MouseRight:
      moveSquares = @[]
    elif moveSquares.len == 0:
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

proc draw (b:var Boxy) =
  b.drawImage("board",vec2(bx.toFloat,by.toFloat))
  b.drawText("text7",800,1025,mouseOn(),aovel60White)
  b.drawText("text8",400,1025,
    "Square nr: "&(if mouseOnSquareNr() == 0: "n/a" else: mouseOnSquareNr().intToStr),
    aovel60White
  )
  for player in players:
    if player.kind != none:
      b.drawBatch(player)
      b.drawBatchText(player)
  for moveSquare in moveSquares:
    b.drawRect(squares[moveSquare].area.toRect,selColor)
  for player in players:
    for square in player.piecesOnSquares:
      b.drawRect(player.pieceOn(square).toRect,player.getColor)

proc initCityPlay*() =
  initSquareHandles()
  playerBatches = newPlayerBatches()
  players = newPlayers([human,human,human,human,human,human])
  wirePlayerBatches()
  printPlayers()
  board = putPiecesOnBoard()
  for highway in highways:
    echo highway,": ",players[1].piecesOnSquare(highway)
    echo highway,": ",playersPiecesOnSquare(highway)
    echo highway,": ",nrOfPiecesOnSquare(highway)
  printBoard()
  nextPlayerTurn()
  echo "Turn:"
  echo "nr: ",turn.nr
  echo "player nr: ",turn.player.nr
  addCall(newCall("cityplay",keyboard,mouse,draw))