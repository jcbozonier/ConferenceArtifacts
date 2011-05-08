require 'test/unit'
require Dir.pwd + '/search_tweet.rb'

class TweetRelationTests < Test::Unit::TestCase
  def test_when_relating_a_single_tweet_with_content

    text = "worda"

    expected_word_relationships = [
      {
        "word"=>"worda",
        "count"=>1,
        "related_to" => []
      }
    ]

    created_word_relationships = relate_words_in text

    assert_equal expected_word_relationships, created_word_relationships, "should equal"
  end

  def test_when_relating_a_single_tweet_with_multiple_words

    text = "worda wordb word_c"

    expected_word_relationships = [
      {
        "word"=>"worda",
        "count"=>1,
        "related_to" => ["wordb", "word_c"]
      },
      {
        "word"=>"wordb",
        "count"=>1,
        "related_to" => ["worda", "word_c"]
      },
      {
        "word"=>"word_c",
        "count"=>1,
        "related_to" => ["worda", "wordb"]
      }
    ]

    created_word_relationships = relate_words_in text

    assert_equal created_word_relationships, expected_word_relationships, "should equal"
  end

  def test_when_combining_relationships_with_one_word_each
    word_relationship_a = [
      {
        "word"=>"worda",
        "count"=>1,
        "related_to" => []
      },
    ]

    word_relationship_b = [
      {
        "word"=>"wordb",
        "count"=>1,
        "related_to" => []
      },
    ]

    expected_relationship = [
      {
        "word"=>"worda",
        "count"=>1,
        "related_to" => []
      },
      {
        "word"=>"wordb",
        "count"=>1,
        "related_to" => []
      }
    ]

    combined_relationship = combine_relationships word_relationship_a, word_relationship_b

    assert_equal expected_relationship, combined_relationship, "should be right!"
  end

  def test_when_combining_relationships_with_one_word_each_that_are_the_same
    word_relationship_a = [
      {
        "word"=>"worda",
        "count"=>1,
        "related_to" => []
      },
    ]

    word_relationship_b = [
      {
        "word"=>"worda",
        "count"=>1,
        "related_to" => []
      },
    ]

    expected_relationship = [
      {
        "word"=>"worda",
        "count"=>2,
        "related_to" => []
      }
    ]

    combined_relationship = combine_relationships word_relationship_a, word_relationship_b

    assert_equal expected_relationship, combined_relationship, "should be right!"
  end


    def test_related_to_should_combine
    word_relationship_a = [
      {
        "word"=>"worda",
        "count"=>1,
        "related_to" => ["foo"]
      },
    ]

    word_relationship_b = [
      {
        "word"=>"worda",
        "count"=>1,
        "related_to" => ["bar"]
      },
    ]

    expected_relationship = [
      {
        "word"=>"worda",
        "count"=>2,
        "related_to" => ["foo", "bar"]
      }
    ]

    combined_relationship = combine_relationships word_relationship_a, word_relationship_b

    assert_equal expected_relationship, combined_relationship, "should be right!"
  end

  def test_related_to_should_combine_only_over_unique_word
    word_relationship_a = [
      {
        "word"=>"worda",
        "count"=>1,
        "related_to" => ["foo"]
      },
    ]

    word_relationship_b = [
      {
        "word"=>"worda",
        "count"=>1,
        "related_to" => ["foo"]
      },
    ]

    expected_relationship = [
      {
        "word"=>"worda",
        "count"=>2,
        "related_to" => ["foo"]
      }

    ]

    combined_relationship = combine_relationships word_relationship_a, word_relationship_b

    assert_equal expected_relationship, combined_relationship, "should be right!"
  end

end