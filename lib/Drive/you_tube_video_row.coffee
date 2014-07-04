numeral = require "numeral"

class YouTubeVideoRow

  __URL_COLUMN = "2"
  __VIEWS_COLUMN = "8"
  __DURATION_COLUMN = "10"

  _regex = /\=HYPERLINK\("(https?:\/\/www\.youtube\.com\/watch\?v=(.*))","(.*)"\)/
  _raw = null
  _transport = null
  _rowNumber = null

  url: null
  video_id: null
  rowNumber: null

  views: null
  durationSeconds: null
  durationFormatted: ->
    return null unless @durationSeconds?
    return numeral(@durationSeconds).format("0:0")

  constructor: (spreadsheetRow, rowNumber, transport) ->
    throw new Error("Not a YouTubeVideoRow") unless YouTubeVideoRow.isYouTubeVideoRow spreadsheetRow
    throw new Error("transport is required") unless transport?
    _raw = spreadsheetRow
    _transport = transport
    @rowNumber = rowNumber
    urlData = spreadsheetRow[__URL_COLUMN]
    matches = _regex.exec(urlData)
    @url = matches[1]
    @video_id = matches[2]
    @title = matches[3]

    @views = spreadsheetRow[__VIEWS_COLUMN] if spreadsheetRow[__VIEWS_COLUMN]?
    @durationSeconds = numeral().unformat(spreadsheetRow[__DURATION_COLUMN]) if spreadsheetRow[__DURATION_COLUMN]?.indexOf(":") > -1

  save: (next) ->
    #TODO: introduce dirty flag
    updates = []
    if @views?
      update = {}
      update[@rowNumber] = {}
      update[@rowNumber][__VIEWS_COLUMN] = numeral(@views).format("0,0")
      updates.push update

    if @durationSeconds?
      update = {}
      update[@rowNumber] = {}
      update[@rowNumber][__DURATION_COLUMN] = @durationFormatted()
      updates.push update

    for update in updates
      _transport.add update

    # console.log("*************** updates: %j", updates)

    return unless next?
    _transport.send next
    # next()

  @isYouTubeVideoRow: (row) -> row["2"]? && _regex.test(row["2"])

module.exports = YouTubeVideoRow