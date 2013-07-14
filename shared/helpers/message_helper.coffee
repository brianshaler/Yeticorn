class @MessageHelper
  @toAll: (gameId, message) ->
    game = Games.findOne gameId
    if game
      for player in game.players
        MessageHelper.sendMessage gameId, player, message
  
  @sendMessage: (gameId, recipient, message) ->
    Messages.insert
      gameId: gameId
      recipient: recipient
      message: message
      read: false
