defmodule KV do
  use Application

  @impl true
  def start(_type, _args) do
    port = Application.fetch_env!(:kv, :port)

    children = [
      {Registry, name: KV, keys: :unique},
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
      {Task.Supervisor, name: KV.ServerSupervisor},
      Supervisor.child_spec({Task, fn -> KV.Server.accept(port) end}, restart: :permanent)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @doc """
  Creates a bucket with the given name.
  """
  def create_bucket(name) do
    DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.Bucket, name: via(name)})
  end

  @doc """
  Looks up the give bucket.
  """
  def lookup_bucket(name) do
    GenServer.whereis(via(name))
  end

  defp via(name), do: {:via, Registry, {KV, name}}
end
