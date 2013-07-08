class @BoardController
  constructor: () ->
    @board = null
    @game = null
    Meteor.autosubscribe =>
      Meteor.subscribe "board", Session.get("gameId") if Session.get("gameId")
      Meteor.subscribe "game", Session.get("gameId") if Session.get("gameId")
    
    Template.map.tiles = =>
      @game = Games.findOne Session.get("gameId")
      @board = Boards.findOne gameId: Session.get("gameId")
      ""
    Template.map.rendered = =>
      @render()
  
  clickTile: (event) =>
    targ = $(event.target)
    tile = null
    while targ.length > 0 and !tile
      if targ.attr "data-row"
        tile = targ
      targ = targ.parent()
    window.clickedTile = tile
  
  render: () =>
    return if !@board?.tiles? or !@game?
    h = window.viewporter.viewportHeight - $(".status-bar").height()
    w = $(".map-holder").width()
    $(".map-holder").css
      height: h
    pos = {}
    _.each @board.tiles, (tile) =>
      tileId = "tile-#{tile.row}x#{tile.column}"
      el = $("##{tileId}")
      pos = TileHelper.getPosition tile, @board.columns, @board.rows, w, h
      if !el? || el.length == 0
        el = $("<tile>")
        el.append($("<canvas>"))
        el.append($("<a href=\"#\">&nbsp;</a>"))
        el.addClass("board-tile")
        el.attr
          id: tileId
          "data-row": tile.row
          "data-column": tile.column
        $(".game-map").append el
      canvas = $("canvas", el)
      el.css
        position: "absolute"
        left: pos.x
        top: pos.y
        width: Math.round Tile::width * pos.scale
        height: Math.round Tile::height * pos.scale
      canvas.css
        width: Tile::width * pos.scale
        height: Tile::height * pos.scale
      canvas[0].width = Tile::width * pos.scale
      canvas[0].height = Tile::height * pos.scale
      $("a", el).css
        "margin-left": Math.round Tile::width * pos.scale * .15
        width: Math.round Tile::width * pos.scale * .7
        "margin-top": Math.round Tile::height * pos.scale * .1
        height: Math.round Tile::height * pos.scale * .8
      .click @clickTile
      if tile.player
        tile.character = @game.characters[tile.player]
        if @game.weapons[tile.player]
          tile.weapon = @game.weapons[tile.player]
      TileHelper.drawTile tile, canvas[0]
      #el.append($("<img src=\"/images/tile_bg.png\" width=\"#{Tile::width * pos.scale}px\" height=\"#{Tile::height * pos.scale}px\" />"))
    bw = TileHelper.boardWidth @board.columns, pos.scale
    if bw < w
      $(".game-map").css
        position: "absolute"
        left: Math.floor(w-bw)/2+"px"
    else
      $(".game-map").css left: "0px"
    
