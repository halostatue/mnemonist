defmodule Xmerl.SimpleForm do
  @moduledoc ~S"""
  A port of Saxy.SimpleForm to xmerl_sax_parser.

  Comment nodes will be presented was `{:comment, data}`.
  """

  @type tag_name :: String.t()
  @type attributes :: [{name :: String.t(), value :: String.t()}]
  @type content :: [String.t() | {:cdata, String.t()} | t]
  @type comment :: {:comment, String.t()}
  @type t :: {tag_name, attributes, content} | comment

  @spec parse_string(binary() | charlist() | iodata(), options :: keyword()) :: {:ok, t} | {:error, term()}
  def parse_string(data, _options \\ []) do
    result =
      :xmerl_sax_parser.stream(
        data,
        event_fun: &__MODULE__.Handler.handle_event/3,
        event_state: %{elements: [], comments: []},
        file_type: :normal,
        external_entities: :none,
        fail_undeclared_ref: false
      )

    case result do
      {:ok, document, _rest} -> {:ok, document}
      {:error, {_name, reason}} -> {:error, reason}
      {_tag, _location, reason, _endtags, _state} -> {:error, reason}
      {:fatal_error, reason} -> IO.warn(inspect(reason))
    end
  end
end
