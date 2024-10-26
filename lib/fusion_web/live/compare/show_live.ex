defmodule FusionWeb.CompareLive.Show do
  use FusionWeb, :live_view

  alias Fusion.RAG.{Completion, ComparisonLib}

  @impl true
  def mount(%{"id" => id}, _session, socket) when is_connected?(socket) do
    case ComparisonLib.get_comparison(id) do
      nil ->
        socket
          |> put_flash(:error, "Comparison not found")
          |> redirect(to: "/compare")
          |> ok

      comparison_state ->
        :ok = Fusion.subscribe(ComparisonLib.comparison_topic(id))

        socket
          |> assign(:id, id)
          |> assign(:completion, comparison_state.completion)
          |> assign(:responses, comparison_state.responses)
          |> assign(:key_difference, comparison_state.key_difference)
          |> assign(:key_fields, ComparisonLib.key_fields())
          |> assign(:variables, comparison_state.variables)
          |> assign(:adding_variable?, false)
          |> assign(:site_menu_active, "compare")
          |> ok
    end
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:key_fields, ComparisonLib.key_fields())
    |> assign(:key_difference, nil)
    |> ok
  end

  @impl true
  def handle_event("update-key_difference", %{"key_difference" => key_difference}, %{assigns: assigns} = socket) do
    ComparisonLib.update_key_difference(assigns.id, key_difference)

    socket
    |> noreply
  end

  def handle_event("add-variable", %{"variable-value" => new_variable}, %{assigns: assigns} = socket) do
    ComparisonLib.add_new_variable(assigns.id, new_variable)

    socket
    |> assign(:adding_variable?, true)
    |> noreply
  end

  def handle_event("remove-variable", %{"value" => value}, %{assigns: assigns} = socket) do
    ComparisonLib.remove_variable(assigns.id, value)

    socket
    |> noreply
  end

  @impl true
  def handle_info(
        {FusionWeb.RAG.CompletionComponent, {:updated_changeset, %{changes: changes}}},
        socket
      ) do

    socket
    |> noreply
  end

  def handle_info(%{topic: "Fusion.Comparison:" <> _, event: :new_key_difference} = msg, socket) do
    socket
    |> assign(:key_difference, msg.key_difference)
    |> assign(:variables, msg.variables)
    |> noreply
  end

  def handle_info(%{topic: "Fusion.Comparison:" <> _, event: :new_variable} = msg, socket) do
    socket
    |> assign(:variables, msg.variables)
    |> assign(:adding_variable?, false)
    |> noreply
  end

  def handle_info(%{topic: "Fusion.Comparison:" <> _, event: :removed_variable} = msg, socket) do
    socket
    |> assign(:variables, msg.variables)
    |> noreply
  end

  def handle_info(%{topic: "Fusion.Comparison:" <> _, event: :awaiting_completions} = msg, socket) do
    socket
    |> assign(:responses, %{})
    |> noreply
  end

  def handle_info(%{topic: "Fusion.Comparison:" <> _, event: :new_response} = msg, socket) do
    socket
    |> assign(:responses, Map.put(socket.assigns.responses, msg.variable_value, msg.response))
    |> noreply
  end

  def handle_info(%{topic: "Fusion.Comparison:" <> _} = msg, socket) do
    IO.puts "#{__MODULE__}:#{__ENV__.line}"
    IO.inspect "No handler for event :#{msg.event}, msg #{inspect msg}"
    IO.puts ""

    socket
    |> noreply
  end

  defp default_llm_opts() do
    %{
      model_name: "llama3.2",
      prompt: "What is the best type of Triangle?",
      variable: "model_name"
    }
  end
end
