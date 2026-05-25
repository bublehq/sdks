import { BubleCanceledError, BubleGenerationError, BubleTimeoutError } from '../errors.js';
import type { BubleHTTPClient } from '../http.js';
import type { RequestOptions, WaitOptions } from '../types/common.js';
import type {
  CreateGenerationRequest,
  GenerationTask,
  GenerationTaskEnvelope
} from '../types/generations.js';

const DEFAULT_WAIT_INTERVAL = 2_000;
const DEFAULT_WAIT_TIMEOUT = 10 * 60_000;
const TERMINAL_STATUSES = new Set(['success', 'failed', 'canceled']);

function sleep(ms: number, signal?: AbortSignal) {
  return new Promise<void>((resolve, reject) => {
    const timer = setTimeout(resolve, ms);
    if (signal) {
      signal.addEventListener(
        'abort',
        () => {
          clearTimeout(timer);
          reject(signal.reason || new Error('Aborted.'));
        },
        { once: true }
      );
    }
  });
}

export class GenerationsResource {
  private readonly http: BubleHTTPClient;

  constructor(http: BubleHTTPClient) {
    this.http = http;
  }

  create(body: CreateGenerationRequest, options?: RequestOptions) {
    this.http.assertPublicGenerationBody(body);
    return this.http.post<GenerationTaskEnvelope>('/api/v1/generations', body, options);
  }

  retrieve(id: string, options?: RequestOptions) {
    return this.http.get<GenerationTaskEnvelope>(
      `/api/v1/generations/${encodeURIComponent(id)}`,
      undefined,
      options
    );
  }

  async wait(id: string, options: WaitOptions = {}) {
    const startedAt = Date.now();
    const interval = options.interval ?? DEFAULT_WAIT_INTERVAL;
    const timeout = options.timeout ?? DEFAULT_WAIT_TIMEOUT;
    const throwOnFailed = options.throwOnFailed ?? true;
    const throwOnCanceled = options.throwOnCanceled ?? true;

    while (true) {
      if (Date.now() - startedAt > timeout) {
        throw new BubleTimeoutError(`Generation ${id} did not finish within ${timeout}ms.`, timeout);
      }

      const envelope = await this.retrieve(id, options);
      const task = envelope.data;

      if (TERMINAL_STATUSES.has(task.status)) {
        if (task.status === 'failed' && throwOnFailed) {
          throw new BubleGenerationError(task.error?.message || 'Generation failed.', task);
        }
        if (task.status === 'canceled' && throwOnCanceled) {
          throw new BubleCanceledError(`Generation ${id} was canceled.`, task);
        }
        return envelope as GenerationTaskEnvelope & { data: GenerationTask };
      }

      await sleep(interval, options.signal);
    }
  }
}
