defmodule RinhaVanilla.Payments.Purge do
  @moduledoc false
  def purge_all_data() do
    RinhaVanilla.Cache.cleanup()
  end
end
