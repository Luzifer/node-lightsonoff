#!./node_modules/.bin/coffee

settings = require './settings'
mactable = {}
switchedoff = false

Tail = require('tail').Tail
request = require 'request'

log = new Tail(settings.watchfile)
log.on 'line', (data) =>
  if data.indexOf('DHCPREQUEST') < 0
    return

  mac = data.match(/.*from ([0-9a-f:]{17})\s/)[1]
  time = getTime()
  mactable[mac] = time

interval = (time, fkt) ->
  setInterval fkt, time

delay = (time, fkt) ->
  setTimeout fkt, time

delay 60 * 1000, ->
  interval 5 * 1000, ->
    lightson = false
    time = getTime()
    for mac in settings.presence_watched
      if mactable[mac] != undefined and time - mactable[mac] < settings.timeout
        lightson = true
        switchedoff = false

    if lightson == false and switchedoff == false
      switchedoff = true
      for actuator, state of settings.ezcontrol.offstates
        switchActuator actuator, state

getTime = ->
  Math.round(new Date().getTime() / 1000)

switchActuator = (actuator, state) ->
  # http://xs1/control?callback=callback&cmd=set_state_actuator&number=1&function=2&nocache=1374337216561
  request
    url: "http://#{settings.ezcontrol.hostname}/control"
    qs:
      "cmd": "set_state_actuator"
      "number": actuator
      "function": state
      "nocache": getTime()
  , (error, response, body) ->
    if error or response.statusCode != 204
      console.log [error, response, body]

interval 5 * 1000, ->
  process.stdout.write '\u001B[2J\u001B[0;0f'
  for mac, time of mactable
    console.log [mac, time, getTime() - time]

interval 300 * 1000, ->
  settings = require './settings'
