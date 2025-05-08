defmodule Charlie.Memory do
  alias Charlie.WeaviateClient
  alias Charlie.LocalLLM
  alias Charlie.Chat.Conversation

  def create_episodic_memory_prompt(conversation) do
    """
    You are an expert conversation analyzer. Your task is to analyze the conversation between a human and an AI assistant provided below, and create a structured summary that can be used as memory for future reference.
    Keep in mind that user preferences are always the most important thing and should be addressed.

    Analyze the conversation carefully and extract:
    2-4 context tags that would help identify similar conversations in the future
    A one-sentence summary of what was accomplished
    The most effective approach or strategy used
    The most important pitfall or approach to avoid

    Format your response in JSON exactly as follows:
    ```json
    {"context_tags": ["tag1", "tag2", ...],
    "summary": "one sentence describing the conversation outcome",
    "what_worked": "most effective approach/strategy used",
    "what_to_avoid": "key pitfall or ineffective approach if irrelevant, just use N/A"}
    ```

    Example output:
    {"context_tags": ["debugging", "python", "error-handling"],
    "summary": "Helped user fix a RecursionError in their Python script by identifying an infinite loop in their tree traversal function.",
    "what_worked": "Breaking down the problem step-by-step and using print statements to track the recursion depth.",
    "what_to_avoid": "Avoid making assumptions about the input data structure without validation."}

    Conversation to analyze:
    #{conversation}
    """
  end

  def summarize_conversation(%Conversation{} = convo) do
    convo
    |> Conversation.to_string()
    |> create_episodic_memory_prompt()
    |> LocalLLM.prompt(format: "json")
    |> Jason.decode!()
  end

  def save_episodic_memory(%Conversation{} = convo) do
    summary = summarize_conversation(convo)

    vector =
      ("search_document: " <> episodic_memory_to_string(summary))
      |> Charlie.LocalLLM.embed()
      |> List.first()

    WeaviateClient.create_object("EpisodicMemory", summary, vector: vector)
  end

  def recall_episodic_memory(user_input) do
    WeaviateClient.search_episodic_memory("search_query: " <> user_input)
    |> get_in(["Get", "EpisodicMemory"])
    |> then(fn
      nil ->
        nil

      results ->
        results
        |> List.first()
        |> episodic_memory_to_string()
    end)
  end

  def episodic_memory_to_string(summary) do
    """
    context tags: #{Enum.join(summary["context_tags"], ", ")}
    summary: #{summary["summary"]}
    what worked: #{summary["what_worked"]}
    what to avoid: #{summary["what_to_avoid"]}
    """
  end
end
