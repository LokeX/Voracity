import cityscape
import sequtils
import random
import sugar

type
  PlayerKind* = enum
    human = "Human",
    computer = "Computer",
    none = "None"
  PlayerColors* = enum
    red,green,blue,yellow,black,white
  Player* = ref object
    nr*:int
    color*:PlayerColors
    kind*:PlayerKind
    batch*:AreaHandle
    turnNr*:int
    piecesOnSquares*:array[5,int]
    cash*:int
  Turn* = ref object
    nr*:int
    player*:Player
    diceMoved*:bool
    pieceMoved*:bool
    undrawnCards*:int
  Square = tuple
    evals:seq[tuple[evalDesc:string,eval:int]]
    nrOfPlayerPieces:array[6,int]
  Board = array[1..60,Square]
  RemovePiece* = tuple[player:Player,piece:int]

const 
  piecePrice* = 5000
  defaultPlayerKinds = [human,human,none,none,none,none]
  highways* = [5,17,29,41,53]
  gasStations* = [2,15,27,37,47]
  bars* = [1,16,18,20,28,35,40,46,51,54]
  maxRollFrames = 40

var
  removePiece*:RemovePiece
  playerKinds*:array[1..6,PlayerKind] = defaultPlayerKinds
  dice*:array[1..2,int] = [3,4]
  dieRollFrame* = maxRollFrames
  players*:array[1..6,Player]
  turn*:Turn = nil
  board:Board

proc rollDice*() = 
  for i,die in dice: dice[i] = rand(1..6)

proc isRollingDice*(): bool =
  dieRollFrame < maxRollFrames

proc isDouble*(): bool = dice[1] == dice[2]

proc startDiceRoll*() =
  if not isRollingDice(): 
    randomize()
    dieRollFrame = 0
    playSound("wuerfelbecher")

proc newDefaultPlayers*(): array[1..6,Player] =
  for i in 1..6:
    result[i] = Player(
      nr:i,
      kind:playerKinds[i],
      color:PlayerColors(i-1),
      piecesOnSquares:highways
    )
    echo players[i].kind

proc newPlayers*(kind:array[6,PlayerKind]): array[1..6,Player] =
  randomize()
  var randomPosition = rand(1..6)
  for color in PlayerColors:
    while result[randomPosition] != nil: 
      randomPosition = rand(1..6)
    result[randomPosition] = Player(
      nr:randomPosition,
      color:color,
      kind:kind[color.ord],
      piecesOnSquares:highways,
      cash:25000
    )

proc putPiecesOnBoard(): Board =
  for player in players:
    if player.kind != none:
      for square in player.piecesOnSquares:
        inc result[square].nrOfPlayerPieces[player.nr-1]

proc nextPlayerTurn*() =
  startDiceRoll()
  let contesters = players.filterIt(it.kind != none)
  if turn == nil: turn = Turn(nr:1,player:contesters[0]) else:
    let
      isLastPlayer = turn.player.nr == contesters[^1].nr
      turnNr = if isLastPlayer: turn.nr+1 else: turn.nr
      nextPlayer = if isLastPlayer: contesters[0] else:
        contesters[contesters.mapIt(it.nr).find(turn.player.nr)+1]
    turn = Turn(nr:turnNr,player:nextPlayer)
  turn.player.turnNr = turn.nr  

proc removePieceOn(square:int): tuple[player:Player,piece:int] =
  for player in players.filterIt(it.kind != none):
    for pieceNr,piece in player.piecesOnSquares:
      if piece == square:
        return (player,pieceNr)

proc setRemovePieceOn*(square:int) =
  removePiece = removePieceOn(square)

proc removePlayersPiece*() =
  removePiece.player.piecesOnSquares[removePiece.piece] = 0

func piecesOnSquare*(player:Player,square:int): int =
  if player.kind != none:
    player.piecesOnSquares.count(square)
  else:
    return 0

proc playersPiecesOnSquare(square:int): array[1..6,int] =
  for i,player in players:
    result[i] = player.piecesOnSquare(square)

proc nrOfPiecesOn*(square:int): int =
  playersPiecesOnSquare(square).sum

proc hasPieceOn*(player:Player,square:int): bool =
  player.piecesOnSquares.any(p => p == square)

func moveToSquare(fromSquare:int,die:int): int =
  result = fromSquare+die
  if result > 60: result -= 60

proc moveToSquares(fromSquare:int,dice:array[2,int]): seq[int] =
  if fromSquare == 0: 
    result.add(highways)
    result.add(gasStations)
  elif fromSquare in highways: 
    result.add(gasStations)
  if not turn.diceMoved:
    for die in dice:
      if fromsquare != 0: result.add(moveToSquare(fromSquare,die))
      if fromSquare in highways or fromsquare == 0:
        if fromSquare == 0: result.add(highways.mapIt(moveToSquare(it,die)))
        result.add(gasStations.mapIt(moveToSquare(it,die)))
    result = result.filterIt(it != fromSquare).deduplicate()

proc toggleKind*(kind:PlayerKind): PlayerKind =
  case kind
    of human:computer
    of computer:
      if playerKinds.filterIt(it != none).len == 1:human else:none
    of none:human

proc moveToSquares*(fromSquare:int): seq[int] = moveToSquares(fromSquare,dice)

proc movePiece*(fromSquare,toSquare:int) =
  var pieceNr = turn.player.piecesOnSquares.find(fromSquare)
  if pieceNr > -1: turn.player.piecesOnSquares[pieceNr] = toSquare

players = newDefaultPlayers()
board = putPiecesOnBoard() 
  