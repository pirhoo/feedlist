striptags = require 'striptags'
cheerio   = require('cheerio')

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
  # Remove an HTML element from the item description
  rmel: (selector)=>
    (item)=>
      dom = cheerio.load(item.description)
      # Instanciate jQuery with the given window and remove the right element
      do dom(selector).remove
      # Get the new description
      item.description = do dom.html
      item


module.exports = exports = Pipe
