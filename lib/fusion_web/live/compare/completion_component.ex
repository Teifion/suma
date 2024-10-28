defmodule FusionWeb.RAG.CompletionComponent do
  @moduledoc false
  use FusionWeb, :live_component
  # import Fusion.Helper.ColourHelper, only: [rgba_css: 2]

  alias Fusion.RAG.Completion
  alias Fusion.RAG.ComparisonLib

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} phx-target={@myself} phx-change="validate" phx-submit="save" id="completion-form">
        <div class="row mb-4">
          <%!-- Core properties --%>
          <div class="col-md-12 col-lg-6">
            <label for="completion_user_prompt" class="control-label">User prompt:</label>
            <.input field={@form[:user_prompt]} type="text" phx-debounce="500" autofocus="autofocus" disabled={@key_difference == :user_prompt && "disabled"} />
            <br />

            <label for="completion_model_name" class="control-label">Model name:</label>
            <.input field={@form[:model_name]} options={@model_names} type="select" phx-debounce="500" disabled={@key_difference == :model_name && "disabled"} />
            <br />
          </div>

          <div class="col-md-12 col-lg-6">
            <label for="completion_prompt" class="control-label">RAG Embed:</label>
            <input type="text" id="embed_name" value={assigns[:content_name]} class="form-control" disabled="disabled" />
            <br />
          </div>
        </div>

        <div class="row">
          <div class="col">
            <%= case @action do %>
              <% :new -> %>
                <button class="btn btn-primary btn-block" type="submit">Begin comparison</button>
              <% :edit -> %>
                <button class="btn btn-primary btn-block" type="submit">Update</button>
            <% end %>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{completion: completion} = assigns, socket) do
    changeset = Completion.changeset(completion)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"completion" => completion_params}, socket) do
    completion_params = convert_params(completion_params)

    changeset =
      socket.assigns.completion
      |> Completion.changeset(completion_params)
      |> Map.put(:action, :validate)

    notify_parent({:updated_changeset, changeset})

    {:noreply,
     socket
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"completion" => completion_params}, socket) do
    completion_params = convert_params(completion_params)

    save_completion(socket, socket.assigns.action, completion_params)
  end

  defp save_completion(socket, :edit, completion_params) do
    case Account.update_completion(socket.assigns.completion, completion_params) do
      {:ok, completion} ->
        notify_parent({:saved, completion})

        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> redirect(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_completion(socket, :new, completion_params) do
    {:ok, _pid} = ComparisonLib.start_comparison_server(completion_params)

    # case Account.create_completion(completion_params) do
    #   {:ok, completion} ->
    #     notify_parent({:saved, completion})

    #     {:noreply,
    #      socket
    #      |> put_flash(:info, "User created successfully")
    #      |> redirect(to: socket.assigns.patch)}

    #   {:error, %Ecto.Changeset{} = changeset} ->
    #     {:noreply, assign_form(socket, changeset)}
    # end
    socket
    |> noreply
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp convert_params(params) do
    params
  end
end
