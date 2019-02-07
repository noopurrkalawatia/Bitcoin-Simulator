#---
# Title        : Assignment - 4.2
# Subject      : Distributed And Operating Systems Principles
# Team Members : Noopur R K
# File name    : room_channel.ex
#---

defmodule MyBitcoinSimulatorWeb.RoomChannel do
  use Phoenix.Channel
  alias Bitcoin.Compute

  def join("room:lobby", _message, socket) do
    {:ok, socket}
  end

  def join("room:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("new_msg", msg, socket) do
    push socket, "new_time", msg
    {:noreply, socket}
  end


  # def handle_in("new_msg", %{"body" => body}, socket) do
  #   #call the function here.
  #   toReturn = %{"blocks" => 4, "txn" => 2}
  #   broadcast!(socket, "test", %{body: toReturn})
  #   {:noreply, socket}
  # end
end
