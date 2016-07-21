# RoR Resume Uploader App

![minio_ROR1](https://github.com/minio/ror-resumeuploader-app/blob/master/docs/screenshots/minio-RoR1.jpg?raw=true)

This example will guide you through the code to build a simple Ruby on Rails App that works with a Minio Server. We will learn how to use the **aws-sdk** in our rails app to upload objects to a Minio Server. Full code is available here : https://github.com/minio/ror-resumeuploader-app, released under Apache 2.0 License.

## 1. Prerequisites

* Install mc  from [here](https://docs.minio.io/docs/minio-client-quick-start-guide).
* Install Minio Server from [here](https://docs.minio.io/docs/minio ).
* [ruby 2.0](https://www.ruby-lang.org/en/documentation/installation/#package-management-systems) and above
* [rails 4.0](http://guides.rubyonrails.org/v4.0/)  and above


## 2. Dependencies

* aws-sdk v2.0 gem

## 3. Install

Get the code from here and do a bundle install as shown below.

```sh

$ git clone https://github.com/minio/ror-resumeuploader-app
$ cd ror-resumeuploader-app
$ bundle install

```

Apart from all the standard gems to make a rails application, add the aws-sdk v2 gem to our Gemfile.

```ruby

source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.4'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end
# Add the aws sdk gem
gem 'aws-sdk', '~> 2'

```

Note: If running this example on Ubuntu, please include [therubyracer](https://github.com/cowboyd/therubyracer) gem.

## 4. Set Up Bucket

We've created a public minio server called https://play.minio.io:9000 for developers to use as a sandbox. Minio Client mc is preconfigured to use the play server. Create a bucket called 'resumes' on play.minio.io. Use the `mc mb` command to accomplish this.

```sh

$ mc mb play/resumes

```

## 5. Configure AWS SDK with keys to Minio Server

Add an initializer file called aws.rb and set the credentials for Minio Server as shown below. In this example we use Minio's public server https://play.minio.io:9000. This may be replaced by your own instance of a running Minio Server in your own deployments.

```ruby

Aws.config.update(
  region: 'us-east-1',
  endpoint: "https://play.minio.io:9000",
  force_path_style: true,
  credentials: Aws::Credentials.new(
    "Q3AM3UQ867SPQQA43P2F",
    "zuf+tfteSlswRu7BJ86wekitnifILbZam1KYY3TG"
  )
)

```

*Note* - Add the `sslEnabled: false` if the endpoint uses http instead of https.

## 6. Upload Objects

* require 'aws-sdk'  in the controller since we want to create an s3 client.
* create a key to hold the uploaded file object's name. We will write this to our database.
* set the bucket name and the key.
* using the upload_file store the contents of the file.

Since Minio Server is an AWS compatible server, it works seamlessly with the aws-sdk.

```ruby

class UploadsController < ApplicationController
  require 'aws-sdk'
  def new
  end

  def create   
    # Create a new s3 resource with a new s3 client.
    s3 = Aws::S3::Resource.new(Aws::S3::Client.new)  

    # Create a key.
    key = File.basename params[:file].path

    # Set the bucket and the key.
    obj = s3.bucket("resumes").object(params[:file].original_filename)

    # Upload the file.
    obj.upload_file(params[:file].open)

    # Save the uploaded details to the local database.
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

```

NOTE: In this particular example, we complete the upload process using the upload_file api call available via the aws-sdk library. If we want to process the upload on the view, we would post the file to a presigned URL that is able to accept our POST submission.

## 7. Create Views

We create a form which can do a multipart upload. We will use a file_field_tag to choose the file from the filesystem and a submit tag to submit the form to the upload controller for processing.

```xml

<div class="col-offset-lg-2 col-lg-12">
			<h1>Upload your Resume</h1>

			<div class="well"  style="background-color: #EFE0D5;">
				<%= form_tag uploads_path,  :html => {:multipart => true}, enctype: 'multipart/form-data' do %>
			    <%= file_field_tag :file  %>  <br/>

			    <%= submit_tag 'Upload file' , :class=>"btn btn-block btn-danger"  %>
			  <% end %>
			</div>
</div>

```

## 8. Run The App

The full code is available here : https://github.com/minio/ror-resumeuploader-app.  Start the rails server as shown below.

```sh

$ rake db:migrate
$ rails s

```
Now if you visit http://localhost:3000 you should be able to see the example application.

## 9. Explore Further

- [Using `minio-js` client SDK with Minio Server](https://docs.minio.io/docs/javascript-client-quickstart-guide)
- [Minio JavaScript client SDK API Reference](https://docs.minio.io/docs/javascript-client-api-reference)
