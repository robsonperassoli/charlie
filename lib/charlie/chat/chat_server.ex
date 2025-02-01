defmodule Charlie.Chat.ChatServer do
  alias Charlie.LocalLLM.Message
  alias Charlie.LocalLLM
  use GenServer

  # Client API
  def start_link() do
    system_message = """
    You are Charlie, a helpful AI assistant. Respond in a friendly, clear manner while being direct and honest about your capabilities.

    Core Behaviors:

    Think through problems step by step
    Ask for clarification when needed
    Keep responses concise unless detail is requested
    Respond in the same language as the user
    Acknowledge when you're unsure about something

    Limitations:

    Cannot access internet or external data
    Cannot remember past conversations
    Cannot create or modify files
    Cannot verify real-world information
    Cannot generate or edit images

    Ethics:

    Do not assist with harmful or illegal activities
    Provide factual information while avoiding harmful content
    Respect privacy and maintain appropriate boundaries
    Redirect unsafe requests to safer alternatives

    Always format code using markdown with proper syntax highlighting.
    Your purpose is to help users while being direct, ethical, and clear about what you can and cannot do.
    """

    GenServer.start_link(__MODULE__, [%Message{role: :system, content: system_message}],
      name: __MODULE__
    )
  end

  def send_message(message) do
    GenServer.cast(__MODULE__, {:send_message, message})
  end

  def get_messages() do
    GenServer.call(__MODULE__, :get_messages)
  end

  # Server Callbacks
  @impl GenServer
  def init(initial_value) do
    {:ok, initial_value}
  end

  @impl GenServer
  def handle_cast({:send_message, message}, state) do
    messages = state ++ [%Message{role: :user, content: message}]

    {:noreply, messages, {:continue, :evaluate_messages}}
  end

  @impl GenServer
  def handle_call(:get_messages, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_continue(:evaluate_messages, state) do
    new_state = state ++ [%Message{role: :assistant, content: ""}]

    LocalLLM.chat(state,
      into: fn {:data, data}, {req, resp} ->
        chunk = Jason.decode!(data)

        last_chunk = chunk["message"]["content"]

        Process.send(self(), {:update_incoming_eval, last_chunk}, [])
        {:cont, {req, resp}}
      end
    )

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info({:update_incoming_eval, last_chunk}, state) do
    {last_message, other_messages} = List.pop_at(state, -1)

    new_state =
      other_messages ++ [%Message{last_message | content: last_message.content <> last_chunk}]

    {:noreply, new_state}
  end
end
