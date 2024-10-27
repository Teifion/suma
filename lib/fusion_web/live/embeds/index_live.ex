defmodule FusionWeb.Embeds.IndexLive do
  @moduledoc false
  use FusionWeb, :live_view

  alias Fusion.RAG.ContentLib

  @impl true
  def mount(_params, _session, socket) when is_connected?(socket) do
    socket
    |> assign(:site_menu_active, "embeds")
    |> assign(:search_term, "")
    |> get_contents
    |> ok
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:site_menu_active, "embeds")
     |> assign(:contents, [])}
  end

  @impl true
  def handle_event("update-search", %{"value" => search_term}, socket) do
    socket
    |> assign(:search_term, search_term)
    |> get_contents
    |> noreply
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @spec get_contents(Phoenix.Socket.t()) :: Phoenix.Socket.t()
  defp get_contents(%{assigns: assigns} = socket) do
    order_by =
      if assigns.search_term != "" do
        "Name (A-Z)"
      else
        "Newest first"
      end

    contents =
      ContentLib.list_contents(where: [name_like: assigns.search_term], order_by: order_by, limit: 50)

    socket
    |> assign(:contents, contents)
  end
end
