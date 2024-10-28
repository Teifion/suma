defmodule Suma.RAG.ComparisonServer do
  @moduledoc """
  The GenServer used to track the state of an ongoing comparison
  """

  use SumaWeb, :server

  alias Suma.RAG.{Completion, CompletionLib, ComparisonLib, EmbedLib, ModelLib, ContentLib}

  alias Suma.RAG
  use GenServer
  defmodule State do
    @moduledoc false
    defstruct ~w(id completion key_difference variables topic responses embeds contents)a
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
      # state = if Enum.member?(@new_embed_variables, field) or Enum.empty?(state.embeds) do
      #   request_new_embeds(state)
      # else
      #   state
      # end

      state = if Enum.member?(@new_embed_variables, field) or Enum.empty?(state.contents) do
        request_new_contents(state)
      else
        state
      end

      Suma.broadcast(state.topic, %{
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
      case state.key_difference do
        :model_name ->
          model = ModelLib.get_model_by_name!(new_variable)
          # request_new_embed(state.completion.user_prompt, model, new_variable)
          request_new_content(state.completion.user_prompt, model, new_variable)
        :user_prompt ->
          model = ModelLib.get_model_by_name!(state.completion.model_name)
          # request_new_embed(new_variable, model, new_variable)
          request_new_content(new_variable, model, new_variable)
        _ ->
          :ok
      end

      # get_response(state, new_variable)

      new_state = struct(state, %{
        variables: state.variables ++ [new_variable]
      })

      Suma.broadcast(state.topic, %{
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

    Suma.broadcast(state.topic, %{
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

  # def handle_info({ref, {:new_embed, key, variables, result}}, state) do
  #   new_embeds = Map.put(state.embeds, key, result)

  #   state = state
  #   |> struct(%{embeds: new_embeds})

  #   variables
  #   |> Enum.each(fn v ->
  #     get_response(state, v)
  #   end)

  #   state
  #   |> noreply
  # end

  def handle_info({ref, {:new_content, key, variables, result}}, state) do
    new_contents = Map.put(state.contents, key, result)

    state = state
    |> struct(%{contents: new_contents})

    variables
    |> Enum.each(fn v ->
      get_response(state, v)
    end)

    state
    |> noreply
  end

  def handle_info({ref, {:completion, variable_value, {:ok, response}}}, state) do
    new_state = struct(state, %{
      responses: Map.put(state.responses, variable_value, response)
    })

    Suma.broadcast(state.topic, %{
      event: :new_response,
      comparison_id: state.id,
      variable_value: variable_value,
      response: response
    })

    new_state
    |> noreply
  end

  def handle_info(:generate_new_completions, %State{} = state) do
    _tasks = state.variables
      |> Enum.map(fn variable_value ->
        # # Do we need to generate an embed?
        # if get_existing_embed(state, variable_value) == nil do
        #   nil
        # else
        #   get_response(state, variable_value)
        # end

        # Do we need to generate a content?
        if get_existing_content(state, variable_value) == nil do
          nil
        else
          get_response(state, variable_value)
        end
      end)

    new_state = struct(state, %{
      responses: %{},
    })

    Suma.broadcast(state.topic, %{
      event: :awaiting_completions,
      comparison_id: state.id,
    })

    {:noreply, new_state}
  end

  # Creates an async task
  @spec get_response(State.t(), any()) :: Task.t()
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

    # Using the vectors in the prompt, I may have misread the docs....
    # vectors = if key_difference == :content do
    #   state.embeds[variable_value]
    # else
    #   embed = state.embeds[{user_prompt, model.id}]
    #   if embed == :none do
    #     %{vectors: Pgvector.new([])}
    #   else
    #     embed
    #   end
    # end
    # |> Map.get(:vectors)
    # |> Pgvector.to_list()

    embed_content = if key_difference == :content do
      state.contents[variable_value]
    else
      state.contents[{user_prompt, model.id}]
    end

    final_prompt = RAG.format_prompt(user_prompt, embed_content, system_prompt)

    Task.async(fn ->
      response = CompletionLib.get_response(
        model.name,
        final_prompt,
        client: client
      )

      {:completion, variable_value, response}
    end)
  end

  # defp get_existing_embed(%{key_difference: :model_name} = state, value) do
  #   model = RAG.ModelLib.get_model_by_name!(value)
  #   state.embeds[{state.completion.user_prompt, model.id}]
  # end

  # defp get_existing_embed(%{key_difference: :user_prompt} = state, value) do
  #   model = RAG.ModelLib.get_model_by_name!(state.completion.model_name)
  #   state.embeds[{value, model.id}]
  # end

  # defp get_existing_embed(state, _value) do
  #   model = RAG.ModelLib.get_model_by_name!(state.completion.model_name)
  #   state.embeds[{state.completion.user_prompt, model.id}]
  # end

  # defp request_new_embeds(%{key_difference: :model_name} = state) do
  #   embed_map = state.variables
  #   |> Enum.each(fn value ->
  #     model = RAG.ModelLib.get_model_by_name!(value)
  #     request_new_embed(state.completion.user_prompt, model, value)
  #   end)

  #   struct(state, %{
  #     embeds: %{}
  #   })
  # end

  # defp request_new_embeds(%{key_difference: :user_prompt} = state) do
  #   model = RAG.ModelLib.get_model_by_name!(state.completion.model_name)

  #   embed_map = state.variables
  #   |> Enum.each(fn value ->
  #     request_new_embed(value, model, value)
  #   end)

  #   struct(state, %{
  #     embeds: %{}
  #   })
  # end

  # defp request_new_embed(user_prompt, model, variables) do
  #   Task.async(fn ->
  #     embed_result = EmbedLib.get_nearest_embed(user_prompt, model, Ollama.init())

  #     {:new_embed, {user_prompt, model.id}, List.wrap(variables), embed_result}
  #   end)
  # end

  defp get_existing_content(%{key_difference: :model_name} = state, value) do
    model = RAG.ModelLib.get_model_by_name!(value)
    state.contents[{state.completion.user_prompt, model.id}]
  end

  defp get_existing_content(%{key_difference: :user_prompt} = state, value) do
    model = RAG.ModelLib.get_model_by_name!(state.completion.model_name)
    state.contents[{value, model.id}]
  end

  defp get_existing_content(state, _value) do
    model = RAG.ModelLib.get_model_by_name!(state.completion.model_name)
    state.contents[{state.completion.user_prompt, model.id}]
  end

  defp request_new_contents(%{key_difference: :model_name} = state) do
    content_map = state.variables
    |> Enum.each(fn value ->
      model = RAG.ModelLib.get_model_by_name!(value)
      request_new_content(state.completion.user_prompt, model, value)
    end)

    struct(state, %{
      contents: %{}
    })
  end

  defp request_new_contents(%{key_difference: :user_prompt} = state) do
    model = RAG.ModelLib.get_model_by_name!(state.completion.model_name)

    content_map = state.variables
    |> Enum.each(fn value ->
      request_new_content(value, model, value)
    end)

    struct(state, %{
      contents: %{}
    })
  end

  defp request_new_content(user_prompt, model, variables) do
    Task.async(fn ->
      embed = EmbedLib.get_nearest_embed(user_prompt, model, Ollama.init())

      content_result = if embed do
        content_object = ContentLib.get_content!(embed.content_id)
        |> Map.get(:text)
      else
        ""
      end

      {:new_content, {user_prompt, model.id}, List.wrap(variables), content_result}
    end)
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
    id = args[:id] || Suma.uuid()

    Registry.register(
      Suma.LocalComparisonRegistry,
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
      embeds: %{},
      contents: %{}
    }

    {:ok, state}
  end
end
