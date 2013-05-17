require 'rubygem' unless defined?(Gem)
require 'bundler'
require 'open-uri'
require 'cgi'

Bundler.require()

$wall_count = 0

class AhxcjbPlugin
  include Cinch::Plugin

  listen_to :channel

  def listen(m)
    wall_messages = [
      "Have a GREAT day",
      "Bring on the wall!"
    ]

    morning_messages = [
      "Please respect the Queens timezone",
      "Not in the civilised world",
      "Have a GREAT day"
    ]

    if /^morning/i =~ m.message 
      if m.channel.opped?(bot.nick) && m.user.nick.downcase == "ahxcjb" && Time.now.strftime("%P") == "pm"
        m.channel.kick m.user.nick, morning_messages.sample
      end
    end

    if m.user.nick.downcase == "ahxcjb"
      $wall_count += 1
      if $wall_count > 4 && m.channel.opped?(bot.nick)
        $wall_count = 0
        m.channel.kick m.user.nick, wall_messages.sample
      end
    else
      $wall_count = 0 unless m.user.nick == bot.nick
    end
  end
end

class Quote
	include Mongoid::Document
end

class TitlePlugin
	include Cinch::Plugin

	match /title (.+)/, :method => :get_title
	listen_to :message, :method => :get_url

	def get_url(m)
		if m.user.nick != bot.nick
			urls = URI.extract(m.params[1])
			urls.uniq.each do |url|
				if /^(http|https):\/\//.match(url)
					get_title m, url
				end
			end
		end
	end

	def get_title(m, url)
		if /^(http|https):\/\//.match(url).nil?
			m.reply "#{m.user.nick}: Sorry, I only understand http/https"
		else
			doc = Nokogiri::HTML(open(url)) rescue nil
			title = doc.title rescue nil
			m.reply "#{m.user.nick}: #{url} - #{(title || 'Title not found')}"
		end
	end
end

class QuotePlugin
	include Cinch::Plugin

	match /addquote (.+)/, :method => :addquote
	match /quote$/, :method => :randomquote
	match /quote (.+)/, :method => :searchquote
	listen_to :join, :method => :joined

	def joined(m)
		if m.user.nick != bot.nick
			quotes = Quote.where(:quote => /<.?#{m.user.nick}>/i)
			quote = quotes.skip(rand(quotes.count)).limit(1).first
			sayquote m, quote unless quote.nil?
		end
	end

	def randomquote(m)
		quote = Quote.skip(rand(Quote.count)).limit(1).first
		sayquote m, quote
	end

	def sayquote(m, quote)
		output = "#{quote.quote} (added by #{quote.user})"
		m.channel? ? m.channel.notice(output) : m.reply(output)
	end

	def addquote(m, quote)
		new_quote = Quote.create(quote: quote, user: m.user.nick, created: Time.now)
		m.channel? ? m.channel.notice("Added quote with ID #{new_quote.id}") : m.reply("Added quote with ID #{new_quote.id}")
	end

	def searchquote(m, search)
		quotes = Quote.where(:quote => /.*#{search}.*/i)
		quote = quotes.skip(rand(quotes.count)).limit(1).first
		sayquote m, quote unless quote.nil?
	end
end


class UrbanDictionary
	include Cinch::Plugin

	match /urban (.+)/, {:method => :lookup}
	def lookup(m, word)
		url = "http://www.urbandictionary.com/define.php?term=#{CGI.escape(word)}"
		debug "URL: #{url}"
		output = ""
		doc = Nokogiri::HTML(open(url))
		if doc.css('div.definition').count == 0
			output = "No results found"
		elsif doc.css('div.definition').count == 1
			output = doc.css('div.definition').first.text
		else
			if doc.css('div.definition').count == 2
				(1..2).each do |i|
					output += i.to_s + ": " + doc.css('div.definition')[i-1].text + " "
				end
			else
				(1..3).each do |i|
					output += i.to_s + ": " + doc.css('div.definition')[i-1].text + " "
				end
			end
		end
		output = CGI.unescape_html(output.gsub(/\s+/, ' '))
		#definition = CGI.unescape_html(Nokogiri::HTML(open(url)).at("div.definition").text.gsub(/\s+/,' ')) rescue nil
		debug "Definition: #{output}"
		m.reply(output || "No results found", true)
	end
end

bot = Cinch::Bot.new do
	configure do |c|
		c.server = "penguin.uk.eu.blitzed.org"
		c.nick = "otquote"
		c.realname = "OT Quotes"
		c.user = "otquote"
		c.channels = ["#ot-quote"]
		c.plugins.plugins = [UrbanDictionary,QuotePlugin,AhxcjbPlugin]
		c.verbose = true
	end
end
Mongoid.load!("mongoid.yml","production")
bot.start
