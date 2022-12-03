
// === PUBLIC API ===

loadFont = function(fontSheet, fontData)
	if not file.exists(fontSheet) then 
		print "Font sheet not found: " + fontSheet ; exit
	else if not file.exists(fontData) then 
		print "Font data not found: " + fontData ; exit
	end if
	
	font = new Font
	// Load font sheet image
	fontSheetImg = file.loadImage(fontSheet)
	font.fontSheetImg = fontSheetImg
	// Build glyph-map
	fontDataLines = file.readLines(fontData)
	parseDataLines(fontDataLines, font)
	// Return font
	return font
end function

newBaseLineRenderer = function(target, font)
	renderer = new BaseLineRenderer
	renderer.init(target, font)
	return renderer
end function

newLineHeightRenderer = function(target, font)
	renderer = new LineHeightRenderer
	renderer.init(target, font)
	return renderer
end function

newCompactRenderer = function(target, font)
	renderer = new CompactRenderer
	renderer.init(target, font)
	return renderer
end function

newImageRenderer = function(font)
	renderer = new ImageRenderer
	renderer.init(font)
	return renderer
end function

// === FONT ===

Font = {}
Font.lineHeight = 0
Font.base = 0
Font.fontSheetImg = null
Font.glyphMap = {}
Font.getGlyphData = function(char)
	glyphData = self.glyphMap[char.code]
	return glyphData
end function
Font.getGlyphImg = function(char)
	glyph = self.getGlyphData(char)
	glyphImg = glyph.getImage(self.fontSheetImg)
	return glyphImg
end function
Font.getAdvanceX = function(char)
	data = self.getGlyphData(char)
	return data.xadvance
end function
Font.resolveHeight = function(str)
	maxHeight = 0
	for c in str
		charData = self.getGlyphData(c)
		h = charData.height
		if h > maxHeight then 
			maxHeight = h
		end if
	end for
	return maxHeight
end function
Font.resolveWidth = function(str)
	cx = 0
	for c in str
		ax = self.getAdvanceX(c)
		cx = cx + ax
	end for
	return cx
end function
Font.resolveDimensions = function(str)
	w = self.resolveWidth(str)
	h = self.resolveHeight(str)
	return {"width": w, "height": h}
end function

// === GLYPH ===

Glyph = {}
Glyph.charId = 0
Glyph.x = 0
Glyph.y = 0
Glyph.width = 0
Glyph.height = 0
Glyph.xoffset = 0
Glyph.yoffset = 0
Glyph.xadvance = 0
Glyph.page = 0
Glyph.chnl = 0
Glyph.getImage = function(fontSheetImg)
	// Convert to MiniMicro's Y - which starts at the bottom
	// Also point to the glyph's bottom-left corner instead
	// of top-left as specified in the data
	y = fontSheetImg.height - self.y - self.height
	x = self.x
	glyphImg = fontSheetImg.getImage(x,y,self.width,self.height)
	return glyphImg
end function

// === PARSER ===

parseDataLines = function(lines, font)
	for line in lines
		if isCommonInfoLine(line) then
			commonInfoMap = parsePropertiesLine(line)
			font.lineHeight = commonInfoMap["lineHeight"]
			font.base = commonInfoMap["base"]
		end if
		if isCharLine(line) then
			charInfo = parsePropertiesLine(line)
			// Create glyph object
			glyph = new Glyph
			glyph.charId = charInfo["id"]
			glyph.x = charInfo["x"]
			glyph.y = charInfo["y"]
			glyph.width = charInfo["width"]
			glyph.height = charInfo["height"]
			glyph.xoffset = charInfo["xoffset"]
			glyph.yoffset = charInfo["yoffset"]
			glyph.xadvance = charInfo["xadvance"]
			glyph.page = charInfo["page"]
			glyph.chnl = charInfo["chnl"]
			// Add to map
			font.glyphMap[glyph.charId] = glyph
		end if
	end for
end function

isCommonInfoLine = function(line)
	return startsWith(line, "common")
