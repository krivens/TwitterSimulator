defmodule TwitterClientSim do
    @moduledoc """
    Documentation for TwitterClient.
    """
  
    @doc """
    Hello world.
  
    ## Examples
  
        iex> TwitterClient.hello
        :world
  
    """
    def main(opts) do
      numclients = String.to_integer(Enum.at(opts,0))
      #skew = String.to_integer(Enum.at(opts,1))
      IO.puts "numclients #{numclients}"
      servernode = "server@127.0.0.1" |> String.to_atom
      clientnode = "client@127.0.0.1" |> String.to_atom
      Node.start(clientnode)
      Node.connect(servernode)
      generate_users(numclients, servernode)
    end

    def generate_users(numclients, servernode) do
      #generate the users as well as their number of subscribers, and from there the probability of subscribing to them
      maxsubscribers = div(numclients,round(:math.log2(numclients)))
      users = Enum.reduce(1..numclients, [], fn (clientnum, accumulator) ->
        userid = Integer.to_string(clientnum)
        noofsubscribers = div(maxsubscribers,clientnum)
        probofsubscription = noofsubscribers/numclients
        {:ok,pid} = TwitterClient.start(%{:userid=>userid, :rank=>clientnum, :servernode=>servernode, :simmode=>true})
        TwitterClient.register(pid)
        accumulator ++ [%{:userid=>userid, :rank=>clientnum, :pid=>pid, :probability=>probofsubscription}]
        end
        )
      #problist = Enum.reduce(users, [], fn(usermap) -> accumulator ++ [Map.get(usermap, :probability)])
      Enum.each(users, fn (usermap) -> 
        pid = Map.get(usermap, :pid)
        TwitterClient.login(pid)
        Enum.each(users, fn insidemap ->
          if((Map.get(usermap, :userid) != Map.get(insidemap, :userid)) && :rand.uniform() <= Map.get(insidemap, :probability)) do
            TwitterClient.subscribe(pid, Map.get(insidemap,:userid))
          end
        end)
      end)
      users
    end
  end
  