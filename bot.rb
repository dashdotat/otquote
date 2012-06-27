require 'rubygem' unless defined?(Gem)
require 'bundler'
require 'open-uri'
require 'cgi'

Bundler.require()

class Quote
	include Mongoid::Document
end

class QuotePlugin
	include Cinch::Plugin

	match /addquote (.+)/, :method => :addquote
	match /quote$/, :method => :randomquote
	match /quote (.+)/, :method => :searchquote
	listen_to :join, :method => :joined

	def joined(m)
		#m.reply "#{m.user} joined", false unless m.user.nick == bot.nick
	end

	def randomquote(m)
		quote = Quote.skip(rand(Quote.count)).limit(1).first
		m.reply(quote.quote || "No quotes added yet - go on, be the first", false)
	end

	def addquote(m, quote)
		new_quote = Quote.create(quote: quote)
		m.reply "Added quote with ID #{new_quote.id}", false
	end

	def searchquote(m, search)
		#m.reply "Will search for '#{search}'", false
	end
end


class UrbanDictionary
	include Cinch::Plugin

	match /urban (.+)/, {:method => :lookup}
	def lookup(m, word)
		url = "http://www.urbandictionary.com/define.php?term=#{CGI.escape(word)}"
		debug "URL: #{url}"
		definition = CGI.unescape_html(Nokogiri::HTML(open(url)).at("div.definition").text.gsub(/\s+/,' ')) rescue nil
		debug "Definition: #{definition}"
		m.reply(definition || "No results found", true)
	end
end

bot = Cinch::Bot.new do
	configure do |c|
		c.server = "penguin.uk.eu.blitzed.org"
		c.nick = "otquote"
		c.realname = "OT Quotes"
		c.user = "otquote"
		c.channels = ["#ot-quote"]
		c.plugins.plugins = [UrbanDictionary,QuotePlugin]
		c.verbose = true
	end
end
Mongoid.load!("mongoid.yml","production")
bot.start
