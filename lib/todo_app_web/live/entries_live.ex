defmodule TodoAppWeb.EntriesLive do
  use TodoAppWeb, :live_view
  alias TodoApp.Todo.Entry

  def render(assigns) do
    ~H"""
    <h2 class="text-2xl font-bold">Todo's ✅</h2>
    <.form
      :let={f}
      for={@create_form}
      phx-submit="create_entry"
      phx-change="validate"
      class="flex gap-4 items-start py-4"
    >
      <.input type="text" field={f[:title]} placeholder="input title" class="w-full" />
      <.button type="submit">create</.button>
    </.form>
    <div class="divide-y divide-neutral-300">
      <%= for entry <- @entries do %>
        <div class="flex gap-4 py-2 items-center" id={"entry-#{entry.id}"}>
          <%= if entry.done? do %>
            <input
              type="checkbox"
              phx-click="restore"
              phx-value-entry-id={entry.id}
              class="cursor-pointer"
              checked
            />
            <div class="line-through italic">
              <%= entry.title %>
            </div>
          <% else %>
            <input
              type="checkbox"
              phx-click="done"
              phx-value-entry-id={entry.id}
              class="cursor-pointer"
            />
            <div>
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

    TodoAppWeb.Endpoint.subscribe("entries:created")
    entries |> Enum.map(fn entry -> subscribe(entry.id) end)

    socket =
      assign(socket,
        entries: entries,
        todo_selector: todo_selector(entries),
        # the `to_form/1` calls below are for liveview 0.18.12+. For earlier versions, remove those calls
        create_form: socket |> init_create_form,
        update_form: socket |> init_update_form(entries)
      )

    {:ok, socket, layout: {TodoAppWeb.Layouts, :app}}
  end

  defp init_create_form(socket) do
    AshPhoenix.Form.for_create(Entry, :create,
      api: TodoApp.Todo,
      actor: socket.assigns.current_user
    )
    |> to_form()
  end

  defp init_update_form(socket, entries) do
    AshPhoenix.Form.for_update(List.first(entries, %Entry{}), :update,
      api: TodoApp.Todo,
      actor: socket.assigns.current_user
    )
    |> to_form()
  end

  defp subscribe(entry_id) do
    TodoAppWeb.Endpoint.subscribe("entries:done:#{entry_id}")
    TodoAppWeb.Endpoint.subscribe("entries:restore:#{entry_id}")
    TodoAppWeb.Endpoint.subscribe("entries:deleted:#{entry_id}")
  end

  defp unsubscribe(entry_id) do
    TodoAppWeb.Endpoint.unsubscribe("entries:done:#{entry_id}")
    TodoAppWeb.Endpoint.unsubscribe("entries:restore:#{entry_id}")
    TodoAppWeb.Endpoint.unsubscribe("entries:deleted:#{entry_id}")
  end

  def handle_event("validate", %{"form" => params}, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.create_form, params)
    {:noreply, assign(socket, create_form: form)}
  end

  def handle_event("delete_entry", %{"entry-id" => entry_id}, socket) do
    user = socket.assigns.current_user
    entry_id |> Entry.get_by_id!(actor: user) |> Entry.destroy!()
    unsubscribe(entry_id)
    entries = Entry.read_all!(actor: user)

    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  def handle_event("create_entry", %{"form" => params}, socket) do
    case AshPhoenix.Form.submit(socket.assigns.create_form, params: params) do
      {:ok, entry} ->
        user = socket.assigns.current_user
        subscribe(entry.id)
        entries = Entry.read_all!(actor: user)

        {:noreply,
         assign(socket,
           create_form: socket |> init_create_form,
           entries: entries,
           todo_selector: todo_selector(entries)
         )}

      {:error, form} ->
        {:noreply, assign(socket, create_form: form)}
    end
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

  def handle_info(%{topic: "entries:created", payload: %{data: entry}}, socket) do
    subscribe(entry.id)
    entries = Entry.read_all!(actor: socket.assigns.current_user)
    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  def handle_info(%{topic: "entries:done:" <> _}, socket) do
    entries = Entry.read_all!(actor: socket.assigns.current_user)
    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  def handle_info(%{topic: "entries:restore:" <> _}, socket) do
    entries = Entry.read_all!(actor: socket.assigns.current_user)
    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  def handle_info(%{topic: "entries:deleted:" <> id}, socket) do
    unsubscribe(id)
    entries = Entry.read_all!(actor: socket.assigns.current_user)
    {:noreply, assign(socket, entries: entries, todo_selector: todo_selector(entries))}
  end

  defp todo_selector(entries) do
    for entry <- entries do
      {entry.title, entry.id}
    end
  end
end
