import cityview
import strutils
import random

let
  dieFaces* = loadImages("pics\\diefaces\\*.gif")
  dieFace1 = newImageHandle(dieFaces[0],100,200)
  dieFace2 = newImageHandle(dieFaces[1],100,265)

addImages(dieFaces)
addMouseHandle(newMouseHandle(dieFace1))
addMouseHandle(newMouseHandle(dieFace2))
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

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    if dieRollFrame == maxRollFrames and mouseOnDice(): 
      dieRollFrame = 0
      playSound("wuerfelbecher")

proc draw (b:var Boxy) =
  if dieRollFrame < maxRollFrames: 
    rollDice()
    inc dieRollFrame
  b.drawImage(die1,pos = vec2(100, 200)) 
  b.drawImage(die2,pos = vec2(100, 265))
  
proc initCityDice*() =
  addCall(newCall("citydice",keyboard,mouse,draw))
