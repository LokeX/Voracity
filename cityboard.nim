import cityview
import strutils
import sequtils

type
  Players = enum
    red,green,blue,yellow,black,white

const
  sqOff = 43
  (bx,by) = (200,100)
  (tbxo,lryo) = (220,172)
  (tyo,byo) = (70,690)
  (lxo,rxo) = (70,1030)

  selColor = color(255,255,255,100)
  playerColors = [
    color(1,0,0),color(0,1,0),
    color(0,0,1),color(1,1,0),
    color(255,255,255),color(1,1,1)
  ]

let
  board = newImageHandle(("board", readImage("engboard.jpg")),bx,by)

addImage(board)
addMouseHandle(newMouseHandle(board))

proc squareNames (filePath:string): seq[string] =
  var 
    nr = 1
    text = open(filePath,fmRead)
  while not endOfFile(text):
    result.add(text.readLine&" Nr. "&nr.intToStr)
    inc nr
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
  squares = zipToAreaHandles(squareNames("dat\\board.txt"),squareAreas())

for areaHandle in squares:
  addMouseHandle(newMouseHandle(areaHandle))

proc pieceOnSquare(player:Players,squareNr:int): Area =
  var
    (x,y,w,h) = squares[squareNr].area
  if w == 35:
    result = (x+5,y+6+(player.ord*15),w-10,12)
  else:
    result = (x+6+(player.ord*15),y+5,12,h-10)

proc playerColor(player:Players): Color = playerColors[player.ord]

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    if mouseOn(board): 
      playSound("carstart-1")

proc draw (b:var Boxy) =
  b.drawImage("board",vec2(200, 100))
#[   for handle in squares:
    b.drawRect(handle.area.toRect(),selColor) ]#
  for player in Players:
    for highway in [5,17,29,41,53]:
      b.drawRect(player.pieceOnSquare(highway).toRect,player.playerColor)
#      b.drawRect(player.pieceOnSquare(17).toRect,player.playerColor)

proc initCityBoard*() =
  addCall(newCall("board",keyboard,mouse,draw))