#pragma once

#include <obs-module.h>
#include <util/threading.h>
#include <util/circlebuf.h>
#include <stdint.h>
#include <stdbool.h>

// Engine types
typedef enum {
	ENGINE_SHERPA_ONNX = 0,  // CPU-friendly, fast (80ms latency)
	ENGINE_HS_TASNET,        // Low latency, GPU (25ms latency)
	ENGINE_CLEARERVOICE,     // Best for speech (50ms latency)
	ENGINE_SPLEETERRT,       // High quality (100ms latency)
	ENGINE_COUNT
} engine_type_t;

// Forward declarations
typedef struct audio_engine_context_s audio_engine_context_t;

// Engine interface - each engine must implement this
typedef struct {
	const char *name;           // Internal name (e.g., "sherpa")
	const char *display_name;   // UI display name
	const char *model_filename; // Model filename (e.g., "sherpa-vocals.onnx")

	// Lifecycle
	audio_engine_context_t *(*create)(uint32_t sample_rate, uint8_t channels);
	void (*destroy)(audio_engine_context_t *ctx);

	// Processing (processes audio in-place or to output buffer)
	void (*process)(audio_engine_context_t *ctx,
	                const float *input,
	                float *output,
	                size_t frames);

	// Info
	uint32_t (*get_latency_ms)(audio_engine_context_t *ctx);
	bool (*requires_gpu)(void);
} audio_engine_interface_t;

// Audio isolation filter context
struct audio_isolator_filter {
	obs_source_t *context;

	// Engine selection
	engine_type_t current_engine;
	audio_engine_context_t *engine_context;

	// Settings
	float strength;          // 0.0 - 1.0 (blend between original and isolated)
	bool auto_detect;        // Auto-detect music and enable isolation
	bool enabled;            // Master enable/disable
	uint32_t video_delay_ms; // Video delay to compensate for audio latency

	// Audio processing
	pthread_mutex_t mutex;
	uint32_t sample_rate;
	uint8_t channels;

	// Buffering for chunked processing
	struct circlebuf input_buffer;
	struct circlebuf output_buffer;
	size_t chunk_size;       // Optimal chunk size for processing

	// Lip-sync compensation
	uint64_t last_audio_ts;  // Last audio timestamp
	bool first_frame;

	// Performance monitoring
	uint64_t process_time_ns; // Time spent in last processing call
	uint32_t frames_processed;
};

// Global engine registry (defined in audio-isolator-filter.c)
extern audio_engine_interface_t *g_engines[ENGINE_COUNT];

// Engine implementations (each defined in their own file)
extern audio_engine_interface_t sherpa_engine;
extern audio_engine_interface_t hstasnet_engine;
extern audio_engine_interface_t clearervoice_engine;
extern audio_engine_interface_t spleeterrt_engine;

// Helper functions
const char *get_plugin_data_path(const char *filename);
bool download_model_if_needed(const char *model_filename);
