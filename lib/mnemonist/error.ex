defmodule MnemonistError do
  @moduledoc """
  An exception raised when there is an error in processing mnemonics.
  """

  defexception [:message]

  @impl true
  def message(%{message: message}), do: message
end
