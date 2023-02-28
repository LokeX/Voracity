import cityscape
import cityplay
import cityvista
import cityeval
import sequtils
import os

var
  aiDone,aiWorking:bool
  autoEndTurn = true

proc aiTurn(): bool =
  not aiWorking and 
  turn != nil and 
  turn.player.kind == computer and 
  not isRollingDice()

proc drawCards() =
  while nrOfUndrawnBlueCards > 0:
    drawBlueCard()
    echo $turn.player.color&" player draws: ",turn.player.cards[^1].title
    playSound("page-flip-2")
    let cashedPlans = cashInPlans()
    if cashedPlans.len > 0: 
      playSound("coins-to-table-2")
      echo $turn.player.color&" player cashes plans:"
      for plan in cashedPlans: echo plan.title

proc reroll(hypothetical:Hypothetic): bool =
  let 
    bestDiceMoves = hypothetical.bestDiceMoves()
    bestDice = bestDiceMoves.mapIt(it.die)
  echo "dice: ",dice
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
  echo $turn.player.color&" player takes turn:"
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

proc keyboard (k:KeyEvent) =
  if k.button == KeyE: autoEndTurn = not autoEndTurn
  if k.button == KeyN:
    echo "n key: new game"
    aiWorking = false
    aiDone = true
    endDiceRoll()
    playSound("carhorn-1")
    newGameSetup()

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState) and m.button == MouseRight:
    if aiDone:
      aiDone = false
      aiWorking = false

proc cycle() =
  if aiTurn(): aiTakeTurn()

proc initCityai*() =
  addCall(newCall("cityai",keyboard,mouse,nil,cycle))
