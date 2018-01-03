# RoR Resume Uploader App [![Slack](https://slack.minio.io/slack?type=svg)](https://slack.minio.io)

![minio_ROR1](https://github.com/minio/ror-resumeuploader-app/blob/master/docs/screenshots/minio-RoR1.jpg?raw=true)

本示例将会指导你使用Ruby on Rails和Minio Server构建一个简单的app。我们将学习如何在我们的rails app中使用**aws-sdk**上传对象到一个Minio Server上。你可以通过[这里](https://github.com/minio/ror-resumeuploader-app)获取完整的代码，代码是以Apache 2.0 License发布的。

## 1. 前提条件

* 从[这里](https://docs.minio.io/docs/minio-client-quickstart-guide)下载并安装mc。
* 从[这里](https://docs.minio.io/docs/minio )下载并安装Minio Server。
* [ruby 2.0](https://www.ruby-lang.org/en/documentation/installation/#package-management-systems)。
* [rails 4.0](http://guides.rubyonrails.org/v4.0/)。


## 2. 依赖

* aws-sdk v2.0 gem

## 3. 安装

按下面所示获取代码，并调用bundle install。

```sh
git clone https://github.com/minio/ror-resumeuploader-app
cd ror-resumeuploader-app
bundle install
```

除了rails应用需要的的所有的标准gem外，添加一个aws-sdk v2 gem到Gemfile中。

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

注意: 如果是在Ubuntu上运行这个示例，请添加[therubyracer](https://github.com/cowboyd/therubyracer) gem。

## 4. 设置存储桶

我们已经创建了一个公开的Minio Server(https://play.minio.io:9000) 供大家进行开发和测试。Minio Client `mc`已经预设好和play server的配置。调用`mc mb`命令，在`play.minio.io:9000`上创建一个名叫`resumes`的存储桶。 

```sh
mc mb play/resumes
```

## 5. 配置AWS SDK连接Minio Server

添加一个名叫aws.rb的初始化文件，并按下面所示设置好连接Minio Server的认证信息。在本示例中我们使用的是Minio的公开服务https://play.minio.io:9000 ，你也可以改成你自己的。

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

*注意* - 如果服务用的是http而不是https的话，加上`sslEnabled: false`配置。

## 6. 上传对象

* 在controller中require 'aws-sdk'。
* 创建一个key用于持有文件对象的名称。我们会将这个写到数据库中。
* 设置存储桶名称和key。
* 使用upload_file存储文件内容。

由于Minio Server与AWS S3完美兼容，所以它能与aws-sdk无缝对接。

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

注意: 在这个例子中，我们使用aws-sdk库提供的upload_file api来完成上传过程。 如果我们想要在view上处理上传，我们会将文件发布到一个能够接受我们的POST提交的presigned URL。

## 7. 创建Views

创建一个可以做multipart upload的form。我们将使用file_field_tag来从本地选择文件，submit tag来提供form到upload controller进行处理。

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

## 8. 运行App

你可以从[这里](https://github.com/minio/ror-resumeuploader-app)获取完整的代码。按下面所示启动这个rails服务。

```sh
rake db:migrate
rails s
```
现在如果你访问http://localhost:3000 ，你应该可以看到这个示例程序。

## 9. Explore Further

- [Using `minio-js` client SDK with Minio Server](https://docs.minio.io/docs/javascript-client-quickstart-guide)
- [Minio JavaScript client SDK API Reference](https://docs.minio.io/docs/javascript-client-api-reference)
