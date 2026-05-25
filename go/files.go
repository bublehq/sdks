package buble

import (
	"bytes"
	"context"
	"io"
	"mime"
	"mime/multipart"
	"net/http"
	"path/filepath"
)

// FileUpload represents a file source that can be uploaded to Buble.
type FileUpload struct {
	filename string
	open     func() (io.ReadCloser, error)
}

// FileFromPath creates a file upload source from a local path. The file is
// streamed from disk when the request is sent.
func FileFromPath(path string) FileUpload {
	return FileUpload{
		filename: filepath.Base(path),
		open: func() (io.ReadCloser, error) {
			return openFile(path)
		},
	}
}

// FileFromBytes creates a file upload source from bytes.
func FileFromBytes(data []byte, filename string) FileUpload {
	return FileUpload{
		filename: filename,
		open: func() (io.ReadCloser, error) {
			return io.NopCloser(bytes.NewReader(data)), nil
		},
	}
}

// FileFromReader creates a file upload source from an io.Reader. If the reader
// also implements io.Closer, it is closed after the upload body is written.
func FileFromReader(reader io.Reader, filename string) FileUpload {
	return FileUpload{
		filename: filename,
		open: func() (io.ReadCloser, error) {
			if closer, ok := reader.(io.ReadCloser); ok {
				return closer, nil
			}
			return io.NopCloser(reader), nil
		},
	}
}

// FilesService provides source media upload methods.
type FilesService struct {
	client *Client
}

// Upload uploads an image, video, or audio file for use as generation input.
func (s *FilesService) Upload(ctx context.Context, file FileUpload, options ...UploadOption) (*Envelope[UploadedFile], error) {
	config := uploadConfig{}
	for _, option := range options {
		option(&config)
	}

	filename := firstNonEmpty(config.filename, file.filename, "file")
	contentType := firstNonEmpty(config.contentType, inferContentType(filename), "application/octet-stream")

	body, contentTypeHeader, err := multipartUploadBody(file, filename, contentType, config)
	if err != nil {
		return nil, err
	}

	var out Envelope[UploadedFile]
	if err := s.client.doBody(ctx, http.MethodPost, "/api/v1/files", body, contentTypeHeader, &out); err != nil {
		return nil, err
	}
	return &out, nil
}

func multipartUploadBody(file FileUpload, filename, contentType string, config uploadConfig) (io.Reader, string, error) {
	reader, writer := io.Pipe()
	multipartWriter := multipart.NewWriter(writer)

	go func() {
		defer writer.Close()
		defer multipartWriter.Close()

		fields := map[string]string{
			"file_type": config.fileType,
			"model":     config.model,
			"mode":      config.mode,
		}
		for key, value := range fields {
			if value == "" {
				continue
			}
			if err := multipartWriter.WriteField(key, value); err != nil {
				_ = writer.CloseWithError(err)
				return
			}
		}

		source, err := file.open()
		if err != nil {
			_ = writer.CloseWithError(err)
			return
		}
		defer source.Close()

		part, err := multipartWriter.CreatePart(textprotoMIMEHeader(map[string]string{
			"Content-Disposition": `form-data; name="file"; filename="` + escapeQuotes(filename) + `"`,
			"Content-Type":        contentType,
		}))
		if err != nil {
			_ = writer.CloseWithError(err)
			return
		}
		if _, err := io.Copy(part, source); err != nil {
			_ = writer.CloseWithError(err)
			return
		}
	}()

	return reader, multipartWriter.FormDataContentType(), nil
}

func inferContentType(filename string) string {
	if filename == "" {
		return "application/octet-stream"
	}
	if contentType := mime.TypeByExtension(filepath.Ext(filename)); contentType != "" {
		return contentType
	}
	return "application/octet-stream"
}
