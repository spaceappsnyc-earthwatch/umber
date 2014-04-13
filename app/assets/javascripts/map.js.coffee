class Map
  baseUrl: "http://10.0.0.2"
  port: "5001"

  constructor: ->
    @drawMap()

    @$dataset = $("[name='dataset_id[]']")
    @$years = $("[name='years[]']")
    @$times = $("[name='times[]']")

    @$dataset.on("change", @getTimes)
    @$years.on("change", @getTimes)
    @$times.on("change", @getPoints)

    @setDataSets()

    geocoder = new google.maps.Geocoder()

    googleGeocoding = (text, callResponse) ->
      geocoder.geocode({address: text}, callResponse)

    filterJSONCall = (rawjson) ->
      json = {}
      disp = []

      $.each rawjson, (i, raw) ->
        key = raw.formatted_address
        loc = L.latLng(raw.geometry.location.lat(), raw.geometry.location.lng())
        json[ key ]= loc

      return json

    @map.addControl(new L.Control.Search({
        callData: googleGeocoding,
        filterJSON: filterJSONCall,
        markerLocation: true,
        autoType: false,
        autoCollapse: true,
        minLength: 2,
        zoom: 10
      }))

  setDataSets: =>
    $.getJSON "#{@baseUrl}:#{@port}/datasets", (data) =>
      $.each data.datasets, (i, e) =>
        @$dataset.append($("<option/>").attr("value", e.slug).text(e.name))
        $("#options").addClass("animated fadeInLeftBig").removeClass("hide")

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

    delta_lat = 10
    delta_lng = 30

    $.getJSON "#{@baseUrl}:#{@port}/dataset/#{year}/#{dataset_id}?lat=#{latitude}&lng=#{longitude}&time=#{time}&delta_lat=#{delta_lat}&delta_lng=#{delta_lng}", (data) =>
      @drawGeoJSON(data)
      @fillLegend(data)

  drawMap: (data) ->
    @map = L.map('map', zoomControl: false).setView(window.coordinates, 5)
    new L.Control.Zoom({ position: 'topright' }).addTo(@map)

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
      L.circle([e.lat, e.lng], 150000, options).addTo(@layerGroup)

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

window.Map = Map
