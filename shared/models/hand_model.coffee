@Hands = new Meteor.Collection "hands"

Hands.allow
  insert: -> false
  update: -> false
  remove: -> false
