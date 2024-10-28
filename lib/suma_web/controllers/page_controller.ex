defmodule SumaWeb.PageController do
  use SumaWeb, :controller

  def readme(conn, _params) do
    render(conn, :readme, site_menu_active: "readme")
  end
end
