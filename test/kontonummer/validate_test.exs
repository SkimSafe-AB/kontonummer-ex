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
      assert {:ok, %{type: 2, comment: 3}} = Validate.account(8000, "1234567890")
    end
  end
end
