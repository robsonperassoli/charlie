defmodule Charlie.Chat.Conversation do
  alias Charlie.UserSettings
  alias Charlie.Memory
  alias Charlie.LocalLLM.Message
  alias __MODULE__

  defstruct [:messages]

  @system_prompt """
  You are Charlie, a helpful AI assistant.
  Respond in a friendly and cheerful manner while being direct and honest about your capabilities.
  You can refer to the user as #{UserSettings.user_name()}.

  Core Behaviors:

  Think through problems step by step
  Ask for clarification when needed
  Keep responses concise unless detail is requested
  Respond in the same language as the user
  Acknowledge when you're unsure about something

  Limitations:

  Cannot access internet or external data
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

  def new() do
    %Conversation{
      messages: [%Message{role: :system, content: @system_prompt}]
    }
  end

  def add_message(%Conversation{} = conversation, role, content, tool_calls \\ nil)
      when role in [:system, :user, :tool, :assistant] do
    %Conversation{
      conversation
      | messages:
          conversation.messages ++
            [%Message{role: role, content: content, tool_calls: tool_calls}]
    }
  end

  def get_messages(%Conversation{messages: messages}) do
    messages
  end

  def last_message(%Conversation{messages: messages}) do
    messages
    |> List.pop_at(-1)
    |> elem(0)
  end

  def system_message(%Conversation{messages: messages}) do
    messages
    |> Enum.find(&(&1.role === :system))
  end

  def recall_episodic_memory(%Conversation{} = convo) do
    last_message = last_message(convo)

    last_message.content
    |> Memory.recall_episodic_memory()
    |> then(fn
      nil ->
        convo

      memory ->
        set_episodic_recall(convo, memory)
    end)
  end

  def set_episodic_recall(%Conversation{messages: messages} = convo, recall) do
    [_system_message | other_messages] = messages

    prompt_with_memory =
      @system_prompt <>
        """

        You recall past conversations with the user, here are the details:

        #{recall}

        Use these memories as context for your response to the user.
        """

    %Conversation{
      convo
      | messages: [%Message{role: :system, content: prompt_with_memory}] ++ other_messages
    }
  end

  @doc """
  Converts conversation into a formatted string
  """
  def to_string(%Conversation{} = conversation) do
    conversation.messages
    |> Enum.reject(&(&1.role === :system))
    |> Enum.map(fn message ->
      "#{message.role |> Atom.to_string() |> String.upcase()}: #{message.content}"
    end)
    |> Enum.join("\n")
  end
end
