class @Tile
  width: 240
  height: 210

if Meteor.isClient
  files =
    black: "/images/character/black2.png"
    blue: "/images/character/blue2.png"
    orange: "/images/character/orange2.png"
    yellow: "/images/character/yellow2.png"
    Axe: "/images/cards/weapons/axe.png"
    Pot: "/images/cards/weapons/pot.png"
    "Ray Gun": "/images/cards/weapons/raygun.png"
    Scissors: "/images/cards/weapons/scissors.png"
    Shuriken: "/images/cards/weapons/shuriken.png"
    Spork: "/images/cards/weapons/spork.png"
  
  assets = {}
  
  for key, value of files
    assets[key] = new Image()
    assets[key].src = value
  assets

class @TileHelper
  @getImage: (tile) ->
    x = 1
  
  @getPosition: (tile, boardColumns, boardRows, w, h) ->
    bw = @boardWidth boardColumns
    bh = @boardHeight boardRows
    if bw/bh > w/h
      scale = w / bw
    else
      scale = h / bh
    x = Math.round Tile::width * tile.column * 0.75 * scale
    y = Math.round Tile::height * ((tile.column % 2)/2 + tile.row) * scale

    {x: x, y: y, scale: scale}
  
  @boardWidth: (boardColumns, scale = 1) ->
    bw = Tile::width * (0.25+boardColumns*0.75) * scale
  
  @boardHeight: (boardRows, scale = 1) ->
    bh = Tile::height * (0.5+boardRows) * scale
    
  @drawTile: (tile, canvas) =>
    ctx = canvas.getContext("2d")
    
    w = canvas.width
    h = canvas.height
    x0 = 0
    x1 = w*.25
    x2 = w*.75
    x3 = w
    
    y0 = 0
    y1 = h*.5
    y2 = h
    
    ctx.fillStyle = "#eee"
    @hex ctx, x0, x1, x2, x3, y0, y1, y2
    ctx.fill()
    
    #tile.player and 
    if tile.character and assets[tile.character]
      asset = assets[tile.character]
      if asset.width > 0
        imgAspect = asset.width/asset.height
        aspect = x3/y2
        if imgAspect > aspect
          imgw = x3
          imgh = imgw/imgAspect
        else
          imgh = y2
          imgw = imgh*imgAspect
        imgw *= 1.3
        imgh *= 1.3
        ctx.save()
        ctx.beginPath()
        @hex ctx, x0, x1, x2, x3, y0, y1, y2
        ctx.closePath()
        ctx.clip()
        ctx.translate(x3*.5, y2*.5)
        ctx.rotate(-Math.PI*.20)
        ctx.drawImage asset, -x3/2, -y2/2, imgw, imgh
        ctx.restore()
    if tile.weapon and assets[tile.weapon.name]
      asset = assets[tile.weapon.name]
      if asset.width > 0
        imgAspect = asset.width/asset.height
        aspect = x3/y2
        if imgAspect > aspect
          imgw = x3
          imgh = imgw/imgAspect
        else
          imgh = y2
          imgw = imgh*imgAspect
        imgw *= 0.6
        imgh *= 0.6
        ctx.save()
        ctx.beginPath()
        @hex ctx, x0, x1, x2, x3, y0, y1, y2
        ctx.closePath()
        ctx.clip()
        ctx.translate(x3*.5, y2*.5)
        ctx.rotate(-Math.PI*.10)
        ctx.drawImage asset, -x3*.45, -y2*.4, imgw, imgh
        ctx.restore()
    ctx.beginPath()
    @hex ctx, x0, x1, x2, x3, y0, y1, y2
    ctx.strokeStyle = "#ffffff"
    ctx.lineWidth = 2
    ctx.stroke()
  
  @hex: (ctx, x0, x1, x2, x3, y0, y1, y2) ->
    ctx.moveTo x1, y0
    ctx.lineTo x2, y0
    ctx.lineTo x3, y1
    ctx.lineTo x2, y2
    ctx.lineTo x1, y2
    ctx.lineTo x0, y1
    ctx.lineTo x1, y0
    
