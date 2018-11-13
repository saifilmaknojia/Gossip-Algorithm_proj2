defmodule Proj2.Failure do
  @name __MODULE__
  def start_link(failures) do
    Agent.start_link(fn -> %{a: failures} end, name: __MODULE__)
  end

  def update_failure_count do
    Agent.update(@name, fn map -> Map.update(map, :b, 0, &(&1+1))end)
  end

  def get_failure_count() do
    total = Agent.get(@name, fn map -> Map.get(map, :a) end)
    num_failures = Agent.get(@name, fn map -> Map.get(map, :b) end)
    #balance = total - num_failures

    #IO.puts "Failure remaining = #{balance}"
    #IO.puts "Failure Count = #{num_failures}"
  end
end
