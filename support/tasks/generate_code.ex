defmodule Mix.Tasks.GenerateCode do
  @shortdoc "Generate YAPL code"
  @moduledoc "Generate YAPL code from current metadata"

  use Mix.Task

  require Logger

  @libphonenumber ~c"resources/PhoneNumberMetadata.xml"
  # @nanp "resources/nanp_report.csv"

  @impl true
  def run(_args) do
    Application.ensure_all_started(:xmerl)

    data = File.read!(@libphonenumber)

    data
    |> Xmerl.SimpleForm.parse_string()
    |> IO.inspect()

    # case :xmerl_sax_parser.file(data,
    #        event_fun: &handle_event/3,
    #        event_state: [],
    #        file_type: :normal,
    #        external_entities: :none,
    #        fail_undeclared_ref: false
    #      ) do
    #   {:ok, result, _rest} -> IO.inspect(result)
    #   {:error, {name, reason}} -> IO.inspect("error: #{name}: #{reason}")
    #   {tag, _location, reason, _endtags, _state} -> IO.inspect("error: #{tag}: #{reason}")
    # end
  end

  # handle_event(event, _location, state)
end
