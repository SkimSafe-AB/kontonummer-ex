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

      iex> Kontonummer.Validate.account("0000-1234567")
      {:error, :bank_not_found}

      iex> Kontonummer.Validate.account("invalid")
      {:error, :invalid_number}
  """
  @spec account(String.t()) :: {:ok, map()} | {:error, atom()}
  def account(account_number) when is_binary(account_number) do
    with {:ok, clearing, account_digits} <- parse_account_number(account_number),
         {:ok, bank} <- find_bank(clearing),
         {:ok, is_valid} <- validate_with_bank(bank, clearing, account_digits) do
      {:ok, build_result(bank, clearing, digits_to_string(account_digits), is_valid)}
    end
  end

  @doc """
  Validates a Swedish bank account number with separate clearing and account number.

  This is useful when you already have the clearing number and account number
  as separate values.

  ## Parameters
  - `clearing` - Clearing number as integer or string (e.g., 9660 or "9660")
  - `account_number` - Account number as string (e.g., "1234567")

  ## Returns
  - `{:ok, result}` - Map with bank name, validity, type, comment, clearing, and account
  - `{:error, reason}` - Atom describing the error

  ## Examples

      iex> Kontonummer.Validate.account(6761, "755555112")
      {:ok, %{bank: "Handelsbanken", valid: true, type: 2, comment: 2, clearing: 6761, account: "755555112"}}

      iex> Kontonummer.Validate.account("6761", "755555112")
      {:ok, %{bank: "Handelsbanken", valid: true, type: 2, comment: 2, clearing: 6761, account: "755555112"}}

      iex> Kontonummer.Validate.account(0, "1234567")
      {:error, :bank_not_found}

      iex> Kontonummer.Validate.account(9660, "12345")
      {:error, :invalid_length}
  """
  @spec account(integer() | String.t(), String.t()) :: {:ok, map()} | {:error, atom()}
  def account(clearing, account_number) when is_integer(clearing) and is_binary(account_number) do
    with {:ok, account_digits} <- parse_digits(account_number),
         {:ok, bank} <- find_bank(clearing),
         {:ok, is_valid} <- validate_with_bank(bank, clearing, account_digits) do
      {:ok, build_result(bank, clearing, account_number, is_valid)}
    end
  end

  def account(clearing, account_number) when is_binary(clearing) and is_binary(account_number) do
    case parse_integer(clearing) do
      {:ok, clearing_int} -> account(clearing_int, account_number)
      error -> error
    end
  end

  # ============================================================================
  # PRIVATE HELPERS - Parsing
  # ============================================================================

  defp parse_account_number(account_number) do
    # Remove spaces, hyphens, etc.
    cleaned = String.replace(account_number, ~r/[\s\-]/, "")

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

  defp build_result(bank, clearing, account, is_valid) do
    %{
      bank: bank.name,
      valid: is_valid,
      type: bank.type,
      comment: bank.comment,
      clearing: clearing,
      account: account
    }
  end
end
