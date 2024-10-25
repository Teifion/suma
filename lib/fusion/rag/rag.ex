defmodule Fusion.RAG do
  @moduledoc """

  """

  @default_system_prompt "Using this data: {{vectors}}. Respond to this prompt: {{user_prompt}}"

  def default_system_prompt(), do: @default_system_prompt


  @spec format_prompt(String.t(), list(), String.t() | nil) :: String.t()
  def format_prompt(user_prompt, vectors, system_prompt) do
    system_prompt = system_prompt || @default_system_prompt

    system_prompt
    |> String.replace("{{vectors}}", inspect(vectors))
    |> String.replace("{{user_prompt}}", user_prompt)
  end
end
