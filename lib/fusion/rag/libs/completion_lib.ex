defmodule Fusion.RAG.CompletionLib do
  @moduledoc false

  alias Fusion.RAG.Completion


  def get_response(model_name, prompt, opts \\ []) do
    client = opts[:client] || Ollama.init()

    {:ok, response} = Ollama.completion(client, [
      model: model_name,
      prompt: prompt
    ])
  end
end
