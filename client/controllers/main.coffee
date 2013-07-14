Meteor.subscribe "players"
Meteor.subscribe "recentGames"
Meteor.subscribe "myGames"

window.addEventListener "viewportchanged", (v) ->
  pg = $(".game-page")
  if pg?.length == 1
    pg.css
      height: v.height - pg.offset().top

app = null
root = @

@initRoutes()

class @App
  constructor: ->
    @game = new GameController()
    
    Meteor.startup =>
      root.viewport = new Viewporter "outer-container", fullHeightPortrait: false
      Deps.autorun =>
        lastUpdate = Session.set "lastUpdate", Date.now()
  
  # adds gameId as first parameter after method in Meteor.call()
  @call: () =>
    args = _.toArray arguments
    method = args.shift()
    args.unshift Session.get "gameId"
    args.unshift method
    Meteor.call.apply Meteor.call, args
  
  @error: (str) =>
    App.alert "Error", str
  
  @alert: (title = "", str = "") =>
    if str == ""
      str = title
      title = false
    #alert "Hey! #{str}"
    Session.set "alert", str
    Session.set "alertTitle", title
  
  @getEnergy: (energyRequired, cb) =>
    app.game.energyCallback = cb
    Session.set "energyRequired", energyRequired
  
  @gotEnergy: (retry, cancel) =>
    if app.game.energyCallback
      app.game.energyCallback retry, cancel
    app.game.energyCallback = false
    Session.set "energyRequired", false
  
  @selectOpponents: (opponents, cb) =>
    app.game.energyCallback = cb
    Session.set "selectOpponents", opponents
  
  @selectFromHand: (type, quantity, cb) =>
    app.game.energyCallback = cb
    Session.set "selectionType", type
    Session.set "selectCardsFromHand", quantity
  
  addPlayerInfo: (games) =>
    @game.addPlayerInfo games

app = @app = new @App()

Template.page.anyGames = =>
  Template.page.myGames().length > 0 or Template.page.gameList().length > 0

Template.page.myGames = =>
  games = Games.find(players: Meteor.userId()).fetch()
  app.addPlayerInfo games

Template.page.gameList = =>
  games = Games.find(
    {$and: [
      $where: "this.started == false"
      players:
        $ne: Meteor.userId()]}
    {sort: createdDate: -1}
  ).fetch()
  app.addPlayerInfo games

Template.page.showGame = ->
  Session.get "showGame"

Template.page.gameLoading = ->
  Session.get "gameLoading"

Template.page.error = ->
  Session.get "createError"
    
Template.page.ownerName = () ->
  ownerName this

Template.page.userById = () ->
  userById this

Template.page.displayName = () ->
  displayName this

Template.page.events
  "click .logout": () =>
    Meteor.logout()
  "click .join-button": (event, template) =>
    gameId = String $(event.target).attr "id"
    if gameId.length > 0
      App.call "addPlayer"
      Meteor.Router.to "/game/#{gameId}"
  "click .create-public-game": =>
    Meteor.call "createGame", 
      public: true
    , (error, gameId) =>
      if !error and gameId
        Meteor.Router.to "/game/#{gameId}"
  "click .create-private-game": =>
    Meteor.call "createGame", 
      public: false
    , (error, gameId) =>
      if !error and gameId
        Meteor.Router.to "/game/#{gameId}"
  "submit .signup-form": (event, template) =>
    event.preventDefault()
    obj = {}
    try
      obj.username = template.find(".username").value
      if !(obj.username.length >= 4) or !obj.username.match(/^[a-z0-9_]+ ?[a-z0-9_]+$/gi)
        throw new Error "User name not valid"
      obj.password = template.find(".password").value
      obj.profile = {name: obj.username}
      huser = CryptoJS.MD5(obj.username).toString()
      hpw = CryptoJS.MD5(obj.password).toString()
      obj.email = "#{huser}@#{hpw}.com"
    catch err
      Session.set "createError", err.message
      return false
    Session.set "createError", null
    try
      Accounts.createUser obj, (err1) ->
        if err1
          console.log err1
        Meteor.loginWithPassword obj.email, obj.password, (err2) ->
          if err2
            if err1
              Session.set "createError", err1.reason
            else
              Session.set "createError", err2.reason
            return console.log err2
          Session.set "createError", null
    catch err
      Session.set "createError", err.message.replace("options.", "")
    false

