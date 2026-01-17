/*
 * Audio Isolator Filter - Main Implementation
 *
 * This filter processes audio in real-time to isolate vocals and remove background music.
 * It includes automatic lip-sync compensation by delaying video to match audio processing latency.
 */

#include "audio-isolator-filter.h"
#include <util/platform.h>
#include <util/dstr.h>
#include <media-io/audio-resampler.h>
#include <obs-frontend-api.h>

#define PLUGIN_NAME "stream_audio_isolator"
#define PLUGIN_VERSION "1.0.0"

// Settings property names
#define S_ENGINE "engine"
#define S_STRENGTH "strength"
#define S_AUTO_DETECT "auto_detect"
#define S_ENABLED "enabled"
#define S_VIDEO_DELAY "video_delay_ms"

// Text (will be localized)
#define T_(s) obs_module_text(s)
#define TEXT_ENGINE T_("Engine")
#define TEXT_STRENGTH T_("IsolationStrength")
#define TEXT_AUTO_DETECT T_("AutoDetect")
#define TEXT_ENABLED T_("Enabled")
#define TEXT_VIDEO_DELAY T_("VideoDelay")

// Engine registry
audio_engine_interface_t *g_engines[ENGINE_COUNT] = {
	&sherpa_engine,
	&hstasnet_engine,
	&clearervoice_engine,
	&spleeterrt_engine
};

// ===== HELPER FUNCTIONS =====

const char *get_plugin_data_path(const char *filename)
{
	static char path[512];
	const char *module_path = obs_get_module_data_path(obs_current_module());
	snprintf(path, sizeof(path), "%s/%s", module_path, filename);
	return path;
}

bool download_model_if_needed(const char *model_filename)
{
	const char *model_path = get_plugin_data_path(model_filename);

	if (os_file_exists(model_path)) {
		blog(LOG_INFO, "Model already exists: %s", model_path);
		return true;
	}

	// TODO: Implement model download from GitHub releases
	blog(LOG_WARNING, "Model not found: %s", model_path);
	blog(LOG_INFO, "Please download models manually from releases page");
	return false;
}

// ===== VIDEO DELAY COMPENSATION =====

static void apply_video_delay(obs_source_t *source, uint32_t delay_ms)
{
	// Apply async delay to the parent source (usually the scene or source with video)
	obs_source_t *parent = obs_filter_get_parent(source);
	if (!parent) {
		blog(LOG_WARNING, "Cannot apply video delay: no parent source");
		return;
	}

	// Set the sync offset for video to compensate for audio processing delay
	int64_t delay_ns = (int64_t)delay_ms * 1000000LL;
	obs_source_set_sync_offset(parent, delay_ns);

	blog(LOG_INFO, "Applied video delay: %u ms to compensate for audio latency", delay_ms);
}

// ===== FILTER LIFECYCLE =====

static const char *audio_isolator_get_name(void *unused)
{
	UNUSED_PARAMETER(unused);
	return obs_module_text("AudioIsolator");
}

static void *audio_isolator_create(obs_data_t *settings, obs_source_t *source)
{
	struct audio_isolator_filter *filter = bzalloc(sizeof(*filter));
	filter->context = source;
	filter->first_frame = true;

	pthread_mutex_init(&filter->mutex, NULL);

	// Initialize circular buffers
	circlebuf_init(&filter->input_buffer);
	circlebuf_init(&filter->output_buffer);

	// Default chunk size (will be adjusted based on sample rate)
	filter->chunk_size = 1024;

	blog(LOG_INFO, "Audio Isolator Filter created");

	// Load settings and initialize
	audio_isolator_update(filter, settings);

	return filter;
}

static void audio_isolator_destroy(void *data)
{
	struct audio_isolator_filter *filter = data;

	pthread_mutex_lock(&filter->mutex);

	// Destroy current engine
	if (filter->engine_context) {
		audio_engine_interface_t *engine = g_engines[filter->current_engine];
		engine->destroy(filter->engine_context);
		filter->engine_context = NULL;
	}

	// Free buffers
	circlebuf_free(&filter->input_buffer);
	circlebuf_free(&filter->output_buffer);

	pthread_mutex_unlock(&filter->mutex);
	pthread_mutex_destroy(&filter->mutex);

	bfree(filter);
	blog(LOG_INFO, "Audio Isolator Filter destroyed");
}

