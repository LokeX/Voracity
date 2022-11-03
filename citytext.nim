import boxy
import cityview

type
  TextImage* = tuple[globalBounds:Rect,textImage:Image]

func fontFace (typeFace: Typeface,size: float32, color: Color): Font =
  result = newFont(typeFace)
  result.size = size
  result.paint = color

proc font* (fontName:string, size:float32, color:Color): Font = 
  result = fontFace(readTypeface("fonts\\"&fontName&".ttf"),size,color)

let 
  aovel60White = font("AovelSansRounded-rdDL",60,color(1,1,1,1))

func arrangement (text:string, tFont:Font, winSize:Vec2): Arrangement =
  result = typeset(@[newSpan(text, tFont)], bounds = winSize)

proc imageText (arrangement: Arrangement, x,y: float32): TextImage =
  let
    transform    = translate(vec2(x,y))
    globalBounds = arrangement.computeBounds(transform).snapToPixels()    
    image        = newImage(globalBounds.w.int, globalBounds.h.int)
    imageSpace   = translate(-globalBounds.xy) * transform  
  image.fillText(arrangement, imageSpace)
  result = (globalBounds,image)

proc imageText* (text:string,x,y:float32,font:Font,winSize:Vec2): TextImage =
  result = imageText(text.arrangement(font,winSize),x,y)

proc drawText* (bx:var Boxy,imageKey:string,x,y:float32,text: string) =
  let txt = text.imageText(x,y,aovel60White,winSize().vec2)
  bx.addImage(imageKey, txt.textImage)
  bx.drawImage(imageKey, txt.globalBounds.xy)

