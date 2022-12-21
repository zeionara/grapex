defmodule Grapex.ExceptionHandling do

  defmacro raise_or_nil(clause) do
    quote do
      case unquote(clause) do
        {:error, message} -> raise List.to_string(message)
        _ -> nil
      end
    end
  end

  defmacro raise_or_value(clause) do
    quote do
      case unquote(clause) do
        {:error, message} -> raise List.to_string(message)
        {:ok, value} -> value
      end
    end
  end

  defmacro raise_or_value(clause, as: type) do
    quote do
      case unquote(clause) do
        {:error, message} -> raise List.to_string(message)
        {:ok, value} -> (unquote(type)).(value)
      end
    end
  end

  defmacro nil_or_value(clause, as: type) do
    quote do
      case unquote(clause) do
        {:error, message} -> nil
        {:ok, value} -> (unquote(type)).(value)
      end
    end
  end

end
