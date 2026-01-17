/*
 * HS-TasNet Engine Implementation
 *
 * Hybrid Spectrogram-TasNet for low-latency music source separation
 * Optimized for GPU inference
 * Expected latency: ~25ms (lowest latency option)
 */

#include "../audio-isolator-filter.h"
#include <util/platform.h>
#include <onnxruntime_c_api.h>
#include <string.h>

struct hstasnet_engine_context {
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

static audio_engine_context_t *hstasnet_create(uint32_t sample_rate, uint8_t channels)
{
	struct hstasnet_engine_context *ctx = bzalloc(sizeof(*ctx));
	ctx->sample_rate = sample_rate;
	ctx->channels = channels;
	ctx->ort_api = OrtGetApiBase()->GetApi(ORT_API_VERSION);

	blog(LOG_INFO, "Initializing HS-TasNet engine...");

	// Create environment
	OrtStatus *status = ctx->ort_api->CreateEnv(ORT_LOGGING_LEVEL_WARNING,
	                                             "HSTasNetEngine", &ctx->env);
	if (status != NULL) {
		blog(LOG_ERROR, "Failed to create ONNX environment");
		ctx->ort_api->ReleaseStatus(status);
		bfree(ctx);
		return NULL;
	}

	// Create session options
	OrtSessionOptions *session_options;
	ctx->ort_api->CreateSessionOptions(&session_options);

	// Try to enable CUDA for GPU acceleration
	// Use CUDA provider if available (Windows/Linux with NVIDIA GPU)
	OrtCUDAProviderOptions cuda_options;
	memset(&cuda_options, 0, sizeof(cuda_options));
	cuda_options.device_id = 0;

	OrtStatus *cuda_status = ctx->ort_api->SessionOptionsAppendExecutionProvider_CUDA(
		session_options, &cuda_options);

	if (cuda_status == NULL) {
		ctx->gpu_available = true;
		blog(LOG_INFO, "GPU (CUDA) enabled for HS-TasNet");
	} else {
		ctx->gpu_available = false;
		blog(LOG_WARNING, "GPU not available, falling back to CPU");
		ctx->ort_api->ReleaseStatus(cuda_status);

		// Configure for CPU
		ctx->ort_api->SetIntraOpNumThreads(session_options, 4);
		ctx->ort_api->SetInterOpNumThreads(session_options, 2);
	}

	ctx->ort_api->SetSessionGraphOptimizationLevel(session_options, ORT_ENABLE_ALL);

	// Load model
	const char *model_path = get_plugin_data_path("models/hstasnet.onnx");
	blog(LOG_INFO, "Loading HS-TasNet model from: %s", model_path);

	status = ctx->ort_api->CreateSession(ctx->env, model_path,
	                                      session_options, &ctx->session);
	if (status != NULL) {
		blog(LOG_ERROR, "Failed to load HS-TasNet model");
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
		ctx->ort_api->CreateMemoryInfo("Cuda", OrtArenaAllocator,
		                                0, OrtMemTypeDefault, &ctx->memory_info);
	} else {
		ctx->ort_api->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault,
		                                   &ctx->memory_info);
	}

	ctx->input_names[0] = "input";
	ctx->output_names[0] = "vocals";

	blog(LOG_INFO, "HS-TasNet engine initialized successfully");
	blog(LOG_INFO, "  Device: %s", ctx->gpu_available ? "GPU (CUDA)" : "CPU");

	return (audio_engine_context_t *)ctx;
}

static void hstasnet_destroy(audio_engine_context_t *data)
{
	struct hstasnet_engine_context *ctx = (struct hstasnet_engine_context *)data;

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
	blog(LOG_INFO, "HS-TasNet engine destroyed");
}

static void hstasnet_process(audio_engine_context_t *data,
                             const float *input,
                             float *output,
                             size_t frames)
{
	struct hstasnet_engine_context *ctx = (struct hstasnet_engine_context *)data;

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
		blog(LOG_ERROR, "HS-TasNet: Failed to create input tensor");
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
		blog(LOG_ERROR, "HS-TasNet: Inference failed");
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

static uint32_t hstasnet_get_latency_ms(audio_engine_context_t *data)
{
	UNUSED_PARAMETER(data);
	return 25; // Low latency design
}

static bool hstasnet_requires_gpu(void)
{
	return true; // Optimized for GPU
}

audio_engine_interface_t hstasnet_engine = {
	.name = "hstasnet",
	.display_name = "HS-TasNet (GPU)",
	.model_filename = "models/hstasnet.onnx",
	.create = hstasnet_create,
	.destroy = hstasnet_destroy,
	.process = hstasnet_process,
	.get_latency_ms = hstasnet_get_latency_ms,
	.requires_gpu = hstasnet_requires_gpu,
};
