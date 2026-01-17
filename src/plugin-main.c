/*
 * Stream Audio Isolator Plugin for OBS Studio
 * Real-time audio separation to remove background music from streams
 *
 * Features:
 * - Multiple AI engines (Sherpa-ONNX, HS-TasNet, ClearerVoice, SpleeterRT)
 * - Automatic lip-sync delay compensation
 * - GPU and CPU support
 * - Adjustable isolation strength
 */

#include <obs-module.h>
#include <util/platform.h>

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE("stream-audio-isolator", "en-US")

MODULE_EXPORT const char *obs_module_description(void)
{
	return "Real-time audio isolation plugin - removes background music from streams";
}

extern struct obs_source_info audio_isolator_filter;

bool obs_module_load(void)
{
	blog(LOG_INFO, "================================");
	blog(LOG_INFO, "Stream Audio Isolator v1.0.0");
	blog(LOG_INFO, "Real-time music removal for streams");
	blog(LOG_INFO, "================================");

	obs_register_source(&audio_isolator_filter);

	blog(LOG_INFO, "Audio Isolator Filter registered successfully");
	blog(LOG_INFO, "Available engines: Sherpa-ONNX, HS-TasNet, ClearerVoice, SpleeterRT");

	return true;
}

void obs_module_unload(void)
{
	blog(LOG_INFO, "Stream Audio Isolator plugin unloaded");
}

MODULE_EXPORT const char *obs_module_name(void)
{
	return "Stream Audio Isolator";
}
