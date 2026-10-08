/* OWNER: AI-02
 *
 * vwish whisper shim, C ABI version 1 (ai.md §4.5, ARCH §16.1). Implemented by AI-03
 * (src/vw_*.cpp) on top of the vendored whisper.cpp v1.9.4 (AI-01).
 *
 * Rules: every entry point is extern "C", default visibility, wrapped in try/catch (C++ exceptions
 * map to VW_ERR_OOM / VW_ERR_INTERNAL) and thread-safe. Every struct starts with struct_size for
 * forward compatibility. All strings passed in are copied. Jobs run on native std::threads; Dart
 * polls status and segments every 250 ms with leaf calls; no Dart callbacks cross threads.
 * Transcript text, prompts and file paths are never logged.
 */
#ifndef VW_WHISPER_H
#define VW_WHISPER_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#define VW_API __declspec(dllexport)
#else
#define VW_API __attribute__((visibility("default"))) __attribute__((used))
#endif

#define VW_ABI_VERSION 1

typedef enum {
  VW_OK = 0,
  VW_ERR_INVALID_ARG = 1,
  VW_ERR_MODEL_LOAD = 2,
  VW_ERR_WAV_FORMAT = 3,
  VW_ERR_IO = 4,
  VW_ERR_OOM = 5,
  VW_ERR_CANCELLED = 6,
  VW_ERR_INFERENCE = 7,
  VW_ERR_BUSY = 8,
  VW_ERR_VAD_MODEL = 9,
  VW_ERR_NO_SPEECH = 10,
  VW_ERR_INTERNAL = 99
} vw_status;

typedef enum { VW_MODEL_LOADING = 0, VW_MODEL_READY = 1, VW_MODEL_FAILED = 2 } vw_model_state;

typedef enum {
  VW_JOB_RUNNING = 1,
  VW_JOB_PAUSED = 2,
  VW_JOB_SUCCEEDED = 3,
  VW_JOB_FAILED = 4,
  VW_JOB_CANCELLED = 5
} vw_job_state;

typedef enum { VW_MODE_TRANSCRIBE = 0, VW_MODE_DETECT_LANGUAGE = 1 } vw_job_mode;

typedef enum { VW_PHASE_PREPARING = 0, VW_PHASE_VAD = 1, VW_PHASE_ENCODING = 2, VW_PHASE_DECODING = 3 } vw_phase;

typedef struct vw_model vw_model;
typedef struct vw_job vw_job;

typedef struct {
  int32_t struct_size;
  int32_t use_gpu;    /* request; the shim applies the iOS GPU policy and may downgrade */
  int32_t flash_attn; /* 1 (default) */
  int32_t dtw_preset; /* 0 = off (default); else whisper_alignment_heads_preset; forces flash_attn = 0 */
} vw_model_params;

typedef struct {
  int32_t struct_size;
  int32_t multilingual, n_vocab, model_type, ftype;
  int32_t gpu_used, gpu_fallback;
} vw_model_info;

typedef struct {
  int32_t struct_size;
  int32_t mode;               /* vw_job_mode */
  const char *wav_path;       /* 16 kHz, mono, PCM s16le, canonical RIFF/WAVE; validated */
  int64_t range_start_ms;     /* inclusive, relative to WAV start; resume point */
  int64_t range_end_ms;       /* exclusive; -1 = end of file */
  const char *language;       /* whisper code ("en", "ja", ...); "auto" only in DETECT mode */
  int32_t n_threads;          /* 1..8; may change later via vw_job_set_threads */
  int32_t chunk_target_ms;    /* 180000 */
  int32_t chunk_search_ms;    /* 15000: search +-this around the target for the quietest 400 ms */
  int32_t chunk_min_ms;       /* 10000: a shorter tail merges into the previous chunk */
  int32_t vad_enabled;
  const char *vad_model_path; /* ggml-silero-v6.2.0.bin */
  float vad_threshold;        /* 0.5 */
  int32_t vad_min_speech_ms;  /* 250 */
  int32_t vad_min_silence_ms; /* 300 */
  int32_t vad_speech_pad_ms;  /* 100 */
  float vad_samples_overlap_s; /* 0.1 */
  int32_t token_timestamps;   /* 1 */
  float no_speech_thold, entropy_thold, logprob_thold, temperature_inc; /* 0.6, 2.4, -1.0, 0.2 */
  int32_t beam_size;          /* <= 1: greedy */
  int32_t best_of;            /* 5 (temperature fallback only) */
  int32_t suppress_nst;       /* 1 unless the user wants sound descriptions */
  int32_t carry_prompt_words; /* 0..40: tail of the previous chunk used as initial_prompt */
  const char *initial_prompt; /* nullable; unused by the v1 UI */
  int32_t detect_max_speech_ms; /* DETECT: up to 30000 ms of speech after the first VAD speech start */
  int32_t detect_search_ms;     /* DETECT: search window for the first speech (600000) */
} vw_job_params;

