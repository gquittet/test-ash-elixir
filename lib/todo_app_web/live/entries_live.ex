defmodule TodoAppWeb.EntriesLive do
  use TodoAppWeb, :live_view
  alias TodoApp.Todo.Entry

  def render(assigns) do
    ~H"""
    <h2>Todo's ✅</h2>
    <div>
      <%= for entry <- @entries do %>
        <div>
          <div><%= entry.title %></div>
          <div><%= if Map.get(entry, :content), do: entry.content, else: "" %></div>
          <button phx-click="delete_entry" phx-value-entry-id={entry.id}>delete</button>
        </div>
      <% end %>
    </div>
    <h2>Create todo</h2>
    <.form :let={f} for={@create_form} phx-submit="create_entry">
      <.input type="text" field={f[:title]} placeholder="input title" />
      <.button type="submit">create</.button>
    </.form>
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
    entries = Entry.read_all!()

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
    entries = Entry.read_all!()

    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  def handle_event("create_entry", %{"form" => %{"title" => title}}, socket) do
    Entry.create(%{title: title})
    entries = Entry.read_all!()

    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  def handle_event("update_entry", %{"form" => form_params}, socket) do
    %{"entry_id" => entry_id, "content" => content} = form_params

    entry_id |> Entry.get_by_id!() |> Entry.update!(%{content: content})
    entries = Entry.read_all!()

    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  defp todo_selector(entries) do
    for entry <- entries do
      {entry.title, entry.id}
    end
  end
end
