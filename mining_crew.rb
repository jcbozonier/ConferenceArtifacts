require "net/http"
require "uri"
require "json"
require "mongo"
include Mongo

def every_minute
  loop do
    yield
    puts "Sleeping..."
    sleep(60)
  end
end

class Database
  def save tweets
    connection_string = "flame.mongohq.com"
    mongo_connection = Mongo::Connection.new(connection_string, 27018)
    db = mongo_connection.db("AltNetMiner")
    if db.authenticate("darkxanthos", "abc123!")
      test_collection = db.collection('AltNetSeattleMentions')
      tweets.each do |tweet|
        test_collection.insert tweet
      end
    end
    mongo_connection.close
  end

  def last_tweet_id_received
    connection_string = "flame.mongohq.com"
    mongo_connection = Mongo::Connection.new(connection_string, 27018)
    db = mongo_connection.db("AltNetMiner")
    if db.authenticate("darkxanthos", "abc123!")
      test_collection = db.collection('AltNetSeattleMentions')
      tweets = test_collection.find({}).sort([["id", -1]]).limit(1).select{|tweet| tweet}

      if tweets.length > 0
        most_recent_archived_tweet = tweets[0]
        return most_recent_archived_tweet["id_str"]
      else
        return "0"
      end
    end

    raise "Log in to Mongo FAILED!"
  end
end

class Twitter
  def search_for hashtag, since_id
    twitter_max_id = since_id
    puts "Searching for all tweets since id #{twitter_max_id}"

    for page_number in 1..15
      uri  = URI.parse("http://search.twitter.com/search.json?q=%23#{hashtag}&rpp=100&page=#{page_number}&since_id=#{twitter_max_id}")
      response = Net::HTTP.get_response(uri)
      result = JSON.parse response.body

      tweet_count = result["results"].length
      puts "Found #{tweet_count} tweets on page #{page_number}."

      if tweet_count > 0
        puts "Found results on page #{page_number}"
        yield result["results"]
      else
        puts "No search results"
        break
      end
    end
  end
end

twitter = Twitter.new
database = Database.new

every_minute do
  twitter.search_for "altnetseattle", database.last_tweet_id_received do |tweets|
    puts "Saving twitter results to datastore"
    database.save tweets
  end
end

