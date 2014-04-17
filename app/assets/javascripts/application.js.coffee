#= require jquery
#= require jquery_ujs
#= require_tree .
#= require leaflet
#= require leaflet-search

$ ->
  $(document).ajaxStart -> $("#circleG").show()
  $(document).ajaxStop -> $("#circleG").hide()
