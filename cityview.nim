import boxy, opengl, windy
import std/sequtils
import std/os
import slappy
export boxy
export windy
export os

type
  FileName     = tuple[name,path:string]
  ImageName*   = tuple[name:string,image:Image]
  MouseHandle* = ref object 
    name*          :string
    x1*,y1*,x2*,y2*:int

  KeyState = tuple[down,pressed,released,toggle:bool]
  Event    = object of RootObj
    keyState*: KeyState
    button*  :Button
  MouseEvent* = ref object of Event
    pos* :tuple[x,y:int]
  KeyEvent*   = ref object of Event
    rune*:Rune

  KeyCall   = proc(keyboard:KeyEvent)
  MouseCall = proc(mouse:MouseEvent)
  DrawCall  = proc(boxy:var Boxy)
  Call      = ref object
    reciever:string
    keyboard:KeyCall
    mouse   :MouseCall
    draw    :DrawCall

let 
  window* = newWindow(
    "Voracity",
    ivec2(800,600),
    WindowStyle.DecoratedResizable, 
    visible = false
  )
  scr = getScreens()[0]
  scrWidth* = cast[int32](scr.right)
  scrHeight* = cast[int32](scr.bottom)
  winWidth* = scrWidth-(scrWidth div 20)
  winHeight* = scrHeight-(scrHeight div 8)
#  boxyScale*: float = 1+(1-(1024/scrWidth))
  boxyScale*: float = 1

window.size = ivec2(winWidth,winHeight)
window.pos = ivec2(110,110)
window.icon = readImage("barman.png")
window.runeInputEnabled = true
makeContextCurrent(window)
loadExtensions()
slappyInit()

var
  calls*:seq[Call]
  mouseHandles*:seq[MouseHandle]
  bxy = newBoxy()

bxy.scale(boxyScale)
#bxy.scale(1)
window.visible = true

proc winSize*(): IVec2 =
  ivec2(winWidth,winHeight)

proc playSound*(sound:string) =
  discard newSound("sounds\\"&sound&".wav").play()

proc echoMouseHandles*() =
  for mouse in mouseHandles:
    echo mouse.name

proc addCall*(call:Call) = calls.add(call)

proc newCall*(r:string, k:KeyCall, m:MouseCall, d:DrawCall): Call =
  Call(reciever:r,keyboard:k,mouse:m,draw:d)

func mouseClicked(button:Button): bool = 
  button in [
    MouseLeft,MouseRight,MouseMiddle,
    DoubleClick,TripleClick,QuadrupleClick
  ]

func mouseClicked*(k:KeyState): bool = 
  k.down or k.pressed or k.released

func mousePos(pos:Ivec2): tuple[x,y:int] =
  (cast[int](pos[0]),cast[int](pos[1]))

proc keyState(b:Button): KeyState =
  (window.buttonDown[b], window.buttonDown[b],
  window.buttonReleased[b], window.buttonToggle[b])

func keyState(): KeyState = (false,false,false,false)

proc newMouseMoveEvent(): MouseEvent =
  MouseEvent(pos:mousePos(window.mousePos),keyState:keyState())

proc newMouseKeyEvent(b:Button): MouseEvent = 
  MouseEvent(
    pos:mousePos(window.mousePos),
    keyState:keyState(b),
    button:b
  )

proc newKeyEvent(b:Button,r:Rune): KeyEvent = 
  KeyEvent(
    rune:r,
    keyState:keyState(b),
    button:b
  )

proc newMouseEvent(button:Button): MouseEvent =
    if mouseClicked(button): 
      newMouseKeyEvent(button) 
    else: 
      newMouseMoveEvent()

func fileNames*(paths: seq[string]): seq[FileName] =
  for path in paths: 
    result.add (splitFile(path).name,path)

proc mouseOn*(h:MouseHandle): bool =
  let
    (mx,my) = mousePos(window.mousePos)
  h.x1 <= mx and h.y1 <= my and mx <= h.x2 and my <= h.y2

proc mouseOn*(): string =
  for i in countdown(mouseHandles.len-1,0):
    if mouseOn(mouseHandles[i]):
      return mouseHandles[i].name
  return "None"

proc mouseOn*(imgName:ImageName): bool =
  mouseOn() == imgName.name

proc newMouseHandle*(hn:string,x,y,w,h:int): MouseHandle =
  MouseHandle(
    name:hn,
    x1:(x.toFloat*boxyScale).toInt,
    y1:(y.toFloat*boxyScale).toInt,
    x2:((x+w).toFloat*boxyScale).toInt,
    y2:((y+h).toFloat*boxyScale).toInt
  )    

proc newMouseHandle*(ni:ImageName,x,y:int): MouseHandle =  
  let
    w = ni.image.width
    h = ni.image.height
  newMouseHandle(ni.name,x,y,w,h)

proc addMouseHandle*(mh:MouseHandle) =
  mouseHandles.add(mh)

proc loadImages(files:seq[FileName]): seq[ImageName] =
  for file in files:
    result.add (file.name,readImage(file.path))

proc loadImages*(s:string): seq[ImageName] =
  loadImages(toSeq(walkFiles(s)).fileNames())

proc addImage*(ih:ImageName) =
  bxy.addImage(ih.name,ih.image)

proc addImages*(ihs:seq[ImageName]) =
  for ih in ihs:
    bxy.addImage(ih.name,ih.image)

window.onButtonPress = proc (button:Button) =
  if button == KeyEscape:
    window.closeRequested = true
  else:
    for call in calls:
      if mouseClicked(button):
        if call.mouse != nil: 
          call.mouse(newMouseEvent(button))
      else:
        if call.keyboard != nil: 
          call.keyboard(newKeyEvent(button,"¤".toRunes[0]))

window.onFrame = proc() =
  bxy.beginFrame(window.size)
  for call in calls:
    if call.draw != nil: call.draw(bxy)
  bxy.endFrame()
  window.swapBuffers()

window.onRune = proc(rune:Rune) =
  var button:Button
  for call in calls:
    if call.keyboard != nil: 
      call.keyboard(newKeyEvent(button,rune))

window.onMouseMove = proc () =
  for call in calls:
    if call.mouse != nil: 
      call.mouse(newMouseMoveEvent())
