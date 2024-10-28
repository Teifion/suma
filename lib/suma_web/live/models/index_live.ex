defmodule SumaWeb.Models.IndexLive do
  @moduledoc false
  use SumaWeb, :live_view

  alias Suma.RAG.ModelLib

  @impl true
  def mount(_params, _session, socket) when is_connected?(socket) do
    :ok = Suma.subscribe("Suma.Models")

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
  def handle_info(%{topic: "Suma.Models", event: :list_updated}, socket) do
    IO.puts ""
    IO.inspect "X", label: "#{__MODULE__}:#{__ENV__.line}"
    IO.puts ""

    socket
    |> get_models
    |> noreply
  end

  @impl true
  def handle_event("update-search", %{"value" => search_term}, socket) do
    socket
    |> assign(:search_term, search_term)
    |> get_models
    |> noreply
  end

  def handle_event("refresh-list", _, socket) do
    # Suma.RAG.ModelServer.refresh_list()
    ModelLib.cast_model_server(:refresh_list)

    socket
    |> noreply
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @spec get_models(Phoenix.Socket.t()) :: Phoenix.Socket.t()
  defp get_models(%{assigns: assigns} = socket) do
    models =
      ModelLib.list_models(where: [name_like: assigns.search_term], order_by: "Name (A-Z)", limit: 50)

    socket
    |> assign(:models, models)
  end
end
