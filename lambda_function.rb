require 'aws-sdk-s3'
require 'mini_magick'
require 'logger'

def lambda_handler(event:, context:)
  puts event.inspect
  process_key(event)
  {
    statusCode: 200,
    body: {
      message: "Resized image successfully!",
    }.to_json,
  }
end

def process_key(event)
  bucket = ENV["RESIZED_IMAGES_BUCKET"]
  target_resize = event["pathParameters"]["target-resize"]
  key = event["pathParameters"]["image-key"]
  return unless key || target_resize

  s3 = Aws::S3::Client.new
  binary = s3.get_object(bucket: ENV['ORIGINAL_IMAGES_BUCKET'], key: key)&.body&.read
  # binary = Base64.decode64(event["body"]).split("------WebKitFormBoundaryKwZbNBPCZQyYgDPK\r\nContent-Disposition: form-data; ").last.split("\r\n\r\n").last.gsub("\r\n------WebKitFormBoundarysHaL2u7Mq2k1AEMt--\r\n", "")
  return unless binary

  image = MiniMagick::Image.read(binary)
  
  image.resize(target_resize)

  s3.put_object(bucket: bucket, key: key, body: File.read(image.tempfile))
  key
rescue Aws::S3::Errors::NoSuchKey
  logger.error("KEY: #{key} not found")
  nil
end

private

def logger
  @logger ||= Logger.new(STDOUT)
end