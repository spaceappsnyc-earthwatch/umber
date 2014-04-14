class window.Map
  baseUrl: "http://10.0.0.2"
  port: "5001"

  constructor: ->
    @setupMap()

    @$dataset = $("[name='dataset_id[]']")
    @$years = $("[name='years[]']")
    @$times = $("[name='times[]']")

    @$dataset.on("change", @getTimes)
    @$years.on("change", @getTimes)
    @$times.on("change", @getPoints)

    @setDataSets()
    @setupSearch()

  setDataSets: =>
    $.getJSON "#{@baseUrl}:#{@port}/datasets", (data) =>
      $.each data.datasets, (i, e) =>
        @$dataset.append($("<option/>").attr("value", e.slug).text(e.name))
        $("#options").addClass("animated fadeInLeftBig").removeClass("hide")

  setupSearch: =>
    search = new MapSearch(@map)

    search.on 'search_locationfound', (location, title) =>
      @marker.setLatLng(location.latlng)
      window.coordinates = [location.latlng.lat, location.latlng.lng]

    @map.addControl(search)

  getTimes: =>
    @$times.empty()
    $("#times").addClass("fadeOutLeftBig").removeClass("fadeInLeftBig")

    slug = @$dataset.val()
    year = @$years.val()

    $.getJSON "#{@baseUrl}:#{@port}/dataset/#{year}/#{slug}", (data) =>
      $.each data.times, (i, e) =>
        @$times.append($("<option/>").attr("value", e.time).text(e.time_as_string))

      $("#times").addClass("animated fadeInLeftBig").removeClass("hide fadeOutLeftBig")

  getPoints: =>
    dataset_id = @$dataset.val()
    year = @$years.val()
    time = @$times.val()

    latitude  = window.coordinates[0]
    longitude = window.coordinates[1]

    delta_lat = 8
    delta_lng = 16

    $.getJSON "#{@baseUrl}:#{@port}/dataset/#{year}/#{dataset_id}?lat=#{latitude}&lng=#{longitude}&time=#{time}&delta_lat=#{delta_lat}&delta_lng=#{delta_lng}", (data) =>
      @drawGeoJSON(data)
      @fillLegend(data)

  setupMap: ->
    @map = L.map('map', zoomControl: false).setView(window.coordinates, 7)
    new L.Control.Zoom({ position: 'topright' }).addTo(@map)

    L.tileLayer('http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
      attribution: '&copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Tiles courtesy of <a href="http://hot.openstreetmap.org/" target="_blank">Humanitarian OpenStreetMap Team</a>',
      maxZoom: 20
    ).addTo(@map)

    @marker = L.marker(window.coordinates).addTo(@map)
    @dataPoints = L.layerGroup([]).addTo(@map)

  squareCenteredAtCoords: (latitude, longitude, padding) ->
    latitude = parseFloat(latitude)
    longitude = parseFloat(longitude)

    [
      [latitude + padding, longitude + padding]
      [latitude + padding, longitude - padding]
      [latitude - padding, longitude - padding]
      [latitude - padding, longitude + padding]
    ]

  drawGeoJSON: (data) =>
    @dataPoints.clearLayers()

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

      L.polygon(@squareCenteredAtCoords(e.lat, e.lng, 1.25), options).addTo(@dataPoints)
      L.circle([e.lat, e.lng], 150000, options).addTo(@dataPoints)

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
