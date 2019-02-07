#---
# Title        : Assignment - 4.2
# Subject      : Distributed And Operating Systems Principles
# Team Members : Noopur R K
# File name    : myBitcoinSimulator_controller.ex
#---

defmodule MyBitcoinSimulatorWeb.BitcoinSimulatorController do
  use MyBitcoinSimulatorWeb, :controller
@moduledoc """
This module is the main controller which begins the simulation of the
Bitcoin mining and transaction.
"""
  #alias Bitcoin.Main
  def index(conn, _params) do
    {client_list, miner_list} = Bitcoin.Main.initialiseNodes()
    Bitcoin.Main.letsMineThoseCoins(client_list, miner_list, 10)
    conn
    |> assign(:peer_count, 100)
    #|> render("index.html")
    render(conn, "index.html")
  end
end
