import Config

config :nx, :default_defn_options, [compiler: EXLA, client: :cuda]
config :exla, :clients, cuda: [platform: :cuda], default: [platform: :cuda]

config :grapex, 
  project_root: File.cwd!,
  relentness_root: "#{System.get_env("HOME")}/relentness"

# import_config #{Mix.env()}.exs”
