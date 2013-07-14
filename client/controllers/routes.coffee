# Wrapped in a method so it can be invoked on initial load after "app" is created
@initRoutes = ->
  # I think this filter prevents the page from initially showing you 
  # logged out while it figures out that you're logged in...
  Meteor.Router.filters
    "checkLoggedIn": (page) ->
      if Meteor.loggingIn()
        return "loading"
      else
        return page
  Meteor.Router.filter "checkLoggedIn"
  
  Meteor.Router.add
    "/game/:id": (id) ->
      app.game.loadGame id
      "page"
    "/": ->
      Session.set "gameId", null
      Session.set "showGame", false
      Session.set "createError", null
      "page"
    "*": "not_found"
