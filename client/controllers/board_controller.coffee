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
    
    Template.my_info.weapon = =>
      @getMyWeapon()
    
    Template.my_info.events
      "click .btn-close": =>
        Session.set "showMyInfo", false
  
  getMyWeapon: =>
    weapon = @game.weapons[Meteor.userId()]
    if !weapon?
      weapon = WeaponHelper.fists()
    weapon
  
  clickTile: (event) =>
    targ = $(event.target)
    tile = null
    myColumn = -1
    myRow = -1
    clickedColumn = -1
    clickedRow = -1
    clickedPlayer = false
    while targ.length > 0 and !tile
      if targ.attr "data-row"
        tile = targ
        clickedColumn = parseInt tile.attr "data-column"
        clickedRow = parseInt tile.attr "data-row"
        clickedPlayer = tile.attr "data-player"
      targ = targ.parent()
    if clickedColumn == -1 or clickedRow == -1
      return console.log "clicked = -1"
    clickedTile = {column: clickedColumn, row: clickedRow}
    
    myTile = $("[data-player=#{Meteor.userId()}]")
    if myTile and myTile.length == 1
      myColumn = parseInt myTile.attr "data-column"
      myRow = parseInt myTile.attr "data-row"
    if myColumn == -1 or myRow == -1
      return console.log "mine = -1"
    
    if clickedTile.column == myColumn and clickedTile.row == myRow
      Session.set "showMyInfo", true
      return
    
    if clickedPlayer and clickedPlayer != Meteor.userId()
      @attack clickedTile, true
      return
    
    @move {column: myColumn, row: myRow}, clickedTile, true
  
  move: (fromTile, toTile, canRetry = false) =>
    dist = BoardHelper.getStepsToTile fromTile, toTile
    App.call "moveTo", toTile.column, toTile.row, (err, data) =>
      if err and err.reason
        if err.reason == ErrorHelper.ENERGY_REQUIRED
          App.getEnergy Gameplay.energyRequiredToMove(dist), (retry, cancel) =>
            if retry and canRetry
              @move fromTile, toTile, false
            else
              "cancel"
        else
          App.error err.reason
  
  attack: (tile, canRetry = false) =>
    @game = Games.findOne Session.get "gameId"
    weapon = @getMyWeapon()
    if @game.currentTurnEnergy < weapon.useCost
      App.getEnergy weapon.useCost, (retry, cancel) =>
        if retry and canRetry
          @attack tile, false
        else
          "cancel"
      #return App.alert "Not enough energy!"
    else
      console.log "attacking!", tile, @game.currentTurnEnergy
      App.call "attack", tile.column, tile.row, @game.currentTurnEnergy, (err, data) =>
        if err and err.reason
          App.error err.reason
  
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
        el.attr "data-player", tile.player
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
    
