import boxy, opengl, windy
import cityload
export boxy
export windy

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
    height = cast[int32](scr.bottom-(scr.bottom div 5))  
  ivec2(width,height)

window.size = winSize()
window.pos = ivec2(110,110)
window.icon = readImage("barman.png")
makeContextCurrent(window)
loadExtensions()

type
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

var  
  calls*:seq[Call]
  bxy = newBoxy()

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

window.onButtonPress = proc (button:Button) =
  if button == KeyEscape:
    echo "Esc button pressed"
    window.closeRequested = true
  else:
    for call in calls:
      if mouseKeyEvent(button):
        if call.mouse != nil: 
          call.mouse(newMouseEvent(button))
      else:
        if call.keyboard != nil: 
          call.keyboard(newKeyEvent(button,"*".toRunes[0]))

#bxy.scale(1.5)
bxy.addImage("board", readImage("engboard.jpg"))
bxy.addImageHandles(cityload.diefaces)
window.visible = true
#slappyInit()
#discard newSound("sounds\\carstart-1.wav").play()

window.onFrame = proc() =
  bxy.beginFrame(window.size)
  for call in calls:
    if call.draw != nil: call.draw(bxy)
  bxy.drawImage("board", pos = vec2(200, 200))
  bxy.drawImage("2", pos = vec2(100, 200)) 
  bxy.drawImage("1",pos = vec2(100, 300))
  bxy.drawRect(rect(vec2(300,300),vec2(500,500)),color(255,255,255,150))
  bxy.endFrame()
  window.swapBuffers()
