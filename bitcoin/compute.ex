#---
# Title        : Assignment - 4.2
# Subject      : Distributed And Operating Systems Principles
# Team Members : Noopur R K
# File name    : compute.ex
#---

defmodule Bitcoin.Compute do
  #alias Bitcoin.Miner
  @moduledoc """
  This module is responsible for passing the transaction count.
  """
  def computeTransBlock(blockchain) do
    noOfTransactions = Enum.reduce(blockchain, 0 ,fn t,accc -> accc+ length(t.transactions) end)
    noOfTransactions
  end

  def fetchBlockChain() do
    #minersList = GenServer.call
  end
end
