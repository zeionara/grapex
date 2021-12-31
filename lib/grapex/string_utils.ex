defmodule StringUtils do
  @padding_window_size 3

  def pad(index, placeholder \\ " ", padding_window_size \\ @padding_window_size) when is_number(index) do
    String.pad_trailing(to_string(index), padding_window_size, placeholder)
  end
end
