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

defmodule EdgehogWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern
  import_types EdgehogWeb.Schema.AstarteTypes
  import_types EdgehogWeb.Schema.AppliancesTypes
  import_types EdgehogWeb.Schema.LocalizationTypes
  import_types EdgehogWeb.Schema.TenantsTypes
  import_types Absinthe.Plug.Types
  import_types Absinthe.Type.Custom

  alias EdgehogWeb.Middleware
  alias EdgehogWeb.Resolvers

  def middleware(middleware, _field, %Absinthe.Type.Object{identifier: type})
      when type in [:query, :subscription, :mutation] do
    middleware ++ [Middleware.ErrorHandler]
  end

  def middleware(middleware, _field, _object) do
    middleware
  end

  node interface do
    resolve_type fn
      %Edgehog.Astarte.Device{}, _ ->
        :device

      %Edgehog.Appliances.HardwareType{}, _ ->
        :hardware_type

      %Edgehog.Appliances.ApplianceModel{}, _ ->
        :appliance_model

      _, _ ->
        nil
    end
  end

  query do
    node field do
      resolve fn
        %{type: :device, id: id}, _ ->
          Resolvers.Astarte.find_device(%{id: id}, %{})

        %{type: :hardware_type, id: id}, _ ->
          Resolvers.Appliances.find_hardware_type(%{id: id}, %{})

        %{type: :appliance_model, id: id}, _ ->
          Resolvers.Appliances.find_appliance_model(%{id: id}, %{})
      end
    end

    import_fields :astarte_queries
    import_fields :appliances_queries
    import_fields :tenants_queries
  end

  mutation do
    import_fields :appliances_mutations
  end
end
