 
 # ResumeUploader Application, (C) 2016 Minio, Inc.
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #     http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 #
 

class UploadsController < ApplicationController
  require 'aws-sdk'
  def new
  end

  def create
     
     s3 = Aws::S3::Resource.new(Aws::S3::Client.new)   
     key = File.basename params[:file].path
     obj = s3.bucket("resumes").object(params[:file].original_filename)
     obj.upload_file(params[:file].open)
   
    @upload = Upload.new(
            url: obj.public_url,
            name: obj.key
    )     
           
    if @upload.save
        redirect_to uploads_path, success: 'File successfully uploaded'
    else
        flash.now[:notice] = 'There was an error'
        render :new
    end
  end

  def index
    @uploads = Upload.all
  end
  
  
end

