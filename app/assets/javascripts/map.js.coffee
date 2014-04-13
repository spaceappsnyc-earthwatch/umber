class Map
  @baseUrl: "http://10.0.0.2:5000"

  constructor: ->
    @drawMap()

    @$dataset = $("[name='dataset_id[]']")
    @$years = $("[name='years[]']")
    @$times = $("[name='times[]']")

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
        @$times.append($("<option/>").attr("value", e).text(e))

  getPoints: =>
    dataset_id = @$dataset.val()
    year = @$years.val()
    time = @$times.val()

    latitude  = window.coordinates[0]
    longitude = window.coordinates[1]

    $.getJSON "http://10.0.0.2:5000/dataset/#{dataset_id}/points?latitude=#{latitude}&longitude=#{longitude}&time=#{time}", (data) =>
      @drawGeoJSON(data)

  drawMap: (data) ->
    #@map = L.map('map').setView([window.coordinates[0], window.coordinates[1]], 13)
    @map = L.map('map').setView(window.coordinates, 6)
    L.tileLayer('http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Tiles courtesy of <a href="http://hot.openstreetmap.org/" target="_blank">Humanitarian OpenStreetMap Team</a>',
      maxZoom: 20
      }
    ).addTo(@map)

    @marker = L.marker(window.coordinates).addTo(@map)

  polyForCoords: (e) ->
    [
      [e.latitude + 1, e.longitude + 1]
      [e.latitude + 1, e.longitude - 1]
      [e.latitude - 1, e.longitude - 1]
      [e.latitude - 1, e.longitude + 1]
    ]

  drawGeoJSON: (data) =>
    # geoJSONFeature = {
    #   type: "Feature"
    #   geometry: {
    #     type: "Point"
    #     coordinates: [data[0].longitude, data[0].latitude]
    #   }
    # }
    # L.geoJson(geoJSONFeature).addTo(@map)

    scale = (value) ->
      range = data.max_value - data.min_value
      value - data.min_value

    onEachFeature = (feature, layer) ->
      if feature.properties && feature.properties.popupContent
        layer.bindPopup feature.properties.popupContent

    getColorAtScalar = (n) ->
      n = n * 240 / (data.max_value)
      "hsl(#{n}, 100%, 50%)"

    $.each data.points, (i, e) =>
      L.polygon(@polyForCoords(e)).addTo(@map)

      # geoJSONFeature = {
      #   type: "Feature",
      #   properties: {
      #     name: "scale: #{scale(e.value)}, value: #{e.value}",
      #     popupContent: "scale: #{scale(e.value)}<br>value: #{e.value}<br>color: #{getColorAtScalar(scale(e.value))}"
      #   },
      #   geometry: {
      #     type: "Point"
      #     coordinates: [e.longitude, e.latitude]
      #   }
      # }

      # geoJSONMarkerOptions = {
      #   radius: 10
      #   fillColor: getColorAtScalar(scale(e.value))
      #   color: "black"
      #   weight: 1
      #   opacity: 1
      #   fillOpacity: 0.8
      # }

      # pointToLayer = (feature, latLng) ->
      #   L.circleMarker(latLng, geoJSONMarkerOptions)

      # L.geoJson(geoJSONFeature, {
      #   pointToLayer: pointToLayer
      #   onEachFeature: onEachFeature
      # }).addTo(@map)

window.Map = Map
