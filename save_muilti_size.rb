require 'aws-sdk-s3'
require 'mini_magick'
require 'logger'
THUMB = {'thumb' => '300x300'}
ORIGINAL = {'original' => ''}
MEDIUM = {'medium' => '500x500'}
SMALL = {'small' => '100x100'}
BIG = {'big' => '700x700'}

def lambda_handler(event:, context:)
  logger.info("-----IN Lambda handler @@@ -------")
  logger.info("1 print event:======")
  logger.info(event.inspect)
 
  logger.info("2 end print======")
  res = {}
  # res = event['Records'].map do |record|
  #   key = record.dig('s3', 'object', 'key')
  #   next unless key
  #   puts "Hi this is image name: #{key.inspect} !"

  #   process_key(key)
  # end.compact
  process_key(event)

  {
    statusCode: 200,
    body: {
      message: res,
    }.to_json,
  }
end

def process_key(event,key= "test")
  logger.info "Processing KEY: #{key}"
  bucket = event["pathParameters"]["bucket"]
  style = event["pathParameters"]["style"]
  key = event["pathParameters"]["key"]

  s3 = Aws::S3::Client.new
  # binary = s3.get_object(bucket: ENV['ORIGINAL_IMAGES_BUCKET'], key: key)&.body&.read
  binary = Base64.decode64(event["body"]).split("------WebKitFormBoundaryKwZbNBPCZQyYgDPK\r\nContent-Disposition: form-data; ").last.split("\r\n\r\n").last.gsub("\r\n------WebKitFormBoundarysHaL2u7Mq2k1AEMt--\r\n", "")
  logger.info "before returning---------"
  return unless binary
  logger.info "after returning---------"

  logger.info "Puckage name: #{ENV['ORIGINAL_IMAGES_BUCKET']}"

  image = MiniMagick::Image.read(binary)
  logger.info "image ------: #{image.inspect}---"
  case style
  when THUMB.keys.first
    size = THUMB.values.first
  when MEDIUM.keys.first
    size = MEDIUM.values.first
  when SMALL.keys.first
    size = SMALL.values.first
  when BIG.keys.first
    size = BIG.values.first
  else
    size = ""
  end
  image.resize(size) unless size.empty?

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