defmodule SumaWeb.Models.NewLive do
  @moduledoc false
  use SumaWeb, :live_view

  alias Suma.RAG.ModelLib

  @impl true
  def mount(_params, _session, socket) when is_connected?(socket) do
    models = ModelLib.list_models(order_by: ["Name (A-Z)"])

    existing_names = models
    |> Enum.map(&(&1.name))

    popular_models = ModelLib.popular_models()
    |> Enum.reject(fn model -> model in existing_names end)

    socket
      |> assign(:popular_models, popular_models)
      |> assign(:site_menu_active, "models")
      |> assign(:models, models)
      |> assign(:progress, nil)
      |> assign(:current_request, nil)
      |> ok
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:site_menu_active, "models")
    |> assign(:progress, nil)
    |> assign(:current_request, nil)
    |> ok
  end

  @impl true
  @spec handle_event(String.t(), map(), Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
  def handle_event("quick-get-model", %{"model_name" => model_name}, socket) do
    socket
    |> do_get_model(model_name)
    |> noreply
  end

  def handle_event("form-get-model", %{"model_name" => model_name}, socket) do
    socket
    |> do_get_model(model_name)
    |> noreply
  end

  def handle_info({_request_pid, {:data, _data}} = message, socket) do
    pid = socket.assigns.current_request.pid

    case message do
      {^pid, {:data, %{"status" => "pulling manifest"} = data}} ->
        socket
        |> assign(:progress, "pulling manifest")

      {^pid, {:data, %{"status" => "verifying sha256 digest"} = data}} ->
        socket
        |> assign(:progress, "verifying sha256 digest")

      {^pid, {:data, %{"status" => "writing manifest"} = data}} ->
        socket
        |> assign(:progress, "writing manifest")

      {^pid, {:data, %{"status" => "writing manifest"} = data}} ->
        socket
        |> assign(:progress, "removing any unused layers")

      {^pid, {:data, %{"status" => "success"} = data}} ->
        socket
        |> assign(:progress, "success")

      # {^pid, {:data, %{"done" => true} = data}} ->
      #   IO.puts "DONE - true"
      #   # handle the final streaming chunk
      #   socket

      {_pid, {:data, data}} ->
        IO.puts "Unexpected message: #{inspect(data, pretty: true)}"
        # this message was not expected!
        socket
    end
    |> noreply
  end

  def handle_info({ref, {:ok, %Req.Response{status: 200}}}, socket) do
    Process.demonitor(ref, [:flush])

    socket
    |> assign(:current_request, nil)
    |> noreply
  end

  defp do_get_model(socket, model_name) do
    model_name = model_name
      |> String.trim()

    # Now to make it actually pull the model down!
    {:ok, task} = Ollama.pull_model(Ollama.init(), name: model_name, stream: self())

    socket
    |> assign(:current_request, task)
    |> assign(:progress, "building request")
  end
end
