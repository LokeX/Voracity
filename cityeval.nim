import cityplay
import sequtils
import math
import algorithm
import sugar

const
  highwayVal* = 1000
  valBar = 2500
  posPercent = [1.0,0.3,0.3,0.3,0.3,0.3,0.3,0.25,0.24,0.22,0.20,0.18,0.15]

type
  Move* = tuple[pieceNr,die,fromSquare,toSquare,eval:int]
  EvalBoard* = array[61,int]
  Hypothetic* = tuple
    board:array[61,int]
    pieces:array[5,int]
    cards:seq[BlueCard]

proc countBars(pieces:array[5,int]): int = pieces.countIt(it in bars)

proc barVal*(pieces:array[5,int]): int = valBar-(500*countBars(pieces))

func piecesOn(hypothetical:Hypothetic,square:int): int =
  hypothetical.pieces.count(square)

func requiredPiecesOn*(hypothetical:Hypothetic,square:int): int =
  if hypothetical.cards.len == 0: 0 else:
    hypothetical.cards.mapIt(it.squares.required.count(square)).max

func freePiecesOn(hypothetical:Hypothetic,square:int): int =
  hypothetical.piecesOn(square) - hypothetical.requiredPiecesOn(square)

proc covers(pieceSquare,coverSquare:int): bool =
  for die in 1..6:
    if coverSquare in moveToSquares(pieceSquare,die):
      return true

proc isCovered(hypothetical:Hypothetic, square:int): bool =
  hypothetical.pieces.anyIt(it.covers(square))

proc blueCovers(hypothetical:Hypothetic,card:BlueCard): seq[tuple[pieceNr,squareNr:int]] =
  for pieceNr,pieceSquare in hypothetical.pieces:
    for blueSquareNr,blueSquare in card.squares.required:
      if pieceSquare == blueSquare or pieceSquare.covers(blueSquare): 
        result.add (pieceNr,blueSquareNr)

proc blueCovered(hypothetical:Hypothetic,card:BlueCard): bool =
  let 
    covers = hypothetical.blueCovers(card)
    availablePieces = covers.mapIt(it.pieceNr).deduplicate
    enoughPieces =  availablePieces.len >= card.squares.required.len
  if not enoughPieces: #or not allSquaresCovered: 
    return false
  for squareNr in 0..card.squares.required.len-1:
    if covers.filterIt(it.squareNr == squareNr).len == 0:
      return false

#  echo card.title,": covered"
  return true

proc oneInMoreBonus(hypothetical:Hypothetic,card:BlueCard,square:int):int =
  let 
    requiredSquare = card.squares.required[0]
    piecesOnRequiredSquare = hypothetical.piecesOn(requiredSquare) > 0
  if square == requiredSquare:
    if piecesOnRequiredSquare:
      result = 40_000
    else:
      result = 20_000
  if piecesOnRequiredSquare and square in card.squares.oneInMoreRequired:
    if hypothetical.piecesOn(square) > 0: 
      result = 40_000
    else: 
      result = 20_000

proc oneRequiredBonus(hypothetical:Hypothetic,card:BlueCard,square:int): int =
  if card.squares.oneInMoreRequired.len > 0:
    result = hypothetical.oneInMoreBonus(card,square)
  elif turn.player.cash+20_000 > cashAmountToWin():
    result = 100_000
  else:
    result = 40_000 

proc blueBonus(hypothetical:Hypothetic,card:BlueCard,square:int): int =
  let
    requiredSquares = card.squares.required.deduplicate
    squareIndex = requiredSquares.find(square)
  if squareIndex >= 0 or square in card.squares.oneInMoreRequired:
    let nrOfPiecesRequired = card.squares.required.len
    if nrOfPiecesRequired == 1: 
      result = hypothetical.oneRequiredBonus(card,square)
    else:
      let
        piecesOn = requiredSquares.mapIt(hypothetical.pieces.count(it))
        requiredPiecesOn = requiredSquares.mapIt(card.squares.required.count(it))
        freePieces = piecesOn[squareIndex] - requiredPiecesOn[squareIndex]
      if freePieces < 1 and hypothetical.blueCovered(card):
        var nrOfPieces = 1
        for square in 0..requiredSquares.len-1:
          if piecesOn[square] > requiredPiecesOn[square]:
            nrOfPieces += requiredPiecesOn[square]
          else:
            nrOfPieces += piecesOn[square]
        result = (40_000 div nrOfPiecesRequired)*nrOfPieces
        #echo card.title,": square: ",square," bonus: ",result

