import cityscape
import cityplay
import cityvista
import citytext
import strutils
import sequtils
import math
import algorithm
import os
import sugar

const
  highwayVal = 1000
  valBar = 5000
  posPercent = [1.0,0.3,0.3,0.3,0.3,0.3,0.3,0.25,0.24,0.22,0.20,0.18,0.15]

type
  Move = tuple[pieceNr,die,fromSquare,toSquare,eval:int]
  Square = object
    vals:seq[tuple[evalDesc:string,val:int]]
    nrOfPlayerPieces*:array[6,int]
  Board = array[0..60,Square]
  EvalBoard = array[61,int]
  Hypothetic = tuple
    board:array[61,int]
    pieces:array[5,int]
    cards:seq[BlueCard]

var
  aiDone,aiWorking:bool
  hypo:Hypothetic
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

func anyOn(pieces:openArray[int],squares:seq[int]): bool = pieces.anyIt(it in squares)

func piecesOn(hypothetical:Hypothetic,square:int): int =
  hypothetical.pieces.count(square)

func requiredPiecesOn(hypothetical:Hypothetic,square:int): int =
  hypothetical.cards.mapIt(it.squares.required.count(square)).max

func freePiecesOn(hypothetical:Hypothetic,square:int): int =
  hypothetical.piecesOn(square) - hypothetical.requiredPiecesOn(square)

func writeBlue(evalBoard:EvalBoard,card:BlueCard,pieces:openArray[int]): EvalBoard =
  result = evalBoard
  for square in card.squares.required:
    result[square] += card.cash div (
      if pieces.anyOn(card.squares.required): 1 else: 2
    )

#[ func blueSquareVals(hypothetical:Hypothetic,squares:seq[int]): seq[int] =
  for square in squares:
 ]#    
proc posPercentages(hypothetical:Hypothetic,squares:seq[int]): seq[float] =
  var freePieces:int
  for square in squares:
    let freePiecesOnSquare = hypothetical.freePiecesOn(square)
    if freePiecesOnSquare > 0:
      freePieces += freePiecesOnSquare
    if freePieces == 0:
      result.add posPercent[square]
    else:
      result.add posPercent[square].pow(freePieces.toFloat)

proc evalSquare(hypothetical:Hypothetic,square:int): int =
  let 
    squares = toSeq(square..square+posPercent.len-1).mapIt(adjustToSquareNr(it))
    baseSquareVals = squares.mapIt(hypo.board[it].toFloat)
    squarePercent = hypothetical.posPercentages(squares)
  toSeq(0..posPercent.len-1)
  .mapIt((baseSquareVals[it]*squarePercent[it]).toInt)
  .sum

proc evalPos(hypo:Hypothetic): int = 
  hypo.pieces.mapIt(hypo.evalSquare(it)).sum

proc baseEvalBoard(pieces:array[5,int]): EvalBoard =
  result[0] = 4000
  for highway in highways: 
    result[highway] = highwayVal
  for bar in bars: 
    result[bar] = barVal(pieces)

proc evalBlue(hypo:Hypothetic,card:BlueCard): int =
  evalPos (
    baseEvalBoard(hypo.pieces)
    .writeBlue(card,hypo.pieces),
    hypo.pieces,
    hypo.cards
  )

proc evalBlues(hypothetical:Hypothetic): seq[BlueCard] =
  for card in hypothetical.cards:
    var tc = card
    tc.eval = hypothetical.evalBlue(card)
    result.add tc
  result.sort((a,b) => a.eval - b.eval)

proc evalMove(hypo:Hypothetic,pieceNr,toSquare:int): int =
  var pieces = hypo.pieces
  pieces[pieceNr] = toSquare
  (hypo.board,pieces,hypo.cards).evalPos()

proc bestMove(hypothetical:Hypothetic,pieceNr,fromSquare,die:int): Move =
  let
    squares = moveToSquares(fromSquare,die)
    evals = squares.mapIt(hypothetical.evalMove(pieceNr,it))
    bestEval = evals.maxIndex
    bestSquare = squares[bestEval]
    eval = evals[bestEval]
  result = (pieceNr,die,fromSquare,bestSquare,eval)

proc move(hypothetical:Hypothetic,dice:openArray[int]): Move = 
  var moves:seq[Move]
  for pieceNr,fromSquare in hypothetical.pieces:
    for die in dice:
      moves.add hypothetical.bestMove(pieceNr,fromSquare,die)
  echo moves
  result = moves.sortedByIt(it.eval)[^1]

proc hypoMoves(hypothetical:Hypothetic): seq[Move] =
  for pieceNr,fromSquare in hypothetical.pieces:
    for die in 1..6: result.add hypothetical.bestMove(pieceNr,fromSquare,die)

proc aiCanRun(): bool =
  not aiWorking and 
  turn != nil and 
  turn.player.kind == computer and 
  not isRollingDice()

proc drawCards() =
  while nrOfUndrawnBlueCards > 0:
    drawBlueCard()

proc bestDiceMoves(hypothetical:Hypothetic): seq[Move] =
  let moves = hypothetical.hypoMoves()
  for die in 1..6:
    let dieMoves = moves.filterIt(it.die == die)
    result.add dieMoves[dieMoves.mapIt(it.eval).maxIndex()]
  result.sortedByIt(it.eval)

proc reroll(hypothetical:Hypothetic): bool =
  let bestDiceMoves = hypothetical.bestDiceMoves()
  for diceMove in bestDiceMoves:
    echo "DiceMove: ",diceMove
  isDouble() and bestDiceMoves.mapIt(it.die)[^1] != dice[1]

proc runAi() =
  aiWorking = true
  drawCards()
  var 
    hypothetical:Hypothetic = (
      baseEvalBoard(turn.player.piecesOnSquares),
      turn.player.piecesOnSquares,
      turn.player.cards 
    )
  hypothetical.cards = hypothetical.evalBlues()
  turn.player.cards = hypothetical.cards
  hypo = hypothetical
  echo "board: ",hypothetical.board
  echo "dice: ",dice
  echo "posEval: ",hypothetical.evalPos()
  for card in hypothetical.cards:
    echo "card: "
    echo "title: ",card.title
    echo "eval: ",card.eval
  if not hypothetical.reroll():
    let move = hypothetical.move(dice)
    echo "move: ",move
    moveFromTo(move.fromSquare,move.toSquare)
    drawCards() 
    hypothetical.cards = turn.player.cards
    hypothetical.cards = hypothetical.evalBlues()
    turn.player.cards = hypothetical.cards
  else:
    sleep(1000)
    startDiceRoll()
    aiWorking = false
  aiDone = true

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
  if k.button == KeyA:
    turn.player.piecesOnSquares = hypo.pieces
    turn.player.cards = hypo.cards
    aiWorking = false
    aiDone = false
    startDiceRoll()
  if k.button == KeyN:
    aiWorking = false
    aiDone = false
    echo "n key: new game"
    playSound("carhorn-1")
    newGameSetup()
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune
  else:
    echo k.button

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState) and m.button == MouseRight:
    if aiDone:
      aiDone = false
      aiWorking = false
#      nextPlayerTurn()
    echo "pos: ",m.pos

proc draw (b:var Boxy) =
  if turn != nil: b.drawVals()

proc cycle() =
  if aiCanRun(): runAi()

proc initCityai*() =
  addCall(newCall("cityai",keyboard,mouse,draw,cycle))
