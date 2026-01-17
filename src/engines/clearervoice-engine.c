/*
 * ClearerVoice Engine Implementation
 *
 * State-of-the-art speech enhancement and separation
 * Best for speech clarity and voice isolation
 * Expected latency: ~50ms
 */

#include "../audio-isolator-filter.h"
#include <util/platform.h>
#include <onnxruntime_c_api.h>

struct clearervoice_engine_context {
	OrtSession *session;
	OrtEnv *env;
	OrtMemoryInfo *memory_info;
	const OrtApi *ort_api;

	uint32_t sample_rate;
	uint8_t channels;

	const char *input_names[1];
	const char *output_names[1];
};

static audio_engine_context_t *clearervoice_create(uint32_t sample_rate, uint8_t channels)
{
	struct clearervoice_engine_context *ctx = bzalloc(sizeof(*ctx));
	ctx->sample_rate = sample_rate;
	ctx->channels = channels;
	ctx->ort_api = OrtGetApiBase()->GetApi(ORT_API_VERSION);

	blog(LOG_INFO, "Initializing ClearerVoice engine...");

	// Create environment
	OrtStatus *status = ctx->ort_api->CreateEnv(ORT_LOGGING_LEVEL_WARNING,
	                                             "ClearerVoiceEngine", &ctx->env);
	if (status != NULL) {
		ctx->ort_api->ReleaseStatus(status);
		bfree(ctx);
		return NULL;
	}

	// Create session options
	OrtSessionOptions *session_options;
	ctx->ort_api->CreateSessionOptions(&session_options);

	// Balanced CPU/GPU settings
	ctx->ort_api->SetIntraOpNumThreads(session_options, 4);
	ctx->ort_api->SetSessionGraphOptimizationLevel(session_options, ORT_ENABLE_ALL);

	// Load model
	const char *model_path = get_plugin_data_path("models/clearervoice.onnx");
	blog(LOG_INFO, "Loading ClearerVoice model from: %s", model_path);

	status = ctx->ort_api->CreateSession(ctx->env, model_path,
	                                      session_options, &ctx->session);
	if (status != NULL) {
		blog(LOG_ERROR, "Failed to load ClearerVoice model");
		const char *error_msg = ctx->ort_api->GetErrorMessage(status);
		blog(LOG_ERROR, "ONNX Error: %s", error_msg);
		ctx->ort_api->ReleaseStatus(status);
		ctx->ort_api->ReleaseSessionOptions(session_options);
		ctx->ort_api->ReleaseEnv(ctx->env);
		bfree(ctx);
		return NULL;
	}

	ctx->ort_api->ReleaseSessionOptions(session_options);

	// Create memory info
	ctx->ort_api->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault,
	                                   &ctx->memory_info);

	ctx->input_names[0] = "input";
	ctx->output_names[0] = "output";

	blog(LOG_INFO, "ClearerVoice engine initialized successfully");

	return (audio_engine_context_t *)ctx;
}

static void clearervoice_destroy(audio_engine_context_t *data)
{
	struct clearervoice_engine_context *ctx = (struct clearervoice_engine_context *)data;

	if (ctx->memory_info) {
		ctx->ort_api->ReleaseMemoryInfo(ctx->memory_info);
	}
	if (ctx->session) {
		ctx->ort_api->ReleaseSession(ctx->session);
	}
	if (ctx->env) {
		ctx->ort_api->ReleaseEnv(ctx->env);
	}

	bfree(ctx);
	blog(LOG_INFO, "ClearerVoice engine destroyed");
}

static void clearervoice_process(audio_engine_context_t *data,
                                 const float *input,
                                 float *output,
                                 size_t frames)
{
	struct clearervoice_engine_context *ctx = (struct clearervoice_engine_context *)data;

	// Input shape: [batch, samples, channels]
	int64_t input_shape[] = {1, (int64_t)frames, ctx->channels};
	const size_t input_tensor_size = frames * ctx->channels;

	// Create input tensor
	OrtValue *input_tensor = NULL;
	OrtStatus *status = ctx->ort_api->CreateTensorWithDataAsOrtValue(
		ctx->memory_info,
		(void *)input,
		input_tensor_size * sizeof(float),
		input_shape,
		3,
		ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT,
		&input_tensor
	);

	if (status != NULL) {
		ctx->ort_api->ReleaseStatus(status);
		memcpy(output, input, input_tensor_size * sizeof(float));
		return;
	}

	// Run inference
	OrtValue *output_tensor = NULL;
	status = ctx->ort_api->Run(
		ctx->session, NULL,
		ctx->input_names, (const OrtValue *const *)&input_tensor, 1,
		ctx->output_names, 1,
		&output_tensor
	);

	if (status != NULL) {
		ctx->ort_api->ReleaseStatus(status);
		ctx->ort_api->ReleaseValue(input_tensor);
		memcpy(output, input, input_tensor_size * sizeof(float));
		return;
	}

	// Get output
	float *output_data;
	ctx->ort_api->GetTensorMutableData(output_tensor, (void **)&output_data);
	memcpy(output, output_data, input_tensor_size * sizeof(float));

	// Cleanup
	ctx->ort_api->ReleaseValue(input_tensor);
	ctx->ort_api->ReleaseValue(output_tensor);
}

static uint32_t clearervoice_get_latency_ms(audio_engine_context_t *data)
{
	UNUSED_PARAMETER(data);
	return 50; // Medium latency, best quality
}

static bool clearervoice_requires_gpu(void)
{
	return false; // Works well on CPU
}

audio_engine_interface_t clearervoice_engine = {
	.name = "clearervoice",
	.display_name = "ClearerVoice",
	.model_filename = "models/clearervoice.onnx",
	.create = clearervoice_create,
	.destroy = clearervoice_destroy,
	.process = clearervoice_process,
	.get_latency_ms = clearervoice_get_latency_ms,
	.requires_gpu = clearervoice_requires_gpu,
};
