defmodule MyBitcoinSimulatorWeb.HelloController do
  use MyBitcoinSimulatorWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
