defmodule SumaWeb.Contents.ShowLive do
  @moduledoc false
  use SumaWeb, :live_view

  alias Suma.RAG

  # def x do
  #   id = "542aca8a-822c-4c9d-bc69-5cf372c667c4"
  #   model_name = "llama3.2:latest"
  #   batch_create_embeds(model_name, contents)
  # end

  @impl true
  def mount(%{"id" => id}, _session, socket) when is_connected?(socket) do
    content = RAG.get_content!(id)
    models = RAG.list_model_embeds_for_content(id)

    socket =
      socket
      |> assign(:site_menu_active, "contents")
      |> assign(:content, content)
      |> assign(:models, models)
      |> assign(:updating, [])

    if socket.assigns.content do
      # :ok = PubSub.subscribe(user_topic(user_id))

      {:ok, socket}
    else
      {:ok, redirect(socket, to: ~p"/contents")}
    end
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:site_menu_active, "contents")
    |> assign(:content, nil)
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
        %{topic: "Suma.Contents.User:" <> _, event: :client_updated} = msg,
        socket
      ) do
    new_client = socket.assigns.client |> Map.merge(msg.changes)

    socket
    |> assign(:client, new_client)
    |> noreply
  end

  def handle_info(%{topic: "Suma.Contents.User:" <> _}, socket) do
    socket
    |> noreply()
  end

  def handle_info(
        {SumaWeb.Contents.UserFormComponent, {:updated_changeset, %{changes: _changes}}},
        socket
      ) do
    {:noreply, socket}
  end

  @impl true
  @spec handle_event(String.t(), map(), Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
  def handle_event("create-embed", %{"model_id" => model_id}, socket) do
    model = Suma.RAG.get_model!(model_id)
    Suma.RAG.ModelServer.generate_embed(model, socket.assigns.content)

    new_updating = socket.assigns.updating ++ [model_id]

    socket
    |> assign(:updating, new_updating)
    |> noreply
  end
end