typedef struct {
  int32_t struct_size;
  int32_t state;             /* vw_job_state */
  int32_t error;             /* vw_status (valid when FAILED/CANCELLED) */
  int32_t phase;             /* vw_phase */
  int32_t progress_permille; /* 0..1000 over [range_start, range_end) */
  int32_t chunk_index, chunk_count; /* 0-based current chunk; count known after planning */
  int32_t chunks_completed;  /* chunks whose segments are final */
  int32_t segments_ready;    /* segments available to take */
  int64_t processed_ms;      /* audio covered by completed work */
  int64_t compute_ms;        /* wall time spent in whisper calls (excludes pauses) */
  int32_t threads;           /* current n_threads */
  char language[8];          /* language used/detected */
  float language_p;
} vw_job_status;

/* library */
VW_API int32_t vw_abi_version(void);
VW_API const char *vw_engine_version(void);   /* whisper_version(), e.g. "1.9.4" */
VW_API const char *vw_system_info(void);      /* diagnostics only */
VW_API uint64_t vw_cpu_features(void);        /* Android: HWCAP-derived bitmask; iOS: 0 */
VW_API int32_t vw_perf_core_count(void);      /* iOS: hw.perflevel0.physicalcpu; Android: 0 */
VW_API void vw_set_log_level(int32_t level);  /* 0 off ... 4 debug; never logs text or paths */
VW_API int32_t vw_lang_max_id(void);
VW_API const char *vw_lang_code(int32_t id);  /* whisper_lang_str */
VW_API void vw_shutdown_all(void);            /* cancel+join all jobs, free all models (hot restart) */
VW_API void vw_free(void *p);

/* model */
VW_API vw_model *vw_model_load(const char *model_path, const vw_model_params *params); /* loads on a native thread */
VW_API int32_t vw_model_get_state(const vw_model *m); /* vw_model_state; renamed from ai.md's vw_model_state(), which collided with the enum typedef */
VW_API int32_t vw_model_error(const vw_model *m, char *buf, int32_t buf_len);
VW_API int32_t vw_model_info_get(const vw_model *m, vw_model_info *out);
VW_API void vw_model_release(vw_model *m); /* refcounted; freed after the last job using it */

/* job: at most one active job per model (VW_ERR_BUSY otherwise) */
VW_API vw_job *vw_job_start(vw_model *m, const vw_job_params *params, int32_t *out_status);
VW_API void vw_job_status_get(const vw_job *j, vw_job_status *out); /* leaf, O(1) */
VW_API char *vw_job_take_segments_json(vw_job *j, int32_t from_index, int32_t max_count); /* free with vw_free */
VW_API char *vw_job_language_probs_json(vw_job *j, int32_t top_n); /* DETECT result; free with vw_free */
VW_API void vw_job_cancel(vw_job *j);
VW_API void vw_job_pause(vw_job *j, int32_t abort_current_chunk); /* 0: at next chunk; 1: abort and redo on resume */
VW_API void vw_job_resume(vw_job *j);
VW_API void vw_job_set_threads(vw_job *j, int32_t n_threads); /* applied at the next chunk */
VW_API void vw_job_free(vw_job *j); /* cancels if running, joins the thread, frees */

#ifdef __cplusplus
}
#endif

#endif /* VW_WHISPER_H */
