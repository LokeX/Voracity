import cityscape
import cityplay
import cityvista
import citytext
import strutils
import sequtils

const
  highwayVal = 3000
  valBar = 5000

type
  Dice = array[2,int]
  HypoDice = array[15,Dice]
  HypoMove = object
    pieceNr:int
    dice:Dice
    toSquares:seq[int]

var
  hypoDice: HypoDice
  hypoMoves:seq[HypoMove]
  board:Board

proc getHypoDice(): HypoDice =
  var count = 0
  for die1 in 1..5:
    for die2 in 2..6:
      if die1 != die2 and die2 > die1:
        result[count] = [die1,die2]
        inc count

proc getHypoMoves(hypoDice:HypoDice): seq[HypoMove] =
  for pNr,piece in turn.player.piecesOnSquares:
    for dice in hypoDice:
      result.add HypoMove(
        pieceNr:pNr,
        dice:dice,
        toSquares:moveToSquares(piece,dice)
      )

proc pieces(): array[5,int] = turn.player.piecesOnSquares

proc countBars(): int = pieces().countIt(it in bars)

proc barVal(): int = valBar-(1000*countBars())

proc anyPieceOn(squares:seq[int]): bool = 
  squares.anyIt(turn.player.hasPieceOn(it))

proc blueVals(board:var Board) =
  for card in turn.player.cards:
    for square in card.squares.required:
      board[square].evals.add (
        card.title,card.cash div (
          if anyPieceOn(card.squares.required): 1 else: 2
        )
      )

proc boardVals(board:var Board) =
  for highway in highways:
    board[highway].evals.add ("highway",highwayVal)
  for square in bars:
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
      for i,val in values:
        let (desc,eval) = val
        b.drawText(
          "values:"&desc&i.intToStr,
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
    computeBoard(board)
    hypoDice = getHypoDice()
    for dice in hypoDice:
      echo dice
    hypoMoves = getHypoMoves(hypoDice)
    nextPlayerTurn()

proc initCityai*() =
  addCall(newCall("cityai",keyboard,mouse,draw,cycle))