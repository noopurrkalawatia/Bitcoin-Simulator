
#---
# Title        : Assignment - 4.2
# Subject      : Distributed And Operating Systems Principles
# Team Members : Noopur R K
# File name    : miner.ex
#---
defmodule Bitcoin.Miner do
  alias Bitcoin.Utility
  use GenServer
@moduledoc """

"""
  def createMiner() do
    {:ok,pid} = GenServer.start_link(__MODULE__,:ok)
    pid
  end

  @doc """
  Init function.
  Miner will have blockchain, publickey, privatekey, pendingTransactions(which will be empty when created)
  publickey and privatekey are generated from helper method
  """
  def init(:ok) do
    {publicKey, privateKey} = Utility.generateKeys()
    {:ok, {[],publicKey,privateKey,[],[],[]}}
  end

  def handle_call({:getBlockChainState}, _from, state) do
    {blockchain, publickey, privatekey, pendingTransactions,minersTable,peersTable}=state
    {:reply, blockchain, state}
  end

  def handle_call({:getMiners},_from,state)do
    {blockchain, publickey, privatekey, pendingTransactions,minersTable,peersTable}=state
    {:reply,minersTable,state}
  end

  def handle_call({:fetchPendingTransactions},_from,state) do
    {_,_,_, pendingTransactions,_,_}=state
    {:reply,pendingTransactions,state}
  end

  def handle_call({:mine},_from,state) do
    {blockchain, publicKey, privateKey, pendingTransactions,minersTable,peersTable} = state

    validPendingTransactions = Enum.filter(pendingTransactions,fn x -> checkTrasactionValidity(x,blockchain) == true end)
    blockchain =
    if validPendingTransactions == [] do
      blockchain
    else
      rewardCoins = 100
      rewardCoins

      #Miner adds only valid transactions to the block
      hashValue = Utility.computeHashValue(["",publicKey,rewardCoins,0])
      rewardTransaction = %{
        :senderPublicAddress => "",
        :receiverPublicKey => publicKey,
        :transactionHash => hashValue,
        :coins => rewardCoins,
        :signature => :crypto.sign(:ecdsa,:sha256,hashValue,[privateKey, :secp256k1]),
      }
      validPendingTransactions=validPendingTransactions++[rewardTransaction]

      computedMinedBlock = %{}

      #Get the previous block from the blockchain
      previousHashValue =
      if blockchain == [] do
        :crypto.hash(:sha256,'initialHash') |> Base.encode16
      else
        previousBlock = Enum.at(blockchain, -1)
        previousBlock[:currentHash]
      end

      #Update the previous hash
      computedMinedBlock = Map.put(computedMinedBlock ,:previousHashValue,previousHashValue)

      #update all the transactions
      computedMinedBlock = Map.put(computedMinedBlock , :transactions,validPendingTransactions)

      #Call the miner and get the correct hash and nonce
      #toEncrypt=validPendingTransactions++[previousHash]
      toEncrypt = Enum.map(validPendingTransactions,fn x ->
        Enum.map(x,fn {_,v} -> v end)
      end)
      toEncrypt = toEncrypt++[previousHashValue]
      {currentHash,nonce} = proofOfWork(toEncrypt,"0")

      computedMinedBlock   = Map.put(computedMinedBlock, :currentHash, currentHash)
      computedMinedBlock   = Map.put(computedMinedBlock, :nonce, nonce)
      computedMinedBlock   = Map.put(computedMinedBlock, :timestamp, :os.system_time(:millisecond))

      #Add the mined block to the blockchain
      blockchain=blockchain++[computedMinedBlock]
      blockchain
    end

    Enum.each(peersTable,fn x->GenServer.cast(x,{:setBlockChain,blockchain})end)
    answer = computeTransBlock(blockchain)
    broadcast(answer,"transaction")

    state={blockchain, publicKey, privateKey, [],minersTable,peersTable}
    {:reply,blockchain,state}
  end

  def handle_cast({:setMinersTable,minersTable,peersTable},state) do
    {blockchain, publicKey, privateKey, pendingTransactions,minersTable,peersTable} = state
    minersTable  = minersTable
    peersTable = peersTable
    state = {blockchain, publicKey, privateKey, pendingTransactions,minersTable,peersTable}
    {:noreply,state}
  end

    @doc """
  Adds a transaction to pending transactions array
  """
  def handle_cast({:addParticularTransaction,transaction},state) do
    {blockchain, publicKey, privateKey, pendingTransactions,minersTable,peersTable} = state
    currentTransaction = pendingTransactions
    currentTransaction = currentTransaction++[transaction]
    pendingTransactions = currentTransaction
    state = {blockchain, publicKey, privateKey, pendingTransactions,minersTable,peersTable}
    {:noreply,state}
  end

  def addParticularTransaction(p,transaction) do
    GenServer.cast(p,{:addParticularTransaction,transaction})
  end

  def fetchPendingTransactions(p) do
    GenServer.call(p,{:fetchPendingTransactions})
  end

  def mine(p) do
    GenServer.call(p,{:mine})
  end

  def checkTrasactionValidity(transaction,blockchain) do
    IO.inspect transaction[:transactionHash]
    IO.inspect transaction[:signature]
    IO.inspect transaction[:senderPublicAddress]
    verifyHashValue=:crypto.verify(
      :ecdsa,
      :sha256,
      transaction[:transactionHash],
      transaction[:signature],
      [transaction[:senderPublicAddress], :secp256k1]
    )
    #Assume every client has initial balance of 15 coins
    initialBalance = 15
    balanceVerify =
    if blockchain == [] do
      true
      #initialBalance >= transaction[:coins]

    else
      #Fetch the number of coins sender has sent
      #From every block we are going to fetch the particular transaction and
      #Find the number of queries as mentioned in the query/transaction
      senderCurrentCoins=
      try do
        Enum.reduce(blockchain, 0 ,fn block ,accumulateTransactions->
          accumulateTransactions + Enum.reduce(block.transactions, 0,fn particularTransaction,acc ->
          cond do
            particularTransaction.senderPublicAddress  == transaction[:senderPublicAddress] -> acc + particularTransaction.coins
            true -> acc
          end
          end)
        end)
      rescue
        _ in Enum.EmptyError -> 0
      end

      #Fetch the number of coins sender has received
      receivedCoins=
      try do
        Enum.reduce(blockchain, 0 ,fn block,accumulateTransactions->
          accumulateTransactions + Enum.reduce(block.transactions, 0,fn particularTransaction,acc ->
          cond do
            particularTransaction.receiverPublicKey  == transaction[:senderPublicAddress] -> acc + particularTransaction.coins
            true -> acc
          end
          end)
        end)
      rescue
        _ in Enum.EmptyError -> 0
      end
      #Add the initial amount of coins
      receivedCoins = receivedCoins + initialBalance

      # True if receivedCoins is more than sent, false otherwise
      receivedCoins >= senderCurrentCoins + transaction[:coins]
    end
    #IO.inspect balanceVerify
    balanceVerify && verifyHashValue
  end

  def proofOfWork(data, nonce) do
    nonceInt = String.to_integer(nonce)
    temp = :crypto.hash(:sha256, [nonce, data]) |> Base.encode16
    if(String.slice(temp,0,4) === String.duplicate("0",4)) do
        {temp,nonce}
    else
        proofOfWork(data, Integer.to_string(nonceInt+1))
    end
  end

  def checkBlockchainValidity(chain) do
    Enum.reduce(Enum.slice(chain, 1, length(chain)), true, fn block, acc ->
      previous = Enum.at(chain, Enum.find_index(chain, fn k -> block == k end) - 1)
      cond do
        getNewHash(block)!= block.currentHash -> acc and false
        block.previousHash != previous.currentHash -> acc and false
        true -> acc and true
      end
    end)
  end

  def getNewHash(block) do
    encryptTransactions = Enum.map(block.transactions,fn particularTransaction ->
        Enum.map(particularTransaction,fn {_,v} -> v end)
      end)
      encryptTransactions = encryptTransactions++[block.previousHash]
      {currentHash,nonce} = proofOfWork(encryptTransactions,"0")
      currentHash
  end

  defp broadcast(time, response) do
    :timer.sleep(200)
    MyBitcoinSimulatorWeb.Endpoint.broadcast! "room:lobby", "new_msg", %{
      response: response,
      time: time,
    }
  end

  def computeTransBlock(blockchain) do
    noOfTransactions = Enum.reduce(blockchain, 0 ,fn t,accc -> accc+ length(t.transactions) end)
    noOfTransactions
  end


end
