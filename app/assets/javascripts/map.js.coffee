class Map
  @baseUrl: "http://10.0.0.2:5000"

  constructor: ->
    @drawMap()

    @$dataset = $("[name='dataset_id[]']")
    @$years = $("[name='years[]']")
    @$times = $("[name='times[]']")

    @$dataset.on("change", @getTimes)
    @$years.on("change", @getTimes)
    @$times.on("change", @getPoints)

    @setDataSets()

  setDataSets: =>
    $.getJSON "http://10.0.0.2:5000/datasets", (data) =>
      $.each data.datasets, (i, e) =>
        @$dataset.append($("<option/>").attr("value", e.slug).text(e.name))

  getTimes: =>
    slug = @$dataset.val()
    year = @$years.val()
    $.getJSON "http://10.0.0.2:5000/dataset/#{year}/#{slug}", (data) =>
      @$times.empty()
      $.each data.times, (i, e) =>
        @$times.append($("<option/>").attr("value", e.time).text(e.time_as_string))

  getPoints: =>
    dataset_id = @$dataset.val()
    year = @$years.val()
    time = @$times.val()

    latitude  = window.coordinates[0]
    longitude = window.coordinates[1]

    $.getJSON "http://10.0.0.2:5000/dataset/#{year}/#{dataset_id}?lat=#{latitude}&lng=#{longitude}&time=#{time}&delta_lat=7&delta_lng=10", (data) =>
      @drawGeoJSON(data)
      @fillLegend(data)

  drawMap: (data) ->
    @map = L.map('map').setView(window.coordinates, 4)

    L.tileLayer('http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
      attribution: '&copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Tiles courtesy of <a href="http://hot.openstreetmap.org/" target="_blank">Humanitarian OpenStreetMap Team</a>',
      maxZoom: 20
    ).addTo(@map)

    @marker = L.marker(window.coordinates).addTo(@map)
    @layerGroup = L.layerGroup([]).addTo(@map)

  polyForCoords: (e) ->
    latitude = parseFloat(e.lat)
    longitude = parseFloat(e.lng)

    padding = 1.25

    [
      [latitude + padding, longitude + padding]
      [latitude + padding, longitude - padding]
      [latitude - padding, longitude - padding]
      [latitude - padding, longitude + padding]
    ]

  drawGeoJSON: (data) =>
    @layerGroup.clearLayers()

    min = data.headers.actual_range[0]
    max = data.headers.actual_range[1]

    scale = (value) ->
      range = max - min
      parseFloat(value - min) #/ range

    onEachFeature = (feature, layer) ->
      if feature.properties && feature.properties.popupContent
        layer.bindPopup feature.properties.popupContent

    getColorAtScalar = (n) ->
      n = (n - min) * 240 / (max - min)
      "hsl(#{n}, 100%, 50%)"

    $.each data.results, (i, e) =>

      options =
        stroke: false
        fillColor: getColorAtScalar(e.val)
        opacity: 1

      L.polygon(@polyForCoords(e), options).addTo(@layerGroup)
      L.circle([e.lat, e.lng], 200000, options).addTo(@layerGroup)

  fillLegend: (data) =>
    min = data.headers.actual_range[0]
    max = data.headers.actual_range[1]
    range = max - min

    scale = (value) ->
      parseFloat(value - min) #/ range

    getColorAtScalar = (n) ->
      n = (n - min) * 240 / (max - min)
      "hsl(#{n}, 100%, 50%)"

    color = getColorAtScalar(min)
    $(".colorswatch.min").css("background-color": color)
    color = getColorAtScalar(max)
    $(".colorswatch.max").css("background-color": color)

    $(".min.value").text(min + " #{data.headers.units}")
    $(".max.value").text(max + " #{data.headers.units}")

    for i in [1...100] by 10
      color = getColorAtScalar(range / 100 * i)
      $(".colorswatch.ste-#{i}").css("background-color": color)

window.Map = Map
