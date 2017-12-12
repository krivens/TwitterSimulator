defmodule TwitterServer do
  use GenServer
  @moduledoc """
  Documentation for TwitterProject4.
  """

  @doc """
  Hello world.

  ## Examples

      iex> TwitterProject4.hello
      :world

  """

  def main(args) do
    start_link(args)
  end

  def start_link(_opts) do
    start_server()
  end
  
  def start_server do
    Node.start("master@127.0.0.1" |> String.to_atom)
    setup_tables()
    #IO.puts(self())
    #receive do
    #  _ -> :init.stop()
    #end
  end

  defp setup_tables do
    :ets.new(:users, [:set, :public, :named_table])
    :ets.new(:user_servers, [:set, :public, :named_table])
    :ets.new(:user_subscribers, [:bag, :public, :named_table])
    :ets.new(:user_mailbox, [:bag, :public, :named_table])
    :ets.new(:user_tweet_counter, [:set, :public, :named_table])
    :ets.new(:tweet_table, [:set, :public, :named_table])
    :ets.new(:hashtag_table, [:bag, :public, :named_table])
    :ets.new(:mentions_table, [:bag, :public, :named_table])
  end
end
