defmodule Fusion do
  @moduledoc """
  Fusion
  """

  @type user_id :: Fusion.Account.User.id()

  @type query_args ::
          keyword(
            id: non_neg_integer() | nil,
            where: list(),
            preload: list(),
            order_by: list(),
            offset: non_neg_integer() | nil,
            limit: non_neg_integer() | nil
          )

  @spec uuid() :: String.t()
  def uuid() do
    Ecto.UUID.generate()
  end

  def get_client() do
    client = Ollama.init()
  end

  def generate_embed(client, data, opts \\ []) do
    {:ok, resp} = Ollama.embed(client, model: opts[:model] || "llama3.2", input: data)
    resp["embeddings"]
  end

  def testrun() do
    client = Ollama.init()
    model = "llama3.2"
    embedding_documents = [
      "Llamas are members of the camelid family meaning they're pretty closely related to vicuñas and camels",
      "Llamas were first domesticated and used as pack animals 4,000 to 5,000 years ago in the Peruvian highlands",
      "Llamas can grow as much as 6 feet tall though the average llama between 5 feet 6 inches and 5 feet 9 inches tall",
      "Llamas weigh between 280 and 450 pounds and can carry 25 to 30 percent of their body weight",
      "Llamas are vegetarians and have very efficient digestive systems",
      "Llamas live to be about 20 years old, though some only live for 15 years and others live to be 30 years old",
    ]
    prompt = "What animals are llamas related to?"

    {:ok, response} = Ollama.embed(client, model: model, input: embedding_documents)

    (
      response["embeddings"]
      |> Enum.zip(embedding_documents)
      |> Enum.each(fn {vectors, content} ->
        {:ok, _} = Fusion.Chat.EmbedLib.create_embed(%{
          title: "LLamas",
          url: "llamas",
          content: content,
          tokens: Enum.count(vectors),
          vectors: vectors
        })
      end)
    )

    # Get the appropriate embed
    {:ok, response} = Ollama.embed(client, model: model, input: prompt)
    [response_embedding] = response["embeddings"]
    closest_embed = Fusion.Chat.EmbedQueries.do_query(response_embedding)
    closest_vectors = closest_embed.vectors |> Pgvector.to_list()

    # Now generate the actual response
    {:ok, response} = Ollama.completion(client, [
      model: model,
      prompt: "Using this data: #{inspect closest_vectors}. Respond to this prompt: #{prompt}",
    ])
  end

  def chat(client, prompt, opts \\ []) do
    resp_tuple = Ollama.completion(client, [
      model: opts[:model] || "llama3.2",
      prompt: prompt,
    ])

    case resp_tuple do
      {:ok, resp} ->
        resp["response"]

      v -> v
    end
  end

  # PubSub delegation
  alias Fusion.Helpers.PubSubHelper

  @doc false
  @spec broadcast(String.t(), map()) :: :ok
  defdelegate broadcast(topic, message), to: PubSubHelper

  @doc false
  @spec subscribe(String.t()) :: :ok
  defdelegate subscribe(topic), to: PubSubHelper

  @doc false
  @spec unsubscribe(String.t()) :: :ok
  defdelegate unsubscribe(topic), to: PubSubHelper

  # Cluster cache delegation
  @spec invalidate_cache(atom, any) :: :ok
  defdelegate invalidate_cache(table, key_or_keys), to: Fusion.CacheClusterServer
end
