class @GameController
  constructor: ->
    @game = null
    @hand = new HandController()
    @crystals = new CrystalsController()
    @board = new BoardController()
    
    $(document).ready () ->
      $("body").addClass("view-hand")
    
    window.game = @
    window.addEventListener "viewportchanged", (v) =>
      @board.render()
    
    Meteor.autosubscribe =>
      Meteor.subscribe "game", @gameId() if @gameId()
      Meteor.subscribe "crystals", @gameId() if @gameId()
    
    Deps.autorun =>
      lastUpdate = Session.set "lastUpdate", Date.now()
      @game = Games.findOne Session.get "gameId"
      @board.render()
    
    Template.game.playerList = ->
      Meteor.users.find _id: {$nin: [Meteor.userId()]}
    
    Template.game.myTurn = @myTurn
    Template.game.gameReady = @gameReady
    Template.game.gameId = @gameId
    Template.game.game = @getGame
    Template.game.myGame = @myGame
    Template.game.currentView = ->
      Session.get "currentView"
    Template.game.displayName = () ->
      displayName this
    
    Template.game.events
      "click .challenge-button": (event, template) =>
        id = String $(event.target).attr "id"
        if id.length > 0
          Meteor.call "challenge", @gameId(), id
        #Meteor.call('invite', Session.get("selected"), this._id);
      "click .ttt-enabled .move-btn": (event, template) =>
        id = String $(event.target).attr "id"
        Meteor.call "takeTurn", @gameId()
      "click .end-turn": () =>
        $("#tmp").html(Date.now())
        Meteor.call "endTurn", Session.get("gameId"), (err, data) =>
          console.log err, data
    
    Template.players.players = @getPlayers
    Template.players.displayName = () ->
      displayName this
    
    Template.players.events
      "click .start-game": =>
        console.log "start game!"
        Meteor.call "startGame", Session.get "gameId"
    
    Template.status_bar.players = =>
      players = @getPlayers()
      cnt = 0
      _.each players, (player) =>
        player.id = cnt++
        player.myTurn = player._id == @game.currentTurnId
      players
    
    Template.status_bar.isMyTurn = =>
      @game.currentTurnId == Meteor.userId()
    
    Template.status_bar.currentTurnEnergy = =>
      lastUpdate = Session.get "lastUpdate"
      @game.currentTurnEnergy
    
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
    
    Template.map.date = ->
      Date.now()
  
  loadGame: (id) =>
    # access parameters in order a function args too
    Meteor.subscribe "game", id, (err) =>
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
        x = "do something else"
        Session.set "gameId", null
        Session.set "showGame", false
        Session.set "createError", "Game not found"
      Session.set "visible", true
    cnt = Games.find(_id: id).count()
  
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
    return @game.players.length == 2
  
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
    players = _.map @game.players, (playerId) =>
      p = @playerById playerId
      p.avatar = "/images/character/#{@game.characters[playerId]}1.png"
      p.crystals = Crystals.findOne gameId: @game._id, owner: playerId
      p.stacks = []
      if p.crystals?.stacks?.length > 0
        console.log p.crystals
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


Template.game.userById = () ->
  userById this
