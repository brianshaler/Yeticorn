class @CrystalsController
  constructor: ->
    @stacks = [[],[],[],[],[],[]]
    
    Meteor.autosubscribe =>
      Meteor.subscribe "crystals", Session.get("gameId") if Session.get("gameId")
    
    # Other people's crystals!
    # Crystals.find({gameId: Session.get("gameId"), owner: {$ne: Meteor.userId()}})
    
    Template.crystals.stacks = ->
      stacks = []
      crystals = Crystals.findOne
        gameId: Session.get("gameId")
        owner: Meteor.userId()
      cnt = -1
      if crystals and crystals.stacks
        stacks = _.map crystals.stacks, (stack) ->
          cnt++
          obj =
            cards: stack
            order: cnt
            count: stack.length
      stacks
    
    Template.crystals.events =
      "click .crystals-stack": (event, template) =>
        i = 0
        targ = $(event.target)
        energy = false
        while i < 100 and targ.length > 0 and energy == false
          if targ.attr("data-energy")
            energy = parseInt targ.attr("data-energy")
          targ = targ.parent()
          i++
        if energy == 0
          App.alert "Can't spend uncharged crystals, dummy!"
        if energy == false
          return "i don't know what happened"
        if energy > 0
          spendingCrystals = [0,0,0,0,0,0]
          spendingCrystals[energy] = 1
          App.call "spendCrystals", spendingCrystals, (err, data) ->
            if err?.reason
              return App.alert err.reason
          console.log "SHUT UP AND TAKE MY #{energy} CRYSTALS!"
