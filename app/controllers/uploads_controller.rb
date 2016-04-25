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

