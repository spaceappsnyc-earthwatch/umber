class window.MapSearch
  constructor: (@map) -> @setup()

  setup: ->
    geocoder = new google.maps.Geocoder()

    googleGeocoding = (text, callResponse) ->
      geocoder.geocode({address: text}, callResponse)

    filterJSONCall = (rawjson) =>
      json = {}

      $.each rawjson, (i, raw) ->
        key = raw.formatted_address
        loc = L.latLng(raw.geometry.location.lat(), raw.geometry.location.lng())
        json[key] = loc

      json

    @control = new L.Control.Search
      callData: googleGeocoding
      filterJSON: filterJSONCall
      markerLocation: false
      circleLocation: false
      autoType: false
      autoCollapse: true
      minLength: 2
      zoom: 5

    @map.addControl(@control)

  on: (event, callback) -> @control.on event, callback
