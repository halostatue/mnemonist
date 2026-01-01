defmodule MnemonistError do
  @moduledoc """
  An exception raised when there is an error in processing mnemonics.
  """

  defexception [:message]

  @impl Exception
  def message(%{message: message}), do: message
end
