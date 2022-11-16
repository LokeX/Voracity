import cityview
import strutils
import random

const
  maxRollFrames = 40
  die1Pos = (x:100,y:200)
  die2Pos = (x:100,y:265)

let
  dieFaceImages* = loadImages("pics\\diefaces\\*.gif")
  dieFace1 = newImageHandle(dieFaceImages[0],die1Pos.x,die1Pos.y)
  dieFace2 = newImageHandle(dieFaceImages[1],die2Pos.x,die2Pos.y)

addImages(dieFaceImages)
addMouseHandle(newMouseHandle(dieFace1))
addMouseHandle(newMouseHandle(dieFace2))
randomize()

var
  dice:array[1..2,int] = [3,4]
  dieRollFrame = maxRollFrames

proc mouseOnDice(): bool =
  mouseOn(dieFace1) or mouseOn(dieFace2)

proc rollDice() = 
  for i,die in dice: dice[i] = rand(1..6)

proc isRollingDice(): bool =
  dieRollFrame < maxRollFrames

proc rotateDie(b:var Boxy,die:ImageHandle) =
  var (x,y,w,h) = die.area
  b.drawImage(
    dice[die.img.name.parseInt].intToStr,
    center = vec2((x.toFloat+(w/2)),y.toFloat+(h/2)),
    angle = (dieRollFrame*9).toFloat,
    tint = color(1,1,1,41-dieRollFrame.toFloat)
  )

func imagePos(image:ImageHandle): Vec2 =
  vec2(image.area.x.toFloat,image.area.y.toFloat)

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
    b.drawImage(dice[1].intToStr,pos = imagePos(dieFace1)) 
    b.drawImage(dice[2].intToStr,pos = imagePos(dieFace2))
  else:
    rollDice()
    b.rotateDie(dieFace1)
    b.rotateDie(dieFace2)
    inc dieRollFrame

proc initCityDice*() =
  addCall(newCall("citydice",keyboard,mouse,draw))
