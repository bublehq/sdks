# frozen_string_literal: true

require_relative 'test_helper'

class ClientTest < Minitest::Test
  def test_requires_api_key
    old_key = ENV.delete('BUBLE_API_KEY')

    assert_raises(Buble::Error) { Buble::Client.new }
  ensure
    ENV['BUBLE_API_KEY'] = old_key if old_key
  end

  def test_builds_resources_with_custom_transport
    client = Buble::Client.new(api_key: 'sk_test', transport: FakeTransport.new)

    assert_instance_of Buble::MediaModelsResource, client.media_models
    assert_instance_of Buble::FilesResource, client.files
    assert_instance_of Buble::GenerationsResource, client.generations
    assert_instance_of Buble::AppsResource, client.apps
    assert_instance_of Buble::ChatResource, client.chat
  end
end
