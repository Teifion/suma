defmodule FusionWeb.Admin.Models.IndexLive do
  @moduledoc false
  use FusionWeb, :live_view

  alias Fusion.RAG.ModelLib

  @impl true
  def mount(_params, _session, socket) when is_connected?(socket) do
    socket
    |> assign(:site_menu_active, "models")
    |> assign(:search_term, "")
    |> get_models
    |> ok
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:site_menu_active, "models")
     |> assign(:models, [])}
  end

  @impl true
  def handle_event("update-search", %{"value" => search_term}, socket) do
    socket
    |> assign(:search_term, search_term)
    |> get_models
    |> noreply
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @spec get_models(Phoenix.Socket.t()) :: Phoenix.Socket.t()
  defp get_models(%{assigns: assigns} = socket) do
    order_by =
      if assigns.search_term != "" do
        "Name (A-Z)"
      else
        "Newest first"
      end

    models =
      ModelLib.list_models(where: [name_like: assigns.search_term], order_by: order_by, limit: 50)

    socket
    |> assign(:models, models)
  end
end
