require "net/http"
require "uri"
require "json"
require "mongo"
include Mongo

def search_for_altnetseattle page_number, since_id
  hashtag = "altnetseattle"
  #hashtag = "tragicmoviedeaths"
  uri  = URI.parse("http://search.twitter.com/search.json?q=%23#{hashtag}&rpp=100&page=#{page_number}&since_id=#{since_id}")
  response = Net::HTTP.get_response(uri)
  result = JSON.parse response.body
  tweet_count = result["results"].length
  puts "Found #{tweet_count} tweets on page #{page_number}."
  
  if tweet_count > 0
    yield result 
    true
  else
    false
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

def warn_of_duplicates_between previous_tweet_ids, result_ids
  result_ids.each do |result_id|
    puts "DUPE Found!" if previous_tweet_ids.include? result_id
  end
end

previous_tweet_ids = []

previous_max_id = current_max_id_in_archived_tweets
twitter_max_id = previous_max_id

every_minute do
  puts "Checking for new messages since id #{previous_max_id}"

  for page_number in 1..15
    puts "Looking at page #{page_number}"
    any_results = search_for_altnetseattle page_number, previous_max_id do |twitter_response|
      puts "Found results on page #{page_number}"

      result_ids = twitter_response["results"].select{|result| result["id_str"]}

      twitter_max_id = twitter_response["max_id_str"]

      warn_of_duplicates_between previous_tweet_ids, result_ids
      result_ids.each do |result_id|
        previous_tweet_ids << result_id
      end

      puts "Saving twitter results to datastore"
      save_to_datastore twitter_response
    end

    if not any_results
      puts "No search results"
      break
    end
  end
end
