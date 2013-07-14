class @BoardHelper
  constructor: () ->
  
  @generateTiles: (mapColumns = 10, mapRows = 6) ->
    tiles = []
    for row in [0..mapRows-1]
      for column in [0..mapColumns-1]
        tiles.push
          row: row
          column: column
          player: false
          gypsy: false
    tiles
  
  @getTileAt: (board, column, row) ->
    match = null
    for tile in board.tiles
      match = tile if tile.column == column and tile.row == row
    match
  
  @getStepsToTile: (tile1, tile2) ->
    q1 = tile1.column
    r1 = tile1.row
    q2 = tile2.column
    r2 = tile2.row
    
    cube1 = @offsetToCube q1, r1
    cube2 = @offsetToCube q2, r2
    dist = @cubicDistance cube1, cube2
    
    dist
  
  @offsetToCube: (q, r) ->
    x = q
    z = r - (q - (q&1)) / 2
    y = -x-z
    
    {x: x, y: y, z: z}
  
  @cubicDistance: (cube1, cube2) ->
    (Math.abs(cube1.x - cube2.x) + Math.abs(cube1.y - cube2.y) + Math.abs(cube1.z - cube2.z)) / 2
  
  @neighboringTiles: (board, tile) ->
    _.filter board.tiles, (t) =>
      if t.column > tile.column-2 or t.column < tile.column+2
        if t.row > tile.row-2 or t.row < tile.row+2
          if 1 == @getStepsToTile tile, t
            return true
  
  @getTilesWithPlayers: (board) ->
    _.filter board.tiles, (t) ->
      t.player
  
  @gypsyTile: (board) ->
    _.find board.tiles, (tile) ->
      tile.gypsy
  
  @moveGypsy: (board) ->
    currentTile = @gypsyTile board
    
    return "not found" unless currentTile
    
    neighbors = @neighboringTiles board, currentTile
    neighbors = _.filter neighbors, (tile) ->
      tile.column != 0 and tile.row != 0 and tile.column < board.columns-1 and tile.row < board.rows-1 and !tile.player
    return unless neighbors.length > 0
    tilesWithPlayers = @getTilesWithPlayers board
    distances = _.map neighbors, (tile) =>
      eachPlayer = _.map tilesWithPlayers, (twp) =>
        tile: twp, distance: @getStepsToTile tile, twp
      tile: tile, distance: (_.min eachPlayer, (twp) -> twp.distance).distance
    grouped = _.groupBy distances, (item) -> item.distance
    farthest = _.max _.keys(grouped), (key) -> parseInt key
    
    _.each board.tiles, (tile) -> tile.gypsy = false
    target = grouped[farthest][Math.floor Math.random()*grouped[farthest].length]
    target.tile.gypsy = true
    
    Boards.update _id: board._id,
      $set:
        tiles: board.tiles
