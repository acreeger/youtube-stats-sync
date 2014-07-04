VideoRow = require("./you_tube_video_row")

class Worksheet
  _you_tube_videos = []
  _transport = null

  constructor: (rows, transport) ->
    _transport = transport
    init_you_tube_videos(rows)

  you_tube_videos: ->
    return _you_tube_videos.slice(0)

  init_you_tube_videos = (rows) ->
    for i,row of rows
      _you_tube_videos.push new VideoRow(row, i, _transport) if VideoRow.isYouTubeVideoRow(row)

  update: (cb) ->
    _transport.send cb

module.exports = Worksheet
