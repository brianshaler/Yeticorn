
getGame = (gameId, userId, duringAnyTurn = false) ->
  game = Games.findOne gameId
  if !game or (!game.public and !_.contains game.players, userId)
    throw new Meteor.Error 404, "No such game"
  if game.currentTurnId != userId and !duringAnyTurn
    throw new Meteor.Error 403, "It's not your turn"
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
      stacks = [[],[],[],[],[],[]]
      for [1..3]
        stacks[1].push Cards.getCrystal()
      crystalsId = Crystals.insert
        owner: game.players[i]
        gameId: gameId
        stacks: stacks
      handIds.push handId
      crystalsIds.push crystalsId
    
    for player in game.players
      game.life[player] = 20
    
    game.currentTurnId = game.players[0]
    game.currentTurnEnergy = 0
    game.tradeWithGypsy = false
    game.gypsyCards = Gameplay.newGypsyCards()
    
    Games.update _id: gameId,
      $set:
        started: game.started
        boardId: game.boardId
        deckId: game.deckId
        handIds: handIds
        crystalsIds: crystalsIds
        currentTurnId: game.currentTurnId
        currentTurnEnergy: game.currentTurnEnergy
        tradeWithGypsy: game.tradeWithGypsy
        gypsyCards: game.gypsyCards
        life: game.life
  chooseCharacter: (gameId, color = "") ->
    check gameId, String
    check color, String
    
    game = getGame gameId, @userId, true
    
    if game.started and 1==2
      throw new Meteor.Error 403, "Can't do this after the game has started!"
    
    if color == ""
      game.characters[@userId] = CharacterHelper.getRandomCharacter _.unique game.characters
    else if CharacterHelper.canChooseCharacter _.unique(game.characters), color
      game.characters[@userId] = color
    else
      throw new Meteor.Error 403, "Not a valid/available color"
    
    Games.update _id: gameId,
      $set:
        characters: game.characters
  playCardFromHand: (gameId, cardIndex, toArea, options) ->
    check gameId, String
    check cardIndex, Number
    check toArea, String
    check options, Object
    
    saveDeck = false
    
    game = getGame gameId, @userId
    hand = Hands.findOne
      gameId: gameId
      owner: @userId
    card = hand.cards[cardIndex]
    
    # remove the card from hand
    # but only after it's verified to be a valid move
    pluck = ->
      hand.cards.splice cardIndex, 1
    
    if toArea == "crystals" and card.type == "crystal"
      pluck()
      crystals = Crystals.findOne
        gameId: gameId
        owner: @userId
      crystals.stacks[0].push card
      Crystals.update _id: crystals._id,
        $set:
          stacks: crystals.stacks
    else if toArea == "weapon" and card.type == "weapon"
      pluck()
      if card.playCost > game.currentTurnEnergy
        throw new Meteor.Error 403, ErrorHelper.ENERGY_REQUIRED
      game.currentTurnEnergy -= card.playCost
      game.weapons[@userId] = card
    else if toArea == "spell" and card.type == "spell"
      if card.playCost > game.currentTurnEnergy
        throw new Meteor.Error 403, ErrorHelper.ENERGY_REQUIRED
      
      myCardsIds = _.clone options.myCards
      if options.myCards?.length > 0
        options.myCards = _.map options.myCards, (index) =>
          if index == cardIndex
            throw new Meteor.Error 403, "You can't use the card you're playing!"
          hand.cards[index]
      
      if !SpellHelper.conditionsMet card, options
        throw new Meteor.Error 403, "You haven't met the conditions yet.."
      
      if card.opponentRandomCard? > 0
        _.each options.opponents, (playerId) =>
          _hand = Hands.findOne
            gameId: gameId
            owner: playerId
          
          if _hand.cards.length == 0
            MessageHelper.sendMessage gameId, @userId, "Can't steal from an empty hand!"
          else
            for i in [1..card.opponentRandomCard]
              if _hand.cards.length > 0
                pickMe = Math.floor Math.random()*_hand.cards.length
                if card.opponentCardTo and String(card.opponentCardTo) == "hand"
                  hand.cards.push _hand.cards[pickMe]
                _hand.cards.splice pickMe, 1
            Hands.update _id: _hand._id,
              $set:
                cards: _hand.cards
      if card.takeWeapon? == true
        _.each options.opponents, (playerId) =>
          if game.weapons[playerId]
            hand.cards.push game.weapons[playerId]
          game.weapons[playerId] = false
      if card.loseLife? > 0
        _.each options.opponents, (playerId) =>
          game.life[playerId] -= card.loseLife
      if card.myCardTo? == "weapon"
        game.weapons[options.opponents[0]] = options.myCards[0]
      
      left = _.filter hand.cards, (card, index) =>
        keep = true
        keep = false if index == cardIndex
        if keep and myCardsIds?.length > 0
          if -1 != myCardsIds.indexOf index
            keep = false
        keep
      
      hand.cards = left
      
      if card.drawCards? > 0
        saveDeck = true
        deck = Decks.findOne
          gameId: gameId
        for i in [1..card.drawCards]
          hand.cards.push deck.cards.pop()
      
      if card.gainLife? > 0
        game.life[@userId] += card.gainLife
      
      if !game.spells?
        game.spells = []
      game.currentTurnEnergy -= card.playCost
      if SpellHelper.isPersistent card
        game.spells.push card
      
    else
      throw new Meteor.Error 403, "NOPE."
    
    Games.update _id: gameId,
      $set:
        life: game.life
        weapons: game.weapons
        spells: game.spells
        currentTurnEnergy: game.currentTurnEnergy
    Hands.update _id: hand._id,
      $set:
        cards: hand.cards
    if saveDeck
      Decks.update _id: deck._id,
        $set:
          cards: deck.cards
  endTurn: (gameId) ->
    check gameId, String
    
    game = getGame gameId, this.userId
    
    livingPlayers = Gameplay.livingPlayers game
    index = (1 + livingPlayers.indexOf @userId) % livingPlayers.length
    game.currentTurnId = livingPlayers[index]
    MessageHelper.sendMessage gameId, livingPlayers[index], "It's your turn!"
    game.currentTurnEnergy = 0
    game.movesThisTurn = 0
    game.spells = []
    game.tradeWithGypsy = false
    game.gypsyCards = Gameplay.newGypsyCards()
    
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
    
    BoardHelper.moveGypsy Boards.findOne gameId: gameId
    
    Games.update _id: gameId,
      $set:
        currentTurnId: game.currentTurnId
        currentTurnEnergy: game.currentTurnEnergy
        tradeWithGypsy: game.tradeWithGypsy
        movesThisTurn: game.movesThisTurn
        spells: game.spells
        gypsyCards: game.gypsyCards
    Decks.update _id: deck._id,
      $set:
        cards: deck.cards
    Hands.update _id: hand._id,
      $set:
        cards: hand.cards
    Crystals.update _id: crystals._id,
      $set:
        stacks: crystals.stacks
