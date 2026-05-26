# frozen_string_literal: true

require_relative 'test_helper'

class FilesTest < Minitest::Test
  def test_uploads_multipart_file_and_fields
    transport = FakeTransport.new
    transport.enqueue_response('data' => { 'url' => 'https://example.com/file.png' })
    resource = Buble::FilesResource.new(transport)
    upload = Buble::FileUpload.from_io(StringIO.new('data'), filename: 'reference.png', content_type: 'image/png')

    resource.upload(upload, file_type: 'image', model: 'google/nano-banana', mode: 'image_to_image')

    request = transport.requests[0]
    assert_equal '/api/v1/files', request[:path]
    assert_equal 'image', request[:fields][:file_type]
    assert_equal 'google/nano-banana', request[:fields][:model]
    assert_equal 'reference.png', request[:file].filename
    assert_equal 'image/png', request[:file].content_type
  end
end
