import cityscape
import cityplay
import cityvista
import citytext
import strutils
import sequtils

proc pieces(): array[5,int] = turn.player.piecesOnSquares

proc countBars(): int = pieces().countIt(it in bars)

proc barVal(): int = 25-(5*countBars())

proc blueVals(board:var Board) =
  for card in turn.player.cards:
    for square in card.squares.required:
      board[square].evals.add (card.title,card.cash div 1000)

proc boardVals(board:var Board) =
  for square in 0..60:
    if square in highways:
      board[square].evals.add ("highway",10)
    elif square in bars:
      board[square].evals.add ("bar",barVal())

proc putPiecesOnBoard(board:var Board) =
  for player in players.filterIt(it.kind != none):
    for square in player.piecesOnSquares:
      inc board[square].nrOfPlayerPieces[player.nr-1]

proc computeBoard(board:var Board) =
  blueVals(board)
  boardVals(board)

proc drawVals(b:var Boxy) =
  let mo = mouseOnSquareNr()
  if mo > -1 and mo <= 60:
    var board:Board
    computeBoard(board)
    let values = board[mo].evals
    if values.len > 0:
      let area:Area = (bx+220,by+220,200,35*values.len)
      b.drawRect(area.toRect,color(1,1,1))
      b.drawAreaShadow(area,2,color(255,255,255,150))
      for val in values:
        let (desc,eval) = val
        b.drawText(
          "values:"&desc,
          area.x.toFloat+10,
          area.y.toFloat+5,
          desc&": "&eval.intToStr,
          fontFace(roboto,20,color(0,0,0))
        )

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune
  else:
    echo k.button

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    echo "pos: ",m.pos

proc draw (b:var Boxy) =
  if turn != nil: b.drawVals()

proc cycle() =
  if turn != nil and turn.player.kind == computer:
    echo "ai online"

proc initCityai*() =
  addCall(newCall("cityai",keyboard,mouse,draw,cycle))