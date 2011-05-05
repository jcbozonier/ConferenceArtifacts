require 'test/unit'
require Dir.pwd + '/search_tweet.rb'

class WordCloudTests < Test::Unit::TestCase
  def test_given_a_tweet_with_no_content
    example_tweet = {
      "_id"=>{"$oid"=>"4dc1838907f30a3d91000023"},
      "from_user_id_str"=>"247169",
      "profile_image_url"=>"http://a1.twimg.com/profile_images/25425132/me_normal.jpg",
      "created_at"=>"Wed, 04 May 2011 16:48:56 +0000",
      "from_user"=>"ang3lsdream",
      "id_str"=>"65820214343909377",
      "metadata"=>{"result_type"=>"recent"},
      "to_user_id"=>266645,
      "text"=>"",
      "id"=>65820214343909377,
      "from_user_id"=>247169,
      "to_user"=>"jamesthigpen",
      "geo"=>nil,
      "iso_language_code"=>"en",
      "to_user_id_str"=>"266645",
      "source"=>'<a href="http://seesmic.com/seesmic_mobile/android/" rel="nofollow">Seesmic for Android</a>'
    }

    users_referenced = SearchTweet.users_referenced_in example_tweet

    assert_equal ["ang3lsdream"], users_referenced, "should pull the screen name from the from_user field"
  end

  def test_given_a_tweet_with_one_name_referenced_in_content
    example_tweet = {
      "_id"=>{"$oid"=>"4dc1838907f30a3d91000023"},
      "from_user_id_str"=>"247169",
      "profile_image_url"=>"http://a1.twimg.com/profile_images/25425132/me_normal.jpg",
      "created_at"=>"Wed, 04 May 2011 16:48:56 +0000",
      "from_user"=>"ang3lsdream",
      "id_str"=>"65820214343909377",
      "metadata"=>{"result_type"=>"recent"},
      "to_user_id"=>266645,
      "text"=>"@jamesthigpen actually I will be on the 145 to Seattle to get Eric for heading to #altnetseattle w00t!",
      "id"=>65820214343909377,
      "from_user_id"=>247169,
      "to_user"=>"jamesthigpen",
      "geo"=>nil,
      "iso_language_code"=>"en",
      "to_user_id_str"=>"266645",
      "source"=>'<a href="http://seesmic.com/seesmic_mobile/android/" rel="nofollow">Seesmic for Android</a>'
    }

    users_referenced = SearchTweet.users_referenced_in example_tweet

    assert_equal ["ang3lsdream", "jamesthigpen"].sort, users_referenced.sort, "should pull the screen name from the from_user field"
  end

  def test_given_a_tweet_with_one_name_referenced_in_content_multiple_times
    example_tweet = {
      "_id"=>{"$oid"=>"4dc1838907f30a3d91000023"},
      "from_user_id_str"=>"247169",
      "profile_image_url"=>"http://a1.twimg.com/profile_images/25425132/me_normal.jpg",
      "created_at"=>"Wed, 04 May 2011 16:48:56 +0000",
      "from_user"=>"ang3lsdream",
      "id_str"=>"65820214343909377",
      "metadata"=>{"result_type"=>"recent"},
      "to_user_id"=>266645,
      "text"=>"@jamesthigpen actually I @jamesthigpen will be on the 145 to Seattle to get Eric for heading to #altnetseattle w00t!",
      "id"=>65820214343909377,
      "from_user_id"=>247169,
      "to_user"=>"jamesthigpen",
      "geo"=>nil,
      "iso_language_code"=>"en",
      "to_user_id_str"=>"266645",
      "source"=>'<a href="http://seesmic.com/seesmic_mobile/android/" rel="nofollow">Seesmic for Android</a>'
    }

    users_referenced = SearchTweet.users_referenced_in example_tweet

    assert_equal ["ang3lsdream", "jamesthigpen"].sort, users_referenced.sort, "should pull the screen name from the from_user field"
  end

  def test_that_distinct_users_are_found_across_multiple_tweets
    example_tweet = {
      "_id"=>{"$oid"=>"4dc1838907f30a3d91000023"},
      "from_user_id_str"=>"247169",
      "profile_image_url"=>"http://a1.twimg.com/profile_images/25425132/me_normal.jpg",
      "created_at"=>"Wed, 04 May 2011 16:48:56 +0000",
      "from_user"=>"ang3lsdream",
      "id_str"=>"65820214343909377",
      "metadata"=>{"result_type"=>"recent"},
      "to_user_id"=>266645,
      "text"=>"@jamesthigpen actually I @jamesthigpen will be on the 145 to Seattle to get Eric for heading to #altnetseattle w00t!",
      "id"=>65820214343909377,
      "from_user_id"=>247169,
      "to_user"=>"jamesthigpen",
      "geo"=>nil,
      "iso_language_code"=>"en",
      "to_user_id_str"=>"266645",
      "source"=>'<a href="http://seesmic.com/seesmic_mobile/android/" rel="nofollow">Seesmic for Android</a>'
    }

    users_referenced = SearchTweet.users_referenced_in example_tweet

    assert_equal ["ang3lsdream", "jamesthigpen"].sort, users_referenced.sort, "should pull the screen name from the from_user field"
  end

  def test_find_conversation_edges_for_tweet_with_no_recipient
    example_tweet = {
      "_id"=>{"$oid"=>"4dc1838907f30a3d91000023"},
      "from_user_id_str"=>"247169",
      "profile_image_url"=>"http://a1.twimg.com/profile_images/25425132/me_normal.jpg",
      "created_at"=>"Wed, 04 May 2011 16:48:56 +0000",
      "from_user"=>"ang3lsdream",
      "id_str"=>"65820214343909377",
      "metadata"=>{"result_type"=>"recent"},
      "to_user_id"=>266645,
      "text"=>"",
      "id"=>65820214343909377,
      "from_user_id"=>247169,
      "to_user"=>"jamesthigpen",
      "geo"=>nil,
      "iso_language_code"=>"en",
      "to_user_id_str"=>"266645",
      "source"=>'<a href="http://seesmic.com/seesmic_mobile/android/" rel="nofollow">Seesmic for Android</a>'
    }

    graph = SearchTweet.conversation_graph example_tweet

    assert_equal "ang3lsdream", graph["sender"], "should know who created the tweet"
    assert_equal [], graph["mentions"], "should not have mentioned anyone"
  end

  def test_find_conversation_edges_for_tweet_with_multiple_recipients
    example_tweet = {
      "_id"=>{"$oid"=>"4dc1838907f30a3d91000023"},
      "from_user_id_str"=>"247169",
      "profile_image_url"=>"http://a1.twimg.com/profile_images/25425132/me_normal.jpg",
      "created_at"=>"Wed, 04 May 2011 16:48:56 +0000",
      "from_user"=>"ang3lsdream",
      "id_str"=>"65820214343909377",
      "metadata"=>{"result_type"=>"recent"},
      "to_user_id"=>266645,
      "text"=>"@jamesthigpen actually I @jamesthigpen will @darkxanthos be on the 145 to Seattle to get Eric for heading to #altnetseattle w00t!",
      "id"=>65820214343909377,
      "from_user_id"=>247169,
      "to_user"=>"jamesthigpen",
      "geo"=>nil,
      "iso_language_code"=>"en",
      "to_user_id_str"=>"266645",
      "source"=>'<a href="http://seesmic.com/seesmic_mobile/android/" rel="nofollow">Seesmic for Android</a>'
    }

    graph = SearchTweet.conversation_graph example_tweet

    assert_equal "ang3lsdream", graph["sender"], "should know who created the tweet"
    assert_equal ["jamesthigpen", "darkxanthos"].sort, graph["mentions"].sort, "should not have mentioned anyone"
    assert_equal Time.parse(example_tweet['created_at']), graph["time_stamp"], "should grab the created date"
    assert_equal "65820214343909377", graph["tweet_id"], "should mark the conversation with the tweet id."
  end

 #d = DateTime.strptime '12:06 AM Oct 15th', '%H:%M %p %b %d'

end