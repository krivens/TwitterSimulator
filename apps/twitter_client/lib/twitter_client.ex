defmodule TwitterClient do
  use GenServer

  def start(opts) do
    GenServer.start(__MODULE__, opts)
  end

  def register(pid) do
    GenServer.call(pid, {:register})
  end

  def handle_call({:register}, _from, state) do
    servernode = Map.get(state, :servernode)
    userid = Map.get(state, :userid)
    {_status, result} = :rpc.call(servernode, UserRegistry, :register_user, [userid, nil])
    {:reply, result, state}
  end

  def login(pid) do
    GenServer.call(pid, {:login})
  end

  def handle_call({:login}, _from, state) do
    servernode = Map.get(state, :servernode)
    userid = Map.get(state, :userid)
    credentials = Map.get(state, :credentials)
    #IO.puts "Trying to login user #{userid}"
    handler = :rpc.call(servernode, UserRegistry, :login, [userid, credentials, self()])
    #IO.puts "Handler was #{inspect(handler)}"
    {:reply, :logged_in, Map.put(state, :handler, handler)}
  end

  def logout(pid) do
    GenServer.call(pid, {:logout})
  end

  def handle_call({:logout}, _from, state) do
    servernode = Map.get(state, :servernode)
    userid = Map.get(state, :userid)
    credentials = Map.get(state, :credentials)
    :rpc.call(servernode, UserRegistry, :logout, [userid, credentials])
    {:reply, :logged_out, Map.put(state, :handler, nil)}    
  end

  def subscribe(pid, touserid) do
    GenServer.call(pid, {:subscribe, touserid})
  end

  def handle_call({:subscribe, touserid}, _from, state) do
    GenServer.cast(Map.get(state, :handler), {:subscribe, touserid})  
    {:reply, :ok, state}
  end

  def tweet(pid, text) do
    GenServer.cast(pid, {:tweet, text})
  end

  def handle_cast({:tweet, text}, state) do
    handler = Map.get(state, :handler)
    _tweetid = GenServer.call(handler, {:tweet, text, nil})
    {:noreply, state}
  end

  def retweet(pid, tweetid) do
    GenServer.cast(pid, {:retweet, tweetid})
  end

  def handle_cast({:retweet, tweetid}, state) do
    GenServer.cast(Map.get(state, :handler), {:retweet, tweetid})
    {:noreply, state}
  end

  def my_mentions(pid) do
    GenServer.call(pid, {:my_mentions})
  end

  def handle_call({:my_mentions}, _from, state) do
    GenServer.call(Map.get(state, :handler), {:my_mentions})
    {:reply, :ok, state}
  end

  def query_hashtag(pid, hashtag) do
    GenServer.call(pid, {:query_hashtag, hashtag})
  end

  def handle_call({:query_hashtag, hashtag}, _from, state) do
    GenServer.call(Map.get(state, :handler), {:query_hashtag, hashtag})
    {:reply, :ok, state}
  end

  def handle_call({:get_tweets, tweetid, userid, tweet, retweetflag, creatorid}, _from, state) do
    if(!Map.get(state, :simmode)) do
      IO.puts "#{Map.get(state, :userid)}:#{if(retweetflag) do "Retweet #{creatorid}" else "Tweet" end}(#{tweetid}) from @#{userid}: #{tweet}"
    end
    {:reply, :ok, state}
  end
end