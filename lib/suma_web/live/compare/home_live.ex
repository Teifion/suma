defmodule SumaWeb.CompareLive.Home do
  use SumaWeb, :live_view

  alias Suma.RAG
  alias Suma.RAG.{Completion, ModelLib}

  @impl true
  def mount(_params, _session, socket) when is_connected?(socket) do
    completion = struct(%Completion{}, default_completion_opts())
    model_names = ModelLib.list_active_model_names()

    socket
    |> assign(:model_names, model_names)
    |> assign(:client, Ollama.init())
    |> assign(:embed_name, nil)
    |> assign(:completion, completion)
    |> assign(:site_menu_active, "compare")
    |> ok
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:model_names, [])
    |> ok
  end

  def handle_info({:comparison_started, id}, socket) do
    socket
    |> redirect(to: ~p"/compare/#{id}")
    |> noreply()
  end

  @impl true
  def handle_info(
        {SumaWeb.RAG.CompletionComponent, {:updated_changeset, %{changes: changes}}},
        socket
      ) do

    if Map.has_key?(changes, :prompt) do
      update_nearest_embed(socket, changes.prompt)
      |> noreply
    else
      socket
      |> noreply
    end
  end

  defp default_completion_opts() do
    %{
      model_name: "llama3.2:latest",
      user_prompt: "What animals are llamas related to?",
      system_prompt: RAG.default_system_prompt()
    }
  end

  defp update_nearest_embed(%{assigns: %{completion: completion, client: client}} = socket, new_prompt) do
    prompt = new_prompt || completion.prompt
    model = ModelLib.get_model_by_name!(completion.model_name)

    embed = Suma.RAG.EmbedLib.get_nearest_embed(prompt, model, client)
    content = Suma.RAG.ContentLib.get_content!(embed.content_id)

    socket
    |> assign(:content_name, content.name)
  end
end
