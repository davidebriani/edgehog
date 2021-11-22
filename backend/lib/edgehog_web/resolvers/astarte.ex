#
# This file is part of Edgehog.
#
# Copyright 2021 SECO Mind Srl
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

defmodule EdgehogWeb.Resolvers.Astarte do
  alias Edgehog.Astarte
  alias Edgehog.Astarte.Device
  alias Edgehog.Geolocation

  def find_device(%{id: id}, _resolution) do
    {:ok, Astarte.get_device!(id)}
  end

  def list_devices(_parent, %{filter: filter}, _context) do
    {:ok, Astarte.list_devices(filter)}
  end

  def list_devices(_parent, _args, _context) do
    {:ok, Astarte.list_devices()}
  end

  def get_hardware_info(%Device{} = device, _args, _context) do
    Astarte.get_hardware_info(device)
  end

  def fetch_storage_usage(%Device{} = device, _args, _context) do
    case Astarte.fetch_storage_usage(device) do
      {:ok, storage_units} -> {:ok, storage_units}
      _ -> {:ok, nil}
    end
  end

  def fetch_wifi_scan_results(%Device{} = device, _args, _context) do
    case Astarte.fetch_wifi_scan_results(device) do
      {:ok, wifi_scan_results} -> {:ok, wifi_scan_results}
      _ -> {:ok, nil}
    end
  end

  def fetch_device_location(%Device{} = device, _args, _context) do
    case Geolocation.fetch_location(device) do
      {:ok, location} -> {:ok, location}
      _ -> {:ok, nil}
    end
  end
end
