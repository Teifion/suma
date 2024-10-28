defmodule SumaWeb.EmbedComponents do
  @moduledoc false
  use SumaWeb, :component
  import SumaWeb.{NavComponents}

  @doc """
  <SumaWeb.EmbedComponents.filter_bar active="active" />

  <SumaWeb.EmbedComponents.filter_bar active="active">
    Right side content here
  </SumaWeb.EmbedComponents.filter_bar>
  """
  attr :selected, :string, default: "list"
  attr :current_user, :map, required: true
  slot :inner_block, required: false

  def filter_bar(assigns) do
    ~H"""
    <div class="row section-menu">
      <div class="col">
        <.section_menu_button_url
          colour="info"
          icon={StylingHelper.icon(:list)}
          active={@selected == "list"}
          url={~p"/embeds"}
        >
          List
        </.section_menu_button_url>

        <.section_menu_button_url
          :if={allow?(@current_user, "admin")}
          colour="info"
          icon={StylingHelper.icon(:new)}
          active={@selected == "new"}
          url={~p"/embeds/new"}
        >
          New
        </.section_menu_button_url>

        <.section_menu_button_url
          :if={@selected == "show"}
          colour="info"
          icon={StylingHelper.icon(:detail)}
          active={@selected == "show"}
          url="#"
        >
          Show
        </.section_menu_button_url>

        <.section_menu_button_url
          :if={@selected == "edit"}
          colour="info"
          icon={StylingHelper.icon(:edit)}
          active={@selected == "edit"}
          url="#"
        >
          Edit
        </.section_menu_button_url>
      </div>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
