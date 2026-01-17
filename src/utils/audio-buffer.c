/*
 * Audio Buffer Utilities
 *
 * Circular buffer implementation for chunked audio processing
 * Helps manage variable-size audio frames and fixed-size model inputs
 */

#include "../audio-isolator-filter.h"
#include <util/circlebuf.h>
#include <string.h>

// Simple ring buffer for audio samples
void audio_buffer_init(struct circlebuf *buf, size_t size)
{
	circlebuf_init(buf);
	circlebuf_reserve(buf, size * sizeof(float));
}

void audio_buffer_free(struct circlebuf *buf)
{
	circlebuf_free(buf);
}

void audio_buffer_push(struct circlebuf *buf, const float *data, size_t count)
{
	circlebuf_push_back(buf, data, count * sizeof(float));
}

size_t audio_buffer_pop(struct circlebuf *buf, float *data, size_t count)
{
	size_t available = buf->size / sizeof(float);
	size_t to_pop = (count < available) ? count : available;

	if (to_pop > 0) {
		circlebuf_pop_front(buf, data, to_pop * sizeof(float));
	}

	return to_pop;
}

size_t audio_buffer_peek(struct circlebuf *buf, float *data, size_t count)
{
	size_t available = buf->size / sizeof(float);
	size_t to_peek = (count < available) ? count : available;

	if (to_peek > 0) {
		memcpy(data, buf->data, to_peek * sizeof(float));
	}

	return to_peek;
}

size_t audio_buffer_available(struct circlebuf *buf)
{
	return buf->size / sizeof(float);
}

void audio_buffer_clear(struct circlebuf *buf)
{
	circlebuf_free(buf);
	circlebuf_init(buf);
}

// Helper: Convert planar audio to interleaved
void audio_planar_to_interleaved(const float **planar, float *interleaved,
                                  size_t frames, uint8_t channels)
{
	for (size_t i = 0; i < frames; i++) {
		for (uint8_t ch = 0; ch < channels; ch++) {
			interleaved[i * channels + ch] = planar[ch][i];
		}
	}
}

// Helper: Convert interleaved audio to planar
void audio_interleaved_to_planar(const float *interleaved, float **planar,
                                  size_t frames, uint8_t channels)
{
	for (size_t i = 0; i < frames; i++) {
		for (uint8_t ch = 0; ch < channels; ch++) {
			planar[ch][i] = interleaved[i * channels + ch];
		}
	}
}
