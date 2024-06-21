#
# This file is part of Edgehog.
#
# Copyright 2024 SECO Mind Srl
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
# SPDX-License-Identifier: Apache-2.0
#

defmodule Edgehog.Devices.Device.ManualRelationships.DeviceGroups do
  use Ash.Resource.ManualRelationship
  require Ash.Query
  require Ecto.Query

  alias Edgehog.Devices.Device

  @impl true
  def load(devices, _opts, %{query: group_query}) do
    device_ids = Enum.map(devices, & &1.id)

    filtered_devices_query =
      Device
      |> Ash.Query.select([:id])
      |> Ash.Query.filter(id in ^device_ids)

    # This produces a `%{device_id1 => [group1, group2], device_id2 => [group2, group3], ...}` map
    device_id_to_groups =
      group_query
      |> Ash.Query.load(devices: filtered_devices_query)
      |> Ash.read!()
      |> Enum.flat_map(&Enum.map(&1.devices, fn device -> {device.id, &1} end))
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      |> Map.new()
      |> Map.take(device_ids)

    {:ok, device_id_to_groups}
  end

  # @impl true
  # def ash_postgres_join(query, _opts, current_binding, as_binding, :inner, destination_query) do
  #   {:ok,
  #    Ecto.Query.from(_ in query,
  #      join: dest in ^destination_query,
  #      as: ^as_binding,
  #      on: dest.post_id == as(^current_binding).id,
  #      on: fragment("strpos(?, ?) > 0", dest.title, as(^current_binding).title)
  #    )}
  # end

  # @impl true
  # def ash_postgres_join(query, _opts, current_binding, as_binding, :left, destination_query) do
  #   {:ok,
  #    Ecto.Query.from(_ in query,
  #      left_join: dest in ^destination_query,
  #      as: ^as_binding,
  #      on: dest.post_id == as(^current_binding).id,
  #      on: fragment("strpos(?, ?) > 0", dest.title, as(^current_binding).title)
  #    )}
  # end

  @impl true
  def ash_postgres_subquery(opts, current_binding, as_binding, destination_query) do
    IO.inspect(
      opts: opts,
      current_binding: current_binding,
      as_binding: as_binding,
      destination_query: destination_query
    )

    {:ok,
     Ecto.Query.from(_ in destination_query,
       where: parent_as(^current_binding).device_id == as(^as_binding).selector
     )}
  end
end
