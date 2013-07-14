class @GameController
  constructor: ->
    @game = null
    @hand = new HandController()
    @crystals = new CrystalsController()
    @board = new BoardController()
    
    @energyCallback = false
    
    Session.set "spendingCrystals", [0,0,0,0,0,0]
    Session.set "defendingCrystals", [0,0,0,0,0,0]
    
    $(document).ready () ->
      $("body").addClass("view-map")
    
    window.game = @
    window.addEventListener "viewportchanged", (v) =>
      @board.render()
    
    Meteor.autosubscribe =>
      Meteor.subscribe "game", @gameId() if @gameId()
      Meteor.subscribe "crystals", @gameId() if @gameId()
      Meteor.subscribe "unread_messages", @gameId() if @gameId()
    
    Deps.autorun =>
      lastUpdate = Session.set "lastUpdate", Date.now()
      @game = Games.findOne Session.get "gameId"
      if @game?.currentTurnId != Meteor.userId()
        Session.set "defendingCrystals", [0,0,0,0,0,0]
        Session.set "spendingCrystals", [0,0,0,0,0,0]
      @board.render()
    
    Template.game.playerList = ->
      Meteor.users.find _id: {$nin: [Meteor.userId()]}
    
    Template.game.myTurn = @myTurn
    Template.game.gameReady = @gameReady
    Template.game.gameId = @gameId
    Template.game.game = @getGame
    Template.game.myGame = @myGame
    Template.game.spectator =
    Template.status_bar.spectator = =>
      lastUpdate = Session.get "lastUpdate"
      @game.owner != Meteor.userId() and -1 == @game.players.indexOf Meteor.userId()
    Template.game.currentView = ->
      Session.get "currentView"
    Template.game.displayName = () ->
      displayName this
    
    Template.game.showOverlay = =>
      Template.game.message() or
      Template.game.underAttack() or
      Template.game.tradeWithGypsy() or
      Template.game.waitingForDefense() or
      Template.game.confirmPlayingWeapon() or
      Template.game.confirmPlayingSpell() or
      Template.game.energyRequired() or
      Template.game.selectOpponents() or
      Template.game.selectCardsFromHand() or
      Template.game.showMyInfo()
    
    Template.game.message = =>
      if Session.get "alert"
        messageTitle: Session.get("alertTitle"), message: Session.get "alert"
      else
        Messages.findOne
          recipient: Meteor.userId()
          gameId: @gameId()
          read: false
    
    Template.game.underAttack = =>
      lastUpdate = Session.get "lastUpdate"
      @game?.attack?.defender == Meteor.userId()
    
    Template.game.tradeWithGypsy = =>
      lastUpdate = Session.get "lastUpdate"
      @game?.tradeWithGypsy && @myTurn()
    
    Template.game.waitingForDefense = =>
      lastUpdate = Session.get "lastUpdate"
      @game?.attack
    
    Template.game.confirmPlayingWeapon = =>
      Session.get "confirmPlayingWeapon"
    
    Template.game.confirmPlayingSpell = =>
      Session.get "confirmPlayingSpell"
    
    Template.game.showMyInfo = =>
      Session.get "showMyInfo"
    
    Template.game.energyRequired = 
    Template.energy_required.energyRequired = =>
      Session.get "energyRequired"
    
    Template.game.selectOpponents = =>
      Session.get "selectOpponents"
    
    Template.game.selectCardsFromHand = =>
      Session.get "selectCardsFromHand"
    
    Template.message.events
      "click .dismiss": (event) =>
        message = Template.game.message()
        if Session.get "alert"
          Session.set "alert", false
          Session.set "alertTitle", false
        else
          App.call "dismissMessage", message._id
    
    Template.players.players = @getPlayers
    Template.players.displayName = () ->
      displayName this
    
    Template.players.canStart = () =>
      lastUpdate = Session.get "lastUpdate"
      return false if !@game?
      @game.players.length > 1 and @game.owner == Meteor.userId()
    
    Template.players.canJoin = () =>
      return false if !@game?
      Meteor.userId() and -1 == @game.players.indexOf Meteor.userId()
    
    Template.players.events
      "click .start-game": =>
        console.log "start game!"
        App.call "startGame"
      "click .join-game": =>
        console.log "join game!"
        App.call "addPlayer"
    
    Template.status_bar.players = =>
      players = @getPlayers()
      cnt = 0
      _.each players, (player) =>
        player.id = cnt++
        player.myTurn = player._id == @game.currentTurnId
        player.life = @game.life[player._id]
      players
    
    Template.status_bar.isMyTurn = =>
      @game.currentTurnId == Meteor.userId()
    
    Template.status_bar.currentTurnEnergy = =>
      lastUpdate = Session.get "lastUpdate"
      @game.currentTurnEnergy
    
    Template.status_bar.totalAvailableEnergy = =>
      crystals = Crystals.findOne
        gameId: Session.get "gameId"
        owner: Meteor.userId()
      return "" if !crystals?.stacks?
      total = 0
      for i in [1..5]
        total += crystals.stacks[i].length * i
      total
    
    Template.status_bar.events
      "click .view-hand-btn": =>
        $("body")
          .addClass("view-hand")
          .removeClass("view-map view-crystals")
      "click .view-map-btn": =>
        $("body")
          .addClass("view-map")
          .removeClass("view-hand view-crystals")
      "click .view-crystals-btn": =>
        $("body")
          .addClass("view-crystals")
          .removeClass("view-map view-hand")
    
    Template.select_opponents.opponentList = =>
      _.filter Template.status_bar.players(), (player) =>
        player._id != Meteor.userId()
    
    Template.defense.availableCrystals = =>
      stacks = []
      crystals = Crystals.findOne
        gameId: Session.get "gameId"
        owner: Meteor.userId()
      return if !crystals?.stacks?
      defendingCrystals = Session.get "defendingCrystals"
      for i in [1..5]
        avail = crystals.stacks[i].length - defendingCrystals[i]
        stack =
          order: i
          available: avail > 0
          count: if avail > 0 then avail else 0
        stacks.push stack
      stacks
    
    Template.defense.totalAttack = =>
      lastUpdate = Session.get "lastUpdate"
      return 0 if !@game?.attack?.weapon?
      Gameplay.getDamage @game.attack.weapon, @game.attack.energy, @game.spells
    
    Template.defense.pendingDamage = =>
      lastUpdate = Session.get "lastUpdate"
      damage = 0
      return 0 if !@game?.attack?
      
      if @game.attack.weapon
        damage = Gameplay.getDamage @game.attack.weapon, @game.attack.energy, @game.spells
      if Template.defense.defenseEnergy() > 0
        damage -= Template.defense.defenseEnergy()
      damage = 0 if damage < 0
      damage
    
    Template.defense.defenseEnergy = =>
      defendingCrystals = Session.get "defendingCrystals"
      total = 0
      for i in [1..5]
        total += i * defendingCrystals[i]
      total
    
    Template.defense.events
      "click .crystals-button": (event) =>
        energy = parseInt $(event.target).attr "data-energy"
        defendingCrystals = Session.get "defendingCrystals"
        defendingCrystals[energy]++
        console.log "energy: #{energy} ", "defendingCrystals", defendingCrystals
        Session.set "defendingCrystals", defendingCrystals
      "click .defense-button": (event) =>
        App.call "defend", Session.get "defendingCrystals"
      "click .reset-defense-button": =>
        Session.set "defendingCrystals", [0,0,0,0,0,0]
    
    Template.energy_required.availableCrystals = =>
      stacks = []
      crystals = Crystals.findOne
        gameId: Session.get "gameId"
        owner: Meteor.userId()
      return if !crystals?.stacks?
      spendingCrystals = Session.get "spendingCrystals"
      for i in [1..5]
        avail = crystals.stacks[i].length - spendingCrystals[i]
        stack =
          order: i
          available: avail > 0
          count: if avail > 0 then avail else 0
        stacks.push stack
      stacks
    
    Template.energy_required.toSpend = =>
      lastUpdate = Session.get "lastUpdate"
      toSpend = @game.currentTurnEnergy
      spendingCrystals = Session.get "spendingCrystals"
      for i in [1..5]
        toSpend += i * spendingCrystals[i]
      toSpend
    
    Template.energy_required.energyDeficit = =>
      deficit = Session.get("energyRequired") - Template.energy_required.toSpend()
      deficit = 0 if deficit < 0
      deficit
    
    Template.energy_required.enoughEnergy = =>
      lastUpdate = Session.get "lastUpdate"
      Template.energy_required.toSpend() >= Session.get "energyRequired"
    
    Template.energy_required.events
      "click .crystals-button": (event) =>
        energy = parseInt $(event.target).attr "data-energy"
        spendingCrystals = Session.get "spendingCrystals"
        spendingCrystals[energy]++
        Session.set "spendingCrystals", spendingCrystals
      "click .retry": =>
        spendingCrystals = Session.get "spendingCrystals"
        App.call "spendCrystals", spendingCrystals, (err, data) ->
          if err?.reason
            return App.error err.reason
          Session.set "spendingCrystals", [0,0,0,0,0,0]
          App.gotEnergy true
      "click .reset-button": =>
        Session.set "spendingCrystals", [0,0,0,0,0,0]
      "click .cancel": =>
        App.gotEnergy null, true
        Session.set "spendingCrystals", [0,0,0,0,0,0]
    
    Template.trade.cards = =>
      totalCrystals = Template.trade.totalCrystalCards()
      _.map @game.gypsyCards, (card) ->
        card.enoughCrystals = card.playCost <= totalCrystals
        card
    
    Template.trade.totalCrystalCards = =>
      crystals = Crystals.findOne
        gameId: Session.get "gameId"
        owner: Meteor.userId()
      CrystalsHelper.totalCrystalCards crystals.stacks
    
    Template.trade.events
      "click .trade-card": (event) =>
        code = $(event.target).attr "data-code"
        App.call "tradeWithGypsy", code
    
    Template.wait_for_defense.stuff = =>
      true
    
    Template.game.rendered = ->
      if Template.game.showOverlay()
        redrawOverlay()
  
  loadGame: (id) =>
    Session.set "gameLoading", true
    # access parameters in order a function args too
    handle = Meteor.subscribe "game", id, (err) =>
      #console.log "found..?"
      Session.set id, true
      game = Games.findOne id
      if game
        #console.log "Showing game."
        Session.set "gameId", id
        Session.set "showGame", true
        Session.set "createError", null
      else
        #console.log "Okay, no game."
        Session.set "gameId", null
        Session.set "showGame", false
        Session.set "createError", "Game not found"
      Session.set "gameLoading", false
  
  gameId: ->
    Session.get "gameId"
  
  getGame: =>
    lastUpdate = Session.get "lastUpdate"
    #Games.findOne Session.get "gameId"
    @addGameInfo @game
    @game
  
  gameReady: =>
    lastUpdate = Session.get "lastUpdate"
    if !@game or !@game.players
      return false
    return @game.players.length >= 2
  
  myGame: =>
    lastUpdate = Session.get "lastUpdate"
    @game.owner == Meteor.userId()
  
  myTurn: =>
    lastUpdate = Session.get "lastUpdate"
    @game.currentTurnId == Meteor.userId()
  
  getPlayers: =>
    @game = Games.findOne Session.get "gameId"
    if !@game?.players?
      return []
    id = 1
    players = _.map @game.players, (playerId) =>
      p = @playerById playerId
      p.id = id++
      p.avatar = "/images/character/#{@game.characters[playerId]}1.png"
      p.crystals = Crystals.findOne gameId: @game._id, owner: playerId
      p.stacks = []
      if p.crystals?.stacks?.length > 0
        p.stacks = _.map p.crystals.stacks, (stack) ->
          count: stack.length
      p
    players
  
  addPlayerInfo: (games) =>
    _.each games, (game) =>
      @addGameInfo game
    games
  
  addGameInfo: (game) =>
    game
  
  playerById: (_id) =>
    Meteor.users.findOne _id

redrawOverlay = ->
  if Template.game.showOverlay()
    viewportWidth = window.viewporter.viewportWidth
    viewportHeight = window.viewporter.viewportHeight
    $(".overlay").css
      width: viewportWidth
      height: viewportHeight
    $(".overlay-popup").css
      "max-width": Math.round viewportWidth*0.9
    popupWidth = $(".overlay-popup").outerWidth()
    popupHeight = $(".overlay-popup").outerHeight()
    $(".overlay-popup").css
      left: viewportWidth / 2 - popupWidth / 2
      top: viewportHeight / 2 - popupHeight / 2
window.addEventListener "viewportchanged", redrawOverlay

Template.game.userById = () ->
  userById this

Template.game.events
  "click .challenge-button": (event, template) =>
    id = String $(event.target).attr "id"
    if id.length > 0
      App.call "challenge", id
  "click .end-turn": () =>
    $("#tmp").html(Date.now())
    App.call "endTurn", (err, data) =>
      console.log err, data
