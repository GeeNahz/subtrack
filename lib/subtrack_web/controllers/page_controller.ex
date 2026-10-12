defmodule SubtrackWeb.PageController do
  use SubtrackWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
