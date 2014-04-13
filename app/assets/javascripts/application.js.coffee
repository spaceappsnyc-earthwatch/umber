#= require jquery
#= require jquery_ujs
#= require_tree .
# require d3
# require topojson.v1.min
#= require leaflet

$ ->
  $(document).ajaxStart -> $("#circleG").show()
  $(document).ajaxStop -> $("#circleG").hide()
