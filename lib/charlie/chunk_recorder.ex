defmodule Charlie.ChunkedRecorder do
  use GenServer

  # 5 seconds per chunk
  @chunk_duration 5_000

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def start_recording do
    GenServer.cast(__MODULE__, :start_recording)
  end

  def stop_recording do
    GenServer.cast(__MODULE__, :stop_recording)
  end

  @impl true
  def init(_) do
    {:ok, %{pipeline: nil, timer: nil}}
  end

  @impl true
  def handle_cast(:start_recording, state) do
    {:ok, pipeline} = Charlie.AudioRecorder.start_recording()
    timer = Process.send_after(self(), :rotate_chunk, @chunk_duration)
    {:noreply, %{pipeline: pipeline, timer: timer}}
  end

  @impl true
  def handle_cast(:stop_recording, %{pipeline: pipeline, timer: timer}) do
    if timer, do: Process.cancel_timer(timer)
    if pipeline, do: Charlie.AudioRecorder.stop_recording(pipeline)
    {:noreply, %{pipeline: nil, timer: nil}}
  end

  @impl true
  def handle_info(:rotate_chunk, %{pipeline: pipeline}) do
    # Stop current recording
    Charlie.AudioRecorder.stop_recording(pipeline)

    # Start new recording
    {:ok, new_pipeline} = Charlie.AudioRecorder.start_recording()
    timer = Process.send_after(self(), :rotate_chunk, @chunk_duration)

    {:noreply, %{pipeline: new_pipeline, timer: timer}}
  end
end
