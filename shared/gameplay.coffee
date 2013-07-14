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
    
    @positionPlayers board, players
    board.tiles[Math.floor Math.random()*board.tiles.length].gypsy = true
    BoardHelper.moveGypsy board
    BoardHelper.moveGypsy board
    
    board
  
  @positionPlayers: (board, players) ->
    attempts = board.tiles.length * 10
    attempts = 200 if attempts < 200
    for player in players
      attempt = 0
      t = board.tiles[Math.floor Math.random()*board.tiles.length]
      while t.player and attempt < attempts
        t = board.tiles[Math.floor Math.random()*board.tiles.length]
        attempt++
      # do something if too many attempts!
      console.log "Adding #{player} to #{t.row}x#{t.column} #{attempt}"
      if t.player
        throw new Meteor.Error 500, "Trying to add a player to a tile that already has a player.. #{attempt}"
      t.player = player
    board
  
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
  
  @newGypsyCards: ->
    cards = []
    for i in [1..2]
      cards.push Cards.getWeapon()
    for i in [1..2]
      cards.push Cards.getSpell()
    cards
  
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
  
  @livingPlayers: (game) ->
    _.filter game.players, (playerId) ->
      game.life[playerId] > 0
  
  @declareWinner: (winner = false) ->
    if winner
      "#{winner.username} won!"
    else
      "Everyone is dead!"
