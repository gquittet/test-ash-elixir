defmodule TodoAppWeb.EntriesLive do
  use TodoAppWeb, :live_view
  alias TodoApp.Todo.Entry

  def render(assigns) do
    ~H"""
    <h2 class="text-2xl font-bold">Todo's ✅</h2>
    <.form :let={f} for={@create_form} phx-submit="create_entry" class="flex gap-4 items-center py-4">
      <.input type="text" field={f[:title]} placeholder="input title" class="w-full" />
      <.button type="submit">create</.button>
    </.form>
    <div class="divide-y divide-neutral-300">
      <%= for entry <- @entries do %>
        <div class="flex gap-4 py-2 items-center" id={"entry-#{entry.id}"}>
          <%= if Map.get(entry, :deleted_at) do %>
            <div class="line-through italic">
              <input
                type="checkbox"
                phx-click="restore"
                phx-value-entry-id={entry.id}
                class="cursor-pointer"
                checked
              />
              <%= entry.title %>
            </div>
          <% else %>
            <div>
              <input
                type="checkbox"
                phx-click="done"
                phx-value-entry-id={entry.id}
                class="cursor-pointer"
              />
              <%= entry.title %>
            </div>
          <% end %>
          <button phx-click="delete_entry" phx-value-entry-id={entry.id}>
            <.icon name="hero-trash" />
          </button>
        </div>
      <% end %>
    </div>
    <h2 class="text-2xl font-bold mt-6">Update todo</h2>
    <.form :let={f} for={@update_form} phx-submit="update_entry">
      <.label>Todo Name</.label>
      <.input type="select" field={f[:entry_id]} options={@todo_selector} />
      <.input type="text" field={f[:content]} placeholder="input content" />
      <.button type="submit">Update</.button>
    </.form>
    """
  end

  def mount(_params, _session, socket) do
    entries = Entry.read_all!(actor: socket.assigns.current_user)

    socket =
      assign(socket,
        entries: entries,
        todo_selector: todo_selector(entries),
        # the `to_form/1` calls below are for liveview 0.18.12+. For earlier versions, remove those calls
        create_form: AshPhoenix.Form.for_create(Entry, :create) |> to_form(),
        update_form:
          AshPhoenix.Form.for_update(List.first(entries, %Entry{}), :update) |> to_form()
      )

    {:ok, socket, layout: {TodoAppWeb.Layouts, :app}}
  end

  def handle_event("delete_entry", %{"entry-id" => entry_id}, socket) do
    user = socket.assigns.current_user
    entry_id |> Entry.get_by_id!(actor: user) |> Entry.destroy!()
    entries = Entry.read_all!(actor: user)

    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  def handle_event("create_entry", %{"form" => %{"title" => title}}, socket) do
    user = socket.assigns.current_user
    Entry.create(%{title: title |> String.trim()}, actor: user)

    entries = Entry.read_all!(actor: user)

    {:noreply,
     assign(socket,
       create_form: AshPhoenix.Form.for_create(Entry, :create) |> to_form(),
       entries: entries,
       todo_selector: todo_selector(entries)
     )}
  end

  def handle_event("done", %{"entry-id" => entry_id}, socket) do
    user = socket.assigns.current_user
    entry_id |> Entry.get_by_id!(actor: user) |> Entry.done!()

    entries = Entry.read_all!(actor: user)

    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  def handle_event("restore", %{"entry-id" => entry_id}, socket) do
    user = socket.assigns.current_user
    entry_id |> Entry.get_by_id!(actor: user) |> Entry.restore!()

    entries = Entry.read_all!(actor: user)

    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  def handle_event("update_entry", %{"form" => form_params}, socket) do
    %{"entry_id" => entry_id, "content" => content} = form_params

    user = socket.assigns.current_user
    entry_id |> Entry.get_by_id!(actor: user) |> Entry.update!(%{content: content})
    entries = Entry.read_all!(actor: user)

    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  defp todo_selector(entries) do
    for entry <- entries do
      {entry.title, entry.id}
    end
  end
end
