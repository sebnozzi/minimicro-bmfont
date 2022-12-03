import "bmfontRendering"

displayWidth = 960
displayHeight = 640
displayMiddle = displayHeight/2

clear

// Load font
font = bmfontRendering.loadFont("demo-assets/freakshow_0.png", "demo-assets/freakshow.txt.fnt")

str = "Mini Micro [{123}]"

// Base-line rendering

y = 500
gfx.line 0,y,displayWidth,y,color.red
renderer = bmfontRendering.newBaseLineRenderer(gfx,font)
renderer.print str,0,y
gfx.print "Base-line rendering",640,520,color.silver

// Line-height rendering

y = 350
gfx.drawRect 0,y,displayWidth,font.lineHeight,color.blue
renderer = bmfontRendering.newLineHeightRenderer(gfx,font)
renderer.print str,0,y
gfx.print "Line-height rendering",640,380,color.silver

// Compact rendering

y = 250
renderer = bmfontRendering.newCompactRenderer(gfx,font)
textHeight = font.resolveHeight(str)
gfx.drawRect 0,y,displayWidth,textHeight,color.green
renderer.print str,0,y
gfx.print "Compact rendering",640,280,color.silver

// Image rendering

renderer = bmfontRendering.newImageRenderer(font)
img = renderer.printToImg(str)

spDisp = display(4)

sprite = new Sprite
sprite.image = img
sprite.tint = color.white
sprite.x = 350
sprite.y = 120

spDisp.sprites.push sprite

gfx.print "Image rendering",640,180,color.silver
gfx.print "(used in Sprite)",640,150,color.silver

maxRotation = 15
degDelta = 0.2
rotation = 0

minScale = 0.75
maxScale = 1
scaleDelta = 0.001
scale = 1

colors = [color.white,color.orange,color.red,color.purple,color.blue,
color.aqua,color.lime,color.green,color.yellow]
colorNr = 0
colorDelta = 0.01

while true
	rotation = rotation + degDelta
	scale = scale + scaleDelta
	
	sprite.rotation = rotation
	sprite.scale = scale
	
	sprite.tint = colors[floor(colorNr)]
	
	colorNr = colorNr + colorDelta
	if floor(colorNr) >= colors.len then
		colorNr = 0
	end if
	
	if rotation >= maxRotation then
		rotation = maxRotation
		degDelta = -1 * degDelta
	else if rotation <= -maxRotation then
		rotation = -maxRotation
		degDelta = -1 * degDelta
	end if
	
	if scale >= maxScale then
		scale = maxScale
		scaleDelta = -1 * scaleDelta
	else if scale <= minScale then
		scale = minScale
		scaleDelta = -1 * scaleDelta
	end if
	
	yield
	
end while
