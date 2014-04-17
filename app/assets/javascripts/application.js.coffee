#= require jquery
#= require jquery_ujs
#= require_tree .
#= require leaflet
#= require leaflet-search
#= require bootstrap
#= require bootstrap/tooltip

$ ->
  $(document).ajaxStart -> $("#circleG").show()
  $(document).ajaxStop -> $("#circleG").hide()
