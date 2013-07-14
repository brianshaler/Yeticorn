class @HandController
  constructor: ->
    @cards = []
    @hand = {}
    
    Session.set "cardIndex", false
    Session.set "confirmPlayingWeapon", false
    Session.set "confirmPlayingSpell", false
    Session.set "spellConditions", {}
    Session.set "selectOpponents", false
    Session.set "selectionType", false
    Session.set "selectCardsFromHand", false
    
    Meteor.autosubscribe =>
      Meteor.subscribe "hand", Session.get("gameId") if Session.get("gameId")
    
    Deps.autorun =>
      lastUpdate = Session.set "lastUpdate", Date.now()
      @hand = Hands.findOne gameId: Session.get "gameId"
    
    Template.hand.hand = =>
      Session.get "lastUpdate"
      cnt = 0
      if @hand and @hand.cards
        @hand.cards = _.map @hand.cards, (card) ->
          card.order = ++cnt
          card
      @hand
    
    Template.hand.events
      "click .playing-card": (event, template) =>
        cardIndex = parseInt($(event.target).attr("data-order")) - 1
        card = @hand.cards[cardIndex]
        if !card?.type?
          return App.alert "I CAN'T WORK UNDER THESE CONDITIONS!"
        
        game = Games.findOne Session.get "gameId"
        
        if card?.type == "crystal"
          @playCard cardIndex, "crystals", {}, true
        if card?.type == "weapon"
          #if game.currentTurnEnergy < card.playCost
          #  return App.alert "Not enough energy!"
          #playIt "weapon"
          console.log "cardIndex #{cardIndex}"
          Session.set "cardIndex", cardIndex
          Session.set "confirmPlayingWeapon", true
        if card?.type == "spell"
          #return App.alert "This is a spell. I don't know how to do stuff with these yet"
          Session.set "cardIndex", cardIndex
          Session.set "confirmPlayingSpell", true
    
    Template.confirm_playing_weapon.card = 
    Template.confirm_playing_spell.card = =>
      Session.get "lastUpdate"
      cardIndex = Session.get "cardIndex"
      return false if !cardIndex? or !@hand?.cards?[cardIndex]?
      @hand.cards[cardIndex]
    
    Template.confirm_playing_weapon.events
      "click .play-it": (event) =>
        Session.set "confirmPlayingWeapon", false
        @playCard Session.get("cardIndex"), "weapon", {}, true
      "click .cancel": (event) =>
        Session.set "confirmPlayingWeapon", false
    
    Template.confirm_playing_spell.events
      "click .play-it": (event) =>
        Session.set "confirmPlayingSpell", false
        @setupSpell()
      "click .cancel": (event) =>
        Session.set "confirmPlayingSpell", false
    
    Template.confirm_playing_weapon.enoughEnergy = 
    Template.confirm_playing_spell.enoughEnergy = =>
      Session.get "lastUpdate"
      cardIndex = Session.get "cardIndex"
      return false if !cardIndex? or !@hand?.cards?[cardIndex]?
      card = @hand.cards[cardIndex]
      return false if !card?
      game = Games.findOne Session.get "gameId"
      card.playCost <= game.currentTurnEnergy
    
    Template.select_opponents.enoughSelected = =>
      conditions = Session.get "spellConditions"
      conditions.opponents?.length == Session.get "selectOpponents"
    
    Template.select_opponents.oneOpponent = =>
      1 == Session.get "selectOpponents"
    
    Template.select_opponents.events
      "click .opponent": (event) =>
        player = $(event.target).attr "data-id"
        conditions = Session.get "spellConditions"
        if !conditions.opponents?
          conditions.opponents = []
        
        existing = conditions.opponents.indexOf player
        if existing != -1
          conditions.opponents.splice existing, 1
        else
          conditions.opponents.push player
        conditions.opponents = _.unique conditions.opponents
        
        Session.set "spellConditions", conditions
      "click .continue": =>
        Session.set "selectOpponents", false
        @selectFromHand()
      "click .cancel": =>
        @cancelSpell()
    
    Template.select_cards_from_hand.cards = =>
      Template.hand.hand().cards
    
    Template.select_cards_from_hand.enoughSelected = =>
      conditions = Session.get "spellConditions"
      conditions.myCards?.length == Session.get "selectCardsFromHand"
    
    Template.select_cards_from_hand.events
      "click .select-card": (event) =>
        console.log "Select!"
        cardIndex = parseInt($(event.target).attr("data-order")) - 1
        card = @hand.cards[cardIndex]
        conditions = Session.get "spellConditions"
        if !conditions.myCards?
          conditions.myCards = []
        
        existing = conditions.myCards.indexOf cardIndex
        if existing != -1
          conditions.myCards.splice existing, 1
        else
          type = Session.get "selectionType"
          if type == "card" or card.type == type
            conditions.myCards.push cardIndex
        conditions.myCards = _.unique conditions.myCards
        
        console.log "clicked #{cardIndex}"
        Session.set "spellConditions", conditions
      "click .continue": =>
        Session.set "selectCardsFromHand", false
        @playSpell()
      "click .cancel": =>
        @cancelSpell()
    
  
  setupSpell: () ->
    conditions = {}
    Session.set "spellConditions", conditions
    cardIndex = Session.get "cardIndex"
    card = @hand.cards[cardIndex]
    
    game = Games.findOne Session.get "gameId"
    if game.currentTurnEnergy < card.playCost
      App.getEnergy card.playCost, (nextStep, cancel) =>
        if nextStep
          @selectOpponents()
        else
          @cancelSpell()
    else
      @selectOpponents()
  
  selectOpponents: =>
    console.log "selectOpponents"
    card = @hand.cards[Session.get "cardIndex"]
    
    opponents = SpellHelper.requiresOpponentSelection card
    if opponents > 0
      console.log "selectOpponents required"
      App.selectOpponents opponents, (nextStep, cancel) =>
        if nextStep
          @selectFromHand()
        else
          @cancelSpell()
    else
      @selectFromHand()
  
  selectFromHand: =>
    console.log "selectFromHand"
    card = @hand.cards[Session.get "cardIndex"]
    
    {type, quantity} = SpellHelper.requiresHandSelection card
    if quantity > 0
      console.log "selectFromHand required"
      App.selectFromHand type, quantity, (nextStep, cancel) =>
        if nextStep
          console.log "playCard"
          @playSpell()
        else
          @cancelSpell()
    else
      # console.log "No hand selection required! #{selectionType}, #{selectionQuantity}"
      @playSpell()
  
  playSpell: =>
    console.log "playSpell!"
    card = @hand.cards[Session.get "cardIndex"]
    conditions = Session.get "spellConditions"
    conditionsTest = _.clone conditions
    if conditionsTest.myCards?.length > 0
      conditionsTest.myCards = _.map conditionsTest.myCards, (cardIndex) =>
        @hand.cards[cardIndex]
    if SpellHelper.conditionsMet card, conditionsTest
      @playCard Session.get("cardIndex"), "spell", conditions, true
    else
      App.alert "An inconceivable error occurred.."
  
  cancelSpell: ->
    Session.set "cardIndex", false
    Session.set "spellConditions", {}
    Session.set "selectOpponents", false
    Session.set "selectionType", false
    Session.set "selectCardsFromHand", false
  
  playCard: (cardIndex, toArea, options = {}, canRetry = false) =>
    card = @hand.cards[cardIndex]
    try
      App.call "playCardFromHand",
        cardIndex,
        toArea,
        options,
        (err, data) =>
          if err and err.reason
            if err.reason == ErrorHelper.ENERGY_REQUIRED
              App.getEnergy card.playCost, (retry, cancel) =>
                if retry and canRetry
                  return @playCard cardIndex, toArea, options, false
                else
                  "cancel"
                Session.set "cardIndex", false
                @cancelSpell()
            else
              App.alert err.reason
              Session.set "cardIndex", false
    catch err
      Session.set "cardIndex", false
      if err and err.reason
        return App.alert err.reason
    
