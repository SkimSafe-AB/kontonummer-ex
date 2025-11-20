defmodule Kontonummer.BanksTest do
  use ExUnit.Case
  alias Kontonummer.Banks
  doctest Kontonummer.Banks

  # Get all banks for property-based testing
  @all_banks Banks.banks()

  describe "bank_by_clearing/1 - edge cases and critical scenarios" do
    test "returns nil for invalid clearing numbers" do
      # Test various out-of-range values
      assert Banks.bank_by_clearing(0) == nil
      assert Banks.bank_by_clearing(1) == nil
      assert Banks.bank_by_clearing(999) == nil
      assert Banks.bank_by_clearing(10_000) == nil
      assert Banks.bank_by_clearing(99_999) == nil
    end

    test "Nordea Type 1 correctly excludes personkonto clearing numbers 3300 and 3782" do
      # 3300 should be Nordea Personkonto (Type 2), NOT regular Nordea (Type 1)
      result_3300 = Banks.bank_by_clearing(3300)
      assert result_3300.name == "Nordea - Personkonto"
      assert result_3300.type == 2
      assert result_3300.comment == 1

      # 3782 should be Nordea Personkonto (Type 2), NOT regular Nordea (Type 1)
      result_3782 = Banks.bank_by_clearing(3782)
      assert result_3782.name == "Nordea - Personkonto"
      assert result_3782.type == 2
      assert result_3782.comment == 1

      # Numbers immediately before 3300 should be regular Nordea Type 1
      assert Banks.bank_by_clearing(3299).name == "Nordea"
      assert Banks.bank_by_clearing(3299).type == 1
      assert Banks.bank_by_clearing(3299).comment == 1

      # Numbers immediately after 3300 should be regular Nordea Type 1
      assert Banks.bank_by_clearing(3301).name == "Nordea"
      assert Banks.bank_by_clearing(3301).type == 1
      assert Banks.bank_by_clearing(3301).comment == 1

      # Numbers immediately before 3782 should be regular Nordea Type 1
      assert Banks.bank_by_clearing(3781).name == "Nordea"
      assert Banks.bank_by_clearing(3781).type == 1
      assert Banks.bank_by_clearing(3781).comment == 1

      # Numbers immediately after 3782 should be regular Nordea Type 1
      assert Banks.bank_by_clearing(3783).name == "Nordea"
      assert Banks.bank_by_clearing(3783).type == 1
      assert Banks.bank_by_clearing(3783).comment == 1
    end

    test "handles banks with multiple disjoint ranges correctly" do
      # Danske Bank has two separate ranges: 1200-1399 and 2400-2499
      danske_1 = Banks.bank_by_clearing(1200)
      danske_2 = Banks.bank_by_clearing(1399)
      danske_3 = Banks.bank_by_clearing(2400)
      danske_4 = Banks.bank_by_clearing(2499)

      assert danske_1.name == "Danske Bank"
      assert danske_2.name == "Danske Bank"
      assert danske_3.name == "Danske Bank"
      assert danske_4.name == "Danske Bank"

      # All should be same type and comment
      assert danske_1.type == 1
      assert danske_1.comment == 1

      # Gap between ranges should find different bank (Nordea) or nil
      result_gap = Banks.bank_by_clearing(1400)
      assert result_gap == nil or result_gap.name != "Danske Bank"
    end

    test "SEB has all three ranges (5000-5999, 9120-9124, 9130-9149)" do
      # Range 1: 5000-5999
      seb_1 = Banks.bank_by_clearing(5000)
      assert seb_1.name == "SEB"
      assert Banks.bank_by_clearing(5999).name == "SEB"

      # Range 2: 9120-9124
      seb_2 = Banks.bank_by_clearing(9120)
      assert seb_2.name == "SEB"
      assert Banks.bank_by_clearing(9124).name == "SEB"

      # Range 3: 9130-9149
      seb_3 = Banks.bank_by_clearing(9130)
      assert seb_3.name == "SEB"
      assert Banks.bank_by_clearing(9149).name == "SEB"

      # All same type and comment
      assert seb_1.type == 1
      assert seb_1.comment == 1
      assert seb_2.type == 1
      assert seb_3.type == 1

      # Gap between ranges 2 and 3 (9125-9129) should not be SEB
      assert Banks.bank_by_clearing(9125) == nil
      assert Banks.bank_by_clearing(9129) == nil
    end

    test "distinguishes between Type 1 and Type 2 banks correctly" do
      # Type 1 example: Swedbank 7000-7999
      type1 = Banks.bank_by_clearing(7500)
      assert type1.name == "Swedbank"
      assert type1.type == 1
      assert type1.comment == 1

      # Type 2 example: Swedbank 8000-8999
      type2 = Banks.bank_by_clearing(8500)
      assert type2.name == "Swedbank"
      assert type2.type == 2
      assert type2.comment == 3

      # Different bank, different type
      handelsbanken = Banks.bank_by_clearing(6500)
      assert handelsbanken.name == "Handelsbanken"
      assert handelsbanken.type == 2
      assert handelsbanken.comment == 2
    end

    test "Länsförsäkringar Bank has multiple entries with different comments" do
      # Comment 1 with ranges 3400-3409 and 9060-9069
      lf_comment1_a = Banks.bank_by_clearing(3405)
      assert lf_comment1_a.name == "Länsförsäkringar Bank"
      assert lf_comment1_a.type == 1
      assert lf_comment1_a.comment == 1

      lf_comment1_b = Banks.bank_by_clearing(9065)
      assert lf_comment1_b.name == "Länsförsäkringar Bank"
      assert lf_comment1_b.type == 1
      assert lf_comment1_b.comment == 1

      # Comment 2 with range 9020-9029
      lf_comment2 = Banks.bank_by_clearing(9025)
      assert lf_comment2.name == "Länsförsäkringar Bank"
      assert lf_comment2.type == 1
      assert lf_comment2.comment == 2
    end

    test "Swedbank Type 2 Comment 1 has two separate ranges (9300-9329, 9330-9349)" do
      # First range
      swedbank_a = Banks.bank_by_clearing(9300)
      assert swedbank_a.name == "Swedbank"
      assert swedbank_a.type == 2
      assert swedbank_a.comment == 1

      swedbank_b = Banks.bank_by_clearing(9329)
      assert swedbank_b.name == "Swedbank"
      assert swedbank_b.type == 2
      assert swedbank_b.comment == 1

      # Second range
      swedbank_c = Banks.bank_by_clearing(9330)
      assert swedbank_c.name == "Swedbank"
      assert swedbank_c.type == 2
      assert swedbank_c.comment == 1

      swedbank_d = Banks.bank_by_clearing(9349)
      assert swedbank_d.name == "Swedbank"
      assert swedbank_d.type == 2
      assert swedbank_d.comment == 1
    end
  end

  describe "bank_by_clearing/1 - comprehensive coverage for all banks" do
    # Automatically test EVERY bank's EVERY range
    for bank <- @all_banks do
      for range <- bank.ranges do
        # Test: Start of range
        @tag bank: bank.name, clearing: range.start, position: :start
        test "finds #{bank.name} (type #{bank.type}, comment #{bank.comment}) at clearing #{range.start} (start
   of range)" do
          bank_name = unquote(bank.name)
          bank_type = unquote(bank.type)
          bank_comment = unquote(bank.comment)
          clearing = unquote(range.start)

          result = Banks.bank_by_clearing(clearing)

          assert result != nil,
                 "Expected to find bank at clearing #{clearing}"

          assert result.name == bank_name,
                 "Expected #{bank_name} at clearing #{clearing}, got #{result.name}"

          assert result.type == bank_type,
                 "Expected type #{bank_type} for #{bank_name}, got #{result.type}"

          assert result.comment == bank_comment,
                 "Expected comment #{bank_comment} for #{bank_name}, got #{result.comment}"
        end

        # Test: End of range
        @tag bank: bank.name, clearing: range.finish, position: :finish
        test "finds #{bank.name} (type #{bank.type}, comment #{bank.comment}) at clearing #{range.finish} (end of
  range)" do
          bank_name = unquote(bank.name)
          bank_type = unquote(bank.type)
          bank_comment = unquote(bank.comment)
          clearing = unquote(range.finish)

          result = Banks.bank_by_clearing(clearing)

          assert result != nil,
                 "Expected to find bank at clearing #{clearing}"

          assert result.name == bank_name,
                 "Expected #{bank_name} at clearing #{clearing}, got #{result.name}"

          assert result.type == bank_type,
                 "Expected type #{bank_type} for #{bank_name}, got #{result.type}"

          assert result.comment == bank_comment,
                 "Expected comment #{bank_comment} for #{bank_name}, got #{result.comment}"
        end

        # Test: Middle of range (only if range has more than 1 number)
        if range.finish > range.start do
          middle = div(range.start + range.finish, 2)

          @tag bank: bank.name, clearing: middle, position: :middle
          test "finds #{bank.name} (type #{bank.type}, comment #{bank.comment}) at clearing #{middle} (middle
  of range)" do
            bank_name = unquote(bank.name)
            bank_type = unquote(bank.type)
            bank_comment = unquote(bank.comment)
            clearing = unquote(middle)

            result = Banks.bank_by_clearing(clearing)

            assert result != nil,
                   "Expected to find bank at clearing #{clearing}"

            assert result.name == bank_name,
                   "Expected #{bank_name} at clearing #{clearing}, got #{result.name}"

            assert result.type == bank_type,
                   "Expected type #{bank_type} for #{bank_name}, got #{result.type}"

            assert result.comment == bank_comment,
                   "Expected comment #{bank_comment} for #{bank_name}, got #{result.comment}"
          end
        end
      end
    end
  end

  describe "bank_by_clearing/1 - boundary testing" do
    # Test that gaps between ranges return nil or a different bank
    test "clearing 9125 falls in gap between SEB ranges (should be nil)" do
      # SEB has 9120-9124 and 9130-9149, so 9125-9129 should be nil
      for clearing <- 9125..9129 do
        assert Banks.bank_by_clearing(clearing) == nil,
               "Expected nil at clearing #{clearing} (gap in SEB ranges)"
      end
    end

    test "clearing just outside Nordea personkonto exclusions returns Type 1 Nordea" do
      # These tests are also in edge cases, but worth repeating for boundary focus
      # Before 3300
      assert Banks.bank_by_clearing(3299).type == 1
      # After 3300
      assert Banks.bank_by_clearing(3301).type == 1
      # Before 3782
      assert Banks.bank_by_clearing(3781).type == 1
      # After 3782
      assert Banks.bank_by_clearing(3783).type == 1
    end
  end
end
