defmodule TwitterProject4Test do
  use ExUnit.Case
  doctest TwitterProject4

  test "greets the world" do
    assert TwitterProject4.hello() == :world
  end

  test "tweeter" do
    srvr=:"server@127.0.0.1"
    Node.connect(srvr)
    Node.spawn(srvr, TwitterProject4, :start_server,[])

    :rpc.call(srvr, UserRegistry, :register_user, ["1", nil])
    :rpc.call(srvr, UserRegistry, :register_user, ["2", nil])
    :rpc.call(srvr, UserRegistry, :register_user, ["3", nil])

    client1 = spawn(Client, :client, ["client1"])
    client2 = spawn(Client, :client, ["client2"])
    client3 = spawn(Client, :client, ["client3"])

    server1 = :rpc.call(srvr, UserRegistry, :login, ["1", nil, client1])
    server2 = :rpc.call(srvr, UserRegistry, :login, ["2", nil, client2])
    server3 = :rpc.call(srvr, UserRegistry, :login, ["3", nil, client3])

    :rpc.call(srvr,UserActor,:subscribe, [server2, "1"])
    :rpc.call(srvr,UserActor,:subscribe, [server3, "2"])

    #:rpc.call(srvr,UserActor,:tweet, [server1, "Send to sub", nil])
    GenServer.call(server1, {:tweet, "Send to sub", nil})
    GenServer.cast(server2, {:retweet, "1_0"})

    :rpc.call(srvr, UserRegistry, :logout, ["2", nil])
    GenServer.call(server1, {:tweet, "Mailbox1", nil})
    GenServer.call(server1, {:tweet, "Mailbox2 #test @3", nil})
    server2 = :rpc.call(srvr, UserRegistry, :login, ["2", nil, client2])
  end

  defmodule Client do
    def client(name) do
    receive do
    {tweetid, userid, tweet, retweetflag, creatorid} -> IO.puts "#{name}:#{inspect(self())}++#{tweetid} from  @#{userid}:#{tweet} **#{retweetflag} #{creatorid}"
    {_} -> IO.puts "Unknown message"
    end
    client(name)
    end
    end
end
