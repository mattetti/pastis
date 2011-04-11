framework 'Cocoa'

class RSSParser
  attr_accessor :parser, :xml_url, :doc
  
  def initialize(xml_url)
    @xml_url = xml_url
    NSApplication.sharedApplication
    url = NSURL.alloc.initWithString(xml_url)
    @parser = NSXMLParser.alloc.initWithContentsOfURL(url)
    @parser.shouldProcessNamespaces = true
    @parser.delegate = self
    @items = []
  end
  
  # RSSItem is a simple class that holds all of RSS items.
  # Extend this class to display/process the item differently.
  class RSSItem
    attr_accessor :title, :description, :link, :guid, :pubDate, :enclosure
    def initialize
      @title, @description, @link, @pubDate, @guid = '', '', '', '', ''
    end
  end
  
  # Starts the parsing and send each parsed item through its block.
  #
  # Usage:
  #   feed.parse do |item|
  #     puts item.link
  #   end
  def parse(&block)
    @block = block
    puts "Parsing #{xml_url}"
    @parser.parse
  end
  
  # Starts the parsing but keep block the main runloop
  # until the parsing is done.
  # Do not use this method in a GUI app.
  # use #parse instead.
  def block_while_parsing(&block)
    @parsed = false
    parse(&block)
    NSRunLoop.currentRunLoop.runUntilDate(NSDate.distantFuture) until @parsed
  end
  
  # Delegate getting called when parsing starts
  def parserDidStartDocument(parser)
    puts "starting parsing.."
  end
  
  # Delegate being called when an element starts being processed
  def parser(parser, didStartElement:element, namespaceURI:uri, qualifiedName:name, attributes:attrs)
    if element == 'item'
      @current_item = RSSItem.new
    elsif element == 'enclosure'
      @current_item.enclosure = attrs
    end
    @current_element = element
  end
  
  # as the parser finds characters, this method is being called
  def parser(parser, foundCharacters:string)
    if @current_item && @current_item.respond_to?(@current_element)
      el = @current_item.send(@current_element) 
      el << string if el.respond_to?(:<<)
    end
  end
  
  # method called when an element is done being parsed
  def parser(parser, didEndElement:element, namespaceURI:uri, qualifiedName:name)
    if element == 'item'
      @items << @current_item
    end
  end
  
  # delegate getting called when the parsing is done
  # If a block was set, it will be called on each parsed items
  def parserDidEndDocument(parser)
    @parsed = true
    puts "done parsing"
    if @block
      @items.each{|item| @block.call(item)}
    end
    @title.strip! unless @title.nil?
    @description.strip! unless @description.nil?
    @link.strip! unless @link.nil?
    @pubDate.strip! unless @pubDate.nil?
    @guid.strip! unless @guid.nil?
    @guid = @title if @guid.nil?
  end
  
end