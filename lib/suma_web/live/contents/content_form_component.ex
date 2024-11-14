defmodule SumaWeb.RAG.ContentFormComponent do
  @moduledoc false
  use SumaWeb, :live_component
  # import Suma.Helper.ColourHelper, only: [rgba_css: 2]

  alias Suma.RAG

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h3>
        <%= @title %>
      </h3>

      <.form for={@form} phx-target={@myself} phx-change="validate" phx-submit="save" id="content-form">
        <div class="row mb-4">
          <%!-- Core properties --%>
          <div class="col-md-6">
            <label for="content_name" class="control-label">Name:</label>
            <.input field={@form[:name]} type="text" autofocus="autofocus" phx-debounce="100" />
            <br />
          </div>

          <div class="col-md-12">
            <label for="text" class="control-label">Text:</label>
            <.input field={@form[:text]} type="textarea" phx-debounce="100" />
            <br />
          </div>
        </div>

        <%= if @content.id do %>
          <div class="row">
            <div class="col">
              <a href={~p"/admin/accounts/content/#{@content.id}"} class="btn btn-secondary btn-block">
                Cancel
              </a>
            </div>
            <div class="col">
              <button class="btn btn-primary btn-block" type="submit">Update content</button>
            </div>
          </div>
        <% else %>
          <div class="row">
            <div class="col">
              <a href={~p"/admin/accounts"} class="btn btn-secondary btn-block">
                Cancel
              </a>
            </div>
            <div class="col">
              <button class="btn btn-primary btn-block" type="submit">Create content</button>
            </div>
          </div>
        <% end %>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{content: content} = assigns, socket) do
    changeset = RAG.change_content(content)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"content" => content_params}, socket) do
    content_params = convert_params(content_params)

    changeset =
      socket.assigns.content
      |> RAG.change_content(content_params)
      |> Map.put(:action, :validate)

    notify_parent({:updated_changeset, changeset})

    {:noreply,
     socket
     |> assign_form(changeset)}
  end

  def handle_event("save", %{"content" => content_params}, socket) do
    content_params = convert_params(content_params)

    save_content(socket, socket.assigns.action, content_params)
  end

  defp save_content(socket, :edit, content_params) do
    case RAG.update_content(socket.assigns.content, content_params) do
      {:ok, content} ->
        notify_parent({:saved, content})

        {:noreply,
         socket
         |> put_flash(:info, "Content updated successfully")
         |> redirect(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_content(socket, :new, content_params) do
    case RAG.create_content(content_params) do
      {:ok, content} ->
        notify_parent({:saved, content})

        {:noreply,
         socket
         |> put_flash(:info, "Content created successfully")
         |> redirect(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp convert_params(params) do
    params
  end
end
