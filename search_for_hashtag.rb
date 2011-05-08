require "net/http"
require "uri"
require "json"
require "mongo"
include Mongo

require Dir.pwd + '/search_tweet.rb'

def every_minute
  loop do
    yield
    puts "Sleeping..."
    sleep(60)
  end
end

class Database
  def add_tweet_events_for tweets
    connection_string = "flame.mongohq.com"
    mongo_connection = Mongo::Connection.new(connection_string, 27018)
    db = mongo_connection.db("AltNetMiner")
    if db.authenticate("darkxanthos", "abc123!")
      test_collection = db.collection('AltNetSeattleMentions')

      test_collection.insert tweets
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

    mongo_connection.close
    raise "Log in to Mongo FAILED!"
  end

  def save_conversation graphs
    puts "saving conversation graphs"

    connection_string = "flame.mongohq.com"
    mongo_connection = Mongo::Connection.new(connection_string, 27018)
    db = mongo_connection.db("AltNetMiner")

    if db.authenticate("darkxanthos", "abc123!")
      test_collection = db.collection('AltNetSeattleDiscussions')
      migrate_existing_tweet_conversations if test_collection.find({}).count() == 0

      test_collection = db.collection('AltNetSeattleDiscussions')

      puts "Inserting conversations into Mongo"
      test_collection.insert graphs
      puts "Done inserting conversations into Mongo"
    end

    mongo_connection.close
  end

  def merge tweets
    puts "connecting to db"
    connection_string = "flame.mongohq.com"
    mongo_connection = Mongo::Connection.new(connection_string, 27018)
    db = mongo_connection.db("AltNetMiner")

    if db.authenticate("darkxanthos", "abc123!")
      puts "creating word relationships"
      test_collection = db.collection('AltNetSeattleWordConnections')
      migrate_existing_tweets_to_word_relationships if test_collection.find({}).count() == 0

      archived_relationships = test_collection.find({})
      combined_relationships = tweets.inject(archived_relationships) do |accum, tweet|
          combine_relationships(accum, relate_words_in(tweet["text"]))
      end

      test_collection.remove({})
      test_collection.insert(combined_relationships)
    end

    mongo_connection.close

    puts "done creating word relationships"
  end

  def migrate_existing_tweets_to_word_relationships
    puts "migrating word relationships"
    connection_string = "flame.mongohq.com"
    mongo_connection = Mongo::Connection.new(connection_string, 27018)
    db = mongo_connection.db("AltNetMiner")

    if db.authenticate("darkxanthos", "abc123!")
      word_connections = db.collection('AltNetSeattleWordConnections')

      tweets = db['AltNetSeattleMentions']

      word_relationships = tweets.find({}).map{|tweet| relate_words_in tweet["text"]}.inject([]){|accum, relationship| combine_relationships relationship, accum}

      word_connections.insert word_relationships
    end

    mongo_connection.close
    puts "done migrating word relationships"
  end

  def migrate_existing_tweet_conversations
    puts "Migrating preexisting conversations"
    connection_string = "flame.mongohq.com"
    mongo_connection = Mongo::Connection.new(connection_string, 27018)
    db = mongo_connection.db("AltNetMiner")
    if db.authenticate("darkxanthos", "abc123!")
      test_collection = db['AltNetSeattleMentions']
      tweets = db['AltNetSeattleMentions'].find({}).select{|tweet| tweet}

      puts "Computing all graphs"
      graphs = []
      tweets.each do |tweet|
        graphs << SearchTweet.conversation_graph(tweet)
      end
      puts "Completed computing all graphs"

      puts "Saving migration"
      discussion_graphs = db.collection('AltNetSeattleDiscussions')
      discussion_graphs.insert graphs
      puts "Migration saved"
    end
    mongo_connection.close
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

    puts "Parsing conversation graphs"
    graphs = []
    tweets.each do |tweet|
      graphs << SearchTweet.conversation_graph(tweet)
    end

    puts "Saving twitter results to datastore"
    database.merge tweets
    database.save_conversation graphs
    database.add_tweet_events_for tweets
  end
end

