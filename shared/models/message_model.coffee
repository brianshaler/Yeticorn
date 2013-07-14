@Messages = new Meteor.Collection "messages"

Messages.allow
  insert: -> false
  update: -> false
  remove: -> false