proc blueVals*(hypothetical:Hypothetic,squares:seq[int]): seq[int] =
  result.setLen(squares.len)
  if hypothetical.cards.len > 0:
    for i,square in squares:
      for card in hypothetical.cards:
        result[i] += hypothetical.blueBonus(card,square)

proc posPercentages(hypothetical:Hypothetic,squares:seq[int]): seq[float] =
  var freePieces:int
  for i,square in squares:
    let freePiecesOnSquare = hypothetical.freePiecesOn(square)
    if freePiecesOnSquare > 0:
      freePieces += freePiecesOnSquare
    if freePieces == 0:
      result.add posPercent[i]
    else:
      result.add posPercent[i].pow(freePieces.toFloat)

proc evalSquare(hypothetical:Hypothetic,square:int): int =
  let 
    squares = toSeq(square..square+posPercent.len-1).mapIt(adjustToSquareNr(it))
    blueSquareValues = hypothetical.blueVals(squares)
    baseSquareVals = squares.mapIt(hypothetical.board[it].toFloat)
    squarePercent = hypothetical.posPercentages(squares)
  result = toSeq(0..posPercent.len-1)
  .mapIt(((baseSquareVals[it]+blueSquareValues[it].toFloat)*squarePercent[it]).toInt)
  .sum
#  echo "square: ",square,": eval: ",result

proc evalPos*(hypothetical:Hypothetic): int = 
  hypothetical.pieces.mapIt(hypothetical.evalSquare(it)).sum

proc baseEvalBoard*(pieces:array[5,int]): EvalBoard =
  result[0] = 4000
  for highway in highways: 
    result[highway] = highwayVal
  for bar in bars: 
    result[bar] = barVal(pieces)
  for square in 1..60:
    if nrOfPiecesOn(square) == 1:
      result[square] += 2000

proc evalBlue(hypothetical:Hypothetic,card:BlueCard): int =
  evalPos (
    baseEvalBoard(hypothetical.pieces),
    hypothetical.pieces,
    @[card]
  )

proc evalBlues(hypothetical:Hypothetic): seq[BlueCard] =
#  echo "evalBlues:"
  for card in hypothetical.cards:
    var tc = card
    tc.eval = hypothetical.evalBlue(card)
    result.add tc
#    echo tc.title&": ",tc.eval
  result.sort((a,b) => b.eval - a.eval)

proc sortBlues*(hypothetical:Hypothetic): seq[BlueCard] =
  var cards = hypothetical.evalBlues
  if cards.len > 3:
    let board = baseEvalBoard(hypothetical.pieces)
    var evals:seq[tuple[cards:seq[BlueCard],eval:int]]
    for i in 0..cards.len-1:
      let eval = (board,hypothetical.pieces,cards[0..2]).evalPos
      evals.add (cards[0..2],eval)
      cards.insert(cards.pop,0)
    let bestCombo = evals[evals.mapIt(it.eval).maxIndex].cards
    for i,card in bestCombo:
      echo card.title,": best combo eval: ",evals[i].eval
      cards.del(cards.find(card))
    result.add bestCombo
  result.add cards

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

proc move*(hypothetical:Hypothetic,dice:openArray[int]): Move = 
  var moves:seq[Move]
  for pieceNr,fromSquare in hypothetical.pieces:
    for die in dice:
      moves.add hypothetical.bestMove(pieceNr,fromSquare,die)
  echo moves
  result = moves.sortedByIt(it.eval)[^1]

proc hypoMoves(hypothetical:Hypothetic): seq[Move] =
  for pieceNr,fromSquare in hypothetical.pieces:
    for die in 1..6: result.add hypothetical.bestMove(pieceNr,fromSquare,die)

proc bestDiceMoves*(hypothetical:Hypothetic): seq[Move] =
  let moves = hypothetical.hypoMoves()
  for die in 1..6:
    let dieMoves = moves.filterIt(it.die == die)
    result.add dieMoves[dieMoves.mapIt(it.eval).maxIndex()]
  result.sortedByIt(it.eval)

