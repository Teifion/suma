defmodule FusionWeb.PageController do
  use FusionWeb, :controller

  def readme(conn, _params) do
    render(conn, :readme, site_menu_active: "readme")
  end
end
