defmodule SumaWeb.Models.ShowLive do
  @moduledoc false
  use SumaWeb, :live_view

  alias Suma.RAG.ModelLib

  @impl true
  def mount(%{"model_name" => model_name}, _session, socket) when is_connected?(socket) do
    model = ModelLib.get_model_by_name!(model_name)

    socket =
      socket
      |> assign(:site_menu_active, "models")
      |> assign(:model, model)

    if socket.assigns.model do
      # :ok = PubSub.subscribe(user_topic(user_id))

      {:ok, socket}
    else
      {:ok, redirect(socket, to: ~p"/models")}
    end
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:site_menu_active, "models")
    |> assign(:model, nil)
    |> ok
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:edit_mode, true)
  end

  defp apply_action(socket, _, _params) do
    socket
    |> assign(:edit_mode, false)
  end

  @impl true
  def handle_info(
        %{topic: "Suma.Models.User:" <> _, event: :client_updated} = msg,
        socket
      ) do
    new_client = socket.assigns.client |> Map.merge(msg.changes)

    socket
    |> assign(:client, new_client)
    |> noreply
  end

  def handle_info(%{topic: "Suma.Models.User:" <> _}, socket) do
    socket
    |> noreply()
  end

  def handle_info(
        {SumaWeb.Models.UserFormComponent, {:updated_changeset, %{changes: _changes}}},
        socket
      ) do
    {:noreply, socket}
  end

  @impl true
  @spec handle_event(String.t(), map(), Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
  def handle_event("enable-model", _, socket) do
    if allow?(socket, ~w(admin)) do
      ModelLib.update_model(socket.assigns.model, %{enabled?: true})
      model = ModelLib.get_model!(socket.assigns.model.id)

      socket
      |> assign(:model, model)
      |> noreply
    else
      socket
      |> noreply
    end
  end

  def handle_event("disable-model", _, socket) do
    if allow?(socket, ~w(admin)) do
      ModelLib.update_model(socket.assigns.model, %{enabled?: false})
      model = ModelLib.get_model!(socket.assigns.model.id)

      socket
      |> assign(:model, model)
      |> noreply
    else
      socket
      |> noreply
    end
  end

  def handle_event("delete-model", _, socket) do
    if allow?(socket, ~w(admin)) do
      ModelLib.cast_model_server({:delete_model, socket.assigns.model.id})

      socket
      |> noreply
    else
      socket
      |> noreply
    end
  end
end
