defmodule Proj2.Neighborhood do
  @name __MODULE__

  def start_link(num_actors) do
    Agent.start_link(fn -> %{} end, name: @name)
    generate_neighborhood(num_actors)
  end

  def generate_neighborhood(num_actors) do
    Enum.each(1..num_actors, fn actor_no ->
      add_actor(actor_no)
    end)
  end

  def add_actor(actor_no) do
    Agent.update(
      @name,
      fn map ->
        Map.update(map, actor_no, 0, & &1)
      end
    )
  end

  def get_keys() do
    Agent.get(@name, fn map -> Map.keys(map) end)
  end

  def remove_actor(actor_no) do
    Agent.update(@name, fn map -> Map.delete(map, actor_no) end)
  end

  def get_random_neighbor() do
    {key, _} = Agent.get(@name, fn map -> Enum.random(map) end)
    key
  end

  def get_neighbor(actor_no, num_actors, topology, start_time) do
    if not_empty() do
      case topology do
        "full" ->
          get_full_neighbor(num_actors)

        "3D" ->
          get_3d_neighbor(actor_no, num_actors)

        "rand2D" ->
          get_2d_neighbor(actor_no, num_actors)

        "sphere" ->
          get_sphere_neighbor(actor_no, num_actors)

        "line" ->
          get_line_neighbor(actor_no, 1, num_actors)

        "imp2D" ->
          get_imp_line_neighbor(actor_no, num_actors)

        _ ->
          2
      end
    else
      current_time = System.monotonic_time(:millisecond)
      end_time = current_time - start_time
      IO.puts("Convergence Achieved in = " <> Integer.to_string(end_time) <> " ms")
      System.halt(0)
    end
  end

  def not_empty, do: get_keys() != []

  def check_neighbor_present(key) do
    Agent.get(@name, fn map -> Map.has_key?(map, key) end)
  end

  def get_full_neighbor(total_actors) do
    rand_neigh = Enum.random(1..total_actors)

    if(check_neighbor_present(rand_neigh)) do
      rand_neigh
    else
      get_full_neighbor(total_actors)
    end
  end

  def get_line_neighbor(start_actor, proximity, num_actors) do
    if proximity > num_actors do
      start_actor
    else
      right_present = check_neighbor_present(start_actor + proximity)
      left_present = check_neighbor_present(start_actor - proximity)

      case right_present || left_present do
        true ->
          if right_present && left_present do
            Enum.random([start_actor + proximity, start_actor - proximity])
          else
            if right_present do
              start_actor + proximity
            else
              start_actor - proximity
            end
          end

        false ->
          get_line_neighbor(start_actor, proximity + 1, num_actors)
      end
    end
  end

  def get_imp_line_neighbor(start_actor, num_actors) do
    close_neighbor = get_line_neighbor(start_actor, 1, num_actors)
    random_neighbor = get_random_neighbor()
    Enum.random([close_neighbor, random_neighbor])
  end

  def flat_neighbors_to_3d(start_actor, flat_actor, flat_neighbors) do
    Enum.map(flat_neighbors, &(&1 - flat_actor + start_actor))
  end

  def select_neighbor(neighbors) do
    if neighbors == [] do
      get_random_neighbor()
    else
      neighbor = Enum.random(neighbors)

      case check_neighbor_present(neighbor) do
        true -> neighbor
        false -> select_neighbor(neighbors -- [neighbor])
      end
    end
  end

  def get_3d_neighbor(start_actor, num_actors) do
    cube_root = :math.pow(num_actors, 1 / 3) |> round
    sqr_root = :math.pow(cube_root, 2) |> round

    flat_actor = rem(start_actor, sqr_root)
    flat_neighbors = get_flat_neighbors(flat_actor, sqr_root)
    neighbors = flat_neighbors_to_3d(start_actor, flat_actor, flat_neighbors)

    cond do
      # Top of cube
      start_actor >= 1 && start_actor <= sqr_root ->
        below_neighbor = start_actor + sqr_root
        select_neighbor(neighbors ++ [below_neighbor])

      # Bottom of cube
      start_actor >= num_actors - sqr_root + 1 && start_actor <= num_actors ->
        above_neighbor = start_actor - sqr_root
        select_neighbor(neighbors ++ [above_neighbor])

      # inside cube
      true ->
        above_neighbor = start_actor - sqr_root
        below_neighbor = start_actor + sqr_root
        select_neighbor(neighbors ++ [above_neighbor, below_neighbor])
    end
  end

  def get_flat_neighbors(start_actor, total_actors) do
    square_size = :math.sqrt(total_actors) |> :math.ceil() |> trunc
    num_zeros = :math.pow(square_size, 2) - total_actors

    left_top = 1
    right_top = square_size
    left_bottom = total_actors - square_size + 1 + num_zeros
    right_bottom = total_actors

    cond do
      start_actor == left_top ->
        [left_top + 1, left_top + square_size]

      start_actor == right_top ->
        [right_top - 1, right_top + square_size]

      start_actor == left_bottom ->
        [left_bottom + 1, left_bottom - square_size]

      start_actor == total_actors ->
        [right_bottom - 1, right_bottom - square_size]

      start_actor < square_size && start_actor > 1 ->
        [start_actor - 1, start_actor + 1, start_actor + square_size]

      rem(start_actor, square_size) == 1 && start_actor != 1 && start_actor != left_bottom ->
        [start_actor + 1, start_actor - square_size, start_actor + square_size]

      rem(start_actor, square_size) == 0 && start_actor != square_size &&
          start_actor != right_bottom ->
        [start_actor - 1, start_actor - square_size, start_actor + square_size]

      start_actor > left_bottom && start_actor < right_bottom ->
        [start_actor - 1, start_actor + 1, start_actor - square_size]

      true ->
        left = start_actor - 1
        right = start_actor + 1
        above = start_actor - square_size
        below = start_actor + square_size

        if(below > total_actors) do
          [left, right, above]
        else
          [left, right, above, below]
        end
    end
  end

  def get_2d_neighbor(start_actor, total_actors) do
    square_size = :math.sqrt(total_actors) |> :math.ceil() |> trunc
    num_zeros = :math.pow(square_size, 2) - total_actors

    left_bottom = total_actors - square_size + 1 + num_zeros
    left_top = 1
    right_top = square_size
    right_bottom = total_actors

    cond do
      # left_top actor[1] with 2 neighbors
      start_actor == left_top ->
        select_neighbor([left_top + 1, left_top + square_size])

      # two_neighbors_2d(right, below)

      # right_top actor with 2 neighbors
      start_actor == right_top ->
        select_neighbor([right_top - 1, right_top + square_size])

      # two_neighbors_2d(left, below)

      # bottom_left actor with 2 neighbors
      start_actor == left_bottom ->
        select_neighbor([left_bottom + 1, left_bottom - square_size])

      # two_neighbors_2d(right, above)

      # bottom_right[last_actor] actor with 2 neighbors
      start_actor == total_actors ->
        select_neighbor([right_bottom - 1, right_bottom - square_size])

      # two_neighbors_2d(left, above)

      # topmost row with 3 neighbors
      start_actor < square_size && start_actor > 1 ->
        select_neighbor([start_actor - 1, start_actor + 1, start_actor + square_size])

      # three_neighbors_2d(left, right, below)

      # leftmost column with 3 neighbors
      rem(start_actor, square_size) == 1 && start_actor != 1 && start_actor != left_bottom ->
        select_neighbor([start_actor + 1, start_actor - square_size, start_actor + square_size])

      # three_neighbors_2d(right, top, below)

      # rightmost column with 3 neighbors
      rem(start_actor, square_size) == 0 && start_actor != square_size &&
          start_actor != right_bottom ->
        select_neighbor([start_actor - 1, start_actor - square_size, start_actor + square_size])

      # three_neighbors_2d(left, top, below)

      # bottom row with 3 neighbors
      start_actor > left_bottom && start_actor < right_bottom ->
        select_neighbor([start_actor - 1, start_actor + 1, start_actor - square_size])

      # three_neighbors_2d(left, right, top)

      # condition for all the actors who are in between, i.e have 4 neighbors
      true ->
        left = start_actor - 1
        right = start_actor + 1
        above = start_actor - square_size
        below = start_actor + square_size

        if(below > total_actors) do
          select_neighbor([left, right, above])
        else
          select_neighbor([left, right, above, below])
        end
    end
  end

  def get_sphere_neighbor(start_actor, total_actors) do
    square_size = :math.sqrt(total_actors) |> :math.ceil() |> trunc
    num_zeros = :math.pow(square_size, 2) - total_actors

    left_bottom = total_actors - square_size + 1 + num_zeros
    left_top = 1
    right_top = square_size
    right_bottom = total_actors

    cond do
      # code for left_top actor[1] with 4 neighbors
      start_actor == left_top ->
        select_neighbor([square_size, left_top + 1, left_bottom, left_top + square_size])

      # code for right_top actor with 4 neighbors
      start_actor == right_top ->
        if(:math.pow(square_size, 2) == total_actors) do
          select_neighbor([right_top - 1, 1, total_actors, right_top + square_size])
        else
          select_neighbor([
            right_top - 1,
            1,
            :math.pow(square_size, 2) - square_size,
            right_top + square_size
          ])
        end

      # code for bottom_left actor with 4 neighbors
      start_actor == left_bottom ->
        select_neighbor([total_actors, left_bottom + 1, left_bottom - square_size, 1])

      # code for bottom_right[last_actor] actor with 4 neighbors
      start_actor == total_actors ->
        select_neighbor([
          right_bottom - 1,
          left_bottom,
          right_bottom - square_size,
          rem(total_actors, square_size)
        ])

      start_actor < square_size && start_actor > 1 ->
        add = :math.pow(square_size, 2) - square_size

        if(start_actor + add <= total_actors) do
          select_neighbor([
            start_actor - 1,
            start_actor + 1,
            start_actor + add,
            start_actor + square_size
          ])
        else
          select_neighbor([
            start_actor - 1,
            start_actor + 1,
            start_actor + add - square_size,
            start_actor + square_size
          ])
        end

      rem(start_actor, square_size) == 1 && start_actor != 1 && start_actor != left_bottom ->
        select_neighbor([
          start_actor + square_size - 1,
          start_actor + 1,
          start_actor - square_size,
          start_actor + square_size
        ])

      rem(start_actor, square_size) == 0 && start_actor != square_size &&
          start_actor != right_bottom ->
        select_neighbor([
          start_actor - 1,
          start_actor - square_size + 1,
          start_actor - square_size,
          start_actor + square_size
        ])

      start_actor > left_bottom && start_actor < right_bottom ->
        subtract = :math.pow(square_size, 2) - square_size

        select_neighbor([
          start_actor - 1,
          start_actor + 1,
          start_actor - square_size,
          start_actor - subtract
        ])

      # condition for all the actors who are in between, i.e have 4 neighbors
      true ->
        left = start_actor - 1
        right = start_actor + 1
        above = start_actor - square_size
        below = start_actor + square_size
        subtract = :math.pow(square_size, 2) - square_size

        if(below > total_actors) do
          select_neighbor([left, right, above, start_actor - subtract])
        else
          select_neighbor([left, right, above, below])
        end
    end
  end
end
