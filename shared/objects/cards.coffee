class @Cards
  @weapons = []
  @spells = []
  @crystal = null
  
  @getWeapon: (name = "") ->
    weapon = false
    name = name.toLowerCase()
    if name != ""
      weapon = _.find @weapons, (w) =>
        w.name.toLowerCase() == name or w.code.toLowerCase() == name
    if !weapon
      weapon = @weapons[Math.floor Math.random()*@weapons.length]
    
    weapon.toObject()
  
  @getSpell: (name = "") ->
    spell = false
    name = name.toLowerCase()
    if name != ""
      spell = _.find @spells, (s) =>
        s.name.toLowerCase() == name or s.code.toLowerCase() == name
    if !spell
      spell = @spells[Math.floor Math.random()*@spells.length]
    console.log spell if !spell.toObject
    spell.toObject()
  
  @getCrystal: ->
    @crystal.toObject()


class @Card
  constructor: (obj) ->
    @props = ["type", "code", "name", "filename", "description", "damage", "range", "playCost", "useCost"]
    @type = ""
    @name = ""
    @code = ""
    @filename = ""
    @description = ""
    @playCost = 0
    @useCost = 0
    
    @fromObject obj
  
  fromObject: (obj = {}) =>
    for k, v of obj
      if @props.indexOf(k) == -1
        @props.push k
      @[k] = v
  
  toObject: =>
    obj = {}
    @code = @name.toLowerCase().replace " ", "_"
    for prop in @props
      if @[prop]?
        obj[prop] = @[prop]
    obj
  
class @Crystal extends @Card
  constructor: (obj) ->
    super obj
    @type = "crystal"
    @filename = "crystal"

class @Weapon extends @Card
  constructor: (obj) ->
    super obj
    @type = "weapon"
    @playCost = 1
    @useCost = 1
    @range = 1
    @damage = 1
    
    @fromObject obj

class @Spell extends @Card
  constructor: (obj) ->
    super obj
    @type = "spell"
    @fromObject obj


Cards.crystal = new Crystal()


###
Cards.weapons.push new Weapon
  name: "Spork"
  filename: "weapons/spork"
  description: ""
  playCost: 1
  useCost: 1
  damage: 2
###

Cards.weapons.push new Weapon
  name: "Scissors"
  filename: "weapons/scissors"
  description: ""
  playCost: 1
  useCost: 2
  damage: 3
Cards.weapons.push new Weapon
  name: "Shuriken"
  filename: "weapons/shuriken"
  description: ""
  playCost: 2
  useCost: 2
  range: 3
  damage: 3
Cards.weapons.push new Weapon
  name: "Pot"
  filename: "weapons/pot"
  description: ""
  playCost: 3
  useCost: 2
  damage: 4
Cards.weapons.push new Weapon
  name: "Ray Gun"
  filename: "weapons/raygun"
  description: ""
  playCost: 5
  useCost: 2
  range: 3
  damage: 3
Cards.weapons.push new Weapon
  name: "Axe"
  filename: "weapons/axe"
  description: ""
  playCost: 6
  useCost: 6
  damage: 10

###
Cards.weapons.push new Weapon
  name: "the jesus"
  filename: "weapons/thejesus"
  damage: 8
  description: ""
  playCost: 10
  useCost: 10
  range: 4
###

Cards.spells.push new Spell
  name: "Draw Card"
  filename: "weapons/spork"
  description: "Draw a card"
  playCost: 2
  drawCards: 1
Cards.spells.push new Spell
  name: "Draw Cards"
  filename: "weapons/spork"
  description: "Draw 2 cards"
  playCost: 3
  drawCards: 2
Cards.spells.push new Spell
  name: "Charity"
  filename: "weapons/spork"
  description: "Select a Weapon card from your hand. Out of the kindness of your heart, give it to a selected opponent. If that opponent has a weapon in play, discard it."
  playCost: 2
  selectOpponent: 1
  selectWeaponFromMyHand: 1
  myCardTo: "weapon"
Cards.spells.push new Spell
  name: "Truce"
  filename: "weapons/spork"
  description: "No damage this turn"
  playCost: 2
  defensive: true
  multiplyDamage: 0.0
Cards.spells.push new Spell
  name: "Blind Thief"
  filename: "weapons/spork"
  description: "Steal a card at random from selected opponent's hand"
  playCost: 2
  selectOpponent: 1
  opponentRandomCard: 1
  opponentCardTo: "hand"
Cards.spells.push new Spell
  name: "Drop it"
  filename: "weapons/spork"
  description: "Drop it like it's hot! Selected opponent discards a card from their hand"
  playCost: 2
  selectOpponent: 1
  opponentRandomCard: 1
Cards.spells.push new Spell
  name: "Trade"
  filename: "weapons/spork"
  description: "Select a Weapon card from your hand. Out of the kindness of your heart, give it to a selected opponent. If that opponent has a weapon in play, put it in your hand."
  playCost: 3
  selectOpponent: 1
  selectWeaponFromMyHand: 1
  myCardTo: "weapon"
  takeWeapon: true
Cards.spells.push new Spell
  name: "Rampage"
  filename: "weapons/spork"
  description: "Double damage! (Play this card before your attack)"
  playCost: 4
  multiplyDamage: 2.0
