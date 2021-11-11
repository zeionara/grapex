defmodule Grapex.Init do
  import Map
  
  @spec set_input_path(map, string) :: map
  def set_input_path(config, path) do
    put(config, :input_path, path)
  end
    
  @spec set_input_path(string) :: map
  def set_input_path(path) do
    set_input_path(%{}, path)
  end

  @spec set_n_epochs(map, integer) :: map
  def set_n_epochs(config, n_epochs) do
    put(config, :n_epochs, n_epochs)
  end
   
  @spec set_input_path(integer) :: map
  def set_n_epochs(n_epochs) do
    set_n_epochs(%{}, n_epochs)
  end

end

