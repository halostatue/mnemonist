defmodule Mix.Tasks.UpdateMetadata do
  @shortdoc "Update YAPL metadata"
  @moduledoc "Downloads the latest metadata for yapl"

  use Mix.Task

  require Logger

  defmodule LibphonenumberMetadata do
    @moduledoc false

    def name(version), do: "libphonenumber metadata #{version}"

    def version(client) do
      client
      |> Req.get!(url: "https://api.github.com/repos/google/libphonenumber/releases/latest")
      |> Map.fetch!(:body)
      |> Map.fetch!("tag_name")
    end

    def file_url, do: "https://raw.githubusercontent.com/google/libphonenumber/:version/:file"
    def files, do: ["resources/PhoneNumberMetadata.xml"]

    def post_process do
      %{
        "README.md" => fn content, opts ->
          String.replace(
            content,
            ~r{Current metadata version: v\d+\.\d+\.\d+\.},
            "Current metadata version: #{opts[:version]}."
          )
        end
      }
    end
  end

  defmodule NanpAssignmentsMetadata do
    @moduledoc false

    def name(_), do: "NANP assignments"
    def version(_), do: nil
    def file_url, do: "https://reports.nanpa.com/public/npa_report.csv"
    def files, do: ["nanpa.csv"]
  end

  @resources [LibphonenumberMetadata, NanpAssignmentsMetadata]

  @resources_directory "resources"

  @impl true
  def run(_args) do
    Application.ensure_all_started(:req)

    for mod <- @resources, do: update_resource_group(mod)
  end

  defp update_resource_group(mod) do
    version = mod.version(req())

    Logger.info(mod.name(version))

    for file <- mod.files() do
      download_file(mod.file_url(), version, file)
    end

    if function_exported?(mod, :post_process, 0) do
      for {filename, processor} <- mod.post_process() || %{} do
        update_file(filename, processor, version: version)
      end
    end
  end

  defp download_file(url, version, file) do
    %{status: 200, body: body} =
      Req.get!(
        req(),
        url: url,
        decode_body: false,
        path_params: [version: version, file: file]
      )

    data =
      body
      |> remove_bom()
      |> dos2unix()

    filename = Path.join([File.cwd!(), @resources_directory, Path.basename(file)])

    File.write!(filename, data)
  end

  defp update_file(filename, processor, opts) do
    file_path = Path.join([File.cwd!(), filename])

    updated_content =
      file_path
      |> File.read!()
      |> processor.(opts)

    File.write!(file_path, updated_content)
  end

  defp req do
    Req.new(headers: [user_agent: "yapl"])
  end

  defp dos2unix(content), do: String.replace(content, "\r\n", "\n")

  defp remove_bom(<<0xEF, 0xBB, 0xBF, rest::binary>>), do: rest
  defp remove_bom(binary), do: binary
end
