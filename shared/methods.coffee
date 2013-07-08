NonEmptyString = Match.Where (x) ->
  check x, String
  x.length != 0

getGame = (gameId, userId) ->
  game = Games.findOne gameId
  if !game or (!game.public and !_.contains game.players, userId)
    throw new Meteor.Error 404, "No such game"
  if game.currentTurnId != userId
    throw new Meteor.Error 403, "It's not your turn"
  if game.players.length < 2
    throw new Meteor.Error 403, "Game isn't ready. There must be at least 2 players"
  game

Meteor.methods
  createGame: (options) ->
    check options, {public: Match.Optional Boolean}
    
    options.public = true
    characters = {}
    characters[this.userId] = CharacterHelper.getRandomCharacter()
    
    if !this.userId
      throw new Meteor.Error 403, "You must be logged in"
    Games.insert
      owner: this.userId
      public: true
      started: false
      players: [this.userId]
      characters: characters
      weapons: {}
      winner: ""
      deckId: ""
      handIds: []
      crystalsIds: []
  addPlayer: (gameId) ->
    check gameId, String
    
    if !this.userId
      throw new Meteor.Error 403, "You must be logged in"
    
    game = Games.findOne gameId
    if !game or game.started
      throw new Meteor.Error 404, "No such game"
    if _.contains game.players, this.userId
      throw new Meteor.Error 403, "This player is already in the game"
    
    game.players.push this.userId
    game.characters[this.userId] = CharacterHelper.getRandomCharacter _.unique game.characters
    
    Games.update _id: gameId,
      $set:
        players: game.players
        characters: game.characters
  chooseCharacter: (gameId, color) ->
    check gameId, String
    check color, String
    
    game = getGame gameId, this.userId
    
    if game.started and 1==2
      throw new Meteor.Error 403, "Can't do this after the game has started!"
    
    if CharacterHelper.canChooseCharacter _.unique(game.characters), color
      game.characters[this.userId] = color
    else
      throw new Meteor.Error 403, "Not a valid/available color"
    
    Games.update _id: gameId,
      $set:
        characters: game.characters
  playCardFromHand: (gameId, cardIndex, toArea, toPosition) ->
    check gameId, String
    check cardIndex, Number
    check toArea, String
    check toPosition, Object
    
    game = getGame gameId, this.userId
    hand = Hands.findOne
      gameId: gameId
      owner: this.userId
    card = hand.cards[cardIndex]
    
    # remove the card from hand
    # but only after it's verified to be a valid move
    pluck = ->
      hand.cards.splice cardIndex, 1
    
    if toArea == "crystals" and card.type == "crystal"
      pluck()
      crystals = Crystals.findOne
        gameId: gameId
        owner: this.userId
      crystals.stacks[0].push card
      Crystals.update _id: crystals._id,
        $set:
          stacks: crystals.stacks
    else if toArea == "weapon" and card.type == "weapon"
      pluck()
      if card.playCost > game.currentTurnEnergy
        throw new Meteor.Error 403, "Not enough energy! #{card.playCost} > #{game.currentTurnEnergy}"
      game.currentTurnEnergy -= card.playCost
      game.weapons[this.userId] = card
    else
      throw new Meteor.Error 403, "NOPE."
    
    Games.update _id: gameId,
      $set:
        weapons: game.weapons
        currentTurnEnergy: game.currentTurnEnergy
    Hands.update _id: hand._id,
      $set:
        cards: hand.cards
  spendCrystals: (gameId, amount) ->
    check gameId, String
    check amount, Number
    
    game = getGame gameId, this.userId
    
    crystals = Crystals.findOne
      gameId: gameId
      owner: this.userId
    
    if crystals?.stacks[amount]?.length > 0
      crystals?.stacks[0].push crystals?.stacks[amount].pop()
      game.currentTurnEnergy += amount
      # go back to start, collect #{amount} energy..
    else
      throw new Meteor.Error 403, "Can't spend crystals you don't have, bro!"
    
    Crystals.update _id: crystals._id,
      $set:
        stacks: crystals.stacks
    Games.update _id: gameId,
      $set:
        currentTurnEnergy: game.currentTurnEnergy

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
