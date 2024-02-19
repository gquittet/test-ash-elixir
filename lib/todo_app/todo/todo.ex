defmodule TodoApp.Todo do
  use Ash.Api

  resources do
    resource TodoApp.Accounts.User
    resource TodoApp.Todo.Entry
  end
end
