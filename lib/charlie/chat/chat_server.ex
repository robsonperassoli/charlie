defmodule Charlie.Chat.ChatServer do
  alias Charlie.Chat.Conversation
  alias Charlie.LocalLLM
  use GenServer

  # Client API
  def start_link() do
    GenServer.start_link(__MODULE__, Conversation.new(), name: __MODULE__)
  end

  def send_message(message) do
    GenServer.cast(__MODULE__, {:send_message, message})
  end

  def get_messages() do
    GenServer.call(__MODULE__, :get_messages)
  end

  def get_conversation() do
    GenServer.call(__MODULE__, :get_conversation)
  end

  def print() do
    GenServer.cast(__MODULE__, :print)
  end

  # Server Callbacks
  @impl GenServer
  def init(initial_value) do
    {:ok, initial_value}
  end

  @impl GenServer
  def handle_cast({:send_message, message}, conversation) do
    new_state = Conversation.add_message(conversation, :user, message)

    {:noreply, new_state, {:continue, :evaluate_messages}}
  end

  @impl GenServer
  def handle_cast(:print, state) do
    state
    |> Conversation.to_string()
    |> IO.inspect()

    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:get_messages, _from, state) do
    {:reply, Conversation.get_messages(state), state}
  end

  @impl GenServer
  def handle_call(:get_conversation, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_continue(:evaluate_messages, %Conversation{} = state) do
    new_state = Conversation.recall_episodic_memory(state)

    body = LocalLLM.chat(new_state.messages, tools: Charlie.Chat.Tools.available_tools())

    tool_calls = body["message"]["tool_calls"]

    new_state =
      Conversation.add_message(state, :assistant, body["message"]["content"], tool_calls)

    if is_list(tool_calls) and Enum.count(tool_calls) > 0 do
      # TODO: tool calls have to run in parallel
      new_state =
        tool_calls
        |> Enum.reduce(
          new_state,
          fn tool_call, acc ->
            Conversation.add_message(acc, :tool, Charlie.Chat.Tools.eval(tool_call), [tool_call])
          end
        )

      {:noreply, new_state, {:continue, :evaluate_messages}}
    else
      {:noreply, new_state}
    end
  end
end
