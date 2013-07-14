class @CrystalsHelper
  constructor: (obj) ->
    # 0 and 1-5
    @stacks = [[], [], [], [], [], []]
    for k, v of obj
      @[k] = v
  
  @incrementAll: (stacks) ->
    for stack in [stacks.length-2..0]
      for crystal in stacks[stack]
        stacks[stack+1].push crystal
      stacks[stack] = []
    stacks
  
  @totalCrystalCards: (stacks) ->
    _.reduce stacks, (memo, stack) ->
      memo + stack.length
    , 0
  
  toObject: ->
    obj = []
    for prop in @props
      obj[prop] = @[prop]
    obj
  