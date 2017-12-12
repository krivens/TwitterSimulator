defmodule TweetStore do

    def insert_tweet(tweetid, userid, tweet) do
        :ets.insert(:tweet_table,{tweetid, userid, tweet})
        spawn(TweetStore, :store_tweet, [tweetid, userid, tweet])
        tweetid
    end

    def store_tweet(tweetid, _userid, tweet) do
        {:ok, hashpattern} = Regex.compile("#[^#@\\s]*")
        {:ok, mentionpattern} = Regex.compile("@[^#@\\s]*")
        if(tweet != nil) do
            hashtags = Regex.scan(hashpattern, tweet)
            Enum.each(hashtags, fn (hashtag) -> :ets.insert(:hashtag_table, {hashtag, tweetid}) end)
            mentions = Regex.scan(mentionpattern, tweet)
            Enum.each(mentions, fn (mention) -> :ets.insert(:mentions_table, {mention, tweetid}) end)
        end
    end

    def get_tweet(tweetid) do
        :ets.lookup(:tweet_table, tweetid)
    end

    def get_mentions(userid) do
        mentionlist = :ets.lookup(:mentions_table, "@"<>userid)
        Enum.reduce(mentionlist, [], fn (record, acc) -> get_tweet(elem(record, 1) ++ acc) end)
    end

    def get_hashtags(hashtag) do
        hashtaggedlist = :ets.lookup(:hashtag_table, hashtag)
        Enum.reduce(hashtaggedlist, [], fn (record, acc) -> get_tweet(elem(record, 1) ++ acc) end)
    end
end