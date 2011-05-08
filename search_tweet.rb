require "time"
class SearchTweet
  def self.users_referenced_in tweet
    referenced_users = [tweet['from_user']]
    tweet_text = tweet['text']

    each_screen_name_in tweet_text do |screen_name|
      referenced_users << screen_name if !referenced_users.include? screen_name
    end

    referenced_users
  end

  def self.each_screen_name_in tweet_text
    for_each_word_in tweet_text do |word|
      if word.start_with?("@") and word.length > 1
        yield word[1..-1]
      end
    end
  end

  def self.conversation_graph tweet
    mentions = []
    each_screen_name_in tweet["text"] do |screen_name|
      mentions << screen_name if !mentions.include? screen_name
    end

    {
      "sender"=>tweet['from_user'],
      "mentions"=>mentions,
      "time_stamp"=>Time.parse(tweet['created_at']),
      "tweet_id"=>tweet['id_str']
    }
  end
end

def relate_words_in text
  relationships = []
  for_each_word_in text do |word|
    relationships << {"word"=>word, "count"=>1,"related_to" => []}
  end

  for_each_word_in text do |word|
    relationships.each do |relationship|
      if word != relationship["word"]
        relationship["related_to"] << word
      end
    end
  end

  relationships
end

class Array
  def histogram
    self.group_by{|x|x}.map{|w,ws| {w => ws.count}}
  end
end

def combine_relationships this_one, that_one
  related_words = combine_related_words(this_one, that_one)
  histogram = (this_one.map{|x|x["word"]} + that_one.map{|x|x["word"]}).histogram

  histogram.map do |wc|
    {"word" => wc.keys.first, "count" => wc.values.first, "related_to" => related_words[wc.keys.first]}
  end
end

def combine_related_words(*args)
  args.inject(Hash.new([])) { |accum, words|
    words.inject(accum) { |acc, w| accum[w["word"]] = (accum[w["word"]] + w["related_to"]).uniq; accum}
  }
end

def find_related word, this_one, that_one
  these_related_ones = this_one.select{|x|x["word"] == word}.first["related_to"]
  those_related_ones = that_one.select{|x|x["word"] == word}.first["related_to"]

  these_related_ones + those_related_ones
end

def for_each_word_in text
  text.split(/[.: "?,\\]/).each{|w| yield w}
end