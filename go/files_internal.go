package buble

import (
	"net/textproto"
	"os"
	"strings"
)

func openFile(path string) (*os.File, error) {
	return os.Open(path)
}

func textprotoMIMEHeader(values map[string]string) textproto.MIMEHeader {
	header := make(textproto.MIMEHeader, len(values))
	for key, value := range values {
		header.Set(key, value)
	}
	return header
}

func escapeQuotes(value string) string {
	return strings.ReplaceAll(value, `"`, `\"`)
}
