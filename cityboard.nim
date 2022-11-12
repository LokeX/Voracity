import cityview

let
  board = newImageHandle(("board", readImage("engboard.jpg")),200,100)
  selColor = color(255,255,255,100)

addImage(board)
addMouseHandle(newMouseHandle(board))

proc lineReadFile (filePath:string): seq[string] =
  var 
    text = open(filePath,fmRead)
  while not endOfFile(text):
    result.add(text.readLine)
  close(text)

var
  squares = lineReadFile("dat\\board.txt")

echo squares

func toRect(x,y,w,h:int): Rect =
  rect(vec2(x.toFloat,y.toFloat),vec2(w.toFloat,h.toFloat))

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    if mouseOn(board):
      playSound("carstart-1")

proc draw (b:var Boxy) =
  b.drawImage("board",vec2(200, 100))
  for i in 0..17:
    b.drawRect(toRect(420+(i*43),170,35,100),selColor)
    b.drawRect(toRect(420+(i*43),790,35,100),selColor)
  for i in 0..11:
    b.drawRect(toRect(270,272+(i*43),100,35),selColor)
    b.drawRect(toRect(1230,272+(i*43),100,35),selColor)

proc initCityBoard*() =
  addCall(newCall("board",keyboard,mouse,draw))