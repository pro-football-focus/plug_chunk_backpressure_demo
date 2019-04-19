defmodule ChunkBackpressureDemoWeb.Router do
  use ChunkBackpressureDemoWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ChunkBackpressureDemoWeb do
    pipe_through :api

    get "/flood", DemoController, :flood
    get "/backpressure", DemoController, :backpressure
  end
end
