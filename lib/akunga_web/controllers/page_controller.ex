defmodule AkungaWeb.PageController do
  use AkungaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
