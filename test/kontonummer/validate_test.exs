defmodule Kontonummer.ValidateTest do
  use ExUnit.Case, async: true
  alias Kontonummer.Validate

  doctest Kontonummer.Validate

  describe "account/1 - full account number string" do
    test "validates Type 1, Comment 2 bank (Svea Bank)" do
      result = Validate.account("9660-1234567")

      assert {:ok, response} = result
      assert response.bank == "Svea Bank AB"
      assert response.type == 1
      assert response.comment == 2
      assert response.clearing == 9660
      assert response.account == "1234567"
      assert is_boolean(response.valid)
    end

    test "validates Type 1, Comment 1 bank (Aion Bank)" do
      result = Validate.account("9580-1234567")

      assert {:ok, response} = result
      assert response.bank == "Aion Bank SA"
      assert response.type == 1
      assert response.comment == 1
    end

    test "accepts account number without separator" do
      result = Validate.account("96601234567")

      assert {:ok, response} = result
      assert response.bank == "Svea Bank AB"
    end

    test "returns error for bank not found" do
      assert Validate.account("0000-1234567") == {:error, :bank_not_found}
    end

    test "returns error for invalid format" do
      assert Validate.account("invalid") == {:error, :invalid_number}
    end

    test "returns error for invalid length" do
      assert Validate.account("9660-12345") == {:error, :invalid_length}
    end
  end

  describe "account/2 - separate clearing and account" do
    test "validates with integer clearing" do
      result = Validate.account(9660, "1234567")

      assert {:ok, response} = result
      assert response.bank == "Svea Bank AB"
      assert response.clearing == 9660
    end

    test "validates with string clearing" do
      result = Validate.account("9660", "1234567")

      assert {:ok, response} = result
      assert response.clearing == 9660
    end

    test "validates all bank type and comment combinations" do
      # Type 1, Comment 1
      assert {:ok, %{type: 1, comment: 1}} = Validate.account(9580, "1234567")

      # Type 1, Comment 2
      assert {:ok, %{type: 1, comment: 2}} = Validate.account(9660, "1234567")

      # Type 2, Comment 1
      assert {:ok, %{type: 2, comment: 1}} = Validate.account(9180, "1234567890")

      # Type 2, Comment 2
      assert {:ok, %{type: 2, comment: 2}} = Validate.account(6000, "123456789")

      # Type 2, Comment 3
      assert {:ok, %{type: 2, comment: 3}} = Validate.account(9500, "1234567890")

      # Type 2, Comment 3 (Swedbank 8xxxx: 5-digit clearing)
      assert {:ok, %{type: 2, comment: 3}} = Validate.account(80002, "1234567890")
    end
  end

  describe "Swedbank 5 digit clearing (8xxxx-x)" do
    test "accepts the check digit with any separator in account/1" do
      for input <- [
        "8327-9 1234567897",
        "8327 9 1234567897",
        "8327-9, 123 456 789-7",
        "832791234567897"
      ] do
        assert {:ok, %{bank: "Swedbank", valid: true, clearing: "8327-9", account: "1234567897"}} =
          Validate.account(input),
          "expected #{input} to be valid"
      end
    end

    test "accepts the check digit with any separator in account/2" do
      for clearing <- ["8327-9", "8327 9", "83279", 83279] do
        assert {:ok, %{bank: "Swedbank", valid: true, clearing: "8327-9"}} =
          Validate.account(clearing, "1234567897"),
          "expected clearing #{inspect(clearing)} to be valid"
      end
    end

    test "accepts account numbers shorter than 10 digits" do
      assert {:ok, %{valid: true, account: "1234566"}} = Validate.account("8327-9 1234566")
    end

    test "returns an error when the check digit is missing" do
      assert Validate.account(8327, "1234567897") == {:error, :missing_clearing_check_digit}
      assert Validate.account("8327", "1234567897") == {:error, :missing_clearing_check_digit}
    end

    test "returns an error when the check digit is wrong" do
      assert Validate.account("8327-1", "1234567897") == {:error, :invalid_clearing_check_digit}
      assert Validate.account("8327-1 1234567897") == {:error, :invalid_clearing_check_digit}
    end

    test "read the first account digit as check digit when only 4 clearing digits are given" do
      assert Validate.account("8327-123456789") == {:error, :invalid_clearing_check_digit}
    end

    test "is invalid when the account number fails the checksum" do
      assert {:ok, %{valid: false, clearing: "8327-9"}} = Validate.account("8327-9 1234567898")
    end

    test "rejects a fifth clearing digit for bank with 4-digit clearing" do
      assert Validate.account(96601, "1234567") == {:error, :invalid_format}
    end

    test "accepts real Swedbank clearing numbers" do
      for clearing <- ~w(8018-4 8105-9 8169-5 8201-6 8327-9 8420-2 8422-8 8431-9) do
        assert {:ok, %{clearing: ^clearing}} = Validate.account(clearing, "1234567897")
      end
    end
  end

  describe "suggest_clearing/1" do
    test "suggests the full clearing for a missing or wrong check digit" do
      assert Validate.suggest_clearing(8327) == {:ok, "8327-9"}
      assert Validate.suggest_clearing(83271) == {:ok, "8327-9"}
      assert Validate.suggest_clearing(8000) == {:ok, "8000-2"}
    end

    test "returns :error for banks with 4-digit clearing" do
      assert Validate.suggest_clearing(6761) == :error
    end
  end
end