static void audio_isolator_update(void *data, obs_data_t *settings)
{
	struct audio_isolator_filter *filter = data;

	pthread_mutex_lock(&filter->mutex);

	// Get settings
	const char *engine_name = obs_data_get_string(settings, S_ENGINE);
	filter->strength = (float)obs_data_get_double(settings, S_STRENGTH);
	filter->auto_detect = obs_data_get_bool(settings, S_AUTO_DETECT);
	filter->enabled = obs_data_get_bool(settings, S_ENABLED);
	filter->video_delay_ms = (uint32_t)obs_data_get_int(settings, S_VIDEO_DELAY);

	// Determine engine type
	engine_type_t new_engine = ENGINE_SHERPA_ONNX;
	for (int i = 0; i < ENGINE_COUNT; i++) {
		if (strcmp(engine_name, g_engines[i]->name) == 0) {
			new_engine = i;
			break;
		}
	}

	// Switch engine if changed
	if (new_engine != filter->current_engine || !filter->engine_context) {
		// Destroy old engine
		if (filter->engine_context) {
			g_engines[filter->current_engine]->destroy(filter->engine_context);
			filter->engine_context = NULL;
		}

		// Download model if needed
		audio_engine_interface_t *engine = g_engines[new_engine];
		if (!download_model_if_needed(engine->model_filename)) {
			blog(LOG_ERROR, "Failed to load model for engine: %s", engine->display_name);
			pthread_mutex_unlock(&filter->mutex);
			return;
		}

		// Create new engine
		filter->current_engine = new_engine;
		filter->engine_context = engine->create(filter->sample_rate, filter->channels);

		if (filter->engine_context) {
			blog(LOG_INFO, "Switched to engine: %s", engine->display_name);

			// Get engine latency and update video delay if auto-mode
			uint32_t latency_ms = engine->get_latency_ms(filter->engine_context);
			if (filter->video_delay_ms == 0) {
				// Auto-calculate video delay based on engine latency
				filter->video_delay_ms = latency_ms;
			}

			// Apply video delay compensation
			apply_video_delay(filter->context, filter->video_delay_ms);

			blog(LOG_INFO, "Engine latency: %u ms, Video delay: %u ms",
			     latency_ms, filter->video_delay_ms);
		} else {
			blog(LOG_ERROR, "Failed to create engine: %s", engine->display_name);
		}
	}

	pthread_mutex_unlock(&filter->mutex);
}

// ===== AUDIO PROCESSING =====

static struct obs_audio_data *audio_isolator_filter_audio(void *data,
                                                           struct obs_audio_data *audio)
{
	struct audio_isolator_filter *filter = data;

	if (!filter->enabled || !filter->engine_context) {
		return audio; // Pass through
	}

	pthread_mutex_lock(&filter->mutex);

	// Get audio info
	const uint32_t frames = audio->frames;
	const uint8_t channels = get_audio_channels(audio->speakers);

	// Initialize sample rate on first frame
	if (filter->sample_rate == 0 || filter->first_frame) {
		const struct audio_output_info *aoi = audio_output_get_info(obs_get_audio());
		filter->sample_rate = aoi->samples_per_sec;
		filter->channels = channels;
		filter->first_frame = false;

		blog(LOG_INFO, "Audio initialized: %u Hz, %u channels",
		     filter->sample_rate, channels);
	}

	// Start performance timer
	uint64_t start_time = os_gettime_ns();

	// Allocate processing buffers
	const size_t sample_count = frames * channels;
	float *input_interleaved = bmalloc(sample_count * sizeof(float));
	float *output_interleaved = bmalloc(sample_count * sizeof(float));

	// Convert planar audio to interleaved
	for (uint32_t ch = 0; ch < channels; ch++) {
		float *channel_data = (float *)audio->data[ch];
		for (uint32_t i = 0; i < frames; i++) {
			input_interleaved[i * channels + ch] = channel_data[i];
		}
	}

	// Process through AI engine
	audio_engine_interface_t *engine = g_engines[filter->current_engine];
	engine->process(filter->engine_context,
	                input_interleaved,
	                output_interleaved,
	                frames);

	// Apply strength (blend original and isolated)
	// strength = 1.0: 100% isolated voice
	// strength = 0.0: 100% original audio
	for (size_t i = 0; i < sample_count; i++) {
		output_interleaved[i] = input_interleaved[i] * (1.0f - filter->strength) +
		                        output_interleaved[i] * filter->strength;
	}

