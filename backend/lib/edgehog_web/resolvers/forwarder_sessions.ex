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

defmodule EdgehogWeb.Resolvers.ForwarderSessions do
  alias Edgehog.Astarte
  alias Edgehog.Devices
  alias Edgehog.Devices.Device

  @doc """
  Fetches a forwarder session by its token and the device ID
  """
  def find_forwarder_session(%{device_id: device_id, session_token: session_token}, _resolution) do
    device =
      device_id
      |> Devices.get_device!()
      |> Devices.preload_astarte_resources_for_device()

    with :ok <- validate_device_connected(device),
         {:ok, appengine_client} <- Devices.appengine_client_from_device(device) do
      Astarte.fetch_forwarder_session(appengine_client, device.device_id, session_token)
    end
  end

  defp validate_device_connected(%Device{online: true}), do: :ok
  defp validate_device_connected(%Device{online: false}), do: {:error, :device_disconnected}
end
