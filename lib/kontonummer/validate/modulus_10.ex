defmodule Kontonummer.Validate.Modulus10 do
  @moduledoc """
  Modulus-10 (Luhn algorithm) validation for Swedish bank account numbers.

  Used by Type 2 banks with Comment 1 and Comment 3.

  ## Algorithm
  The checksum calculation uses alternating weights of 1 and 2 from right to left:
  - Last digit multiplied by 1, second-to-last by 2, etc.
  - If the product is 2-digit, subtract 9 (equivalent to summing the digits)
  - Sum all products
  - Valid if sum is divisible by 10

  ## References
  - Swedish bank documentation (Bankgirot): Section 1.1 10-modulmetoden
  - Also known as the Luhn algorithm (ISO/IEC 7812-1)

  ## Examples

      iex> Kontonummer.Validate.Modulus10.valid?([3, 3, 1, 6, 8, 1, 2, 0, 5, 7, 4, 9, 2])
      true

      iex> Kontonummer.Validate.Modulus10.valid?([1, 2, 3, 4, 5, 6, 7, 8, 9, 0])
      false
  """

  @doc """
  Validates a list of digits using modulus-10 (Luhn algorithm).

  ## Parameters
  - `digits` - List of integers (0-9)

  ## Returns
  - `true` if valid according to modulus-10, `false` otherwise

  ## Examples

      iex> Kontonummer.Validate.Modulus10.valid?([3, 3, 1, 6, 8, 1, 2, 0, 5, 7, 4, 9, 2])
      true

      iex> Kontonummer.Validate.Modulus10.valid?([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
      true

      iex> Kontonummer.Validate.Modulus10.valid?([1, 2, 3, 4, 5, 6, 7, 8, 9, 1])
      false
  """
  @spec valid?([integer()]) :: boolean()
  def valid?(digits) when is_list(digits) do
    digits
    |> checksum()
    |> divisible_by_10?()
  end

  def valid?(_), do: false

  @doc """
  Calculates the modulus-10 checksum for a list of digits.

  The checksum is the sum of all digit products after applying weights.

  ## Parameters
  - `digits` - List of integers (0-9)

  ## Returns
  - Integer sum

  ## Examples

      iex> Kontonummer.Validate.Modulus10.checksum([3, 3, 1, 6, 8, 1, 2, 0, 5, 7, 4, 9, 2])
      50

      iex> Kontonummer.Validate.Modulus10.checksum([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
      0
  """
  @spec checksum([integer()]) :: integer()
  def checksum(digits) when is_list(digits) do
    digits
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(&apply_weight/1)
    |> Enum.sum()
  end

  @doc """
  Calculates the check digit needed to make a number valid under modulus-10.

  ## Parameters
  - `digits` - List of integers (0-9), with last position as 0 (placeholder for check digit)

  ## Returns
  - The check digit (0-9) that makes the number valid

  ## Examples

      iex> Kontonummer.Validate.Modulus10.check_digit([3, 3, 1, 6, 8, 1, 2, 0, 5, 7, 4, 9, 0])
      2

      iex> Kontonummer.Validate.Modulus10.check_digit([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
      0
  """
  @spec check_digit([integer()]) :: integer()
  def check_digit(digits) when is_list(digits) do
    sum = checksum(digits)
    remainder = rem(sum, 10)

    if remainder == 0, do: 0, else: 10 - remainder
  end

  # Private functions

  # Apply alternating weights (1, 2, 1, 2, ...) from right to left
  defp apply_weight({digit, index}) do
    weight = if rem(index, 2) == 0, do: 1, else: 2
    product = digit * weight

    # If product >= 10, subtract 9 (equivalent to summing the two digits)
    # Example: 8 * 2 = 16 → 16 - 9 = 7 (same as 1 + 6)
    if product > 9, do: product - 9, else: product
  end

  defp divisible_by_10?(sum), do: rem(sum, 10) == 0
end
