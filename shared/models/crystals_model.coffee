@Crystals = new Meteor.Collection "crystals"

Crystals.allow
  insert: -> false
  update: -> false
  remove: -> false
