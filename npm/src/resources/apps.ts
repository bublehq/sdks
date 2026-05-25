import { BubleCanceledError, BubleGenerationError, BubleTimeoutError } from '../errors.js';
import type { BubleHTTPClient } from '../http.js';
import type { RequestOptions, WaitOptions } from '../types/common.js';
import type {
  AppGenerationTaskEnvelope,
  AppListOptions,
  CreateAppGenerationRequest,
  PublicAppEnvelope,
  PublicAppsEnvelope
} from '../types/apps.js';

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

class AppGenerationsResource {
  private readonly http: BubleHTTPClient;

  constructor(http: BubleHTTPClient) {
    this.http = http;
  }

  create(app: string, body: CreateAppGenerationRequest, options?: RequestOptions) {
    return this.http.post<AppGenerationTaskEnvelope>(
      `/api/v1/apps/${encodeURIComponent(app)}/generations`,
      body,
      options
    );
  }

  retrieve(app: string, id: string, options?: RequestOptions) {
    return this.http.get<AppGenerationTaskEnvelope>(
      `/api/v1/apps/${encodeURIComponent(app)}/generations/${encodeURIComponent(id)}`,
      undefined,
      options
    );
  }

  async wait(app: string, id: string, options: WaitOptions = {}) {
    const startedAt = Date.now();
    const interval = options.interval ?? DEFAULT_WAIT_INTERVAL;
    const timeout = options.timeout ?? DEFAULT_WAIT_TIMEOUT;
    const throwOnFailed = options.throwOnFailed ?? true;
    const throwOnCanceled = options.throwOnCanceled ?? true;

    while (true) {
      if (Date.now() - startedAt > timeout) {
        throw new BubleTimeoutError(`App generation ${id} did not finish within ${timeout}ms.`, timeout);
      }

      const envelope = await this.retrieve(app, id, options);
      const task = envelope.data;

      if (TERMINAL_STATUSES.has(task.status)) {
        if (task.status === 'failed' && throwOnFailed) {
          throw new BubleGenerationError(task.error?.message || 'App generation failed.', task);
        }
        if (task.status === 'canceled' && throwOnCanceled) {
          throw new BubleCanceledError(`App generation ${id} was canceled.`, task);
        }
        return envelope;
      }

      await sleep(interval, options.signal);
    }
  }
}

export class AppsResource {
  private readonly http: BubleHTTPClient;
  readonly generations: AppGenerationsResource;

  constructor(http: BubleHTTPClient) {
    this.http = http;
    this.generations = new AppGenerationsResource(http);
  }

  list(options: AppListOptions = {}) {
    const { page, limit, ...requestOptions } = options;
    return this.http.get<PublicAppsEnvelope>('/api/v1/apps', { page, limit }, requestOptions);
  }

  retrieve(app: string, options?: RequestOptions) {
    return this.http.get<PublicAppEnvelope>(
      `/api/v1/apps/${encodeURIComponent(app)}`,
      undefined,
      options
    );
  }
}
