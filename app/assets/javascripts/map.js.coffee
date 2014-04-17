class Map
  baseUrl: "http://localhost"
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

    googleGeocoding = (text, callResponse) -> geocoder.geocode({address: text}, callResponse)

    filterJSONCall = (rawjson) =>
      json = {}

      $.each rawjson, (i, raw) ->
        key = raw.formatted_address
        loc = L.latLng(raw.geometry.location.lat(), raw.geometry.location.lng())
        json[key] = loc

      json

    @search = new L.Control.Search
      callData: googleGeocoding
      filterJSON: filterJSONCall
      markerLocation: false
      circleLocation: false
      autoType: false
      autoCollapse: true
      minLength: 2
      zoom: 5

    @map.addControl(@search)

    @search.on 'search_locationfound', (location, title) =>
      @marker.setLatLng(location.latlng)
      window.coordinates = [location.latlng.lat, location.latlng.lng]

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

    delta_lat = 8
    delta_lng = 16

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
    units = data.headers.units

    colorScale = @scale(1, 12, min, max)

    $.each [1..12], (e, i) ->
      $(".colorswatch.step-#{i}").attr("title", "#{colorScale(i).toFixed(2)} #{units}")

    $(".colorswatch").tooltip()

    $.each data.results, (i, e) =>
      options =
        stroke: false
        fillColor: @getColorAtScalar(e.val, min, max)
        fillOpacity: .3

      L.polygon(@polyForCoords(e), options).addTo(@layerGroup)
      circle = L.circle([e.lat, e.lng], 150000, options)
      circle.bindPopup("#{parseFloat(e.val).toFixed(2)} #{units}")
      circle.addTo(@layerGroup)

  fillLegend: (data) =>
    min = data.headers.actual_range[0]
    max = data.headers.actual_range[1]
    range = max - min

    $(".min.value").text(parseFloat(min).toFixed(2) + " #{data.headers.units}")
    $(".max.value").text(parseFloat(max).toFixed(2) + " #{data.headers.units}")

  getColorAtScalar: (n, min, max) ->
    scale = @scale(min, max, 240, 0)
    "hsl(#{parseInt(scale(n))}, 100%, 50%)"

  scale: (inMin, inMax, outMin, outMax) ->
    inMax = parseFloat(inMax)
    inMin = parseFloat(inMin)
    outMin = parseFloat(outMin)
    outMax = parseFloat(outMax)

    inRange = inMax - inMin
    outRange = outMax - outMin

    inMultiplier = 1 / inRange
    outMultiplier = 1 / outRange

    (x) -> (x - inMin) * inMultiplier / outMultiplier + outMin

window.Map = Map
