defmodule Xmerl.SimpleForm.Handler do
  @moduledoc false

  @typedoc """
  - `pattern` is a regex that is used to match the national (significant) number. For
    example, the pattern "(20)(\d{4})(\d{4})" will match number "2070313000", which is the
    national (significant) number for Google London. Note the presence of the parentheses,
    which are capturing groups what specifies the grouping of numbers.

  - `format` specifies how the national (significant) number matched by `pattern` should
    be formatted. Using the same example as above, `format` could contain "$1 $2 $3",
    meaning that the number should be formatted as "20 7031 3000". Each `$x` are replaced
    by the numbers captured by group _x_ in the regex specified by `pattern`.

  - `leading_digits_pattern` is a regex that is used to match a certain number of digits
    at the beginning of the national (significant) number. When the match is successful,
    the accompanying `pattern` and `format` should be used to format this number. For
    example, if `leading_digits="[1-3]|44"`, then all the national numbers starting with
    1, 2, 3 or 44 should be formatted using the accompanying pattern and format.

    The first `leading_digits_pattern` matches up to the first three digits of the
    national (significant) number; the next one matches the first four digits, then the
    first five and so on, until the `leading_digits_pattern` can uniquely identify one
    pattern and format to be used to format the number.

    In the case when only one formatting pattern exists, no `leading_digits_pattern` is
    needed.

  - `national_prefix_formatting_rule` specifies how the national prefix (`$NP`) together
    with the first group (`$FG`) in the national significant number should be formatted in
    the NATIONAL format when a national prefix exists for a certain country. For example,
    when this field contains `($NP$FG)`, a number from Beijing, China (whose `$NP = 0`),
    which would by default be formatted without national prefix as `10 1234 5678` in
    NATIONAL format, will instead be formatted as `(010) 1234 5678`; to format it as
    `(0)10 1234 5678`, the field would contain `($NP)$FG`. Note `$FG` should always be
    present in this field, but `$NP` can be omitted. For example, having `$FG` could
    indicate the number should be formatted in NATIONAL format without the national
    prefix. This is commonly used to override the rule specified for the territory in the
    XML file.

    When this field is missing, a number will be formatted without national prefix in
    NATIONAL format. This field does not affect how a number is formatted in other
    formats, such as INTERNATIONAL.

  - `domestic_carrier_code_formatting_rule` specifies whether the `$NP` can be omitted
    when formatting a number in national format, even though it usually wouldn't be. For
    example, a UK number would be formatted by our library as `020 XXXX XXXX`. If we have
    commonly seen this number written by people without the leading `0`, for example as
    `(20) XXXX XXXX`, this field would be set to `true`. This will be inherited from the
    value set for the territory in the XML file, unless
    a `national_prefix_optional_when_formatting` is defined specifically for this
    NumberFormat.

  - `national_prefix_optional_when_formatting` specifies how any carrier code (`$CC`)
    together with the first group (`$FG`) in the national significant number should be
    formatted when formatWithCarrierCode is called, if carrier codes are used for
    a certain country.
  """
  @type number_format :: %{
          pattern: Regex.t(),
          format: binary(),
          leading_digits_pattern: nil | [binary()],
          national_prefix_formatting_rule: nil | binary(),
          domestic_carrier_code_formatting_rule: nil | binary(),
          # default false
          national_prefix_optional_when_formatting: boolean()
        }

  @type territory :: %{
          # attribute
          # AC, CA, GB, US, etc.
          id: binary(),
          # comment
          # Ascension Island, Canada, United Kingdom, United States of America, etc.
          name: binary(),
          # comment
          itu_url: binary(),
          # attribute
          # 247, 1, 44, 1, etc.
          country_code: binary(),
          # attribute
          international_prefix: binary(),
          # regex, national_number_pattern
          general: binary(),
          #
          rules: map()
        }

  @type lpn :: %{
          header: binary(),
          territories: [territory]
        }

  @type t :: %{elements: list(), comments: list()}

  def handle_event(:startDocument, _location, stack), do: stack

  def handle_event(:endDocument, _location, %{elements: elements, comments: []}), do: Enum.reverse(elements)

  def handle_event(:endDocument, _location, %{elements: elements, comments: comments}),
    do: Enum.reverse(comments ++ elements)

  def handle_event(
        {:startElement, _uri, tag_name, _qualified_name, attributes},
        _location,
        %{elements: elements, comments: comments} = stack
      ) do
    tag = {tag_name, attributes, []}
    %{stack | elements: [tag | comments ++ elements], comments: []}
  end

  def handle_event({:endElement, _uri, tag_name, _qualified_name}, _location, %{
        elements: [{tag_name, attributes, content} | elements],
        comments: comments
      }) do
    current = {to_string(tag_name), attributes, Enum.reverse(content)}

    case elements do
      [] ->
        current

      [{_, _, _} = parent | rest] ->
        {parent_tag_name, parent_attributes, parent_content} = parent
        parent = {parent_tag_name, parent_attributes, [current | comments ++ parent_content]}
        %{elements: [parent | rest], comments: []}

      list ->
        %{elements: [current | comments ++ list], comments: []}
    end
  end

  def handle_event({:endElement, _uri, tag_name, _qualified_name}, _location, [current | _stack]) do
    raise "Error #{tag_name}: #{inspect(current)}"
  end

  def handle_event({:comment, comment}, _location, %{elements: _elements, comments: comments} = stack) do
    %{stack | comments: [to_string(comment) | comments]}
  end

  def handle_event({:characters, chars}, _location, %{elements: elements, comments: _comments} = stack) do
    [{tag_name, attributes, content} | elements] = elements
    current = {tag_name, attributes, [to_string(chars) | content]}
    %{stack | elements: [current | elements]}
  end

  # {:startPrefixMapping, _prefix, _uri} | {:endPrefixMapping, _prefix} |
  # :endDocument | :ignorableWhitespace | :processingInstruction |
  # :startCDATA | :endCDATA |
  # {startDTD, Name :: string(), PublicId :: string(), SystemId :: string()} | endDTD |
  # {startEntity, SysId :: string()} | {endEntity, SysId :: string()} |
  # {elementDecl, Name :: string(), Model :: string()} |
  # {attributeDecl,
  #  ElementName :: string(),
  #  AttributeName :: string(),
  #  Type :: string(),
  #  Mode :: string(),
  #  Value :: string()} |
  # {internalEntityDecl, Name :: string(), Value :: string()} |
  # {externalEntityDecl, Name :: string(), PublicId :: string(), SystemId :: string()} |
  # {unparsedEntityDecl,
  #  Name :: string(),
  #  PublicId :: string(),
  #  SystemId :: string(),
  #  Ndata :: string()} |
  # {notationDecl, Name :: string(), PublicId :: string(), SystemId :: string()}.
  def handle_event(_event, _location, stack), do: stack
end
