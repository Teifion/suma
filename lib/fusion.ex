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

  alias Fusion.RAG


  @spec uuid() :: String.t()
  def uuid() do
    Ecto.UUID.generate()
  end

  def testrun() do
    content_param_list = [
      "Llamas are members of the camelid family meaning they're pretty closely related to vicuñas and camels",
      "Llamas were first domesticated and used as pack animals 4,000 to 5,000 years ago in the Peruvian highlands",
      "Llamas can grow as much as 6 feet tall though the average llama between 5 feet 6 inches and 5 feet 9 inches tall",
      "Llamas weigh between 280 and 450 pounds and can carry 25 to 30 percent of their body weight",
      "Llamas are vegetarians and have very efficient digestive systems",
      "Llamas live to be about 20 years old, though some only live for 15 years and others live to be 30 years old",
    ]
    |> Enum.map(fn text ->
      %{
        name: String.slice(text, 0..30),
        text: text
      }
    end)

    # Create contents
    contents = batch_create_contents(content_param_list)

    # Create the embeds for a given model
    model_name = "llama3.2"
    batch_create_embeds(model_name, contents)

    prompt = "What animals are llamas related to?"
    model = RAG.ModelLib.get_model_by_name!(model_name)
    completion(prompt, model)
  end

  @spec completion(String.t(), String.t() | RAG.Model.t()) :: map()
  def completion(user_prompt, model), do: completion(user_prompt, model, [])

  @spec completion(String.t(), String.t() | RAG.Model.t(), list()) :: map()
  def completion(user_prompt, model_name, opts) when is_bitstring(model_name) do
    model = RAG.ModelLib.get_model_by_name!(model_name)
    completion(user_prompt, model, opts)
  end

  def completion(user_prompt, %RAG.Model{} = model, opts) do
    client = opts[:client] || Ollama.init()

    # If vectors are supplied use them, if an embed is supplied use that otherwise
    # get the nearest embed vectors and use those
    vectors = cond do
      opts[:vectors] != nil ->
        opts[:vectors]
      opts[:embed_id] != nil ->
        embed = RAG.EmbedLib.get_embed!(opts[:embed_id])
        embed.vectors |> Pgvector.to_list()
      true ->
        RAG.EmbedLib.get_nearest_embed_vectors(user_prompt, model, client)
    end

    system_prompt = RAG.format_prompt(user_prompt, vectors, opts[:system_prompt])

    # Now generate the actual response
    {:ok, response} = Ollama.completion(client, [
      model: model.name,
      prompt: system_prompt
    ])

    response
  end

  @spec batch_create_contents([map()]) :: [RAG.Content.t()]
  def batch_create_contents(param_list) do
    param_list
    |> Enum.map(fn params ->
      RAG.ContentLib.get_or_add_content(params)
    end)
  end

  @spec batch_create_embeds(RAG.Model.name(), [RAG.Content.t()]) :: :ok
  def batch_create_embeds(model_name, contents) do
    client = Ollama.init()
    model = RAG.ModelLib.get_or_add_model(%{name: model_name})

    # Find contents not yet embedded for this model
    content_ids = contents |> Enum.map(fn %{id: id} -> id end)
    missing_embed_content_ids = RAG.EmbedLib.find_non_created_embeds(content_ids, model.id)

    # Now filter out the existing embeds
    missing_contents = contents
      |> Enum.filter(fn %{id: id} -> Enum.member?(missing_embed_content_ids, id) end)

    # Combine the missing contents into an API call to Ollama to generate the embed vectors
    new_embed_inputs = missing_contents
      |> Enum.map(fn %{text: text} -> text end)

    {:ok, response} = Ollama.embed(client, model: model.name, input: new_embed_inputs)

    response["embeddings"]
    |> Enum.zip(missing_contents)
    |> Enum.each(fn {vectors, content} ->
      {:ok, _} = RAG.EmbedLib.create_embed(%{
        model_id: model.id,
        content_id: content.id,
        tokens: Enum.count(vectors),
        vectors: vectors
      })
    end)
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
