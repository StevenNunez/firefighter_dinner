# close = results |> Enum.filter(fn r -> Enum.any?(r, fn {dist, _, _} -> dist < 1 end) end)

defmodule FirefighterDinner.FireHouse do
  def all do
    priv_dir = :code.priv_dir(:firefighter_dinner) |> to_string

    File.read!(priv_dir <> "/firehouses.json")
    |> Jason.decode!(keys: :atoms)
    |> Enum.map(fn firehouse ->
      Map.new(firehouse, fn
        {loc, coord} when loc in [:latitude, :longitude] -> {loc, String.to_float(coord)}
        any -> any
      end)
    end)
    |> Enum.filter(&(&1[:latitude]))
  end
end

defmodule FirefighterDinner.Bodegas do
  def all do
    priv_dir = :code.priv_dir(:firefighter_dinner) |> to_string

    File.read!(priv_dir <> "/bodegas.json")
    |> Jason.decode!(keys: :atoms)
    |> Enum.map(fn bodegas ->
      Map.new(bodegas, fn
        {loc, coord} when loc in [:latitude, :longitude] -> {loc, String.to_float(coord)}
        any -> any
      end)
    end)
    |> Enum.filter(&(&1[:latitude]))
  end
end

defmodule FirefighterDinner.Main do
  def sorted_bodegas do
    FirefighterDinner.FireHouse.all
    |> Enum.map(fn fh ->
      Task.async(fn -> sorted_bodegas(fh) end)
    end)
    |> Enum.map(&Task.await(&1))
  end

  def sorted_bodegas(firehouse) do
    FirefighterDinner.Bodegas.all
    |> Enum.map(fn bodega ->
      {FirefighterDinner.DiffCalculator.distance(firehouse, bodega), firehouse, bodega}
    end)
    |> Enum.sort(fn {dist1, _, _}, {dist2, _, _} -> dist1 < dist2 end)
  end
end

defmodule FirefighterDinner.DiffCalculator do
  def distance(loc1, loc2) do
    lat1 = loc1.latitude
    lon1 = loc1.longitude
    lat2 = loc2.latitude
    lon2 = loc2.longitude
    earth_radius = 6_371 #km

    lat_diff = lat2 - lat1 |> degrees_to_radians
    lon_diff = lon2 - lon1 |> degrees_to_radians

    a =
      :math.sin(lat_diff / 2) * :math.sin(lat_diff / 2) +
        :math.cos(degrees_to_radians(lat1)) * :math.cos(degrees_to_radians(lat2)) *
          :math.sin(lon_diff / 2) * :math.sin(lon_diff / 2)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))

    earth_radius * c
  end

  defp degrees_to_radians(degree) do
    degree * :math.pi / 180
  end
end
