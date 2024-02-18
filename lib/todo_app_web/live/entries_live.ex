defmodule TodoAppWeb.EntriesLive do
  use TodoAppWeb, :live_view
  alias TodoApp.Todo.Entry

  def render(assigns) do
    ~H"""
    <h2>Todo's ✅</h2>
    <.form :let={f} for={@create_form} phx-submit="create_entry" class="flex gap-4 items-center">
      <.input type="text" field={f[:title]} placeholder="input title" />
      <.button type="submit">create</.button>
    </.form>
    <div>
      <%= for entry <- @entries do %>
        <div class="flex gap-4 items-center" id={"entry-#{entry.id}"}>
          <input
            type="checkbox"
            phx-click="mark_as_done"
            phx-value-entry-id={entry.id}
            class="cursor-pointer"
            checked={Map.get(entry, :deleted_at)}
          />
          <div class={if Map.get(entry, :deleted_at), do: "line-through italic"}>
            <%= entry.title %>
          </div>
          <button phx-click="delete_entry" phx-value-entry-id={entry.id}>
            <.icon name="hero-trash" />
          </button>
        </div>
      <% end %>
    </div>
    <h2>Update todo</h2>
    <.form :let={f} for={@update_form} phx-submit="update_entry">
      <.label>Todo Name</.label>
      <.input type="select" field={f[:entry_id]} options={@todo_selector} />
      <.input type="text" field={f[:content]} placeholder="input content" />
      <.button type="submit">Update</.button>
    </.form>
    """
  end

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    entries = user_id |> Entry.get_by_author_id!()

    socket =
      assign(socket,
        entries: entries,
        todo_selector: todo_selector(entries),
        # the `to_form/1` calls below are for liveview 0.18.12+. For earlier versions, remove those calls
        create_form: AshPhoenix.Form.for_create(Entry, :create) |> to_form(),
        update_form:
          AshPhoenix.Form.for_update(List.first(entries, %Entry{}), :update) |> to_form()
      )

    {:ok, socket}
  end

  def handle_event("delete_entry", %{"entry-id" => entry_id}, socket) do
    entry_id |> Entry.get_by_id!() |> Entry.destroy!()
    user_id = socket.assigns.current_user.id
    entries = user_id |> Entry.get_by_author_id!()

    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  def handle_event("create_entry", %{"form" => %{"title" => title}}, socket) do
    user_id = socket.assigns.current_user.id
    Entry.create(%{title: title |> String.trim(), author_id: user_id})

    entries = user_id |> Entry.get_by_author_id!()

    {:noreply,
     assign(socket,
       create_form: AshPhoenix.Form.for_create(Entry, :create) |> to_form(),
       entries: entries,
       todo_selector: todo_selector(entries)
     )}
  end

  def handle_event("mark_as_done", %{"entry-id" => entry_id}, socket) do
    Entry.get_by_id!(entry_id) |> Entry.toggle_deleted()

    user_id = socket.assigns.current_user.id
    entries = user_id |> Entry.get_by_author_id!()

    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  def handle_event("update_entry", %{"form" => form_params}, socket) do
    %{"entry_id" => entry_id, "content" => content} = form_params

    entry_id |> Entry.get_by_id!() |> Entry.update!(%{content: content})
    user_id = socket.assigns.current_user.id
    entries = user_id |> Entry.get_by_author_id!()

    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  defp todo_selector(entries) do
    for entry <- entries do
      {entry.title, entry.id}
    end
  end
end
