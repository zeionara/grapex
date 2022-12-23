defmodule Grapex.Option do

  defmacro is(flag) do
    quote do
      Keyword.get(var!(opts), unquote(flag), false)
    end
  end

  defmacro opt(option) do
    quote do
      Keyword.get(var!(opts), unquote(option))
    end
  end

  defmacro opt(option, else: default) do
    quote do
      Keyword.get(var!(opts), unquote(option), unquote(default))
    end
  end

  def parse(default_path \\ "assets/config/default.yml") do
    {opts, args, _} = OptionParser.parse(
      System.argv,
      aliases: [
        v: :verbose,
        s: :seed
      ],
      strict: [
        verbose: :boolean,
        seed: :integer
      ]
    )
    |> IO.inspect

    path = case args do
      [path | _] -> path
      _ -> default_path
    end

    {path, opts}
  end

end
