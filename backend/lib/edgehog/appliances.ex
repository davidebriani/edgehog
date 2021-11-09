#
# This file is part of Edgehog.
#
# Copyright 2021 SECO Mind
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

defmodule Edgehog.Appliances do
  @moduledoc """
  The Appliances context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Edgehog.Repo

  alias Edgehog.Appliances.HardwareType
  alias Edgehog.Appliances.HardwareTypePartNumber

  @doc """
  Returns the list of hardware_types.

  ## Examples

      iex> list_hardware_types()
      [%HardwareType{}, ...]

  """
  def list_hardware_types do
    Repo.all(HardwareType)
    |> Repo.preload(:part_numbers)
  end

  @doc """
  Gets a single hardware_type.

  Raises `Ecto.NoResultsError` if the Hardware type does not exist.

  ## Examples

      iex> get_hardware_type!(123)
      %HardwareType{}

      iex> get_hardware_type!(456)
      ** (Ecto.NoResultsError)

  """
  def get_hardware_type!(id) do
    Repo.get!(HardwareType, id)
    |> Repo.preload(:part_numbers)
  end

  @doc """
  Creates a hardware_type.

  ## Examples

      iex> create_hardware_type(%{field: value})
      {:ok, %HardwareType{}}

      iex> create_hardware_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_hardware_type(attrs \\ %{}) do
    {part_numbers, attrs} = Map.pop(attrs, :part_numbers, [])

    changeset =
      %HardwareType{tenant_id: Repo.get_tenant_id()}
      |> HardwareType.changeset(attrs)

    Multi.new()
    |> Multi.run(:assoc_part_numbers, fn _repo, _changes ->
      {:ok, insert_or_get_hardware_type_part_numbers(changeset, part_numbers, required: true)}
    end)
    |> Multi.insert(:hardware_type, fn %{assoc_part_numbers: changeset} ->
      changeset
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{hardware_type: hardware_type}} ->
        {:ok, Repo.preload(hardware_type, :part_numbers)}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  defp insert_or_get_hardware_type_part_numbers(changeset, part_numbers, opts \\ [])

  defp insert_or_get_hardware_type_part_numbers(changeset, [], opts) do
    if opts[:required] do
      Ecto.Changeset.add_error(changeset, :part_numbers, "are required")
    else
      changeset
    end
  end

  defp insert_or_get_hardware_type_part_numbers(changeset, part_numbers, _opts) do
    timestamp =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    maps =
      Enum.map(
        part_numbers,
        &%{
          tenant_id: Repo.get_tenant_id(),
          part_number: &1,
          inserted_at: timestamp,
          updated_at: timestamp
        }
      )

    # TODO: check for conflicts (i.e. part numbers existing but associated with another hardware type)
    Repo.insert_all(HardwareTypePartNumber, maps, on_conflict: :nothing)
    query = from pn in HardwareTypePartNumber, where: pn.part_number in ^part_numbers
    part_numbers = Repo.all(query)

    Ecto.Changeset.put_assoc(changeset, :part_numbers, part_numbers)
  end

  @doc """
  Updates a hardware_type.

  ## Examples

      iex> update_hardware_type(hardware_type, %{field: new_value})
      {:ok, %HardwareType{}}

      iex> update_hardware_type(hardware_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_hardware_type(%HardwareType{} = hardware_type, attrs) do
    {part_numbers, attrs} = Map.pop(attrs, :part_numbers, [])

    changeset = HardwareType.changeset(hardware_type, attrs)

    Multi.new()
    |> Multi.run(:assoc_part_numbers, fn _repo, _changes ->
      {:ok, insert_or_get_hardware_type_part_numbers(changeset, part_numbers)}
    end)
    |> Multi.update(:hardware_type, fn %{assoc_part_numbers: changeset} ->
      changeset
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{hardware_type: hardware_type}} ->
        {:ok, Repo.preload(hardware_type, :part_numbers)}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  @doc """
  Deletes a hardware_type.

  ## Examples

      iex> delete_hardware_type(hardware_type)
      {:ok, %HardwareType{}}

      iex> delete_hardware_type(hardware_type)
      {:error, %Ecto.Changeset{}}

  """
  def delete_hardware_type(%HardwareType{} = hardware_type) do
    Repo.delete(hardware_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking hardware_type changes.

  ## Examples

      iex> change_hardware_type(hardware_type)
      %Ecto.Changeset{data: %HardwareType{}}

  """
  def change_hardware_type(%HardwareType{} = hardware_type, attrs \\ %{}) do
    HardwareType.changeset(hardware_type, attrs)
  end
end
