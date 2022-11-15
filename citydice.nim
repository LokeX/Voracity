import cityview
import strutils
import random

const
  maxRollFrames = 40
  die1Pos = (x:100,y:200)
  die2Pos = (x:100,y:265)
let
  dieFaces* = loadImages("pics\\diefaces\\*.gif")
  dieFace1 = newImageHandle(dieFaces[0],die1Pos.x,die1Pos.y)
  dieFace2 = newImageHandle(dieFaces[1],die2Pos.x,die2Pos.y)

addImages(dieFaces)
addMouseHandle(newMouseHandle(dieFace1))
addMouseHandle(newMouseHandle(dieFace2))
randomize()

var
  (die1,die2) = ("3","4")
  dieRollFrame = maxRollFrames

proc mouseOnDice(): bool =
  mouseOn(dieFace1) or mouseOn(dieFace2)

proc rollDice() =
  die1 = rand(1..6).intToStr()
  die2 = rand(1..6).intToStr()

proc isRollingDice(): bool =
  dieRollFrame < maxRollFrames

proc rotateDie(b:var Boxy,die:ImageHandle) =
  var (x,y,w,h) = die.area
  b.drawImage(
    die.img.name,
    center = vec2((x.toFloat+(w/2)),y.toFloat+(h/2)),
    angle = (dieRollFrame*9).toFloat,
    tint = color(1,1,1,41-dieRollFrame.toFloat)
  ) 

proc imagePos(image:ImageHandle): Vec2 =
  vec2(image.area.x.toFloat, image.area.y.toFloat)

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    if not isRollingDice() and mouseOnDice(): 
      dieRollFrame = 0
      playSound("wuerfelbecher")

proc draw (b:var Boxy) =
  if not isRollingDice():
    b.drawImage(die1,pos = imagePos(dieFace1)) 
    b.drawImage(die2,pos = imagePos(dieFace2))
  else:
    rollDice()
    rotateDie(b,dieFace1)
    rotateDie(b,dieFace2)
    inc dieRollFrame

proc initCityDice*() =
  addCall(newCall("citydice",keyboard,mouse,draw))
