defmodule Suma.RAG.ComparisonLib do
  @moduledoc """

  """

  # alias Suma.RAG.Comparison

  def key_fields do
    ~w(model_name user_prompt system_prompt)
  end

  @spec comparison_topic(Comparison.id()) :: String.t()
  def comparison_topic(comparison_id) do
    "Suma.Comparison:#{comparison_id}"
  end

  @spec start_comparison_server(map()) :: {:ok, pid()} | {:error, String.t()}
  def start_comparison_server(params) do
    {:ok, pid} = DynamicSupervisor.start_child(Suma.ComparisonSupervisor, {
      Suma.RAG.ComparisonServer,
      name: "comparison_#{Suma.uuid()}",
      data: %{
        params: params,
        id_callback: self()
      }
    })
  end

  def update_key_difference(id, new_key_difference) do
    cast_comparison(id, {:update_key_difference, new_key_difference})
  end

  def add_new_variable(id, new_variable) do
    cast_comparison(id, {:add_new_variable, new_variable})
  end

  def remove_variable(id, value) do
    cast_comparison(id, {:remove_variable, value})
  end

  # @spec send_keepalive(Comparison.id()) :: :ok | nil
  # def send_keepalive(comparison_id) do
  #   cast_comparison(comparison_id, :keepalive)
  # end

  # @doc """
  # Subscribes the process to comparison updates for this user
  # """
  # @spec subscribe_to_comparison(Comparison.id()) :: :ok
  # def subscribe_to_comparison(comparison_id) do
  #   comparison_id
  #   |> comparison_topic()
  #   |> Suma.subscribe()
  # end

  # @doc """
  # Unsubscribes the process to comparison updates for this user
  # """
  # @spec unsubscribe_from_comparison(Comparison.id()) :: :ok
  # def unsubscribe_from_comparison(comparison_id) do
  #   comparison_id
  #   |> comparison_topic()
  #   |> Suma.unsubscribe()
  # end

  @doc """

  """
  @spec get_comparison(Comparison.id()) :: Comparison.t() | nil
  def get_comparison(id) when is_binary(id) do
    call_comparison(id, :get_comparison_state)
  end

  @doc """

  """
  @spec get_comparison_map(Comparison.id()) :: RAG.ComparisonMap.t() | nil
  def get_comparison_map(id) when is_binary(id) do
    call_comparison(id, :get_comparison_map)
  end

  @doc """

  """
  @spec get_players(Comparison.id()) :: RAG.ComparisonMap.t() | nil
  def get_players(id) when is_binary(id) do
    call_comparison(id, :get_players)
  end

  @doc """

  """
  @spec get_comparison_attribute(Comparison.id(), atom()) :: any()
  def get_comparison_attribute(comparison_id, key) do
    call_comparison(comparison_id, {:get_comparison_attribute, key})
  end

  @doc """

  """
  @spec list_local_comparison_ids :: [Comparison.id()]
  def list_local_comparison_ids() do
    Registry.select(Suma.LocalComparisonRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  @doc """

  """
  @spec lookup_id(Comparison.id(), String.t()) :: Ecto.UUID.t() | nil
  def lookup_id(comparison_id, name) do
    call_comparison(comparison_id, {:lookup, name})
  end

  @doc """

  """
  @spec get_lookup_table(Comparison.id()) :: map() | nil
  def get_lookup_table(comparison_id) do
    call_comparison(comparison_id, :lookup_table)
  end

  @doc """
  Adds a player to the comparison
  """
  @spec add_player_to_comparison(Suma.user_id(), Comparison.id()) :: :ok | {:error, String.t()}
  def add_player_to_comparison(user_id, comparison_id) do
    cast_comparison(comparison_id, {:add_player, user_id})
  end

  @doc """
  Adds a player to the comparison
  """
  @spec remove_player_from_comparison(Suma.user_id(), Comparison.id()) :: :ok | nil
  def remove_player_from_comparison(user_id, comparison_id) do
    cast_comparison(comparison_id, {:remove_player, user_id})
  end
  # Process stuff

  @doc """
  Returns a boolean regarding the existence of the comparison.
  """
  @spec comparison_exists?(Comparison.id()) :: boolean
  def comparison_exists?(comparison_id) do
    case Registry.lookup(Suma.LocalComparisonRegistry, comparison_id) do
      [{_pid, _}] -> true
      _ -> false
    end
  end

  @doc false
  @spec get_comparison_pid(Comparison.id()) :: pid() | nil
  def get_comparison_pid(comparison_id) do
    case Registry.lookup(Suma.LocalComparisonRegistry, comparison_id) do
      [{pid, _}] -> pid
      _ -> nil
    end
  end

  @doc false
  @spec cast_comparison(Comparison.id(), any) :: any | nil
  def cast_comparison(comparison_id, msg) do
    case get_comparison_pid(comparison_id) do
      nil ->
        nil

      pid ->
        GenServer.cast(pid, msg)
        :ok
    end
  end

  @doc false
  @spec call_comparison(Comparison.id(), any) :: any | nil
  def call_comparison(comparison_id, message) when is_binary(comparison_id) do
    case get_comparison_pid(comparison_id) do
      nil ->
        nil

      pid ->
        try do
          GenServer.call(pid, message)

          # If the process has somehow died, we just return nil
        catch
          :exit, _ ->
            nil
        end
    end
  end

  @doc false
  @spec stop_comparison_server(Comparison.id()) :: :ok | nil
  def stop_comparison_server(comparison_id) do
    case get_comparison_pid(comparison_id) do
      nil ->
        nil

      p ->
        # Suma.broadcast(comparison_topic(comparison_id), %{
        #   event: :comparison_closed,
        #   comparison_id: comparison_id
        # })

        DynamicSupervisor.terminate_child(Suma.ComparisonSupervisor, p)
        :ok
    end
  end
end
