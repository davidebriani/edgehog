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

defmodule Edgehog.Assets.Uploaders.ApplianceModelPicture do
  use Waffle.Definition

  @acl :public_read
  @versions [:original]

  @extension_allowlist ~w(.jpg .jpeg .gif .png .svg)

  def validate({file, _}) do
    file_extension =
      file.file_name
      |> Path.extname()
      |> String.downcase()

    Enum.member?(@extension_allowlist, file_extension)
  end

  def s3_object_headers(_version, {file, _scope}) do
    [content_type: MIME.from_path(file.file_name)]
  end

  def gcs_object_headers(_version, {file, _scope}) do
    [contentType: MIME.from_path(file.file_name)]
  end

  def gcs_optional_params(_version, {_file, _scope}) do
    [predefinedAcl: "publicRead"]
  end

  def storage_dir(_version, {_file, appliance_model}) do
    "uploads/tenants/#{appliance_model.tenant_id}/appliance_models/#{appliance_model.handle}/picture"
  end
end
