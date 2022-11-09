import cityview
import strutils
import random

let
  dieFaces* = loadImages("pics\\diefaces\\*.gif")
  dieFace1 = newMouseHandle(dieFaces[0],100,200)
  dieFace2 = newMouseHandle(dieFaces[1],100,265)

addImages(dieFaces)
addMouseHandle(dieFace1)
addMouseHandle(dieFace2)
randomize()

const
  maxRollFrames = 40

var
  (die1,die2) = ("3","4")
  dieRollFrame = maxRollFrames

proc mouseOnDice(): bool =
  mouseOn(dieFace1) or mouseOn(dieFace2)

proc rollDice() =
  die1 = rand(1..6).intToStr()
  die2 = rand(1..6).intToStr()
  if dieRollFrame < maxRollFrames: inc dieRollFrame

proc keyboard (k:KeyEvent) =
  echo "dice keyboard:"
  echo k.keyState
  echo k.button
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    echo "mouse clicked:"
    echo m.keyState
    echo m.button
    echo "diceClicked:",mouseOnDice()
    if dieRollFrame == maxRollFrames and mouseOnDice(): 
      dieRollFrame = 0
      playSound("wuerfelbecher")
      #rollDice()

proc draw (b:var Boxy) =
  if dieRollFrame < maxRollFrames: rollDice()
  b.drawImage(die1,pos = vec2(100, 200)) 
  b.drawImage(die2,pos = vec2(100, 265))
  
proc initDice*() =
  addCall(newCall("citydice",keyboard,mouse,draw))
