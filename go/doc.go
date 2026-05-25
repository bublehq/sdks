// Package buble provides a server-side Go client for the Buble public API.
//
// The client supports media model discovery, file uploads, asynchronous image
// and video generation, preconfigured app workflows, and chat model calls
// through OpenAI, Anthropic Messages, and Gemini-compatible API formats.
//
// Use NewClient to construct a client. The client reads BUBLE_API_KEY and
// BUBLE_BASE_URL from the environment when they are not configured explicitly.
//
// Generation requests use Buble's flat public API shape. Stable generation
// fields are represented directly on CreateGenerationRequest, and model-specific
// parameters are passed through Params so newly configured Buble models can be
// used without requiring an SDK release.
//
// API keys are server credentials. Do not expose them in client-side code.
package buble
