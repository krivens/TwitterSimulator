defmodule UserActor do
    use GenServer

    def start(opts) do
        GenServer.start(__MODULE__, opts)
    end

    def tweet(pid, tweet, sessionkey) do
        GenServer.call(pid, {:tweet, tweet, sessionkey})
    end

    def handle_call({:tweet, tweet,  _sessionkey}, _from, state) do
        userid = Map.get(state, :userid)
        tweetcounter = Map.get(state, :tweetcounter)
        tweetid = userid<>"_"<>Integer.to_string(tweetcounter)
        # put it in the database
        TweetStore.insert_tweet(tweetid, userid, tweet)
        :ets.insert(:user_tweet_counter,{userid, tweetid})
        # spawn a process to send it to the list of all subscribers
        spawn(__MODULE__, :send_to_subscribers, [tweetid, userid, tweet, false, nil])
        {:reply, tweetid, Map.put(state, :tweetcounter, tweetcounter+1)}
    end

    def retweet(pid, tweetid) do
        GenServer.cast(pid, {:retweet, tweetid})
    end

    def handle_cast({:retweet, tweetid}, state) do
        tweettuple = :ets.lookup(:tweet_table, tweetid)
        if(length(tweettuple)==0) do
            nil
        else
            {^tweetid,creatorid, tweet} = hd(tweettuple) 
            userid = Map.get(state, :userid)
            spawn(__MODULE__, :send_to_subscribers, [tweetid, userid, tweet, true, creatorid])
        end
        {:noreply, state}
    end

    def send_to_subscribers(tweetid, userid, tweet, retweetflag, creatorid) do
        sublist = :ets.lookup(:user_subscribers, userid)
        Enum.each(sublist, fn ({sender, sub}) ->
            subserver = :ets.lookup(:user_servers, sub)
            if (length(subserver)==0) do
                :ets.insert(:user_mailbox, {sub, userid, tweetid, retweetflag})
            else
                {^sub, pid} = hd(subserver)
                GenServer.cast(pid, {:get_tweet,tweetid, userid, tweet, retweetflag, creatorid})
            end
            end)
    end

    def subscribe(pid, touserid) do
        GenServer.cast(pid, {:subscribe, touserid})
    end

    def handle_cast({:subscribe, touserid}, state) do
        #can't subscribe to self
        if(Map.get(state, :userid) == touserid) do
            nil
        else
            user = :ets.lookup(:users, touserid)
            case user do
                [{^touserid, _}] -> :ets.insert(:user_subscribers, {touserid, Map.get(state, :userid)})
                [] -> nil
            end
        end
        {:noreply, state}
    end

    def deliver_unread(pid) do
        GenServer.cast(pid, {:deliver_unread})
    end
    
    def handle_cast({:deliver_unread}, state) do
        userid = Map.get(state, :userid)
        clientpid = Map.get(state, :clientpid)
        tweetidlist = :ets.lookup(:user_mailbox,userid)
        :ets.delete(:user_mailbox, userid)
        Enum.each(tweetidlist, fn {_,tweeterid,tweetid,retweetflag} -> 
            {^tweetid, creatorid, tweet} = hd(:ets.lookup(:tweet_table, tweetid))
            send_to_client(clientpid, tweetid, tweeterid, tweet, retweetflag, creatorid)
            end)
        {:noreply, state}
    end

    def handle_cast({:get_tweet, tweetid, userid, tweet, retweetflag, creatorid}, state) do
        clientpid = Map.get(state, :clientpid)
        send_to_client(clientpid, tweetid, userid, tweet, retweetflag, creatorid)
        {:noreply, state}
    end

    def send_to_client(clientpid, tweetid, userid, tweet, retweetflag, creatorid) do
        GenServer.call(clientpid, {:get_tweets, tweetid, userid, tweet, retweetflag, creatorid})
    end

    def update_client(pid, clientpid) do
        GenServer.call(pid, {:update_client, clientpid})
    end

    def handle_call({:update_client, clientpid}, _from, state) do
        {:reply, :ok, Map.put(state, :clientpid, clientpid)}
    end

    def my_mentions(pid) do
        GenServer.call(pid, {:my_mentions})
    end

    def handle_call({:my_mentions}, _from, state) do
        userid = Map.get(state, :userid)
        clientpid = Map.get(state, :clientpid)
        tweetlist = TweetStore.get_mentions(userid)
        Enum.each(tweetlist, fn tweetrec -> 
            {tweetid, tweeterid, tweet} = tweetrec
            send_to_client(clientpid, tweetid, tweeterid, tweet, false, nil)
            end)
        {:reply, :ok, state}
    end

    def query_hashtag(pid, hashtag) do
        GenServer.call(pid, {:query_hashtag, hashtag})
    end

    def handle_call({:query_hashtag, hashtag}, _from, state) do
        clientpid = Map.get(state, :clientpid)
        tweetlist = TweetStore.get_hashtags(hashtag)
        Enum.each(tweetlist, fn tweetrec -> 
            {tweetid, tweeterid, tweet} = tweetrec
            send_to_client(clientpid, tweetid, tweeterid, tweet, false, nil)
            end)
        {:reply, :ok, state}
    end
end