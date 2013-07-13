class @Gameplay
  @newDeck: (gameId = "", playerCount = 2) ->
    cardCount = 50 + playerCount * 10
    deck = {}
    deck.gameId = gameId
    deck.cards = (new Deck cardCount).cards
    deck
  
  @newBoard: (gameId = "", players) ->
    playerCount = players.length
    board = {}
    w = Math.round (4+playerCount) * 1.4
    h = Math.round (4+playerCount) * 1.1
    board.gameId = gameId
    board.tiles = BoardHelper.generateTiles w, h
    board.columns = w
    board.rows = h
    
    @setCardPickups board
    @positionPlayers board, players
    
    board
  
  @setCardPickups: (board) ->
    inner = (board.columns-2) * (board.rows-2)
    pickups = []
    while inner > 3 and pickups.length / inner < 1 / 9
      r = Math.floor Math.random()*inner
      if -1 == pickups.indexOf r
        pickups.push r
    for index in pickups
      row = Math.floor(index/(board.columns-2))
      column = index - (row*(board.columns-2))
      t = @getTileAt board, column+1, row+1
      t.cardPickup = true
    board
  
  @positionPlayers: (board, players) ->
    attempts = board.tiles.length * 10
    attempts = 100 if attempts < 100
    for player in players
      attempt = 0
      t = board.tiles[Math.floor Math.random()*board.tiles.length]
      while !t.cardPickup and !t.player and attempt < attempts
        t = board.tiles[Math.floor Math.random()*board.tiles.length]
        attempt++
      # do something if too many attempts!
      t.player = player
    board
  
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
  
  # modifies deck, returns hands
  @dealInitialHands: (deck, playerCount) ->
    cardCount = 5
    hands = []
    for i in [0..playerCount-1]
      hands[i] = []
    for i in [1..cardCount]
      for hand in hands
        hand.push deck.cards.pop()
    hands
  
  @energyRequiredToMove: (distance) ->
    1 + Math.floor(distance/2) + Math.pow((distance-1), 2)
  
  @getDamage: (weapon, energy, spells) ->
    multiple = Math.floor energy/weapon.useCost
    #damage = weapon.damage + (energy-weapon.useCost)
    damage = multiple * weapon.damage + (energy % weapon.useCost)
    if spells?.length > 0
      for spell in spells
        damage = SpellHelper.applySpellToAttack(spell, damage)
    damage
