defmodule Kontonummer.Validate do
  @moduledoc """
  Validation functions for Swedish bank account numbers.

  Provides validation of complete account numbers using bank-specific
  validation rules based on clearing numbers, account types, and comments.

  ## Validation Rules

  Swedish banks use different validation algorithms based on the account type:

  ### Type 1 Banks (11 digits total)
  - **Comment 1**: Clearing digits 2-4 + 7 account digits = 10 digits, Modulus-11
  - **Comment 2**: All 4 clearing digits + 7 account digits = 11 digits, Modulus-11

  ### Type 2 Banks (variable length)
  - **Comment 1**: 10 account digits, Modulus-10
  - **Comment 2**: 9 account digits, Modulus-11
  - **Comment 3**: Up to 10 account digits (padded), Modulus-10

  ### Swedbank clearing numbers starting with 8
  Swedbank clearing numbers in the range 8000-8999 have five digits, written `8XXX-C`.
  The fifth digit is a Modulus-10 check digit over the first four and is required.
  It may be separated by a hyphen, space or comma, or written without a separator.
  ("8327-9", "8327 9", "83279").
  - A missing fifth figit retusn `{:error, :missing_clearing_check_digit}`
  - A wrong fifth digit returns `{:error, :invalid_clearing_check_digit}`
  - The `clearing`in the result is formatted as a string, e.g. `"8327-9"`

  Use `suggest_clearing/1` to get the correct 5-digit clearing number.

  ## Examples

      # Validate full account number
      iex> Kontonummer.Validate.account("6761-755555112")
      {:ok, %{bank: "Handelsbanken", valid: true, type: 2, comment: 2, clearing: 6761, account: "755555112"}}

      # Validate with separate clearing and account
      iex> Kontonummer.Validate.account(6761, "755555112")
      {:ok, %{bank: "Handelsbanken", valid: true, type: 2, comment: 2, clearing: 6761, account: "755555112"}}

      # Bank not found
      iex> Kontonummer.Validate.account("0000-1234567")
      {:error, :bank_not_found}
  """

  alias Kontonummer.Banks
  alias Kontonummer.Validate.{Modulus10, Modulus11}

  # ============================================================================
  # PUBLIC API
  # ============================================================================

  @doc """
  Validates a complete Swedish bank account number.

  The account number should include both clearing number and account number,
  separated by hyphen, space, or no separator.

  ## Parameters
  - `account_number` - Full account number string (e.g., "9660-1234567", "96601234567")

  ## Returns
  - `{:ok, result}` - Map with bank name, validity, type, comment, clearing, and account
  - `{:error, reason}` - Atom describing the error

  ## Examples

      iex> Kontonummer.Validate.account("6761-755555112")
      {:ok, %{bank: "Handelsbanken", valid: true, type: 2, comment: 2, clearing: 6761, account: "755555112"}}

      iex> Kontonummer.Validate.account("8327-9 1234567897")
      {:ok, %{bank: "Swedbank", valid: true, type: 2, comment: 3, clearing: "8327-9", account: "1234567897"}}

      iex> Kontonummer.Validate.account("0000-1234567")
      {:error, :bank_not_found}

      iex> Kontonummer.Validate.account("invalid")
      {:error, :invalid_number}
  """
  @spec account(String.t()) :: {:ok, map()} | {:error, atom()}
  def account(account_number) when is_binary(account_number) do
    with {:ok, clearing, digits} <- parse_account_number(account_number),
         {:ok, bank} <- find_bank(clearing),
         {:ok, check_digit, account_digits} <- take_check_digit(bank, digits),
         :ok <- validate_check_digit(clearing, check_digit),
         {:ok, is_valid} <- validate_with_bank(bank, clearing, account_digits) do
      {:ok, build_result(bank, clearing, check_digit, digits_to_string(account_digits), is_valid)}
    end
  end

  @doc """
  Validates a Swedish bank account number with separate clearing and account number.

  This is useful when you already have the clearing number and account number
  as separate values.

  ## Parameters
  - `clearing` - Clearing number as integer or string (e.g., 9660, "9660" or "8327-9")
    Swedbank clearing numbers starting with 8 require a fifth check digit.
  - `account_number` - Account number as string (e.g., "1234567")

  ## Returns
  - `{:ok, result}` - Map with bank name, validity, type, comment, clearing, and account
  - `{:error, reason}` - Atom describing the error

  ## Examples

      iex> Kontonummer.Validate.account(6761, "755555112")
      {:ok, %{bank: "Handelsbanken", valid: true, type: 2, comment: 2, clearing: 6761, account: "755555112"}}

      iex> Kontonummer.Validate.account("6761", "755555112")
      {:ok, %{bank: "Handelsbanken", valid: true, type: 2, comment: 2, clearing: 6761, account: "755555112"}}

      iex> Kontonummer.Validate.account("8327-9", "1234567897")
      {:ok, %{bank: "Swedbank", valid: true, type: 2, comment: 3, clearing: "8327-9", account: "1234567897"}}

      iex> Kontonummer.Validate.account(0, "1234567")
      {:error, :bank_not_found}

      iex> Kontonummer.Validate.account(9660, "12345")
      {:error, :invalid_length}

      iex> Kontonummer.Validate.account(8327, "1234567897")
      {:error, :missing_clearing_check_digit}

      iex> Kontonummer.Validate.account("8327-1", "1234567897")
      {:error, :invalid_clearing_check_digit}
  """
  @spec account(integer() | String.t(), String.t()) :: {:ok, map()} | {:error, atom()}
  def account(clearing, account_number) when is_integer(clearing) and is_binary(account_number) do
    {clearing, check_digit} = split_clearing(clearing)

    with {:ok, account_digits} <- parse_digits(account_number),
         {:ok, bank} <- find_bank(clearing),
         :ok <- validate_clearing_length(bank, check_digit),
         :ok <- validate_check_digit(clearing, check_digit),
         {:ok, is_valid} <- validate_with_bank(bank, clearing, account_digits) do
      {:ok, build_result(bank, clearing, check_digit, account_number, is_valid)}
    end
  end

  def account(clearing, account_number) when is_binary(clearing) and is_binary(account_number) do
    case parse_integer(String.replace(clearing, ~r/[\s,\-]/, "")) do
      {:ok, clearing_int} -> account(clearing_int, account_number)
      error -> error
    end
  end

  # ============================================================================
  # PUBLIC HELPERS - Suggest clearing check_digit
  # ============================================================================

  @doc """
  Suggests the full clearing number for banks with a 5-digit clearing
  (Swedbank clearing numbers starting with 8).

  Accepts a 4-digit clearing (missing check digit) or a 5-digit clearing
  (possibly wrong check digit) and returns the clearing with the correct
  check digit. Returns `:error` when the bank has a 4-digit clearing or
  no bank matches, i.e. when there is nothing to suggest.

  Note that the suggestion is only correct for the first four digits given;
  it cannot detect a typo in those.

  ## Examples

      iex> Kontonummer.Validate.suggest_clearing(8327)
      {:ok, "8327-9"}

      iex> Kontonummer.Validate.suggest_clearing(83271)
      {:ok, "8327-9"}

      iex> Kontonummer.Validate.suggest_clearing(6761)
      :error
  """

  @spec suggest_clearing(integer()) :: {:ok, String.t()} | :error
  def suggest_clearing(clearing) when clearing > 9_999, do: suggest_clearing(div(clearing, 10))

  def suggest_clearing(clearing) do
    case Banks.bank_by_clearing(clearing) do
      %{clearing_length: 5} ->
        check_digit = Modulus10.check_digit(Integer.digits(clearing) ++ [0])
        {:ok, "#{clearing}-#{check_digit}"}

      _ ->
        :error
    end
  end

  # ============================================================================
  # PRIVATE HELPERS - Parsing
  # ============================================================================

  defp parse_account_number(account_number) do
    # Remove spaces, hyphens, etc.
    cleaned = String.replace(account_number, ~r/[\s,\-]/, "")

    # Minimum length check FIRST
    if String.length(cleaned) < 5 do
      {:error, :invalid_format}
    else
      case String.split_at(cleaned, 4) do
        {clearing_str, account_str}
        when byte_size(clearing_str) == 4 and byte_size(account_str) > 0 ->
          with {:ok, clearing} <- parse_integer(clearing_str),
               {:ok, account_digits} <- parse_digits(account_str) do
            {:ok, clearing, account_digits}
          end

        _ ->
          {:error, :invalid_format}
      end
    end
  end

  defp parse_integer(str) when is_binary(str) do
    case Integer.parse(str) do
      {num, ""} -> {:ok, num}
      _ -> {:error, :invalid_number}
    end
  end

  defp parse_digits(str) when is_binary(str) do
    digits =
      str
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)

    {:ok, digits}
  rescue
    _ -> {:error, :invalid_digits}
  end

  defp digits_to_string(digits) when is_list(digits) do
    Enum.join(digits, "")
  end

  # ============================================================================
  # PRIVATE HELPERS - Bank lookup
  # ============================================================================

  defp find_bank(clearing) when is_integer(clearing) do
    case Banks.bank_by_clearing(clearing) do
      nil -> {:error, :bank_not_found}
      bank -> {:ok, bank}
    end
  end

  # ============================================================================
  # PRIVATE VALIDATION - Type and Comment logic
  # ============================================================================

  # TYPE 1, COMMENT 1: 10 digits with modulus-11 (excludes first clearing digit)
  defp validate_with_bank(%{type: 1, comment: 1}, clearing, account_digits) do
    if length(account_digits) == 7 do
      full_number = build_type1_number(clearing, account_digits, 1)
      is_valid = Modulus11.valid?(full_number)
      {:ok, is_valid}
    else
      {:error, :invalid_length}
    end
  end

  # TYPE 1, COMMENT 2: 11 digits with modulus-11 (includes all clearing digits)
  defp validate_with_bank(%{type: 1, comment: 2}, clearing, account_digits) do
    if length(account_digits) == 7 do
      full_number = build_type1_number(clearing, account_digits, 2)
      is_valid = Modulus11.valid?(full_number)
      {:ok, is_valid}
    else
      {:error, :invalid_length}
    end
  end

  # TYPE 2, COMMENT 1: 10 digits with modulus-10
  defp validate_with_bank(%{type: 2, comment: 1}, _clearing, account_digits) do
    if length(account_digits) == 10 do
      is_valid = Modulus10.valid?(account_digits)
      {:ok, is_valid}
    else
      {:error, :invalid_length}
    end
  end

  # TYPE 2, COMMENT 2: 9 digits with modulus-11
  defp validate_with_bank(%{type: 2, comment: 2}, _clearing, account_digits) do
    if length(account_digits) == 9 do
      is_valid = Modulus11.valid?(account_digits)
      {:ok, is_valid}
    else
      {:error, :invalid_length}
    end
  end

  # TYPE 2, COMMENT 3: Up to 10 digits with modulus-10 (padded)
  defp validate_with_bank(%{type: 2, comment: 3}, _clearing, account_digits) do
    cond do
      length(account_digits) == 0 ->
        {:error, :invalid_length}

      length(account_digits) > 10 ->
        {:error, :invalid_length}

      true ->
        # Pad to 10 digits with leading zeros
        padded = pad_left(account_digits, 10)
        is_valid = Modulus10.valid?(padded)
        {:ok, is_valid}
    end
  end

  # ============================================================================
  # PRIVATE HELPERS - Clearing numbers
  # ============================================================================

  # Banks with 5 digit clearing (Swedbank 8xxx-x): the digit after the first four
  # is the clearing check digit
  defp take_check_digit(bank, [check_digit | account_digits] = digits) do
    case Map.get(bank, :clearing_length, 4) do
      5 -> {:ok, check_digit, account_digits}
      4 -> {:ok, nil, digits}
    end
  end

  # 5-digit clearing given to account/2, e.g. 83279
  defp split_clearing(clearing) when clearing > 9_999, do: {div(clearing, 10), rem(clearing, 10)}
  defp split_clearing(clearing), do: {clearing, nil}

  defp validate_clearing_length(bank, check_digit) do
    case {Map.get(bank, :clearing_length, 4), check_digit} do
      {5, nil} -> {:error, :missing_clearing_check_digit}
      {4, digit} when is_integer(digit) -> {:error, :invalid_format}
      _ -> :ok
    end
  end

  # The fifth clearing digit is a modulus-10 check digit over the first four
  defp validate_check_digit(_clearing, nil), do: :ok

  defp validate_check_digit(clearing, check_digit) do
    if Modulus10.valid?(Integer.digits(clearing) ++ [check_digit]) do
      :ok
    else
      {:error, :invalid_clearing_check_digit}
    end
  end

  # ============================================================================
  # PRIVATE HELPERS - Number building
  # ============================================================================

  defp build_type1_number(clearing, account_digits, comment) do
    # Convert clearing to 4-digit list
    clearing_str = clearing |> Integer.to_string() |> String.pad_leading(4, "0")

    clearing_digits =
      clearing_str
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)

    case comment do
      1 ->
        # COMMENT 1: Drop first clearing digit
        # Result: 3 clearing digits + 7 account digits = 10 total
        Enum.drop(clearing_digits, 1) ++ account_digits

      2 ->
        # COMMENT 2: Use all clearing digits
        # Result: 4 clearing digits + 7 account digits = 11 total
        clearing_digits ++ account_digits
    end
  end

  defp pad_left(digits, target_length) when is_list(digits) and is_integer(target_length) do
    padding_needed = target_length - length(digits)

    if padding_needed > 0 do
      List.duplicate(0, padding_needed) ++ digits
    else
      digits
    end
  end

  defp build_result(bank, clearing, check_digit, account, is_valid) do
    %{
      bank: bank.name,
      valid: is_valid,
      type: bank.type,
      comment: bank.comment,
      clearing: format_clearing(clearing, check_digit),
      account: account
    }
  end

  defp format_clearing(clearing, nil), do: clearing
  defp format_clearing(clearing, check_digit), do: "#{clearing}-#{check_digit}"
end
