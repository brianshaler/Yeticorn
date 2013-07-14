
Meteor.publish "games", () ->
  q = [{public: true}]
  if this.userId
    check this.userId, String
    q.push players: this.userId
    q.push owner: this.userId
  Games.find
    $or: q
    {
      sort:
        createdDate: -1
      limit: 10
    }

Meteor.publish "myGames", () ->
  where =
    $or:
      owner: @userId
      players: @userId
  params =
    sort:
      createdDate: -1
    limit: 10
  Games.find where, params

Meteor.publish "recentGames", () ->
  q = [{public: true}]
  if this.userId
    check this.userId, String
    q.push players: this.userId
    q.push owner: this.userId
  Games.find
    $or: q
    {
      sort:
        createdDate: -1
      limit: 10
    }

Meteor.publish "game", (gameId) ->
  check gameId, String
  q = [{public: true}]
  if this.userId
    check this.userId, String
    q.push players: this.userId
    q.push owner: this.userId
  Games.find
    _id: gameId
    #$or: q

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

Meteor.publish "unreadMessages", (gameId) ->
  check gameId, String
  q = 
    recipient: @userId
    gameId: gameId
    read: false
  params =
    sort:
      createdDate: -1
    limit: 10
  Messages.find q, params
  