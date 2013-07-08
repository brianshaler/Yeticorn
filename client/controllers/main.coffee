Meteor.subscribe "players"
Meteor.subscribe "games"

window.addEventListener "viewportchanged", (v) ->
  $(".game-page").css
    height: v.height

app = null
root = @

Meteor.Router.add
  "/game/:id": (id) ->
    if !Session.get id
      Session.set "visible", false
    app.game.loadGame id
    "page"
  "/": ->
    Session.set "visible", true
    Session.set "gameId", null
    Session.set "showGame", false
    Session.set "createError", null
    "page"
  "*": "not_found"

class @App
  constructor: ->
    Session.set "visible", false
    
    @game = new GameController()
    
    Meteor.startup =>
      root.viewport = new Viewporter "outer-container"
      #Session.set "visible", true
      Deps.autorun =>
        lastUpdate = Session.set "lastUpdate", Date.now()
    
    Template.root.visible = =>
      Session.get "visible"
    
    Template.page.gameList = =>
      games = Games.find($and: [
        $where: "this.players.length == 1"
        players:
          $ne: Meteor.userId()
      ]).fetch()
      @addPlayerInfo games
    
    Template.page.showGame = ->
      Session.get "showGame"
    
    Template.page.error = ->
      Session.get "createError"
  
  addPlayerInfo: (games) =>
    @game.addPlayerInfo games
    
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
      Meteor.call "addPlayer", gameId
      Meteor.Router.to "/game/#{gameId}"
  "click .create-game": =>
    Meteor.call "createGame", 
      public: true
    , (error, gameId) =>
      if !error and gameId
        Meteor.Router.to "/game/#{gameId}"
  "submit .signup-form": (event, template) =>
    event.preventDefault()
    obj = {}
    try
      obj.username = template.find(".username").value
      if !(obj.username.length >= 4) or !obj.username.match(/^[a-z0-9_]+$/gi)
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

app = @app = new @App()
