import cityscape
import cityplay
import cityvista
import citytext
import strutils
import sequtils
import math

const
  highwayVal = 3000
  valBar = 5000
  posPercent = [1.0,0.5,0.5,0.5,0.5,0.5,0.5,0.25,0.24,0.22,0.20,0.18,0.15]

type
  Dice = array[2,int]
  HypoDice = array[15,Dice]
  Move = tuple[piece,die,eval:int]
  HypoMove = object
    pieceNr:int
    dice:Dice
    toSquares:seq[int]
    evals:seq[int]
  Square = object
    vals:seq[tuple[evalDesc:string,val:int]]
    nrOfPlayerPieces*:array[6,int]
  Board = array[0..60,Square]
  EvalBoard = array[61,int]
  Hypothetic = object
    board:array[61,int]
    pieces:array[5,int]
    cards:seq[BlueCard]


var
  hypoDice: HypoDice
  hypoMoves:seq[HypoMove]
  board:Board

proc countBars(pieces:array[5,int]): int = pieces.countIt(it in bars)

proc barVal(pieces:array[5,int]): int = valBar-(1000*countBars(pieces))

proc boardVals() =
  for highway in highways:
    board[highway].vals.add ("highway",highwayVal)
  for square in bars:
      board[square].vals.add ("bar",barVal(turn.player.piecesOnSquares))

proc anyPieceOn(squares:seq[int]): bool = 
  squares.anyIt(turn.player.hasPieceOn(it))

proc blueVals() =
  for card in turn.player.cards:
    for square in card.squares.required:
      board[square].vals.add (
        card.title,card.cash div (
          if anyPieceOn(card.squares.required): 1 else: 2
        )
      )

func evalSquare(hypo:Hypothetic,square:int): int =
  let 
    squares = toSeq(square..square+posPercent.len-1).mapIt(adjustToSquareNr(it))
    piecesAhead = squares.countIt(it in hypo.pieces).toFloat-1
    squareVals = squares.mapIt(hypo.board[it].toFloat)
  toSeq(0..posPercent.len-1)
  .mapIt((squareVals[it]*posPercent[it].pow(piecesAhead)).toInt)
  .sum

func anyOn(pieces:openArray[int],squares:seq[int]): bool = pieces.anyIt(it in squares)

func evalPos(hypo:Hypothetic): int = 
  hypo.pieces.mapIt(hypo.evalSquare(it)).sum

func writeBlue(evalBoard:EvalBoard,card:BlueCard,pieces:openArray[int]): EvalBoard =
  result = evalBoard
  for square in card.squares.required:
    result[square] += card.cash div (
      if pieces.anyOn(card.squares.required): 1 else: 2
    )

proc baseEvalBoard(pieces:array[5,int]): EvalBoard =
  for highway in highways: 
    result[highway] = highwayVal
  for bar in bars: 
    result[bar] = barVal(pieces)

func evalBlue(hypo:Hypothetic,card:BlueCard): int =
  Hypothetic(board:baseEvalBoard(hypo.pieces).writeBlue(card,hypo.pieces)).evalPos()

func writeBlues(evalBoard:EvalBoard,cards:seq[BlueCard],pieces:openArray[int]): EvalBoard =
  for card in cards:
    result = result.writeBlue(card,pieces)

proc evalMove(hypo:Hypothetic,pieceNr,toSquare:int): int =
  var pieces = hypo.pieces
  pieces[pieceNr] = toSquare
  Hypothetic(pieces:pieces,board:hypo.board,cards:hypo.cards).evalPos()

proc initHypoDice() =
  var count = 0
  for die1 in 1..5:
    for die2 in 2..6:
      if die1 != die2 and die2 > die1:
        hypoDice[count] = [die1,die2]
        inc count

proc initHypoMoves(hypo:Hypothetic) =
  for pNr,piece in hypo.pieces:
    for dice in hypoDice:
      let toSquares = moveToSquares(piece,dice)
      hypomoves.add HypoMove(
        pieceNr:pNr,
        dice:dice,
        toSquares:toSquares,
        evals:toSquares.mapIt(hypo.evalSquare(it))
      )

proc bestMove(hypo:Hypothetic): Move =
  var bestMoves:seq[Move]
  for pieceNr,square in hypo.pieces:
    for die in 1..6:
      bestMoves.add (
        pieceNr,
        die,
        moveToSquares(square,die)
        .mapIt(hypo.evalMove(pieceNr,it)).max
      )
  bestMoves[bestMoves.mapIt(it.eval).maxIndex]

proc putPiecesOnBoard(board:var Board) =
  for player in players.filterIt(it.kind != none):
    for square in player.piecesOnSquares:
      inc board[square].nrOfPlayerPieces[player.nr-1]

proc computeBoard() =
  blueVals()
  boardVals()

proc drawVals(b:var Boxy) =
  let mo = mouseOnSquareNr()
  if mo > -1 and mo <= 60:
    var board:Board
    computeBoard()
    let values = board[mo].vals
    if values.len > 0:
      let area:Area = (bx+220,by+220,200,35*values.len)
      b.drawRect(area.toRect,color(1,1,1))
      b.drawAreaShadow(area,2,color(255,255,255,150))
      for i,val in values:
        let (desc,sval) = val
        b.drawText(
          "values:"&desc&i.intToStr,
          area.x.toFloat+10,
          area.y.toFloat+5,
          desc&": "&sval.intToStr,
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
    var hypo = Hypothetic(
      board:baseEvalBoard(turn.player.piecesOnSquares),
      pieces:turn.player.piecesOnSquares,
      cards:turn.player.cards
      )
    while nrOfUndrawnBlueCards > 0:
      drawBlueCard()
      dec nrOfUndrawnBlueCards
    nextPlayerTurn()

proc initCityai*() =
  addCall(newCall("cityai",keyboard,mouse,draw,cycle))

echo 0.5.pow(2)
echo 0.5.pow(3)
