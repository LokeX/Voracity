import cityscape
import cityplay
import cityvista
import cityeval
import citytext
import strutils
import sequtils
import os

type
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
      board[square].vals.add ("bar",1000)

proc blueVals() =
  for card in turn.player.cards:
    for square in card.squares.required:
      board[square].vals.add (
        card.title,card.cash div (
          if anyPieceOn(card.squares.required): 1 else: 2
        )
      )

proc aiCanRun(): bool =
  not aiWorking and 
  turn != nil and 
  turn.player.kind == computer and 
  not isRollingDice()

proc drawCards() =
  while nrOfUndrawnBlueCards > 0:
    drawBlueCard()
    for card in turn.player.cards: echo "player draws: ",card.title
    if cashInPlans() > 0: 
      playSound("coins-to-table-2")

proc reroll(hypothetical:Hypothetic): bool =
  let bestDiceMoves = hypothetical.bestDiceMoves()
  for diceMove in bestDiceMoves:
    echo "DiceMove: ",diceMove
  isDouble() and dice[1] notIn bestDiceMoves.mapIt(it.die)[^2..^1]
#  isDouble() and bestDiceMoves.mapIt(it.die)[^1] != dice[1]

proc echoCards(hypothetical:Hypothetic) =
  for card in hypothetical.cards:
    echo "card: ",card.title
    echo "eval: ",card.eval

proc aiRemovePiece(hypothetical:Hypothetic,square:int): bool =
  if square.hasRemovablePiece:
    if turn.player.hasPieceOn(square):
      return hypothetical.requiredPiecesOn(square) < 2
    else:
      return true

proc moveAi(hypothetical:Hypothetic) =
  let 
    move = hypothetical.move(dice)
    currentPosEval = hypothetical.evalPos()
  echo "move: ",move
  if move.eval >= currentPosEval:
    let removePiece = hypothetical.aiRemovePiece(move.toSquare)
    moveFromTo(move.fromSquare,move.toSquare)
    if removePiece:
      removePlayersPiece(removePieceOn(move.toSquare))
      playSound("Gunshot")
      playSound("Deanscream-2")
  else:
    echo "ai skips move:"
    echo "currentPosEval: ",currentPosEval
    echo "moveEval: ",move.eval

proc runAi() =
  aiWorking = true
  drawCards()
  var hypothetical = hypotheticalInit()
  hypothetical.cards = hypothetical.comboSortBlues()
  turn.player.cards = hypothetical.cards
  hypo = hypothetical
  echo "dice: ",dice
  hypothetical.echoCards()
  echo "old sort:"
  for blue in hypothetical.sortBlues(): echo blue.title
  if not hypothetical.reroll():
    hypothetical.moveAi()
    hypothetical.pieces = turn.player.piecesOnSquares
    drawCards() 
    echo "discard sort:"
    hypothetical.cards = turn.player.cards
    hypothetical.cards = hypothetical.comboSortBlues()
    turn.player.cards = hypothetical.cards
    hypothetical.echoCards()
    echo "old sort:"
    for blue in hypothetical.sortBlues(): echo blue.title
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
