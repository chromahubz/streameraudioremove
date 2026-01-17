/*
 * SpleeterRT Engine Implementation
 *
 * Real-time version of Spleeter for high-quality music source separation
 * Best separation quality, higher latency
 * Expected latency: ~100ms
 */

#include "../audio-isolator-filter.h"
#include <util/platform.h>
#include <onnxruntime_c_api.h>

struct spleeterrt_engine_context {
	OrtSession *session;
	OrtEnv *env;
	OrtMemoryInfo *memory_info;
	const OrtApi *ort_api;

	uint32_t sample_rate;
	uint8_t channels;

	const char *input_names[1];
	const char *output_names[1];

	bool gpu_available;
};

static audio_engine_context_t *spleeterrt_create(uint32_t sample_rate, uint8_t channels)
{
	struct spleeterrt_engine_context *ctx = bzalloc(sizeof(*ctx));
	ctx->sample_rate = sample_rate;
	ctx->channels = channels;
	ctx->ort_api = OrtGetApiBase()->GetApi(ORT_API_VERSION);

	blog(LOG_INFO, "Initializing SpleeterRT engine...");

	// Create environment
	OrtStatus *status = ctx->ort_api->CreateEnv(ORT_LOGGING_LEVEL_WARNING,
	                                             "SpleeterRTEngine", &ctx->env);
	if (status != NULL) {
		ctx->ort_api->ReleaseStatus(status);
		bfree(ctx);
		return NULL;
	}

	// Create session options
	OrtSessionOptions *session_options;
	ctx->ort_api->CreateSessionOptions(&session_options);

	// Try GPU first for best performance
	OrtStatus *cuda_status = OrtSessionOptionsAppendExecutionProvider_CUDA(session_options, 0);
	if (cuda_status == NULL) {
		ctx->gpu_available = true;
		blog(LOG_INFO, "GPU (CUDA) enabled for SpleeterRT");
	} else {
		ctx->gpu_available = false;
		blog(LOG_WARNING, "GPU not available for SpleeterRT, using CPU");
		ctx->ort_api->ReleaseStatus(cuda_status);

		// CPU configuration
		ctx->ort_api->SetIntraOpNumThreads(session_options, 6); // More threads for quality
		ctx->ort_api->SetInterOpNumThreads(session_options, 3);
	}

	ctx->ort_api->SetSessionGraphOptimizationLevel(session_options, ORT_ENABLE_ALL);

	// Load model
	const char *model_path = get_plugin_data_path("models/spleeterrt.onnx");
	blog(LOG_INFO, "Loading SpleeterRT model from: %s", model_path);

	status = ctx->ort_api->CreateSession(ctx->env, model_path,
	                                      session_options, &ctx->session);
	if (status != NULL) {
		blog(LOG_ERROR, "Failed to load SpleeterRT model");
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
	if (ctx->gpu_available) {
		ctx->ort_api->CreateMemoryInfo("Cuda", OrtAllocatorType::OrtArenaAllocator,
		                                0, OrtMemType::OrtMemTypeDefault, &ctx->memory_info);
	} else {
		ctx->ort_api->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault,
		                                   &ctx->memory_info);
	}

	ctx->input_names[0] = "waveform";
	ctx->output_names[0] = "vocals";

	blog(LOG_INFO, "SpleeterRT engine initialized successfully");
	blog(LOG_INFO, "  Device: %s", ctx->gpu_available ? "GPU (CUDA)" : "CPU");

	return (audio_engine_context_t *)ctx;
}

static void spleeterrt_destroy(audio_engine_context_t *data)
{
	struct spleeterrt_engine_context *ctx = (struct spleeterrt_engine_context *)data;

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
	blog(LOG_INFO, "SpleeterRT engine destroyed");
}

static void spleeterrt_process(audio_engine_context_t *data,
                               const float *input,
                               float *output,
                               size_t frames)
{
	struct spleeterrt_engine_context *ctx = (struct spleeterrt_engine_context *)data;

	// Input shape: [batch, channels, samples]
	int64_t input_shape[] = {1, ctx->channels, (int64_t)frames};
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
		blog(LOG_ERROR, "SpleeterRT: Failed to create input tensor");
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
		blog(LOG_ERROR, "SpleeterRT: Inference failed");
		const char *error_msg = ctx->ort_api->GetErrorMessage(status);
		blog(LOG_ERROR, "ONNX Error: %s", error_msg);
		ctx->ort_api->ReleaseStatus(status);
		ctx->ort_api->ReleaseValue(input_tensor);
		memcpy(output, input, input_tensor_size * sizeof(float));
		return;
	}

	// Get output
	float *output_data;
	status = ctx->ort_api->GetTensorMutableData(output_tensor, (void **)&output_data);
	if (status == NULL) {
		memcpy(output, output_data, input_tensor_size * sizeof(float));
	} else {
		ctx->ort_api->ReleaseStatus(status);
		memcpy(output, input, input_tensor_size * sizeof(float));
	}

	// Cleanup
	ctx->ort_api->ReleaseValue(input_tensor);
	ctx->ort_api->ReleaseValue(output_tensor);
}

static uint32_t spleeterrt_get_latency_ms(audio_engine_context_t *data)
{
	UNUSED_PARAMETER(data);
	return 100; // Higher latency for best quality
}

static bool spleeterrt_requires_gpu(void)
{
	return true; // Recommended for GPU
}

audio_engine_interface_t spleeterrt_engine = {
	.name = "spleeterrt",
	.display_name = "SpleeterRT (High Quality)",
	.model_filename = "models/spleeterrt.onnx",
	.create = spleeterrt_create,
	.destroy = spleeterrt_destroy,
	.process = spleeterrt_process,
	.get_latency_ms = spleeterrt_get_latency_ms,
	.requires_gpu = spleeterrt_requires_gpu,
};
