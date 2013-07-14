NonEmptyString = Match.Where (x) ->
  check x, String
  x.length != 0

getGame = (gameId, userId, duringAnyTurn = false) ->
  game = Games.findOne gameId
  if !game or (!game.public and !_.contains game.players, userId)
    throw new Meteor.Error 404, "No such game"
  if game.currentTurnId != userId and !duringAnyTurn
    throw new Meteor.Error 403, "It's not your turn"
  if game.players.length < 2
    throw new Meteor.Error 403, "Game isn't ready. There must be at least 2 players"
  game

getPlayer = (_id) ->
  Meteor.users.findOne _id

Meteor.methods
  createGame: (options) ->
    check options, {public: Match.Optional Boolean}
    
    pub = if options.public then true else false
    characters = {}
    characters[@userId] = CharacterHelper.getRandomCharacter()
    
    if !@userId
      throw new Meteor.Error 403, "You must be logged in"
    Games.insert
      owner: @userId
      public: pub
      started: false
      createdDate: Date.now()
      players: [@userId]
      life: {}
      characters: characters
      weapons: {}
      winner: ""
      deckId: ""
      handIds: []
      crystalsIds: []
  addPlayer: (gameId) ->
    check gameId, String
    
    if !@userId
      throw new Meteor.Error 403, "You must be logged in"
    
    game = Games.findOne gameId
    if !game or game.started
      throw new Meteor.Error 404, "No such game"
    if _.contains game.players, @userId
      throw new Meteor.Error 403, "This player is already in the game"
    
    game.players.push @userId
    game.characters[@userId] = CharacterHelper.getRandomCharacter _.unique game.characters
    
    Games.update _id: gameId,
      $set:
        players: game.players
        characters: game.characters
  chooseCharacter: (gameId, color) ->
    check gameId, String
    check color, String
    
    game = getGame gameId, @userId, true
    
    if game.started and 1==2
      throw new Meteor.Error 403, "Can't do this after the game has started!"
    
    if CharacterHelper.canChooseCharacter _.unique(game.characters), color
      game.characters[@userId] = color
    else
      throw new Meteor.Error 403, "Not a valid/available color"
    
    Games.update _id: gameId,
      $set:
        characters: game.characters
  playSpell: (gameId, cardIndex, options) ->
    check gameId, String
    check cardIndex, Number
    check options, Object
    
    game = getGame gameId, @userId
    hand = Hands.findOne
      gameId: gameId
      owner: @userId
    card = hand.cards[cardIndex]
    
    unless card.type == "spell"
      throw new Meteor.Error 403, "Can't playSpell with a non-Spell card, jerk."
    
    hand.cards.splice cardIndex, 1
    game.spells.push card
    
    Games.update _id: gameId,
      $set:
        spells: game.spells
    Hands.update _id: hand._id,
      $set:
        cards: hand.cards
  spendCrystals: (gameId, spendingCrystals) ->
    check gameId, String
    check spendingCrystals, Match.Where (arr) ->
      for i in [1..5]
        check arr[i], Number
    
    game = getGame gameId, @userId
    
    crystals = Crystals.findOne
      gameId: gameId
      owner: @userId
    
    for i in [1..5]
      if spendingCrystals[i] > 0 and crystals?.stacks?[i]?.length < spendingCrystals[i]
        throw new Meteor.Error 403, "Can't spend crystals you don't have, bro!"
    
    for i in [1..5]
      if spendingCrystals[i] > 0
        for j in [0..spendingCrystals[i]-1]
          try
            crystals?.stacks[0].push crystals?.stacks[i].pop()
            game.currentTurnEnergy += i
          catch err
            console.log err
            throw new Meteor.Error 500, err
            #throw new Meteor.Error 500, "Error spending crystals.."
    
    Crystals.update _id: crystals._id,
      $set:
        stacks: crystals.stacks
    Games.update _id: gameId,
      $set:
        currentTurnEnergy: game.currentTurnEnergy
  moveTo: (gameId, column, row) ->
    check gameId, String
    check column, Number
    check row, Number
    
    game = getGame gameId, @userId
    board = Boards.findOne gameId: gameId
    
    if game.movesThisTurn > 0
      throw new Meteor.Error 403, "Only one move per turn, plz"
    
    myTile = _.find board.tiles, (tile) =>
      tile.player == @userId
    if !myTile
      throw new Meteor.Error 500, "Can't find you on the board!"
    
    destTile = _.find board.tiles, (tile) ->
      tile.row == row and tile.column == column
    if !destTile
      throw new Meteor.Error 404, "I don't see the requested column on the board.."
    
    dist = BoardHelper.getStepsToTile myTile, destTile
    energyToMove = Gameplay.energyRequiredToMove dist
    if game.currentTurnEnergy < energyToMove
      throw new Meteor.Error 403, ErrorHelper.ENERGY_REQUIRED
    
    destTile.player = @userId
    myTile.player = false
    game.currentTurnEnergy -= energyToMove
    
    # This if statement is only required because I haven't initialized any games with this property yet..
    if !game.movesThisTurn?
      game.movesThisTurn = 0
    game.movesThisTurn++
    
    game.tradeWithGypsy = destTile.gypsy == true
    
    Games.update _id: gameId,
      $set:
        currentTurnEnergy: game.currentTurnEnergy
        movesThisTurn: game.movesThisTurn
        tradeWithGypsy: game.tradeWithGypsy
    Boards.update gameId: gameId,
      $set:
        tiles: board.tiles
  attack: (gameId, column, row, energy) ->
    check gameId, String
    check column, Number
    check row, Number
    check energy, Number
    
    game = getGame gameId, @userId
    board = Boards.findOne gameId: gameId
    
    myTile = _.find board.tiles, (tile) =>
      tile.player == @userId
    if !myTile
      throw new Meteor.Error 500, "Can't find you on the board!"
    
    destTile = _.find board.tiles, (tile) ->
      tile.row == row and tile.column == column
    if !destTile
      throw new Meteor.Error 404, "I don't see the requested column on the board.."
    if !destTile.player
      throw new Meteor.Error 404, "I don't see a player on that tile.."
    
    weapon = game.weapons[@userId]
    if !weapon
      console.log "No weapon for #{@userId} on tile #{column}x#{row}, so using fists instead"
      weapon = WeaponHelper.fists()
    
    dist = BoardHelper.getStepsToTile myTile, destTile
    if dist > weapon.range
      throw new Meteor.Error 403, "You are not close enough to attack"
    
    if game.currentTurnEnergy < energy or energy < weapon.useCost
      throw new Meteor.Error 403, "Not enough energy!"
    
    damage = Gameplay.getDamage weapon, energy, game.spells
    
    game.attack =
      attacker: @userId
      defender: destTile.player
      weapon: weapon
      energy: energy
    
    game.currentTurnEnergy -= energy
    
    Games.update _id: gameId,
      $set:
        currentTurnEnergy: game.currentTurnEnergy
        attack: game.attack
    Boards.update gameId: gameId,
      $set:
        tiles: board.tiles
  defend: (gameId, defendingCrystals) ->
    check gameId, String
    check defendingCrystals, Match.Where (arr) ->
      for i in [1..5]
        check arr[i], Number
    
    game = getGame gameId, @userId, true
    
    unless game.attack?.defender == @userId
      throw new Meteor.Error 403, "Why are you defending? You're not under attack.."
    
    crystals = Crystals.findOne
      gameId: gameId
      owner: @userId
    
    totalDefense = 0
    for i in [1..5]
      if crystals.stacks[i].length < defendingCrystals[i]
        throw new Meteor.Error 403, "Can't spend crystals you don't have.."
      # starting at 1 because [a..b] is inclusive of b
      if defendingCrystals[i] > 0
        for j in [0..defendingCrystals[i]-1]
          crystals?.stacks[0].push crystals?.stacks[i].pop()
          totalDefense += i
    
    totalDamage = game.attack.energy - totalDefense
    game.life[@userId] -= totalDamage if totalDamage > 0
    game.life[@userId] = 0 if game.life[@userId] < 0
    game.attack = false
    
    livingPlayers = Gameplay.livingPlayers game
    if livingPlayers.length < 2
      if livingPlayers.length == 1
        game.winner = livingPlayers[0]
        MessageHelper.toAll gameId, Gameplay.declareWinner(getPlayer(livingPlayers[0]))
      else
        MessageHelper.toAll gameId, Gameplay.declareWinner()
      game.currentTurnId = false
    Games.update _id: gameId,
      $set:
        life: game.life
        attack: game.attack
        currentTurnId: game.currentTurnId
        winner: game.winner
    Crystals.update _id: crystals._id,
      $set:
        stacks: crystals.stacks
  tradeWithGypsy: (gameId, code) ->
    check gameId, String
    check code, String
    
    game = getGame gameId, @userId
    
    unless game.currentTurnId == @userId
      throw new Meteor.Error 403, "Can't trade when it's not your turn"
    
    unless game.tradeWithGypsy
      throw new Meteor.Error 403, "Can't trade with the gypsy right now"
    
    hand = Hands.findOne
      gameId: gameId
      owner: @userId
    crystals = Crystals.findOne
      gameId: gameId
      owner: @userId
    
    card = _.find game.gypsyCards, (gc) -> gc.code == code
    
    unless card
      throw new Meteor.Error 403, "Invalid code"
    
    totalCrystalCards = CrystalsHelper.totalCrystalCards crystals.stacks
    
    if totalCrystalCards < card.playCost
      throw new Meteor.Error 403, "You can't afford this"
    
    taken = 0
    for stack in [0..5]
      while taken < card.playCost and crystals.stacks[stack].length > 0
        crystals.stacks[stack].pop()
        taken++
    
    if taken != card.playCost
      throw new Meteor.Error 403, "Had trouble taking #{card.playCost} crystals.."
    
    hand.cards.push card
    
    game.gypsyCards = []
    game.tradeWithGypsy = false
    
    Games.update _id: gameId,
      $set:
        gypsyCards: game.gypsyCards
        tradeWithGypsy: game.tradeWithGypsy
    Crystals.update _id: crystals._id,
      $set:
        stacks: crystals.stacks
    Hands.update _id: hand._id,
      $set:
        cards: hand.cards
  dismissMessage: (gameId, messageId) ->
    check gameId, String
    check messageId, String
    
    message = Messages.findOne
      _id: messageId
      recipient: @userId
    
    if message
      Messages.update _id: messageId,
        $set:
          read: true
  cheat: (gameId, action, val1 = "", val2 = "") ->
    check gameId, String
    check action, String
    check val1, String
    check val2, String
    
    game = getGame gameId, @userId, true
    
    if action == "playCrystal"
      stack = parseInt val1
      crystals = Crystals.findOne
        gameId: gameId
        owner: @userId
      crystals.stacks[stack].push Cards.getCrystal()
      return Crystals.update _id: crystals._id,
        $set:
          stacks: crystals.stacks
    if action == "getSpell"
      spell = Cards.getSpell val1
      hand = Hands.findOne
        gameId: gameId
        owner: @userId
      hand.cards.push spell
      return Hands.update _id: hand._id,
        $set:
          cards: hand.cards
    if action == "getWeapon"
      weapon = Cards.getWeapon val1
      hand = Hands.findOne
        gameId: gameId
        owner: @userId
      hand.cards.push weapon
      return Hands.update _id: hand._id,
        $set:
          cards: hand.cards
    if action == "addLife"
      game.life[@userId] += parseInt val1
      Games.update _id: gameId,
        $set:
          life: game.life
    if action == "myTurn"
      game.currentTurnId = @userId
      Games.update _id: gameId,
        $set:
          currentTurnId: game.currentTurnId

@displayName = (user) ->
  if user.profile and user.profile.name
    return user.profile.name
  user.emails[0].address

@ownerName = (game) ->
  user = Meteor.users.findOne game.owner
  if user.profile and user.profile.name
    return user.profile.name
  return game.owner

@userById = (_id) ->
  _id = _id + ""
  user = Meteor.users.findOne _id
  return _id if !user
  if user.profile and user.profile.name
    return user.profile.name
  user.emails[0].address