end function

parsePropertiesLine = function(line)
	// char id=32   x=0     y=0     width=0     height=0     xoffset=0     yoffset=0     xadvance=28    page=0  chnl=15
	propertiesMap = {}
	parts = line.split(" ")
	for part in parts
		if part == "" then continue
		if isProperty(part) then
			propertyMap = parseProperty(part)
			propertiesMap[propertyMap["key"]] = propertyMap["value"]
		end if
	end for
	return propertiesMap
end function

startsWith = function(str, prefix)
	idx = str.indexOf(prefix)
	return idx == 0
end function

isProperty = function(str)
	idx = str.indexOf("=")
	return idx != null
end function

parseProperty = function(str)
	parts = str.split("=")
	key = parts[0]
	value = parts[1].val
	return {"key": key, "value": value}
end function

isCharLine = function(line)
	return startsWith(line, "char id=")
end function

// === RENDERING ===

TargetRenderer = {}
// Can be an Image or PixelDisplay
TargetRenderer.target = null
TargetRenderer.font = null
TargetRenderer.init = function(target, font)
	self.font = font
	self.target = target
end function
TargetRenderer.lineHeight = function
	return self.font.lineHeight
end function
TargetRenderer.print = function(str,x,y)
	cx = x
	for c in str
		self.renderChar(c,cx,y)
		ax = self.font.getAdvanceX(c)
		cx = cx + ax
	end for
	return {"width": cx, "height": self.lineHeight}
end function

BaseLineRenderer = new TargetRenderer
BaseLineRenderer.renderChar = function(c,x,y)
	img = self.font.getGlyphImg(c)
	charData = self.font.getGlyphData(c)
	finalX = x + charData.xoffset
	
	// Take into account MiniMicro's inverted Y-axis
	finalY = y + self.font.base - charData.yoffset - charData.height
	
	self.target.drawImage img,finalX,finalY
end function

LineHeightRenderer = new TargetRenderer
LineHeightRenderer.renderChar = function(c,x,y)
	img = self.font.getGlyphImg(c)
	charData = self.font.getGlyphData(c)
	finalX = x + charData.xoffset
	
	// Take into account MiniMicro's inverted Y-axis
	finalY = y + self.font.lineHeight - charData.yoffset - charData.height
	
	self.target.drawImage img,finalX,finalY
end function

CompactRenderer = new TargetRenderer
CompactRenderer.print = function(str,x,y)
	// Resolve max-height
	maxHeight = 0
	// Offset of most hight character
	yOffset = 0
	for c in str
		charData = self.font.getGlyphData(c)
		h = charData.height
		if h > maxHeight then 
			maxHeight = h
			yOffset = charData.yoffset
		end if
	end for
	// Render characters
	cx = x
	for c in str
		self.renderChar(c,cx,y,maxHeight+yOffset)
		ax = self.font.getAdvanceX(c)
		cx = cx + ax
	end for
	return {"width": cx, "height": maxHeight}
end function
CompactRenderer.renderChar = function(c,x,y,maxHeight,yOffset)
	img = self.font.getGlyphImg(c)
	charData = self.font.getGlyphData(c)
	finalX = x + charData.xoffset
	
	// Take into account MiniMicro's inverted Y-axis
	finalY = y + maxHeight - charData.height - charData.yoffset
	
	self.target.drawImage img,finalX,finalY
end function

// NOTE: this renderer does not inherit from "TargetRenderer"

ImageRenderer = {}
ImageRenderer.font = null
ImageRenderer.init = function(font)
	self.font = font
end function
ImageRenderer.printToImg = function(str)
	infos = self.font.resolveDimensions(str)
	width = infos["width"]
	height = infos["height"]
	
	tgt = new PixelDisplay
	tgt.clear color.clear,width,height
	
	renderer = newCompactRenderer(tgt, font)
	renderer.print(str,0,0)
	img = tgt.getImage(0,0,width,height)
	
	return img
end function
