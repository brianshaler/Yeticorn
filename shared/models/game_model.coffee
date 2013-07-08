@Games = new Meteor.Collection "games"

Games.allow
  insert: () -> false
  update: (userId, game, fields, modifier) ->
    if userId != game.owner
      return false # not the owner
    
    console.log userId, game, fields, modifier
    allowed = ["title", "public"]
    if _.difference(fields, allowed).length
      return false # tried to write to forbidden field
    
    return true
  remove: (userId, game) ->
    # You can only remove games that you created
    game.owner == userId
