
getGame = (gameId, userId) ->
  game = Games.findOne gameId
  if !game or (!game.public and !_.contains game.players, userId)
    throw new Meteor.Error 404, "No such game"
  if game.currentTurnId != userId
    throw new Meteor.Error 403, "It's not your turn"
  if game.players.length <= 1
    throw new Meteor.Error 403, "Game isn't ready. There must be at least 2 players"
  game


Meteor.methods
  startGame: (gameId) ->
    check gameId, String
    if !this.userId
      throw new Meteor.Error 403, "You must be logged in"
    
    game = Games.findOne gameId
    if !game or game.owner != this.userId
      throw new Meteor.Error 404, "No such game"
    if game.started
      throw new Meteor.Error 404, "Game already started.."
    if game.players < 2
      throw new Meteor.Error 403, "Need more players"
    
    game.started = true
    gameId = game._id
    
    deckObj = Gameplay.newDeck gameId, game.players.length
    game.deckId = deckId = Decks.insert deckObj
    
    boardObj = Gameplay.newBoard gameId, game.players
    game.boardId = boardId = Boards.insert boardObj
    
    handCards = Gameplay.dealInitialHands deckObj, game.players.length
    
    handIds = []
    crystalsIds = []
    for i in [0..game.players.length-1]
      handId = Hands.insert
        owner: game.players[i]
        gameId: gameId
        cards: handCards[i]
      crystalsId = Crystals.insert
        owner: game.players[i]
        gameId: gameId
        stacks: [[],[],[],[],[],[]]
      handIds.push handId
      crystalsIds.push crystalsId
    
    game.currentTurnId = game.players[0]
    
    Games.update _id: gameId,
      $set:
        started: game.started
        boardId: game.boardId
        deckId: game.deckId
        handIds: handIds
        crystalsIds: crystalsIds
        currentTurnId: game.currentTurnId
    
  endTurn: (gameId) ->
    check gameId, String
    
    game = getGame gameId, this.userId
    index = (1 + game.players.indexOf this.userId) % game.players.length
    game.currentTurnId = game.players[index]
    game.currentTurnEnergy = 0
    
    hand = Hands.findOne
      gameId: gameId
      owner: this.userId
    deck = Decks.findOne
      gameId: gameId
    
    hand.cards.push deck.cards.pop()
    
    crystals = Crystals.findOne
      gameId: gameId
      owner: this.userId
    
    crystals.stacks = CrystalsHelper.incrementAll crystals.stacks
    
    Games.update _id: gameId,
      $set:
        currentTurnId: game.currentTurnId
        currentTurnEnergy: game.currentTurnEnergy
    Decks.update _id: deck._id,
      $set:
        cards: deck.cards
    Hands.update _id: hand._id,
      $set:
        cards: hand.cards
    Crystals.update _id: crystals._id,
      $set:
        stacks: crystals.stacks
