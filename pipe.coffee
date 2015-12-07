striptags = require 'striptags'

class Pipe
   # Current feed is simply saved as an attribute
  constructor: (@feed)-> null
  # Nothing
  noop: =>
    # No closure argument
    (item)=> item
  # Strip tags
  nohtml: =>
    # No closure argument
    (item)=>
      item.description = striptags item.description
      item
  # Add the author feed into the title
  addauthor: =>
    # No closure argument
    (item)=>
      # Find the author of the item
      author = item.author or @feed.author
      item.title = "[" + author + "] " + item.title
      item



module.exports = exports = Pipe
