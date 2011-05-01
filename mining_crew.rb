require "net/http"
require "uri"
require "json"
require "mongo"
include Mongo

def search_for hashtag
  twitter_max_id = current_max_id_in_archived_tweets
  puts "Searching for all tweets since id #{twitter_max_id}"

  for page_number in 1..15
    uri  = URI.parse("http://search.twitter.com/search.json?q=%23#{hashtag}&rpp=100&page=#{page_number}&since_id=#{twitter_max_id}")
    response = Net::HTTP.get_response(uri)
    result = JSON.parse response.body

    tweet_count = result["results"].length
    puts "Found #{tweet_count} tweets on page #{page_number}."

    if tweet_count > 0
      puts "Found results on page #{page_number}"
      yield result
    else
      puts "No search results"
      break
    end
  end
end

def every_minute
  loop do
    yield
    puts "Sleeping..."
    sleep(60)
  end
end

def current_max_id_in_archived_tweets
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

def save_to_datastore twitter_response
  connection_string = "flame.mongohq.com"
  mongo_connection = Mongo::Connection.new(connection_string, 27018)
  db = mongo_connection.db("AltNetMiner")
  if db.authenticate("darkxanthos", "abc123!")
    test_collection = db.collection('AltNetSeattleMentions')

    twitter_response["results"].each do |result|
      test_collection.insert result
    end
  end
  mongo_connection.close
end

every_minute do
  search_for "altnetseattle" do |twitter_response|
    puts "Saving twitter results to datastore"
    save_to_datastore twitter_response
  end
end