import Config

config :grapex, 
  project_root: File.cwd!,
  relentness_root: "#{System.get_env("HOME")}/relentness"

# import_config #{Mix.env()}.exs”
