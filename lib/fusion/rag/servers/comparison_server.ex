defmodule Fusion.RAG.ComparisonServer do
  @moduledoc """
  The GenServer used to track the state of an ongoing comparison
  """

  use FusionWeb, :server

  alias Fusion.RAG.{Completion, CompletionLib, ComparisonLib, EmbedLib, ModelLib}

  alias Fusion.RAG
  use GenServer
  defmodule State do
    @moduledoc false
    defstruct ~w(id completion key_difference variables topic responses awaiting_tasks await_ref currently_awaiting embeds)a
  end

  @new_embed_variables ~w(model_name user_prompt)a

  @impl true
  def handle_call(:get_completion, _from, state) do
    {:reply, state.completion, state}
  end

  def handle_call(:get_comparison_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:update_key_difference, new_key_difference}, state) do
    if Enum.member?(ComparisonLib.key_fields(), new_key_difference) do
      field = String.to_atom(new_key_difference)
      existing_value = Map.get(state.completion, field)

      state = struct(state, %{
        key_difference: field,
        variables: [existing_value]
      })

      # Do we need new embeds?
      state = if Enum.member?(@new_embed_variables, field) or Enum.empty?(state.embeds) do
        get_new_embeds(state)
      else
        state
      end

      Fusion.broadcast(state.topic, %{
        event: :new_key_difference,
        comparison_id: state.id,
        key_difference: state.key_difference,
        variables: state.variables,
      })

      send(self(), :generate_new_completions)

      state
    else
      state
    end
    |> noreply
  end

  def handle_cast({:add_new_variable, new_variable}, state) do
    if Enum.member?(state.variables, new_variable) do
      state
    else
      # If the new variable will need a new embed we need to generate a new one for it
      # before we can get a response
      state = case state.key_difference do
        :model_name ->
          model = ModelLib.get_model_by_name!(new_variable)
          embed = get_new_embed(state.completion.user_prompt, model)
          new_embed_map = state.embeds
            |> Map.put({state.completion.user_prompt, model.id}, embed)

          struct(state, %{embeds: new_embed_map})
        :user_prompt ->
          model = ModelLib.get_model_by_name!(state.completion.model_name)
          embed = get_new_embed(new_variable, model)
          new_embed_map = state.embeds
            |> Map.put({new_variable, model.id}, embed)

          struct(state, %{embeds: new_embed_map})
        _ ->
          state
      end

      get_response(state, new_variable)

      new_state = struct(state, %{
        variables: state.variables ++ [new_variable]
      })

      Fusion.broadcast(state.topic, %{
        event: :new_variable,
        variables: new_state.variables,
        comparison_id: state.id,
      })

      new_state
    end
    |> noreply
  end

  def handle_cast({:remove_variable, value}, state) do
    new_state = struct(state, %{
      variables: List.delete(state.variables, value),
      responses: Map.delete(state.responses, value)
    })

    Fusion.broadcast(state.topic, %{
      event: :removed_variable,
      value: value,
      variables: new_state.variables,
      comparison_id: state.id,
    })

    new_state
    |> noreply
  end


  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
    state
    |> noreply
  end

  def handle_info({ref, {:completion, variable_value, {:ok, response}}}, state) do
    new_state = struct(state, %{
      responses: Map.put(state.responses, variable_value, response)
    })

    Fusion.broadcast(state.topic, %{
      event: :new_response,
      comparison_id: state.id,
      variable_value: variable_value,
      response: response
    })

    new_state
    |> noreply
  end

  def handle_info(:generate_new_completions, %State{} = state) do
    tasks = state.variables
      |> Enum.map(fn variable_value ->
        get_response(state, variable_value)
      end)

    new_state = struct(state, %{
      responses: %{},
    })

    Fusion.broadcast(state.topic, %{
      event: :awaiting_completions,
      comparison_id: state.id,
    })

    {:noreply, new_state}
  end

  # Creates an async task
  defp get_response(%{completion: completion, key_difference: key_difference} = state, variable_value) do
    client = Ollama.init()

    # If vectors are supplied use them, if an embed is supplied use that otherwise
    # get the nearest embed vectors and use those
    # vectors = cond do
    #   opts[:vectors] != nil ->
    #     opts[:vectors]
    #   opts[:embed_id] != nil ->
    #     embed = RAG.EmbedLib.get_embed!(opts[:embed_id])
    #     embed.vectors |> Pgvector.to_list()
    #   true ->
    #     RAG.EmbedLib.get_nearest_embed_vectors(user_prompt, model, client)
    # end

    model = if key_difference == :model do
      RAG.ModelLib.get_model_by_name!(variable_value)
    else
      RAG.ModelLib.get_model_by_name!(state.completion.model_name)
    end

    user_prompt = if key_difference == :user_prompt do
      variable_value
    else
      completion.user_prompt
    end

    system_prompt = if key_difference == :system_prompt do
      variable_value
    else
      RAG.default_system_prompt()
    end

    vectors = if key_difference == :content do
      state.embeds[variable_value]
    else
      state.embeds[{user_prompt, model.id}]
    end
    |> Map.get(:vectors)
    |> Pgvector.to_list()

    final_prompt = RAG.format_prompt(user_prompt, vectors, system_prompt)

    Task.async(fn ->
      response = CompletionLib.get_response(
        model.name,
        final_prompt,
        client: client
      )

      {:completion, variable_value, response}
    end)
  end

  defp get_new_embeds(%{key_difference: :model_name} = state) do
    embed_map = state.variables
    |> Map.new(fn value ->
      model = RAG.ModelLib.get_model_by_name!(value)
      embed = get_new_embed(state.completion.user_prompt, model)

      {{state.completion.user_prompt, model.id}, embed}
    end)

    struct(state, %{
      embeds: embed_map
    })
  end

  defp get_new_embeds(%{key_difference: :user_prompt} = state) do
    model = RAG.ModelLib.get_model_by_name!(state.completion.model_name)

    embed_map = state.variables
    |> Map.new(fn value ->
      embed = get_new_embed(value, model)
      {{value, model.id}, embed}
    end)

    struct(state, %{
      embeds: embed_map
    })
  end

  defp get_new_embed(user_prompt, model_name) do
    EmbedLib.get_nearest_embed(user_prompt, model_name, Ollama.init())
  end

  @doc false
  @spec start_link(list) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:data], [])
  end

  @impl true
  @spec init(map) :: {:ok, map}
  def init(%{params: params} = args) do
    # :timer.send_interval(@heartbeat_frequency_ms, :heartbeat)
    id = args[:id] || Fusion.uuid()

    Registry.register(
      Fusion.LocalComparisonRegistry,
      id,
      id
    )

    {:ok, completion} = %Completion{}
      |> Completion.changeset(params)
      |> Ecto.Changeset.apply_action(:save)


    if args[:id_callback] do
      send(args[:id_callback], {:comparison_started, id})
    end

    state = %State{
      id: id,
      topic: ComparisonLib.comparison_topic(id),
      completion: completion,
      key_difference: nil,
      variables: [],
      responses: %{},
      awaiting_tasks: [],
      currently_awaiting: nil,
      await_ref: nil,
      embeds: %{}
    }

    {:ok, state}
  end
end
