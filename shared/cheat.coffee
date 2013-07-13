class @Cheat
  @playCrystal: (stack) ->
    stack = String stack
    App.call "cheat", "playCrystal", stack
  
  @getSpell: (name = "") ->
    App.call "cheat", "getSpell", name
  
  @getWeapon: (name = "") ->
    App.call "cheat", "getWeapon", name