striptags = require 'striptags'
cheerio   = require 'cheerio'
oembed    = require 'oembed'
q         = require 'q'

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
      author = @feed.author or item.author
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
  # Filter feed that do not contains a given word
  contains: (word)=>
    # For quickest search
    word = do word.toLowerCase
    (item)=>
      # A filter can also returns a promise
      q.fcall ->
        if item.title.toLowerCase().indexOf(word) > -1 or
           item.description.toLowerCase().indexOf(word) > -1
          item
        else no
  # Delete a given word from the title or the description
  del: (word, replacement='')=>
    re = new RegExp word, 'gi'
    (item)=>
      item.title = item.title.replace re, replacement
      item.description = item.description.replace re, replacement
      # Returns the item
      item
  # Extract oembed with embedly
  oembed: =>
    # Set the embedly key from env
    oembed.EMBEDLY_KEY = process.env.EMBEDLY_KEY
    (item)=>
      # Deferred result
      deferred = do q.defer
      # Build item uri
      uri = item.url or item.link or item.guid
      # Fetch!
      oembed.fetch uri, maxwidth: 1920, (error, result)->
        # Reject errored page
        if error? then do deferred.reject
        else
          # Update the description
          item.description = result.description
          # Resolve the promise
          deferred.resolve item
      # Return a promise
      deferred.promise



module.exports = exports = Pipe