	// Convert interleaved back to planar
	for (uint32_t ch = 0; ch < channels; ch++) {
		float *channel_data = (float *)audio->data[ch];
		for (uint32_t i = 0; i < frames; i++) {
			channel_data[i] = output_interleaved[i * channels + ch];
		}
	}

	// Performance monitoring
	filter->process_time_ns = os_gettime_ns() - start_time;
	filter->frames_processed += frames;

	// Log performance every 1000 frames
	if (filter->frames_processed >= filter->sample_rate) {
		double process_time_ms = filter->process_time_ns / 1000000.0;
		double audio_duration_ms = (frames * 1000.0) / filter->sample_rate;
		double rtf = process_time_ms / audio_duration_ms; // Real-time factor

		blog(LOG_DEBUG, "Processing: %.2f ms for %.2f ms audio (RTF: %.3f)",
		     process_time_ms, audio_duration_ms, rtf);

		filter->frames_processed = 0;
	}

	bfree(input_interleaved);
	bfree(output_interleaved);

	pthread_mutex_unlock(&filter->mutex);

	return audio;
}

// ===== PROPERTIES (UI) =====

static obs_properties_t *audio_isolator_properties(void *data)
{
	UNUSED_PARAMETER(data);

	obs_properties_t *props = obs_properties_create();

	// Enable checkbox
	obs_properties_add_bool(props, S_ENABLED, TEXT_ENABLED);

	// Engine selection dropdown
	obs_property_t *engine_list = obs_properties_add_list(
		props, S_ENGINE, TEXT_ENGINE,
		OBS_COMBO_TYPE_LIST, OBS_COMBO_FORMAT_STRING
	);

	obs_property_list_add_string(engine_list,
		"Sherpa-ONNX (Fast, CPU)", "sherpa");
	obs_property_list_add_string(engine_list,
		"HS-TasNet (Low Latency, GPU)", "hstasnet");
	obs_property_list_add_string(engine_list,
		"ClearerVoice (Best Speech)", "clearervoice");
	obs_property_list_add_string(engine_list,
		"SpleeterRT (High Quality)", "spleeterrt");

	obs_property_set_long_description(engine_list,
		"Select the AI engine for audio separation.\n"
		"Sherpa-ONNX: Best for CPU-only systems (80ms latency)\n"
		"HS-TasNet: Lowest latency with GPU (25ms latency)\n"
		"ClearerVoice: Best speech clarity (50ms latency)\n"
		"SpleeterRT: Highest quality separation (100ms latency)");

	// Strength slider (0-100%)
	obs_properties_add_float_slider(props, S_STRENGTH, TEXT_STRENGTH,
	                                 0.0, 1.0, 0.01);

	// Video delay (ms) - for lip-sync compensation
	obs_property_t *delay = obs_properties_add_int(props, S_VIDEO_DELAY,
		TEXT_VIDEO_DELAY, 0, 500, 1);
	obs_property_set_long_description(delay,
		"Video delay in milliseconds to compensate for audio processing latency.\n"
		"Set to 0 for automatic delay based on selected engine.\n"
		"Increase this if you notice lip-sync issues (video ahead of audio).");
	obs_property_int_set_suffix(delay, " ms");

	// Auto-detect checkbox
	obs_properties_add_bool(props, S_AUTO_DETECT, TEXT_AUTO_DETECT);

	return props;
}

static void audio_isolator_defaults(obs_data_t *settings)
{
	obs_data_set_default_string(settings, S_ENGINE, "sherpa");
	obs_data_set_default_double(settings, S_STRENGTH, 0.85);
	obs_data_set_default_bool(settings, S_AUTO_DETECT, false);
	obs_data_set_default_bool(settings, S_ENABLED, true);
	obs_data_set_default_int(settings, S_VIDEO_DELAY, 0); // Auto
}

// ===== REGISTER FILTER =====

struct obs_source_info audio_isolator_filter = {
	.id = PLUGIN_NAME,
	.type = OBS_SOURCE_TYPE_FILTER,
	.output_flags = OBS_SOURCE_AUDIO,
	.get_name = audio_isolator_get_name,
	.create = audio_isolator_create,
	.destroy = audio_isolator_destroy,
	.update = audio_isolator_update,
	.filter_audio = audio_isolator_filter_audio,
	.get_properties = audio_isolator_properties,
	.get_defaults = audio_isolator_defaults,
};
