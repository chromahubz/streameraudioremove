/*
 * Sherpa-ONNX Engine Implementation
 *
 * Fast CPU-based audio separation using ONNX Runtime
 * Best for systems without GPU
 * Expected latency: ~80ms
 */

#include "../audio-isolator-filter.h"
#include <util/platform.h>
#include <onnxruntime_c_api.h>

// Sherpa engine context
struct sherpa_engine_context {
	OrtSession *session;
	OrtEnv *env;
	OrtMemoryInfo *memory_info;
	const OrtApi *ort_api;

	uint32_t sample_rate;
	uint8_t channels;

	// Model input/output names
	const char *input_names[1];
	const char *output_names[1];

	// Processing buffer
	float *temp_buffer;
	size_t temp_buffer_size;
};

// ===== INITIALIZATION =====

static audio_engine_context_t *sherpa_create(uint32_t sample_rate, uint8_t channels)
{
	struct sherpa_engine_context *ctx = bzalloc(sizeof(*ctx));
	ctx->sample_rate = sample_rate;
	ctx->channels = channels;
	ctx->ort_api = OrtGetApiBase()->GetApi(ORT_API_VERSION);

	blog(LOG_INFO, "Initializing Sherpa-ONNX engine...");

	// Create ONNX Runtime environment
	OrtStatus *status = ctx->ort_api->CreateEnv(ORT_LOGGING_LEVEL_WARNING,
	                                             "SherpaEngine", &ctx->env);
	if (status != NULL) {
		blog(LOG_ERROR, "Failed to create ONNX environment");
		ctx->ort_api->ReleaseStatus(status);
		bfree(ctx);
		return NULL;
	}

	// Create session options
	OrtSessionOptions *session_options;
	ctx->ort_api->CreateSessionOptions(&session_options);

	// Optimize for CPU
	ctx->ort_api->SetIntraOpNumThreads(session_options, 4);
	ctx->ort_api->SetInterOpNumThreads(session_options, 2);
	ctx->ort_api->SetSessionGraphOptimizationLevel(session_options, ORT_ENABLE_ALL);

	// Optional: Enable CPU optimizations
	// ctx->ort_api->SetSessionExecutionMode(session_options, ORT_SEQUENTIAL);

	// Load model
	const char *model_path = get_plugin_data_path("models/sherpa-vocals.onnx");
	blog(LOG_INFO, "Loading Sherpa model from: %s", model_path);

	status = ctx->ort_api->CreateSession(ctx->env, model_path,
	                                      session_options, &ctx->session);
	if (status != NULL) {
		blog(LOG_ERROR, "Failed to load Sherpa model: %s", model_path);
		const char *error_msg = ctx->ort_api->GetErrorMessage(status);
		blog(LOG_ERROR, "ONNX Error: %s", error_msg);
		ctx->ort_api->ReleaseStatus(status);
		ctx->ort_api->ReleaseSessionOptions(session_options);
		ctx->ort_api->ReleaseEnv(ctx->env);
		bfree(ctx);
		return NULL;
	}

	ctx->ort_api->ReleaseSessionOptions(session_options);

	// Create memory info for CPU
	ctx->ort_api->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault,
	                                   &ctx->memory_info);

	// Set input/output names (these depend on the actual model)
	// You'll need to adjust these based on your ONNX model's I/O names
	ctx->input_names[0] = "audio";
	ctx->output_names[0] = "vocals";

	blog(LOG_INFO, "Sherpa-ONNX engine initialized successfully");
	blog(LOG_INFO, "  Sample rate: %u Hz", sample_rate);
	blog(LOG_INFO, "  Channels: %u", channels);

	return (audio_engine_context_t *)ctx;
}

// ===== CLEANUP =====

static void sherpa_destroy(audio_engine_context_t *data)
{
	struct sherpa_engine_context *ctx = (struct sherpa_engine_context *)data;

	if (ctx->temp_buffer) {
		bfree(ctx->temp_buffer);
	}

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
	blog(LOG_INFO, "Sherpa-ONNX engine destroyed");
}

// ===== PROCESSING =====

static void sherpa_process(audio_engine_context_t *data,
                           const float *input,
                           float *output,
                           size_t frames)
{
	struct sherpa_engine_context *ctx = (struct sherpa_engine_context *)data;

	// Prepare input tensor shape: [batch, frames, channels]
	// Some models might expect [batch, channels, frames] - adjust as needed
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
		blog(LOG_ERROR, "Failed to create input tensor");
		ctx->ort_api->ReleaseStatus(status);
		// Fallback: copy input to output (pass-through)
		memcpy(output, input, input_tensor_size * sizeof(float));
		return;
	}

	// Run inference
	OrtValue *output_tensor = NULL;
	status = ctx->ort_api->Run(
		ctx->session,
		NULL, // Run options
		ctx->input_names,
		(const OrtValue *const *)&input_tensor,
		1, // Number of inputs
		ctx->output_names,
		1, // Number of outputs
		&output_tensor
	);

	if (status != NULL) {
		blog(LOG_ERROR, "Failed to run inference");
		const char *error_msg = ctx->ort_api->GetErrorMessage(status);
		blog(LOG_ERROR, "ONNX Error: %s", error_msg);
		ctx->ort_api->ReleaseStatus(status);
		ctx->ort_api->ReleaseValue(input_tensor);
		// Fallback: copy input to output
		memcpy(output, input, input_tensor_size * sizeof(float));
		return;
	}

	// Get output data
	float *output_data;
	status = ctx->ort_api->GetTensorMutableData(output_tensor, (void **)&output_data);
	if (status != NULL) {
		blog(LOG_ERROR, "Failed to get output data");
		ctx->ort_api->ReleaseStatus(status);
		ctx->ort_api->ReleaseValue(input_tensor);
		ctx->ort_api->ReleaseValue(output_tensor);
		memcpy(output, input, input_tensor_size * sizeof(float));
		return;
	}

	// Copy output data
	memcpy(output, output_data, input_tensor_size * sizeof(float));

	// Cleanup
	ctx->ort_api->ReleaseValue(input_tensor);
	ctx->ort_api->ReleaseValue(output_tensor);
}

// ===== INFO =====

static uint32_t sherpa_get_latency_ms(audio_engine_context_t *data)
{
	UNUSED_PARAMETER(data);
	return 80; // ~80ms typical latency for Sherpa-ONNX
}

static bool sherpa_requires_gpu(void)
{
	return false; // CPU-only
}

// ===== ENGINE INTERFACE =====

audio_engine_interface_t sherpa_engine = {
	.name = "sherpa",
	.display_name = "Sherpa-ONNX (CPU)",
	.model_filename = "models/sherpa-vocals.onnx",
	.create = sherpa_create,
	.destroy = sherpa_destroy,
	.process = sherpa_process,
	.get_latency_ms = sherpa_get_latency_ms,
	.requires_gpu = sherpa_requires_gpu,
};
