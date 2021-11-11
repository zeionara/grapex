defmodule Grapex.Init.Macros do

  defmacro defparam(clause, as: type) do
    # IO.inspect(clause)

    # quoted = quote do
    #   if(unquote(clause), do: a = 2)
    # end
    function_name = String.to_atom("set_#{clause}")
    
    quoted = quote do

      @spec unquote(function_name)(map, unquote(type)) :: map
      def unquote(function_name)(config, value) do
        put(config, unquote(clause), value)
      end

      @spec unquote(function_name)(unquote(type)) :: map
      def unquote(function_name)(value) do
        unquote(function_name)(%{}, value)
      end
    end

    # IO.inspect(quoted)
    quoted
  end

end

defmodule Grapex.Init do
  import Map
  import Grapex.Init.Macros

  # @spec set_input_path(map, String.t) :: map
  # def set_input_path(config, path) do
  #   put(config, :input_path, path)
  # end
  #   
  # @spec set_input_path(String.t) :: map
  # def set_input_path(path) do
  #   set_input_path(%{}, path)
  # end

  # @spec set_n_epochs(map, integer) :: map
  # def set_n_epochs(config, n_epochs) do
  #   put(config, :n_epochs, n_epochs)
  # end
  #  
  # @spec set_input_path(integer) :: map
  # def set_n_epochs(n_epochs) do
  #   set_n_epochs(%{}, n_epochs)
  # end

  # defparam :foo, as: integer
  
  defparam :input_path, as: String.t
  defparam :n_epochs, as: integer
  defparam :n_batches, as: integer

end


