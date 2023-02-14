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
  aiDone,aiWorking,autoEndTurn:bool
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

proc aiTurn(): bool =
  not aiWorking and 
  turn != nil and 
  turn.player.kind == computer and 
  not isRollingDice()

proc drawCards() =
  while nrOfUndrawnBlueCards > 0:
    drawBlueCard()
    playSound("page-flip-2")
    if cashInPlans() > 0: 
      playSound("coins-to-table-2")

proc reroll(hypothetical:Hypothetic): bool =
  let 
    bestDiceMoves = hypothetical.bestDiceMoves()
    bestDice = bestDiceMoves.mapIt(it.die)
  echo "dice: ",dice

#[   echo "bestDiceMoves:"
  echo bestDiceMoves
 ]#
  echo "bestDice:"
  echo bestDice
  isDouble() and dice[1] notIn bestDice[^2..^1]

proc echoCards(hypothetical:Hypothetic) =
  for card in hypothetical.cards:
    echo "card: ",card.title
    echo "eval: ",card.eval

proc knownBlues(): seq[BlueCard] =
  result.add usedCards
  result.add turn.player.cards

func cardsThatRequire(cards:seq[BlueCard],square:int): seq[BlueCard] =
  cards.filterIt(square in it.squares.required or square in it.squares.oneInMoreRequired)

proc planChanceOn(square:int): float =
  let 
    knownCards = knownBlues()
    unknownCards = allBlueCards.filterIt(it notIn knownCards)
  unknownCards.cardsThatRequire(square).len.toFloat/unknownCards.len.toFloat

proc hasPlanChanceOn(player:Player,square:int): float =
  planChanceOn(square)*player.cards.len.toFloat

proc enemyKill(hypothetical:Hypothetic,move:Move): bool =
  if turn.player.hasPieceOn(move.toSquare): return false else:
    let 
      planChance = removePieceOn(move.toSquare).player.hasPlanChanceOn(move.toSquare)
      barKill = move.toSquare in bars and (
        hypothetical.countBars() > 1 or nrOfPlayers() < 3
      )
    echo "removePiece, planChance: ",planChance
    planChance > 0.05 or barKill

proc aiRemovePiece(hypothetical:Hypothetic,move:Move): bool =
  move.toSquare.hasRemovablePiece and (hypothetical.friendlyFireAdviced(move) or 
  hypothetical.enemyKill(move))

proc moveAi(hypothetical:Hypothetic): Hypothetic =
  let 
    move = hypothetical.move(dice)
    currentPosEval = hypothetical.evalPos()
  if move.eval.toFloat >= currentPosEval.toFloat*0.75:
    let 
      removePiece = hypothetical.aiRemovePiece(move)
      pieceToRemove = removePieceOn(move.toSquare)
    echo "move: ",move
    moveFromTo(move.fromSquare,move.toSquare)
    if removePiece:
      removePlayersPiece(pieceToRemove)
      playSound("Gunshot")
      playSound("Deanscream-2")
    result = hypothetical
    result.pieces = turn.player.piecesOnSquares
  else:
    echo "ai skips move:"
    echo "currentPosEval: ",currentPosEval
    echo "moveEval: ",move.eval
    return hypothetical

proc aiReroll() =
  echo "reroll"
  sleep(1000)
  startDiceRoll()
  aiWorking = false

proc aiDraw(hypothetical:Hypothetic): Hypothetic =
  drawCards()
  result = hypothetical
  result.cards = turn.player.cards
  result.cards = result.comboSortBlues()
  turn.player.cards = result.cards
  hypothetical.echoCards()

proc aiTakeTurn() =
  aiWorking = true
  var hypothetical = hypotheticalInit().aiDraw
  if not hypothetical.reroll():
    hypothetical = hypothetical.moveAi()
    hypothetical = hypothetical.aiDraw
    if autoEndTurn and not gameWon(): 
      endTurn()
      aiWorking = false
  else:
    aiReroll()
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
  if k.button == KeyE: autoEndTurn = not autoEndTurn
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

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState) and m.button == MouseRight:
    if aiDone:
      aiDone = false
      aiWorking = false

proc draw (b:var Boxy) =
  if turn != nil: b.drawVals()

proc cycle() =
  if aiTurn(): aiTakeTurn()

proc initCityai*() =
  addCall(newCall("cityai",keyboard,mouse,draw,cycle))
