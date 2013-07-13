###
spell properties:

# Can be played when you're being attacked
defensive: true

# target one opponent
selectOpponent: 1

# where to send the card(s) you selected
myCardTo: "weapon"

# randomly select 1 or more cards from an opponent
opponentRandomCard: 1

# take weapon from in play
takeWeapon: true

# these get removed by the server
selectWeaponFromMyHand: 1
selectCardFromMyHand: 1

??? drawCards: 1

# isPersistent()
multiplyDamage: 2.0

###
class @SpellHelper
  constructor: () ->
  
  @conditionsMet: (spell, options) ->
    met = true
    
    if spell.selectOpponent > 0 and (!options.opponents? or options.opponents.length != spell.selectOpponent)
      met = false
    if spell.selectWeaponFromMyHand > 0
      if !options.myCards? or options.myCards.length != spell.selectWeaponFromMyHand
        met = false
      else
        weaponCount = 0
        _.each options.myCards, (card) ->
          if card.type == "weapon"
            weaponCount++
        if weaponCount != spell.selectWeaponFromMyHand
          met = false
    if spell.selectCardFromMyHand > 0
      if !options.myCards? or options.myCards.length != spell.selectWeaponFromMyHand
        met = false
    met
  
  @applySpellToAttack: (spell, damage) ->
    if typeof spell.multiplyDamage == "number"
      damage *= spell.multiplyDamage
    damage
  
  @isPersistent: (spell) ->
    spell.multiplyDamage?
  
  @requiresOpponentSelection: (spell) ->
    if typeof spell.selectOpponent == "number"
      spell.selectOpponent
    else
      0
  
  @requiresHandSelection: (spell) ->
    type = ""
    quantity = 0
    if spell.selectWeaponFromMyHand? > 0
      type = "weapon"
      quantity = spell.selectWeaponFromMyHand
    else if spell.selectCardFromMyHand? > 0
      type = "card"
      quantity = spell.selectCardFromMyHand
    {selectionType, selectionQuantity} = {type, quantity}
    