defmodule IdenticonGen do
  @moduledoc """
  Generates a identicon from a string
  """
  @images_path Path.expand("../images", __DIR__)
  def generate(str) do
    str
    |> compute_md5()
    |> pick_color()
    |> build_grid()
    |> filter_odd_squares()
    |> build_pixel_map()
    |> draw_image()
    |> save_image(str)
  end

  def save_image(image, filename) do
    @images_path
    |> Path.join("#{filename}.png")
    |> File.write!(image)
  end

  def compute_md5(str) do
    hex =
      :crypto.hash(:md5, str)
      |> :binary.bin_to_list()

    %IdenticonGen.Image{hex: hex}
  end

  def build_grid(%IdenticonGen.Image{hex: hex, color: color} = image) do
    grid =
      hex
      |> Enum.chunk_every(3)
      |> mirror_rows()
      |> List.flatten()
      |> Enum.with_index()

    %IdenticonGen.Image{hex: hex, color: color, grid: grid}
  end

  def draw_image(%IdenticonGen.Image{hex: _, color: color, grid: _, pixel_map: pixel_map}) do
    img = :egd.create(250, 250)
    fill = :egd.color(color)

    pixel_map
    |> Enum.each(fn {start, stop} ->
      {x1, x2} = start
      {y1, y2} = stop
      :egd.filledRectangle(img, start, stop, fill)
    end)

    :egd.render(img)
  end

  def filter_odd_squares(%IdenticonGen.Image{hex: hex, color: color, grid: grid}) do
    odd_grid = Enum.filter(grid, fn {sqr, _idx} -> rem(sqr, 2) == 0 end)
    %IdenticonGen.Image{hex: hex, color: color, grid: odd_grid}
  end

  def build_pixel_map(%IdenticonGen.Image{hex: hex, color: color, grid: grid}) do
    pixel_map =
      Enum.map(grid, fn {_sqr, idx} ->
        vertical = div(idx, 5) * 50
        horizontal = rem(idx, 5) * 50

        top_left = {horizontal, vertical}
        bottom_right = {horizontal + 50, vertical + 50}
        {top_left, bottom_right}
      end)

    %IdenticonGen.Image{hex: hex, color: color, grid: grid, pixel_map: pixel_map}
  end

  def mirror_rows([hd | []]), do: []

  @spec mirror_rows(nonempty_maybe_improper_list) :: [...]
  def mirror_rows([first | rest] = rows) when is_list(first) do
    [first ++ rev(first) | mirror_rows(rest)]
  end

  def rev(row) do
    [hd(tl(row)) | [hd(row)]]
  end

  @spec pick_color(any) :: nil
  def pick_color(%IdenticonGen.Image{hex: hex} = image) do
    pick_color(image, hex)
  end

  def pick_color(%IdenticonGen.Image{hex: _} = image, [red | [green | [blue | _rest]]]) do
    %IdenticonGen.Image{image | color: {red, green, blue}}
  end

  def numbers_from_str(%IdenticonGen.Image{hex: hex}) do
  end
end
