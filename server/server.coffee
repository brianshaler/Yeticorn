
Meteor.publish "games", () ->
  q = [{public: true}]
  if this.userId
    check this.userId, String
    q.push players: this.userId
    q.push owner: this.userId
  Games.find
    $or: q

Meteor.publish "game", (gameId) ->
  check gameId, String
  q = [{public: true}]
  if this.userId
    check this.userId, String
    q.push players: this.userId
    q.push owner: this.userId
  Games.find
    _id: gameId
    $or: q

Meteor.publish "players", () ->
  Meteor.users.find
    _id:
      $ne: this.userId

Meteor.publish "board", (gameId) ->
  check gameId, String
  Boards.find
    gameId: gameId

Meteor.publish "hand", (gameId) ->
  check gameId, String
  check this.userId, String
  Hands.find
    gameId: gameId
    owner: this.userId

Meteor.publish "crystals", (gameId) ->
  check gameId, String
  Crystals.find
    gameId: gameId
