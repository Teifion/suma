defmodule Fusion.RAG.ModelServer do
  @moduledoc """
  The GenServer used to track the state of an ongoing comparison
  """

  use FusionWeb, :server

  alias Fusion.RAG.{Completion, CompletionLib, ComparisonLib, EmbedLib, ModelLib}

  alias Fusion.RAG
  use GenServer
  defmodule State do
    @moduledoc false
    defstruct ~w(client lookup_ref topic)a
  end

  @lookup_frequency_ms 30_000

  def install_model(name) do
    GenServer.cast(__MODULE__, {:install_model, name})
  end

  def uninstall_model(name) do
    GenServer.cast(__MODULE__, {:uninstall_model, name})
  end

  def refresh_list() do
    GenServer.cast(__MODULE__, :refresh_list)
  end

  @impl true
  def handle_info(:lookup_check, %State{} = state) do
    state = update_model_list(state)

    {:noreply, state}
  end

  @impl true
  def handle_cast(:refresh_list, %State{} = state) do
    state = update_model_list(state)

    {:noreply, state}
  end

  def handle_cast({:install_model, name}, %State{} = state) do
    Ollama.pull_model(state.client, name: name, stream: true)

    {:noreply, state}
  end

  def handle_cast({:delete_model, name}, %State{} = state) do
    Ollama.delete_model(state.client, name: name)
    |> IO.inspect

    state
    # |> update_model_list
    |> noreply
  end

  # At time of writing the structure of the model data was:
  # %{
  #   "details" => %{
  #     "families" => ["qwen2"],
  #     "family" => "qwen2",
  #     "format" => "gguf",
  #     "parameter_size" => "14.8B",
  #     "parent_model" => "",
  #     "quantization_level" => "Q4_K_M"
  #   },
  #   "digest" => "7cdf5a0187d5c58cc5d369b255592f7841d1c4696d45a8c8a9489440385b22f6",
  #   "model" => "qwen2.5:14b",
  #   "modified_at" => "2024-10-14T17:27:46.697190176+01:00",
  #   "name" => "qwen2.5:14b",
  #   "size" => 8988124069
  # }
  defp update_model_list(state) do
    ollama_models = Ollama.list_models(state.client)
      |> elem(1)
      |> Map.get("models")

    existing_models = ModelLib.list_models([])

    existing_names = existing_models
      |> Enum.map(& &1.name)

    # Models missing from the DB but existing in Ollama, we need to add them
    new_models = ollama_models
      |> Enum.reject(fn %{"model" => name} ->
        Enum.member?(existing_names, name)
      end)
      |> Enum.map(fn data ->
        {:ok, modified_at, _utc_offset} = DateTime.from_iso8601(data["modified_at"])
        modified_at = DateTime.truncate(modified_at, :second)

        {:ok, model} = ModelLib.create_model(%{
          name: data["model"],
          active?: true,
          enabled?: true,
          installed?: true,
          details: data["details"],
          ollama_modified_at: modified_at,
          size: data["size"]
        })
      end)

    # Models in the DB but not in Ollama, we need to deactivate them
    ollama_names = ollama_models
      |> Enum.map(fn %{"model" => name} -> name end)

    uninstalled_models = existing_models
      |> Enum.reject(fn model ->
        Enum.member?(ollama_names, model.name)
      end)
      |> Enum.map(fn model ->
        {:ok, _model} = ModelLib.update_model(model, %{
          installed?: false,
          active?: false
        })
      end)

    if Enum.any?(new_models) || Enum.any?(uninstalled_models) do
      Fusion.broadcast(state.topic, %{
        event: :list_updated
      })
    end

    state
  end

  @doc false
  @spec start_link(list) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, [])
  end

  @impl true
  @spec init(map) :: {:ok, map}
  def init(_args) do
    {:ok, lookup_ref} = :timer.send_interval(@lookup_frequency_ms, :lookup_check)

    send(self(), :lookup_check)

    Registry.register(
      Fusion.LocalGeneralRegistry,
      "ModelServer",
      "ModelServer"
    )

    state = %State{
      topic: "Fusion.Models",
      lookup_ref: lookup_ref,
      client: Ollama.init()
    }

    {:ok, state}
  end
end
