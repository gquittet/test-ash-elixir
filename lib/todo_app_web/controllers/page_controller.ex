defmodule TodoAppWeb.PageController do
  use TodoAppWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    redirect(conn, to: ~p"/todo")
  end
end
