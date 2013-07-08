class @Cards
  @weapons = []
  @spells = []
  @crystal = null
  
  @getWeapon: ->
    weapon = @weapons[Math.floor Math.random()*@weapons.length]
    weapon.toObject()
  
  @getSpell: ->
    spell = @spells[Math.floor Math.random()*@spells.length]
    spell.toObject()
  
  @getCrystal: ->
    @crystal.toObject()


class @Card
  props: ["type", "name", "filename", "description", "damage", "playCost", "useCost"]
  
  constructor: (obj) ->
    @type = ""
    @name = ""
    @filename = ""
    @description = ""
    @damage = 0
    @playCost = 0
    @useCost = 0
    
    for k, v of obj
      @[k] = v
  
  toObject: =>
    obj = {}
    for prop in @props
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

class @Spell extends @Card
  constructor: (obj) ->
    super obj
    @type = "spell"


Cards.crystal = new Crystal()

Cards.weapons.push new Weapon
  name: "Spork"
  filename: "weapons/spork"
  damage: 1
  description: ""
  playCost: 1
  useCost: 1
Cards.weapons.push new Weapon
  name: "Shuriken"
  filename: "weapons/shuriken"
  damage: 2
  description: ""
  playCost: 2
  useCost: 2
Cards.weapons.push new Weapon
  name: "Pot"
  filename: "weapons/pot"
  damage: 3
  description: ""
  playCost: 3
  useCost: 2
Cards.weapons.push new Weapon
  name: "Ray Gun"
  filename: "weapons/raygun"
  damage: 4
  description: ""
  playCost: 3
  useCost: 3
Cards.weapons.push new Weapon
  name: "Scissors"
  filename: "weapons/scissors"
  damage: 5
  description: ""
  playCost: 5
  useCost: 5
Cards.weapons.push new Weapon
  name: "Axe"
  filename: "weapons/axe"
  damage: 6
  description: ""
  playCost: 6
  useCost: 6
Cards.weapons.push new Weapon
  name: "the jesus"
  filename: "weapons/thejesus"
  damage: 8
  description: ""
  playCost: 10
  useCost: 10

Cards.spells.push new Spell
  name: "spell 1"
  filename: "weapons/thejesus"
  damage: 0
  description: ""
  playCost: 2
  useCost: 0
Cards.spells.push new Spell
  name: "spell 2"
  filename: "weapons/thejesus"
  damage: 0
  description: ""
  playCost: 2
  useCost: 0
