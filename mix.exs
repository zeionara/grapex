defmodule Grapex.MixProject do
  use Mix.Project

  # @external_resource "/usr/lib/libmeager.so"

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
    {:nx, "~> 0.1.0-dev", env: :prod, git: "https://github.com/zeionara/nx.git", sparse: "nx", override: true, ref: "origin/excluding-feature-and-working-xla"}, # "d17b5c739c8a061b3301298b9d3a9f20da1f54f5"}, #  ref: "a64cf126bd3011c0e95d102207be45512689bf1c"},
    {:exla, "~> 0.1.0-dev", github: "zeionara/nx", sparse: "exla", ref: "a64cf126bd3011c0e95d102207be45512689bf1c"}, # "d17b5c739c8a061b3301298b9d3a9f20da1f54f5"},
    # {:exla, github: "zeionara/nx", branch: "main", sparse: "exla", override: true},
    {:axon, "~> 0.1.0-dev", github: "zeionara/axon", branch: "epoch-completion-handler", override: true},
    {:axon_onnx, "~> 0.1.0-dev", github: "zeionara/axon_onnx", ref: "origin/master"}, # "313e6ef80ec585c2628ec573a912492de85f759e"}, # , ref: "origin/master"}, # branch: "master"}, # 
    {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
    {:optimus, "~> 0.2"},
    {:elixir_uuid, "~> 1.2"}
  ]
  end
  # defp deps do
  #   [
  #     # {:dep_from_hexpm, "~> 0.3.0"},
  #     # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #   ]
  # end
end

