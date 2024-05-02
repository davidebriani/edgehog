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

defmodule Edgehog.Devices.Device.Calculations.DeviceLocation do
  use Ash.Resource.Calculation

  alias Edgehog.Devices.Device.Types.DeviceLocation
  alias Edgehog.Geolocation
  alias Edgehog.Geolocation.Coordinates

  @impl true
  def calculate(devices, _opts, _context) do
    Enum.map(devices, fn device ->
      case fetch_device_location(device) do
        {:ok, location} -> location
        _ -> nil
      end
    end)
  end

  defp fetch_device_location(device) do
    with {:ok, position} <- Geolocation.geolocate(device) do
      coordinates = %Coordinates{
        latitude: position.latitude,
        longitude: position.longitude
      }

      address =
        case Geolocation.reverse_geocode(coordinates) do
          {:ok, location} -> location
          _ -> nil
        end

      device_location = %DeviceLocation{
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        altitude_accuracy: position.altitude_accuracy,
        heading: position.heading,
        speed: position.speed,
        timestamp: position.timestamp,
        address: address
      }

      {:ok, device_location}
    end
  end
end
