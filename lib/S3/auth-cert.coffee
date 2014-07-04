AWS = require "aws-sdk"
tmp = require "tmp"
fs  = require "fs"

class S3AuthCert

  bucket: null
  key: null
  local_path: null

  s3 = null

  constructor: (bucket, key, region) ->
    throw new Error "bucket is required" unless bucket?
    throw new Error "key is required" unless key?
    @key = key
    @bucket = bucket

    AWS.config.update({region: region || 'us-east-1'});
    s3 = new AWS.S3()

  download: (cb) ->
    s3.getObject {Key: @key, Bucket: @bucket }, (err, data) ->
      return cb(err) if err?
      tmp.file (err, path, fd) ->
        cb(err) if err?
        fs.writeSync fd, data.Body, 0, data.Body.length, 0
        @local_path = path
        cb(null, path)

  #TODO: clean

module.exports = S3AuthCert