import std/sequtils
import std/os
import boxy
import sugar

type
  FileName     = tuple[name,path:string]
  ImageName*   = tuple[name:string,image:Image]
  ImageHandle* = tuple[x,y:int,namedImage:ImageName]

func fileNames (paths: seq[string]): seq[FileName] =
  for path in paths: 
    result.add (splitFile(path).name,path)

func imageHandles* (namedImages: seq[ImageName]): seq[ImageHandle] =
  for namedImage in namedImages:
    result.add (0,0,namedImage)

proc loadImages (files:seq[FileName]): seq[ImageName] =
  for file in files:
    result.add (file.name,readImage(file.path))

proc loadDieFaceImages (): seq[ImageName] =
  result = loadImages(toSeq(walkFiles("pics\\diefaces\\*.gif")).fileNames())

proc addImageHandles* (bxy:Boxy,imageHandles: seq[ImageHandle]) =
  for imageHandle in imageHandles:
    bxy.addImage(imageHandle.namedImage.name,imageHandle.namedImage.image)

var
  dieFaces* = imageHandles(loadDieFaceImages())

#echo dieFaces.map(func(ih:ImageHandle):string = ih.namedImage.name)
echo dieFaces.map(dieFace => dieFace.namedImage.name) 
dieFaces[0].namedImage.image.applyOpacity(0.5)