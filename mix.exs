defmodule Grapex.MixProject do
  use Mix.Project

  def project do
    [
      app: :grapex,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [ignore_warnings: "dialyzer.no-return"],

      build_embedded: Mix.env == :prod,
      escript: [main_module: Grapex]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  def deps do
  [
    # {:nx, "~> 0.1.0-dev", github: "elixir-nx/nx", branch: "main", sparse: "nx"},
    {:nx, "~> 0.1.0-dev", [env: :prod, git: "https://github.com/zeionara/nx.git", sparse: "nx", override: true]},
    {:exla, github: "zeionara/nx", branch: "main", sparse: "exla", override: true},
    {:axon, "~> 0.1.0-dev", github: "zeionara/axon", branch: "main", override: true},
    {:axon_onnx, "~> 0.1.0-dev", github: "zeionara/axon_onnx", ref: "origin/master"}, # branch: "master"}, # 
    {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
    {:optimus, "~> 0.2"}
  ]
  end
  # defp deps do
  #   [
  #     # {:dep_from_hexpm, "~> 0.3.0"},
  #     # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #   ]
  # end
end

