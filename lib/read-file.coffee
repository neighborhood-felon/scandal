fs = require("fs")
isBinaryFile = require("isbinaryfile")

lastIndexOf = (buffer, length, char) ->
  i = length
  while i--
    return i if buffer[i] == char
  -1

concat = (str1, str2) ->
  if str1? and str2?
    str1 + str2
  else if not str1? and not str2?
    ''
  else if str1?
    str1
  else
    str2

headerBuffer = new Buffer(256)
chunkedBuffer = null

# readWholeFile = (path, size, callback) ->
#   text = null
#   fd = fs.openSync(path, "r")
#   try
#     bytesRead = fs.readSync(fd, headerBuffer, 0, Math.min(size, 256))
#
#     if !isBinaryFile(headerBuffer, bytesRead)
#       remainingBytes = size - bytesRead;
#       if remainingBytes > 0
#         textBuffer = new Buffer(size)
#         bytesRead = fs.readSync(fd, textBuffer, 0, size);
#         text = textBuffer.toString("utf8", 0, bytesRead)
#       else
#         text = headerBuffer.toString("utf8", 0, bytesRead);
#
#     if text?
#       callback(text.split('\n'), 1)
#
#   finally
#     fs.closeSync(fd)

readFile = (path, callback) ->
  chunkSize = readFile.CHUNK_SIZE
  line = 1
  fd = fs.openSync(path, "r");
  try
    offset = 0
    remainder = null
    return if isBinaryFile(headerBuffer, fs.readSync(fd, headerBuffer, 0, 256))

    chunkedBuffer ?= new Buffer(chunkSize)
    bytesRead = fs.readSync(fd, chunkedBuffer, 0, chunkSize, 0)

    while bytesRead
      # Scarier looking. Uses least new objects
      index = lastIndexOf(chunkedBuffer, bytesRead, 10)
      if index < 0
        # no newlines here, the whole thing is a remainder
        newRemainder = chunkedBuffer.toString("utf8", 0, bytesRead)
        str = null
        lines = null
      else if index > -1 and index == bytesRead - 1
        # the last char is a newline
        newRemainder = null
        str = chunkedBuffer.toString("utf8", 0, bytesRead - 1)
        lines = str.split('\n')
      else
        newRemainder = chunkedBuffer.toString("utf8", index+1, bytesRead)
        str = chunkedBuffer.toString("utf8", 0, index)
        lines = str.split('\n')

      # Creates a lot of arrays.
      # str = chunkedBuffer.toString("utf8", 0, bytesRead)
      # lines = str.split('\n')
      #
      # if lines.length == 1
      #   # no newlines here, the whole thing is a remainder
      #   newRemainder = str
      #   lines = null
      # else if str[bytesRead-1] == '\n'
      #   # the last char is a newline
      #   newRemainder = null
      #   lines = lines.slice(0, lines.length-1)
      # else
      #   newRemainder = lines[lines.length-1]
      #   lines = lines.slice(0, lines.length-1)

      if not lines? or lines.length == 0
        remainder = concat(remainder, newRemainder)
      else
        lines[0] = remainder + lines[0] if remainder?
        callback(lines, line)
        remainder = newRemainder

      line += lines.length if lines?
      offset += bytesRead
      bytesRead = fs.readSync(fd, chunkedBuffer, 0, chunkSize, offset)

    callback(remainder.split('\n'), line) if remainder

  finally
    fs.closeSync(fd)

readFile.CHUNK_SIZE = 10240

module.exports = readFile