# frozen_string_literal: true

module Buble
  class FileUpload
    attr_reader :io, :filename, :content_type, :close_after

    def initialize(io:, filename:, content_type: 'application/octet-stream', close_after: false)
      @io = io
      @filename = filename
      @content_type = content_type
      @close_after = close_after
    end

    def self.from_path(path, content_type: 'application/octet-stream')
      new(
        io: File.open(path, 'rb'),
        filename: File.basename(path),
        content_type: content_type,
        close_after: true
      )
    end

    def self.from_io(io, filename:, content_type: 'application/octet-stream')
      new(io: io, filename: filename, content_type: content_type, close_after: false)
    end

    def to_http_part
      HTTP::FilePart.new(io: io, filename: filename, content_type: content_type, close_after: close_after)
    end
  end

  class FilesResource
    def initialize(http)
      @http = http
    end

    def upload(file, file_type: nil, model: nil, mode: nil, **fields)
      upload = coerce_upload(file)
      @http.multipart(
        '/api/v1/files',
        fields: { file_type: file_type, model: model, mode: mode }.merge(fields),
        file: upload.to_http_part
      )
    end

    private

    def coerce_upload(file)
      return file if file.is_a?(FileUpload)
      return FileUpload.from_path(file) if file.is_a?(String)

      if file.respond_to?(:read)
        filename = file.respond_to?(:path) && file.path ? File.basename(file.path) : 'upload'
        return FileUpload.from_io(file, filename: filename)
      end

      raise Error, 'file must be a path, IO, or Buble::FileUpload.'
    end
  end
end
