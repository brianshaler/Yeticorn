@Boards = new Meteor.Collection "boards"

Boards.allow
  insert: -> false
  update: -> false
  remove: -> false
