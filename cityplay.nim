import cityview
import citytext
import strutils
import sequtils
import random

type
  PlayerKind = enum
    human,computer,none
  PlayerColors = enum
    red,green,blue,yellow,black,white
  Player = ref object
    nr:int
    color:PlayerColors
    kind:PlayerKind
    piecesOnSquares:array[5,int]
    cash:int
  Turn = ref object
    nr:int
    player:Player
    diceCast:bool
    pieceMoved:bool
    undrawnCards:int

const
  sqOff = 43
  (bx,by) = (200,100)
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
  board = newImageHandle(("board", readImage("engboard.jpg")),bx,by)

addImage(board)
addMouseHandle(newMouseHandle(board))

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
  players:array[0..5,Player]

proc nextPlayer(): int =
  result = turn.player.nr+1
  while result < 6 and players[result].kind == none:
    inc result

proc nextPlayerTurn() =
  if turn == nil:
    turn = Turn(nr:1,player:players[0])
  elif nextPlayer() < 6:
    turn = Turn(nr:turn.nr,player:players[nextPlayer()])
  else:
    turn = Turn(nr:turn.nr+1,player:players[0])

proc mouseOnSquareNr(): int =
  for i,square in squares:
    if mouseOn() == square.name:
      return i

proc initAreaHandles() =
  for areaHandle in squares:
    addMouseHandle(newMouseHandle(areaHandle))

proc newPlayers() =
  randomize()
  var 
    playerOrder = [-1,-1,-1,-1,-1,-1]
    randomPosition = rand(0..5)
  for color in PlayerColors:
    while (playerOrder[randomPosition] != -1): 
      randomPosition = rand(0..5)
    playerOrder[randomPosition] = 0
    players[randomPosition] = Player(
      nr:randomPosition,
      color:color,
      kind:human,
      piecesOnSquares:highways,
      cash:250000
    )
#    players[color.ord] = Player(color:color,kind:human,piecesOnSquares:highways,cash:250000)

proc pieceOn(player:Player,squareNr:int): Area =
  var
    (x,y,w,h) = squares[squareNr].area
  if w == 35:
    result = (x+5,y+6+(player.color.ord*15),w-10,12)
  else:
    result = (x+6+(player.color.ord*15),y+5,12,h-10)

proc playerColor(color:PlayerColors): Color = playerColors[color]

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    if mouseOn(board):
      playSound("carstart-1")

proc draw (b:var Boxy) =
  b.drawImage("board",vec2(200, 100))
  b.drawText("text1",400,25,
    "Square nr: "&(if mouseOnSquareNr() == 0: "n/a" else: mouseOnSquareNr().intToStr)
  )
  for player in players:
    for square in player.piecesOnSquares:
      b.drawRect(player.pieceOn(square).toRect,player.color.playerColor)

proc initCityPlay*() =
  initAreaHandles()
  newPlayers()
  nextPlayerTurn()
  addCall(newCall("cityplay",keyboard,mouse,draw))