defmodule Proj2.Gossip do
  alias Proj2.Neighborhood

  use GenServer

  def start_link(actor_no, message_count) do
    GenServer.start_link(
      __MODULE__,
      [actor_no, message_count],
      name: :"#{actor_no}"
    )
  end

  def init(state) do
    {:ok, state}
  end

  def spread_rumor(actor_no, num_actors, topology, startTime) do
    pid = GenServer.whereis(:"#{actor_no}")
    GenServer.cast(pid, {:forward, actor_no, num_actors, topology, startTime})
  end

  def handle_cast({:forward, actor_no, num_actors, topology, timestart}, state) do
    [_, message_count] = state

    if message_count < 10 do
      neighbor = Neighborhood.get_neighbor(actor_no, num_actors, topology, timestart)

      if(!Neighborhood.check_neighbor_present(neighbor)) do
        new_neighbor = Neighborhood.get_random_neighbor()
        spread_rumor(new_neighbor, num_actors, topology, timestart)
      else
        spread_rumor(neighbor, num_actors, topology, timestart)
      end

      new_state = [actor_no, message_count + 1]
      {:noreply, new_state}
    else
      #IO.puts "removed actor: #{actor_no}"
      Neighborhood.remove_actor(actor_no)
      neighbor = Neighborhood.get_neighbor(actor_no, num_actors, topology, timestart)
      spread_rumor(neighbor, num_actors, topology, timestart)
      {:noreply, state}
    end
  end
end
