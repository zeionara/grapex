import Config

config :nx, :default_defn_options, [compiler: EXLA, client: :cuda, default_backend: EXLA.Backend]
config :nx, :default_backend, {EXLA.Backend, []}
config :exla, :clients, cuda: [platform: :cuda, preallocate: false, memory_fraction: 0.1], default: [platform: :cuda, preallocate: false]

config :grapex, 
  project_root: File.cwd!,
  relentness_root: "#{System.get_env("HOME")}/relentness",
  meager_path: '/usr/lib/libmeager_erlang'

# import_config #{Mix.env()}.exs”
