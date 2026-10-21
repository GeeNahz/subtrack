defmodule SubtrackWeb.SettingsComponents do
  use SubtrackWeb, :html

  attr :current, :atom, required: true

  def settings_nav(assigns) do
    ~H"""
    <nav class="tabs tabs-border mb-6">
      <.link
        :for={{key, label, path} <- links()}
        href={path}
        class={["tab", @current == key && "tab-active"]}
      >
        {label}
      </.link>
    </nav>
    """
  end

  defp links do
    [
      {:account, "Account", ~p"/users/settings"},
      {:profile, "Profile", ~p"/settings/profile"},
      {:contact, "Contact & timezone", ~p"/settings/contact"}
    ]
  end
end
