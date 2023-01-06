import cityscape
import cityplay
import cityvista
import cityeval
import citytext
import strutils
import sequtils
import math
import algorithm
import os
import sugar

const
  highwayVal = 1000
  valBar = 2500
  posPercent = [1.0,0.3,0.3,0.3,0.3,0.3,0.3,0.25,0.24,0.22,0.20,0.18,0.15]

type
  Move = tuple[pieceNr,die,fromSquare,toSquare,eval:int]
  Square = object
    vals:seq[tuple[evalDesc:string,val:int]]
    nrOfPlayerPieces*:array[6,int]
  Board = array[0..60,Square]

var
  aiDone,aiWorking:bool
  hypo:Hypothetic
  board:Board

proc anyPieceOn(squares:seq[int]): bool = 
  squares.anyIt(turn.player.hasPieceOn(it))

proc boardVals() =
  for highway in highways:
    board[highway].vals.add ("highway",highwayVal)
  for square in bars:
      board[square].vals.add ("bar",barVal(turn.player.piecesOnSquares))

proc blueVals() =
  for card in turn.player.cards:
    for square in card.squares.required:
      board[square].vals.add (
        card.title,card.cash div (
          if anyPieceOn(card.squares.required): 1 else: 2
        )
      )

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
    if cashInPlans() > 0: 
      playSound("coins-to-table-2")

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
  isDouble() and dice[1] notIn bestDiceMoves.mapIt(it.die)[^2..^1]
#  isDouble() and bestDiceMoves.mapIt(it.die)[^1] != dice[1]

proc aiRemovePiece(hypothetical:Hypothetic,square:int): bool =
  if nrOfPiecesOn(square) == 1 and square notIn highways and square notIn gasStations:
    if turn.player.hasPieceOn(square):
      return hypothetical.requiredPiecesOn(square) < 2
    else:
      return true

proc echoCards(hypothetical:Hypothetic) =
  for card in hypothetical.cards:
    echo "card: ",card.title
    echo "eval: ",card.eval

proc runAi() =
  aiWorking = true
  drawCards()
  var 
    hypothetical:Hypothetic = (
      baseEvalBoard(turn.player.piecesOnSquares),
      turn.player.piecesOnSquares,
      turn.player.cards 
    )
  hypothetical.cards = hypothetical.sortBlues()
  turn.player.cards = hypothetical.cards
  hypo = hypothetical
  echo "board: ",hypothetical.board
  echo "dice: ",dice
  echo "posEval: ",hypothetical.evalPos()
  hypothetical.echoCards()

  if not hypothetical.reroll():
    let 
      move = hypothetical.move(dice)
      remPiece = hypothetical.aiRemovePiece(move.toSquare)
    var
      pieceRem = removePieceOn(move.toSquare)
    echo "move: ",move
    moveFromTo(move.fromSquare,move.toSquare)
    if remPiece: 
      removePlayersPiece(pieceRem)
      playSound("Gunshot")
      playSound("Deanscream-2")
    drawCards() 
    echo "discard sort:"
    hypothetical.cards = turn.player.cards
    hypothetical.pieces = turn.player.piecesOnSquares
    hypothetical.cards = hypothetical.sortBlues()
    turn.player.cards = hypothetical.cards
    hypothetical.echoCards()
  else:
    echo "reroll"
    sleep(1000)
    startDiceRoll()
    aiWorking = false
  echo "ai: done"
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
