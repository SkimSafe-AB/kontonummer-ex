defmodule Kontonummer.Validate.Modulus11 do
  @moduledoc """
  Modulus-11 validation for Swedish bank account numbers.

  Used by Type 1 banks (all comments) and Type 2 banks with Comment 2.

  ## Algorithm
  The checksum calculation uses weights from 1 to 10, cycling:
  - Digits are multiplied by weights from right to left: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, ...]
  - Sum all products
  - Valid if sum is divisible by 11

  ## Weight Pattern
  For an 11-digit number: `[1, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]` from left to right
  (which is `[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1]` from right to left)

  ## References
  - Swedish bank documentation (Bankgirot): Section 1.2 11-modulmetoden

  ## Examples

      iex> Kontonummer.Validate.Modulus11.valid?([1, 9, 1, 2, 7, 6, 3, 6, 0, 8, 9, 5, 7])
      true

      iex> Kontonummer.Validate.Modulus11.valid?([1, 2, 3, 4, 5, 6, 7])
      false
  """

  @doc """
  Validates a list of digits using modulus-11.

  ## Parameters
  - `digits` - List of integers (0-9)

  ## Returns
  - `true` if valid according to modulus-11, `false` otherwise

  ## Examples

      iex> Kontonummer.Validate.Modulus11.valid?([1, 9, 1, 2, 7, 6, 3, 6, 0, 8, 9, 5, 7])
      true

      iex> Kontonummer.Validate.Modulus11.valid?([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
      true

      iex> Kontonummer.Validate.Modulus11.valid?([1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 0])
      false
  """
  @spec valid?([integer()]) :: boolean()
  def valid?(digits) when is_list(digits) do
    sum = checksum(digits)
    sum
    |> divisible_by_11?()
  end

  def valid?(_), do: false

  @doc """
  Calculates the modulus-11 checksum for a list of digits.

  ## Parameters
  - `digits` - List of integers (0-9)

  ## Returns
  - Integer sum

  ## Examples

      iex> Kontonummer.Validate.Modulus11.checksum([1, 9, 1, 2, 7, 6, 3, 6, 0, 8, 9, 5, 7])
      286

      iex> Kontonummer.Validate.Modulus11.checksum([0, 0, 0, 0, 0, 0, 0])
      0
  """
  @spec checksum([integer()]) :: integer()
  def checksum(digits) when is_list(digits) do
    weights = weights_for(length(digits))

    Enum.zip(digits, weights)
    |> Enum.map(fn {digit, weight} -> digit * weight end)
    |> Enum.sum()
  end

  @doc """
  Calculates the check digit needed to make a number valid under modulus-11.

  Returns an error if the base number would require a check digit of 10,
  which is invalid (can't be represented as a single digit).

  ## Parameters
  - `digits` - List of integers (0-9), with last position as 0 (placeholder for check digit)

  ## Returns
  - `{:ok, check_digit}` if valid check digit exists (0-9)
  - `{:error, :invalid_base_number}` if check digit would be 10

  ## Examples

      iex> Kontonummer.Validate.Modulus11.check_digit([1, 9, 1, 2, 7, 6, 3, 6, 0, 8, 9, 5, 0])
      {:ok, 7}

      iex> Kontonummer.Validate.Modulus11.check_digit([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
      {:ok, 0}

      # Some base numbers cannot have a valid check digit
      iex> Kontonummer.Validate.Modulus11.check_digit([1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 0])
      {:ok, 6}
  """
  @spec check_digit([integer()]) :: {:ok, integer()} | {:error, :invalid_base_number}
  def check_digit(digits) when is_list(digits) do
    sum = checksum(digits)
    remainder = rem(sum, 11)

    case remainder do
      0 -> {:ok, 0}
      # Would need check digit 10
      1 -> {:error, :invalid_base_number}
      r -> {:ok, 11 - r}
    end
  end

  # Private functions

  # Generate weights for modulus-11: [1, 2, 3, ..., 10, 1, 2, 3, ..., 10, ...]
  # Returns them in reverse order for left-to-right application
  defp weights_for(count) do
    base_weights = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    Stream.cycle(base_weights)
    |> Enum.take(count)
    |> Enum.reverse()
  end

  defp divisible_by_11?(sum), do: rem(sum, 11) == 0
end