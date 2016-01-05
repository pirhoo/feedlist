express    = require 'express'
FeedParser = require 'feedparser'
request    = require 'request'
crypto     = require 'crypto'
Rss        = require 'rss'
Pipe       = require './pipe'

# Shortcut for empty callback
noop = -> null

class FeedList
  # Refresh feed the evry 30 minutes
  REFRESH_INTERVAL: 1000 * 10 * 30
  # Check feed for refreshing every 15 minutes
  CHECKING_INTERVAL: 1000 * 60 * 15
  # Maximum element to display in the RSS
  MAX_ITEMS = 20
  # Listening port
  PORT: process.env.PORT or 3000
  # Get all feeds
  feeds: require './feeds.json'

  constructor: ()->
    # Create an express app
    @app = do express
    # Bind endpoint
    @app.get '/', @getFeeds
    # Fetch every feed once
    do @fetchAll
    # Set an interval to refersh the feed
    setInterval @fetchAll, @CHECKING_INTERVAL
    # Then start listening
    @app.listen @PORT, =>
      console.log 'Listening on http://localhost:%s', @PORT
    setTimeout =>
      @mustRefresh feed for feed in @feeds
    , 2000


  dohash: (d)-> crypto.createHash('md5').update(d).digest('hex')

  mustRefresh: (feed)=>
    # Not fetched yet
    !feed.lastUpdate or
    # Or fetched a moment ago
    Date.now() - feed.lastUpdate.getTime() > @REFRESH_INTERVAL

  fetchAll: =>
    for feed in @feeds
      if @mustRefresh feed
        console.log "Fetch feed", feed.url
        @fetchFeed feed, @saveFeed
      else
        console.log "Skip feed", feed.url

  fetchFeed: (feed, callback=noop)=>
    # Create a new feed parser
    feedparser = new FeedParser normalize: yes
    # Get the feed
    request if feed.timestamp then feed.url + "?" + Date.now() else feed.url
      # Wait for the request to send data
      .on 'response', (res)->
        # Pipe response to feedparse
        @pipe feedparser
      # Unable to fetch the feed, just ignore it
      .on 'error', noop
    # When parsing ends
    feedparser.on 'readable', -> callback feed, @

  saveFeed: (feed, stream)=>
    # Save last update time
    feed.lastUpdate = new Date
    # Create list of items for this feed if any
    feed.items = feed.items or {}
    # For each feed itemm
    while item = do stream.read
      # Items must have a date
      if date = item.date || item.pubDate
        # Create a hash with its link and date
        if hash = @dohash [item.link, date].join(" ")
          # Compiled the feed item
          if compiled = @buildFeedItem(feed, item)
            # Save the item
            feed.items[hash] = compiled

  buildFeedItem: (feed, item)=>
    # Pipe feed (if any)
    if feed.pipe?
      # Create a pipe instance for this feed
      pipe = new Pipe(feed)
      # Put item into the pipe
      for method in feed.pipe.split('|')
        # The filter may mention arguments
        args = method.split ':'
        # Gets filter name
        filter = args[0]
        # Pipe must exist
        if pipe[filter]?
          # Reject the first arguments (which is the name of the filter)
          item = pipe[filter].apply(pipe, args.slice(1, args.length) ) item
        # If a pipe returns false, the item is rejected
        return no unless item
    # Return a new object
    title: item.title
    description: item.description
    url: item.link or item.guid
    author: item.author
    date: item.pubDate or item.date

  getFeeds: (req, res)=>
    # A list of items to display
    items = []
    # For each feed
    for feed in @feeds
      # Every single feed item must be prepared
      for hash of feed.items
        # Add feed's items to the output
        items.push feed.items[hash]
    # Sort the list of items
    items = items.sort (a,b)-> b.date.getTime() - a.date.getTime()
    # Create Rss output
    rss = new Rss title: "Journalism++ Feed", site_url: 'http://www.jplusplus.org'
    # Add every items to the ouput
    rss.item item for item in items.slice(0, MAX_ITEMS)
    # Send the final XML
    res.send rss.xml(indent: true)

new FeedList
