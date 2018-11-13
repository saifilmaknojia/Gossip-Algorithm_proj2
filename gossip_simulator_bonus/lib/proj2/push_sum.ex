defmodule Proj2.PushSum do
  @name __MODULE__
  alias Proj2.Neighborhood
  use GenServer

  def start_link(actor_no, {s_value, w_value, counter}) do
    GenServer.start_link(
      @name,
      [actor_no, {s_value, w_value, counter}],
      name: :"#{actor_no}"
    )
  end

  def init(state) do
    {:ok, state}
  end

  def pushsum(actor_no, s, w, total_actors, topology, startTime) do
    pid = GenServer.whereis(:"#{actor_no}")
    GenServer.cast(pid, {:forward_weight, actor_no, s, w, total_actors, topology, startTime})
  end

  def handle_cast({:forward_weight, actor_no, new_s, new_w, num_actors, topology, timestart}, state) do
    [_, {old_s, old_w, counter}] = state
    updated_s = new_s + old_s
    updated_w = new_w + old_w

    old_ratio = old_s / old_w
    new_ratio = updated_s / updated_w
    change_in_ratio = abs(new_ratio - old_ratio)

    if(counter < 3) do
      if(change_in_ratio <= :math.pow(10, -10)) do
        counter = counter + 1
        neighbor = Neighborhood.get_neighbor(actor_no, num_actors, topology, timestart)

        if(!Neighborhood.check_neighbor_present(neighbor)) do
          new_neighbor = Neighborhood.get_random_neighbor()
          pushsum(new_neighbor, updated_s / 2, updated_w / 2, num_actors, topology, timestart)
        else
          pushsum(neighbor, updated_s / 2, updated_w / 2, num_actors, topology, timestart)
        end

        new_state = [actor_no, {updated_s / 2, updated_w / 2, counter}]
        {:noreply, new_state}
      else
        neighbor = Neighborhood.get_neighbor(actor_no, num_actors, topology, timestart)

        if(!Neighborhood.check_neighbor_present(neighbor)) do
          new_neighbor = Neighborhood.get_random_neighbor()
          pushsum(new_neighbor, updated_s / 2, updated_w / 2, num_actors, topology, timestart)
        else
          pushsum(neighbor, updated_s / 2, updated_w / 2, num_actors, topology, timestart)
        end

        new_state = [actor_no, {updated_s / 2, updated_w / 2, counter}]
        {:noreply, new_state}
      end
    else
      # IO.puts "removed actor: #{actor_no}"
      Neighborhood.remove_actor(actor_no)
      neighbor = Neighborhood.get_neighbor(actor_no, num_actors, topology, timestart)

      if(!Neighborhood.check_neighbor_present(neighbor)) do
        new_neighbor = Neighborhood.get_random_neighbor()
        pushsum(new_neighbor, updated_s / 2, updated_w / 2, num_actors, topology, timestart)
      else
        pushsum(neighbor, updated_s / 2, updated_w / 2, num_actors, topology, timestart)
      end
      {:noreply, state}
    end
  end
end
