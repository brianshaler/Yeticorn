class @CharacterHelper
  @allCharacters = ["black", "blue", "orange", "yellow"]
  
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
