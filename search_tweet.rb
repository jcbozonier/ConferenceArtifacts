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
      if word.include? "@"
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

def for_each_word_in text
  non_word_characters = ['.',':', ' ', '"', '?', ',', '\'']

  current_word = ""

  text.each_char do |character|
    if non_word_characters.include? character
      yield current_word if current_word != ""

      current_word = ""
    else
      current_word += character
    end
  end

  yield current_word if current_word != ""
end