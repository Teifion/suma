defmodule SumaWeb.Embeds.NewLive do
  @moduledoc false
  use SumaWeb, :live_view

  alias Suma.RAG.ModelLib

  @impl true
  def mount(_params, _session, socket) when is_connected?(socket) do
    models = ModelLib.list_models(order_by: ["Name (A-Z)"])

    existing_names = models
    |> Enum.map(&(&1.name))

    popular_models = ModelLib.popular_models()
    |> Enum.reject(fn model -> model in existing_names end)

    socket
      |> assign(:popular_models, popular_models)
      |> assign(:site_menu_active, "embeds")
      |> assign(:models, models)
      |> assign(:state, :waiting)
      |> ok
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:site_menu_active, "embeds")
      |> assign(:state, :loading)
    |> ok
  end

  @impl true
  @spec handle_event(String.t(), map(), Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
  def handle_event("quick-get-model", %{"model_name" => model_name}, socket) do
    socket
    |> do_get_model(model_name)
    |> noreply
  end

  def handle_event("form-get-model", %{"model_name" => model_name}, socket) do
    socket
    |> do_get_model(model_name)
    |> noreply
  end

  defp do_get_model(socket, model_name) do
    # Now to make it actually pull the model down!

    socket
    |> assign(:state, :downloading)
  end
end
