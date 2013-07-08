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
    attempts = board.tiles.length * 5
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
