YouTube = require("youtube-api")
request = require("request")
cheerio = require("cheerio")
duration_parser = require("./lib/util/iso-8601-duration-parser")
numeral = require("numeral")
YouTubeStatsWorksheet = require("./lib/Drive/worksheet")
async = require("async")
S3AuthCert = require("./lib/S3/auth-cert")
Spreadsheet = require("edit-google-spreadsheet")
getenv = require "getenv"

auth_cert_bucket = getenv("YOUTUBE_STATS_SYNC_S3_BUCKET")
auth_cert_key = getenv("YOUTUBE_STATS_SYNC_S3_KEY")
auth_cert = new S3AuthCert(auth_cert_bucket, auth_cert_key)

auth_cert.download (err, local_cert_path) ->
  if err?
    console.error "err while download auth cert from S3:", err
    process.exit(1)

  Spreadsheet.load
    debug: true
    spreadsheetId: getenv("YOUTUBE_STATS_SYNC_SPREADSHEET_KEY")
    worksheetName: getenv("YOUTUBE_STATS_SYNC_WORKSHEET_NAME"),

    oauth:
      email: getenv("YOUTUBE_STATS_SYNC_GOOGLE_SERVICE_ACCOUNT_EMAIL")
      keyFile: local_cert_path
  , (err, spreadsheet) ->
    throw err if err?
    spreadsheet.receive (err, rows, info) ->
      throw err  if err?

      # YouTube.videos.list({
      #     "part": "id,statistics,fileDetails",
      #     "id": "QJkiWwMKwSo"
      # }, function (err, data) {
      #     console.log(err, data);
      # });

      worksheet = new YouTubeStatsWorksheet(rows, spreadsheet)
      processRow = (r, done) ->
        url = r.url
        request url, (error, response, body) ->
          return done error if error?
          if response.statusCode is 200
            $ = cheerio.load(body)
            duration = $(".watch-content meta[itemprop=duration]").attr("content")
            seconds = duration_parser.parseToTotalSeconds(duration)
            formattedDuration = numeral(seconds).format("00:00")
            views = numeral().unformat($(".watch-view-count").text())
            r.durationSeconds = seconds  if seconds and r.durationSeconds isnt seconds
            r.views = views  if views and r.views isnt views
            r.save()
            done()
          else
            done new Error("Request to '" + r.url + "' responded with error code: " + response.statusCode)

      async.each worksheet.you_tube_videos(), processRow, ->
        worksheet.update (err) ->
          throw err  if err
          console.log "Updated!"