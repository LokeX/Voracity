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
  Turn = ref object
    nr*:int
    player*:Player
    diceMoved*:bool
    pieceMoved*:bool
    undrawnCards*:int
  Square = tuple
    evals:seq[tuple[evalDesc:string,eval:int]]
    nrOfPlayerPieces:array[6,int]
  Board = array[1..60,Square]

const
  (bx*,by*) = (200,150)

  selColor* = color(255,255,255,100)
  defaultPlayerKinds = [human,human,human,human,human,human]
  playerColors*:array[PlayerColors,Color] = [
    color(1,0,0),color(0,1,0),
    color(0,0,1),color(1,1,0),
    color(255,255,255),color(1,1,1)
  ]
  batchFontColors*:array[PlayerColors,Color] = [
    color(1,1,1),
    color(255,255,255),
    color(1,1,1),
    color(255,255,255),
    color(1,1,1),
    color(255,255,255),
  ]
  highways* = [5,17,29,41,53]
  gasStations* = [2,15,27,37,47]
  bars* = [1,16,18,20,28,35,40,46,51,54]

  maxRollFrames = 40

var
  dice*:array[1..2,int] = [3,4]
  dieRollFrame* = maxRollFrames
  players*:array[1..6,Player]
  turn*:Turn = nil
  board:Board
  playerKinds*:array[1..6,PlayerKind]

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

proc newDefaultPlayers(): array[1..6,Player] =
  for i in 1..6:
    result[i] = Player(
      nr:i,
      kind:defaultPlayerKinds[i-1],
      color:PlayerColors(i-1),
      piecesOnSquares:highways
    )

proc printPlayers() =
  for player in players:
    echo "player"
    echo player.nr
    echo player.color
    echo player.kind
    echo player.batch.name
    echo player.piecesOnSquares
    echo player.cash

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

proc contestingPlayersNrs(): seq[int] = 
  players.filterIt(it.kind != none).mapIt(it.nr)

proc nextPlayerTurn*() =
  startDiceRoll()
  let contesters = contestingPlayersNrs()
  if turn == nil:
    turn = Turn(nr:1,player:players[contesters[0]])
  else:
    let lastContester = turn.player.nr == contesters[^1]
    turn = Turn(
      nr:if lastContester: turn.nr+1 else: turn.nr,
      player:players[
        if lastContester: 
          contesters[0] 
        else: 
          contesters[
            contesters.find(turn.player.nr)+1
          ]
      ]
    )
  turn.player.turnNr = turn.nr  

proc printBoard() =
  for i in 1..60:
    echo i,": ",board[i]

func piecesOnSquare(player:Player,square:int): int =
  if player.kind != none:
    player.piecesOnSquares.count(square)
  else:
    return 0

proc playersPiecesOnSquare(square:int): array[1..6,int] =
  for i,player in players:
    result[i] = player.piecesOnSquare(square)

proc nrOfPiecesOnSquare(square:int): int =
  playersPiecesOnSquare(square).sum

proc turnPlayerHasPieceOn(square:int): bool =
  turn.player.piecesOnSquares
  .filter(p => p != 0)
  .any(p => p == square)

proc hasLegalMove(square:int): bool =
  square in highways or not turn.diceMoved

proc moveablePieceOn*(square:int): bool =
  turnPlayerHasPieceOn(square) and 
  hasLegalMove(square)

func moveToSquare(fromSquare:int,die:int): int =
  result = fromSquare+die
  if result > 60: result -= 60

proc moveToSquares(fromSquare:int,dice:array[2,int]): seq[int] =
  if fromSquare > 0 and fromSquare <= 60:
    if fromSquare in highways: result.add(gasStations)
    for die in dice:
      result.add(moveToSquare(fromSquare,die))
      if fromSquare in highways:
        result.add(gasStations.map(gasStation => moveToSquare(gasStation,die)))
  else:
    return @[]

proc toggleKind*(kind:PlayerKind): PlayerKind =
  case kind
    of human:computer
    of computer:none
    of none:human

proc moveToSquares*(fromSquare:int): seq[int] = moveToSquares(fromSquare,dice)

proc movePiece*(fromSquare,toSquare:int) =
  var pieceNr = turn.player.piecesOnSquares.find(fromSquare)
  if pieceNr > -1: turn.player.piecesOnSquares[pieceNr] = toSquare

proc printReport() =
  printPlayers()
  for highway in highways:
    echo highway,": ",players[1].piecesOnSquare(highway)
    echo highway,": ",playersPiecesOnSquare(highway)
    echo highway,": ",nrOfPiecesOnSquare(highway)
  printBoard()
  echo PlayerColors(0)

players = newDefaultPlayers()
board = putPiecesOnBoard() 
#printReport()
  