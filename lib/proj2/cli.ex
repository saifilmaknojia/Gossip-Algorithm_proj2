defmodule Proj2.Cli do
  alias Proj2.{Gossip, PushSum, Neighborhood}

  def main(argv) do
    argv |> parse_args |> run

    # Prevent exiting once args passed to run
    Process.sleep(:infinity)
  end

  def parse_args(args) do
    case args do
      [num_actors, topology, algorithm] ->
        {String.to_integer(num_actors), topology, algorithm}

      _ ->
        :help
    end
  end

  def run({num_actors, topology, algorithm}) do
    Neighborhood.start_link(num_actors)

    case algorithm do
      "gossip" ->
        Enum.each(1..num_actors, fn actor_no ->
          Gossip.start_link(actor_no, 0)
        end)

        start_time = System.monotonic_time(:millisecond)
        Gossip.spread_rumor(1, num_actors, topology, start_time)

      "push-sum" ->
        Enum.each(1..num_actors, fn actor_no ->
          PushSum.start_link(actor_no, {actor_no, 1, 0})
        end)

        start_time = System.monotonic_time(:millisecond)
        rand_start = Enum.random(1..num_actors)
        PushSum.pushsum(rand_start, rand_start, 1, num_actors, topology, start_time)

      _ ->
        run(:help)
    end
  end

  def run(:help) do
    IO.puts("""
      Usage:
      mix run proj2.exs <num_actors> <topology> <algorithm>\n
      <num_actors>  - integer
      <topology>    - "full" "3D" "rand2D" "sphere" "line" "imp2D"
      <algorithm>   - "gossip" "push-sum"
    """)

    System.halt(0)
  end
end
