import Config

port =
  cond do
    port_env = System.get_env("PORT") ->
      String.to_integer(port_env)

    config_env() == :test ->
      4040

    true ->
      4050
  end

config :kv, :port, port
