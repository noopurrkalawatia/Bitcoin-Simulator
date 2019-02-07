#---
# Title        : Assignment - 4.2
# Subject      : Distributed And Operating Systems Principles
# Team Members : Noopur R K
# File name    : router.ex
#---

defmodule MyBitcoinSimulatorWeb.Router do
  use MyBitcoinSimulatorWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyBitcoinSimulatorWeb do
    pipe_through :browser

    get "/", BitcoinSimulatorController, :index
    #get "/hello", HelloController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", MyBitcoinSimulatorWeb do
  #   pipe_through :api
  # end
end
