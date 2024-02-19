defmodule TodoAppWeb.AuthOverrides do
  use AshAuthentication.Phoenix.Overrides
  alias AshAuthentication.Phoenix.Components

  override Components.Banner do
    set :image_url, "/images/sign_in_logo.png"
    set :dark_image_url, "/images/sign_in_logo.png"
    set :image_class, "block dark:hidden h-12 w-auto sm:h-24"
    set :dark_image_class, "hidden dark:block h-12 w-auto sm:h-24"
  end
end
