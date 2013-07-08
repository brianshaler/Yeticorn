class @HandController
  constructor: ->
    @cards = []
    @hand = {}
    
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
          return console.log "I CAN'T WORK UNDER THESE CONDITIONS!"
        
        game = Games.findOne Session.get "gameId"
        
        playIt = (toArea, toPosition = {}) =>
          try
            Meteor.call "playCardFromHand",
              Session.get("gameId"),
              cardIndex,
              toArea,
              toPosition,
              (err, data) =>
                if err and err.reason
                  return console.log err.reason
                console.log err, data
          catch err
            if err and err.reason
              return console.log err.reason
        
        if card?.type == "crystal"
          playIt "crystals"
        if card?.type == "weapon"
          if game.currentTurnEnergy < card.playCost
            throw new Meteor.Error "Not enough energy!"
          playIt "weapon"
