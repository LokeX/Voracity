import boxy, opengl, times, windy
import cityload
import citytext
export windy
export boxy
import strutils

let window* = newWindow(
  "Voracity",
  ivec2(800,600),
  WindowStyle.Decorated, 
  visible = false
)

proc winSize (): IVec2 =
  let 
    scr = getScreens()[0]
    width = cast[int32](scr.right-(scr.right div 20))
    height = cast[int32](scr.bottom-(scr.bottom div 5))  
  result = ivec2(width,height)

window.size = winSize()
window.pos = ivec2(110,110)
window.icon = readImage("barman.png")
makeContextCurrent(window)
loadExtensions()

type
  MouseEvent* = tuple
    button:Button
    pos:tuple[x,y:int]
  KeyEvent* = tuple
    button:Button
    ch:char
  KeyCall = proc(keyboard:KeyEvent)
  MouseCall = proc(mouse:MouseEvent)
  DrawCall = proc(boxy:var Boxy)
  Call = ref object
    mode:string
    keyboard:KeyCall
    mouse:MouseCall
    draw:DrawCall

let 
  bgImage = readImage("engboard.jpg")
  aovel60White = font("AovelSansRounded-rdDL",60,color(1,1,1,1))
var  
  calls*:seq[Call]
  bxy = newBoxy()

proc addCall*(call:Call) =
  calls.add(call)

proc newCall*(keyboard:KeyCall, mouse:MouseCall, draw:DrawCall): Call =
  Call(keyboard:keyboard,mouse:mouse,draw:draw)

proc newCall*(keyboard:KeyCall, mouse:MouseCall): Call =
  Call(keyboard:keyboard,mouse:mouse)

proc newCall*(keyboard:KeyCall): Call =
  Call(keyboard:keyboard)

func mouseIsPressed* (button:Button): bool =
  button in [
    MouseLeft,
    MouseRight,
    MouseMiddle,
    DoubleClick,
    TripleClick,
    QuadrupleClick
  ]

#bxy.scale(1.5)
#bxy.addImage("bg", readImage("bggreen.png"))
bxy.addImage("board", readImage("engboard.jpg"))
bxy.addImageHandles(cityload.diefaces)
window.visible = true
#slappyInit()
#discard newSound("sounds\\carstart-1.wav").play()

proc drawText* (imageKey:string,x,y:float32,text: string) =
  let txt = text.imageText(x,y,aovel60White,window.size.vec2)
  bxy.addImage(imageKey, txt.textImage)
  bxy.drawImage(imageKey, txt.globalBounds.xy)

proc mousePos (pos:Ivec2): tuple[x,y:int] =
  (cast[int](window.mousePos[0]),cast[int](window.mousePos[1]))

window.onButtonPress = proc (button:Button) =
  if button == KeyEscape:
    echo "Esc button pressed"
    window.closeRequested = true
  else:
    for call in calls:
      if call.keyboard != nil: call.keyboard (button,'a')
      if call.mouse != nil: call.mouse (button,mousePos(window.mousePos))

window.onFrame = proc() =
  bxy.beginFrame(window.size)
  for call in calls:
    if call.draw != nil: call.draw(bxy)
#  bxy.drawImage("bg", rect = rect(vec2(0, 0), window.size.vec2))
  #bxy.pushLayer()
  bxy.drawImage("board", pos = vec2(200, 200))
  #bxy.blurEffect(50)
  #bxy.popLayer()
  bxy.drawImage("2", pos = vec2(100, 200)) 
  bxy.drawImage("1",pos = vec2(100, 300))
  bxy.drawRect(rect(vec2(300,300),vec2(500,500)),color(255,255,255,150))
  "main-image".drawText(100,100,"Current time:")
  "main-image2".drawText(500,100,now().format("hh:mm:ss"))
  bxy.endFrame()
  window.swapBuffers()
