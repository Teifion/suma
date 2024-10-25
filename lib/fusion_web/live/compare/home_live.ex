defmodule FusionWeb.CompareLive.Home do
  use FusionWeb, :live_view

  alias Fusion.RAG
  alias Fusion.RAG.{Completion, ModelLib}

  @impl true
  def mount(_params, _session, socket) when is_connected?(socket) do
    completion = struct(%Completion{}, default_completion_opts())

    socket
    |> assign(:client, Ollama.init())
    |> assign(:embed_name, nil)
    |> assign(:completion, completion)
    # |> update_nearest_embed
    |> ok
  end

  def mount(_params, _session, socket) do
    socket
    |> ok
  end

  def handle_info({:comparison_started, id}, socket) do
    socket
    |> redirect(to: ~p"/compare/#{id}")
    |> noreply()
  end

  @impl true
  def handle_info(
        {FusionWeb.RAG.CompletionComponent, {:updated_changeset, %{changes: changes}}},
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
      model_name: "llama3.2",
      user_prompt: "What is the best type of Triangle?",
      system_prompt: RAG.default_system_prompt()
    }
  end

  defp update_nearest_embed(%{assigns: %{completion: completion, client: client}} = socket, new_prompt) do
    prompt = new_prompt || completion.prompt
    model = ModelLib.get_model_by_name!(completion.model_name)

    embed = Fusion.RAG.EmbedLib.get_nearest_embed(prompt, model, client)
    content = Fusion.RAG.ContentLib.get_content!(embed.content_id)

    socket
    |> assign(:content_name, content.name)
  end
end
