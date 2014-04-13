class Map
  constructor: ->
    @loadData()

  loadData: ->
    $.getJSON "/data.json", (data) ->
      console.log(data)

window.Map = Map
