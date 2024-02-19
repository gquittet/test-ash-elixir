defmodule TodoApp.Todo do
  use Ash.Api, extensions: [AshAdmin.Api]

  admin do
    show?(true)
  end

  resources do
    resource TodoApp.Accounts.User
    resource TodoApp.Todo.Entry
  end
end
