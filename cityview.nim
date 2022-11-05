import boxy, opengl, windy
import std/sequtils
import std/os
export boxy
export windy
export os
import slappy

let window* = newWindow(
  "Voracity",
  ivec2(800,600),
  WindowStyle.Decorated, 
  visible = false
)

proc winSize*(): IVec2 =
  let 
    scr = getScreens()[0]
    width = cast[int32](scr.right-(scr.right div 20))
    height = cast[int32](scr.bottom-(scr.bottom div 7))  
  ivec2(width,height)

window.size = winSize()
window.pos = ivec2(110,110)
window.icon = readImage("barman.png")
window.runeInputEnabled = true
window.visible = true
makeContextCurrent(window)
loadExtensions()
slappyInit()

proc playSound*(sound:string) =
  #carstart-1
  discard newSound("sounds\\"&sound&".wav").play()

type
  FileName     = tuple[name,path:string]
  ImageName*   = tuple[name:string,image:Image]
  ImageHandle* = ref object 
    namedImage:ImageName
    x,y:int

  KeyState = tuple[down,pressed,released,toggle:bool]
  Event = object of RootObj
    keyState*: KeyState
    button*:Button
  MouseEvent* = ref object of Event
    pos*:tuple[x,y:int]
  KeyEvent* = ref object of Event
    rune*:Rune

  KeyCall = proc(keyboard:KeyEvent)
  MouseCall = proc(mouse:MouseEvent)
  DrawCall = proc(boxy:var Boxy)
  Call = ref object
    mode:string
    keyboard:KeyCall
    mouse:MouseCall
    draw:DrawCall

let
  scrWidth* = getScreens()[0].right
  scrHeight* = getScreens()[0].bottom
var
  boxyScale*: float32 = 1+(1-(1024/scrWidth))
  calls*:seq[Call]
  bxy = newBoxy()
bxy.scale(boxyScale)

proc addCall*(call:Call) = calls.add(call)

proc newCall*(k:KeyCall, m:MouseCall, d:DrawCall): Call =
  Call(keyboard:k,mouse:m,draw:d)

proc newCall*(k:KeyCall, m:MouseCall): Call = 
  Call(keyboard:k,mouse:m)

proc newCall*(k:KeyCall): Call = Call(keyboard:k)

func mouseKeyEvent(button:Button): bool = 
  button in [
    MouseLeft,MouseRight,MouseMiddle,
    DoubleClick,TripleClick,QuadrupleClick
  ]

func isMouseKeyEvent*(k:KeyState): bool = 
  k.down or k.pressed or k.released

proc mousePos(pos:Ivec2): tuple[x,y:int] =
  (cast[int](window.mousePos[0]),cast[int](window.mousePos[1]))

proc keyState(b:Button): KeyState =
  (window.buttonDown[b], window.buttonDown[b],
  window.buttonReleased[b], window.buttonToggle[b])

proc keyState(): KeyState = (false,false,false,false)

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

proc newMouseEvent (button:Button): MouseEvent =
    if mouseKeyEvent(button): 
      newMouseKeyEvent(button) 
    else: 
      newMouseMoveEvent()

func fileNames*(paths: seq[string]): seq[FileName] =
  for path in paths: 
    result.add (splitFile(path).name,path)

func imageHandles*(namedImages: seq[ImageName]): seq[ImageHandle] =
  for namedImage in namedImages:
    result.add(ImageHandle(namedImage:namedImage))

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
      if mouseKeyEvent(button):
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
#  echo "got rune: ",rune
  var button:Button
  for call in calls:
    if call.keyboard != nil: 
      call.keyboard(newKeyEvent(button,rune))

window.onMouseMove = proc () =
  for call in calls:
    if call.mouse != nil: 
      call.mouse(newMouseMoveEvent())