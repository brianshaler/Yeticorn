class @CharacterHelper
  # currently using full character renders, but we may want to build characters dynamically
  @allCharacters = ["black", "blue", "orange", "yellow"]
  @facialHair = ["none", "mustache", "beard", "neckbeard"]
  @eyeWear = ["none", "glasses"]
  
  @getRandomCharacter: (taken = []) ->
    character = @allCharacters[0]
    left = _.filter @allCharacters, (c) ->
      -1 == taken.indexOf c
    if left.length > 0
      character = left[Math.floor Math.random()*left.length]
    character
  
  @canChooseCharacter: (taken = [], selected) ->
    available = _.filter @allCharacters, (c) ->
      -1 == taken.indexOf c
    -1 != available.indexOf selected
