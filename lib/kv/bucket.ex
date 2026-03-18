# GenServer Version
defmodule KV.Bucket do
  use GenServer

  @doc """
  Starts a new bucket.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(bucket, key) do
    GenServer.call(bucket, {:get, key})
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(bucket, key, value) do
    GenServer.call(bucket, {:put, key, value})
  end

  @doc """
  Deletes `key` from `bucket`.

  Returns the current value of `key`, if `key` exists.
  """
  def delete(bucket, key) do
    GenServer.call(bucket, {:delete, key})
  end

  @doc """
  Subscribes the current process to the `bucket`.
  """
  def subscribe(bucket) do
    GenServer.cast(bucket, {:subscribe, self()})
  end

  @doc """
  Counts the number of subscribers on `bucket`.
  """
  def count_subscribers(bucket) do
    GenServer.call(bucket, {:count_subscribers})
  end

  ## Callbacks

  @impl GenServer
  def init(bucket) do
    state = %{
      bucket: bucket,
      subscribers: MapSet.new()
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:get, key}, _from, state) do
    value = get_in(state.bucket[key])
    {:reply, value, state}
  end

  @impl GenServer
  def handle_call({:put, key, value}, _from, state) do
    state = put_in(state.bucket[key], value)
    broadcast(state, {:put, key, value})
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:delete, key}, _from, state) do
    {value, state} = pop_in(state.bucket[key])
    broadcast(state, {:delete, key})
    {:reply, value, state}
  end

  @impl GenServer
  def handle_call({:count_subscribers}, _from, state) do
    count = MapSet.size(state.subscribers)
    {:reply, count, state}
  end

  @impl GenServer
  def handle_cast({:subscribe, pid}, state) do
    Process.monitor(pid)
    state = update_in(state.subscribers, &MapSet.put(&1, pid))
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, _type, pid, _reason}, state) do
    state = update_in(state.subscribers, &MapSet.delete(&1, pid))
    {:noreply, state}
  end

  ## Private Functions
  defp broadcast(state, message) do
    for pid <- state.subscribers do
      send(pid, message)
    end
  end
end

# Agent version
# defmodule KV.Bucket do
#   use Agent
#
#   @doc """
#   Starts a new bucket.
#
#   All options are forwarded to `Agent.start_link/2`.
#   """
#   def start_link(options) do
#     Agent.start_link(fn -> %{} end, options)
#   end
#
#   @doc """
#   Gets a value from the `bucket` by `key`.
#   """
#   def get(bucket, key) do
#     Agent.get(bucket, &Map.get(&1, key))
#   end
#
#   @doc """
#   Puts the `value` for the given `key` in the `bucket`.
#   """
#   def put(bucket, key, value) do
#     Agent.update(bucket, &Map.put(&1, key, value))
#   end
#
#   @doc """
#   Deletes `key` from `bucket`.
#
#   Returns the current value of `key`, if `key` exists.
#   """
#   def delete(bucket, key) do
#     Agent.get_and_update(bucket, &Map.pop(&1, key))
#   end
# end
