import boxy, opengl, times, windy
import std/os
import cityload
#import slappy
import citytext
export windy
#import citydice

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
  KeyListener = proc(button:Button)
  Listener = ref object
    call:KeyListener

let 
  bgImage = readImage("engboard.jpg")
  aovel60White = font("AovelSansRounded-rdDL",60,color(1,1,1,1))
  bxy = newBoxy()

var
  listeners*:seq[Listener]

proc addKeyListener* (listener:Listener) =
  listeners.add(listener)

proc newListener* (listener:KeyListener): Listener =
  result = Listener(call:listener)

func mousePressed* (button:Button): bool =
  result = button in [MouseLeft,MouseRight,MouseMiddle]

proc keyPressed (button:Button) =
  if mousePressed(button):
    echo "Mouse Pressed: ",button
  else:
    echo "Key pressed: ",button

#bxy.scale(1.5)
bxy.addImage("bg", readImage("bggreen.png"))
bxy.addImage("board", bgImage)
bxy.addImageHandles(cityload.diefaces)
echo bxy.getImageSize("1")
addKeyListener(newListener(keyPressed))
#addKeyListener(keyPressed)
#addKeyListener(citydice.keyPressed)
echo "Done loading"
window.visible = true
#slappyInit()
#discard newSound("sounds\\carstart-1.wav").play()

proc drawText* (imageKey:string,x,y:float32,text: string) =
  let txt = text.imageText(x,y,aovel60White,window.size.vec2)
  bxy.addImage(imageKey, txt.textImage)
  bxy.drawImage(imageKey, txt.globalBounds.xy)

window.onButtonPress = proc (button:Button) =
  if button == KeyEscape:
    echo "Esc button pressed"
    window.closeRequested = true
  else:
    for listener in listeners:
      listener.call(button)

window.onFrame = proc() =
  bxy.beginFrame(window.size)
  bxy.drawImage("bg", rect = rect(vec2(0, 0), window.size.vec2))
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


#[ while not window.closeRequested:
  sleep(30)
  pollEvents() ]#