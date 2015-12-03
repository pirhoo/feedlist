striptags = require 'striptags'

class Pipe
   # Current feed is simply saved as an attribute
  constructor: (@feed)-> null
  # Nothing
  noop: (item)-> item
  # Strip tags
  nohtml: (item)->
    item.description = striptags item.description
    item
  # Add the author feed to in the title
  addauthor: (item)->
    # Find the author of the item
    author = item.author or @feed.author
    item.title = "[" + author + "] " + item.title
    item

module.exports = exports = Pipe
