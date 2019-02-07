#---
# Title        : Assignment - 4.2
# Subject      : Distributed And Operating Systems Principles
# Team Members : Noopur R K
# File name    : client.ex
#---

defmodule Bitcoin.Client do
    use GenServer
    alias Bitcoin.Utility
    alias Bitcoin.Miner
@moduledoc """
This module contains the implementation of the client and the functionalities of the same.
"""
    def createWallet() do
        {:ok,pid}=GenServer.start_link(__MODULE__, :ok,[])
        pid
    end

    def init(:ok) do
        {public_key, private_key} = :crypto.generate_key(:ecdh, :secp256k1)
        {:ok, {public_key, private_key, "", "", 0, "",[],[],[]}}
    end

    def handle_call({:getTransactionParticulars}, _from, state) do
        {publicKeyState, privateKeyState, recieverState, signatureState, currencyState, timestampState,peersTable, minersTable, blockchain} = state
        {:reply, {publicKeyState, privateKeyState, recieverState, signatureState, currencyState, timestampState,peersTable, minersTable, blockchain}, state}
    end

    def handle_call({:fetchPublicKey}, _from, state) do
        {publicKeyState, privateKeyState, recieverState, signatureState, currencyState, timestampState,peersTable, minersTable, blockchain} = state
        {:reply, publicKeyState, state}
    end

    def handle_cast({:updatePIDState, receiverPublicAddress, coins, timestampOfTransaction}, state) do
        {publicKeyState, privateKeyState, recieverState, signatureState, currencyState, timestampState,peersTable, minersTable, blockchain} = state
        recieverState = receiverPublicAddress
        currencyState = coins
        timestampState = timestampOfTransaction
        state = {publicKeyState, privateKeyState, recieverState, signatureState, currencyState, timestampState,peersTable, minersTable, blockchain}
        {:noreply, state}
    end

    def handle_cast({:setBlockChain,blockchain},state)do
        {publicKeyState, privateKeyState, recieverState, signatureState, currencyState, timestampState,peersTable, minersTable, blockchain} = state
        #check the validity of the transaction
        result = Miner.checkBlockchainValidity(blockchain)
        if result do
            blockchain = blockchain
        end
        state = {publicKeyState, privateKeyState, recieverState, signatureState, currencyState, timestampState,peersTable, minersTable, blockchain}
    end

    def handle_cast({:setPeersTable,peersTable,minersTable},state) do
        {publicKeyState, privateKeyState, recieverState, signatureState, currencyState, timestampState,peersTable, minersTable, blockchain} = state
        peersTable = peersTable
        minersTable = minersTable
        state = {publicKeyState, privateKeyState, recieverState, signatureState, currencyState, timestampState,peersTable, minersTable, blockchain}
        {:noreply, state}
    end

    def handle_cast({:set_signature, signature}, state) do
        {publicKeyState, privateKeyState, recieverState, signatureState, currencyState, timestampState,peersTable, minersTable, blockchain} = state
        signatureState = signature
        state = {publicKeyState, privateKeyState, recieverState, signatureState, currencyState, timestampState,peersTable, minersTable, blockchain}
        {:noreply, state}
    end

    def createTransaction(pid, receiver, coins,miner) do
        timestampOfTransaction = Integer.to_string(:os.system_time(:millisecond))
        GenServer.cast(pid, {:updatePIDState, receiver, coins, timestampOfTransaction})
        transactionHashValue = signTransaction(pid)
        {publicKeyState, privateKeyState, recieverState, signatureState, currencyState, timestampState,peersTable, minersTable, blockchain} = getTransactionParticulars(pid)
        transaction = %{:senderPublicAddress => publicKeyState, :receiverPublicKey => recieverState, :transactionHash => transactionHashValue,
            :coins => currencyState, :signature => signatureState}
        Miner.addParticularTransaction(miner,transaction)
        Miner.mine(miner)
    end

    def computeHashValue(keys) do
        hash = Utility.computeHashValue(keys)
        hash
    end

    def signTransaction(pid) do
        {publicKeyState, privateKeyState, recieverState, signatureState, currencyState, timestampState,peersTable, minersTable, blockchain} = getTransactionParticulars(pid)
        transactionHashValue = computeHashValue([publicKeyState, recieverState, currencyState, timestampState])
        signature=
            :crypto.sign(
                :ecdsa,
                :sha256,
                transactionHashValue,
                [privateKeyState, :secp256k1]
            )
        GenServer.cast(pid, {:set_signature, signature})
        transactionHashValue
    end

    def getTransactionParticulars(pid) do
        GenServer.call(pid, {:getTransactionParticulars})
    end
end
