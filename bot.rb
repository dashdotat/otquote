require 'rubygem' unless defined?(Gem)
require 'bundler'
require 'open-uri'
require 'cgi'

Bundler.require()

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
		c.channels = ["#surrey-ot"]
		c.plugins.plugins = [UrbanDictionary]
		c.verbose = true
	end
end
bot.start
