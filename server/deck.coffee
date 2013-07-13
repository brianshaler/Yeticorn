@Decks = new Meteor.Collection "decks"

Decks.allow
  insert: -> false
  update: -> false
  remove: -> false

class @Deck
  constructor: (totalCards = 100) ->
    @cards = []
    
    weaponCards = Math.floor totalCards * .2
    spellCards = spellCards = Math.floor totalCards * .3
    crystalCards = Math.floor totalCards - weaponCards - spellCards

    for i in [1..weaponCards]
      @cards.push Cards.getWeapon()
    for i in [1..spellCards]
      @cards.push Cards.getSpell()
    for i in [1..crystalCards]
      @cards.push Cards.getCrystal()
    @cards = @shuffleDeck @cards
  
  shuffleDeck: (deck) ->
    i = deck.length
    while --i > 0
      j = ~~(Math.random() * (i + 1)) # ~~ is a common optimization for Math.floor
      t = deck[j]
      deck[j] = deck[i]
      deck[i] = t
    deck
