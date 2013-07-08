class @BoardHelper
  constructor: () ->
  
  @generateTiles: (mapColumns = 10, mapRows = 6) ->
    tiles = []
    for row in [0..mapRows-1]
      for column in [0..mapColumns-1]
        cardPickup = if ((row+1) % 2) + ((column+1) % 3) == 0 then true else false
        tiles.push
          row: row
          column: column
          cardPickup: cardPickup
          player: false
    tiles
