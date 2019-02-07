#---
# Title        : Assignment - 4.2
# Subject      : Distributed And Operating Systems Principles
# Team Members : Noopur R K
# File name    : main.ex
#---

defmodule Bitcoin.Main do
  alias Bitcoin.Client
  alias Bitcoin.Miner
@moduledoc """
This module is responsible for starting the simulation of the bitcoin transactions.
"""
  def letsMineThoseCoins(client_list, miner_list, timeInterval) do
    Task.async(fn -> simulate(client_list, miner_list, timeInterval) end)
  end

  def initialiseNodes() do
    client_list = Enum.map(1..80, fn x -> Client.createWallet() end)
    miner_list = Enum.map(1..20, fn x -> Miner.createMiner() end)

    Enum.each(client_list, fn x ->
      result = List.delete(client_list, x)
      GenServer.cast(x,{:setPeersTable, result,miner_list})
    end)

    Enum.each(miner_list, fn x ->
      result = List.delete(miner_list, x)
      GenServer.cast(x,{:setMinersTable,result,result})
    end)

    {client_list, miner_list}
  end

  def simulate(client_list, miner_list, timeInterval) do

    miner = Enum.random(miner_list)
    sender_client = Enum.random(client_list)
    receiver_client = Enum.random(client_list)
    receiver_key = GenServer.call(receiver_client,{:fetchPublicKey}, 1000000)

    Client.createTransaction(sender_client, receiver_key, 10, miner)
    random_miner = Enum.random(miner_list)
    c = GenServer.call(random_miner,{:getBlockChainState}, 1000)

    IO.inspect c
    :timer.sleep(5000)
    simulate(client_list, miner_list, timeInterval)
  end

  def test() do

  end
end

