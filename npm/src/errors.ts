export class BubleError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'BubleError';
  }
}

export class BubleAPIError extends BubleError {
  readonly status: number;
  readonly code?: string;
  readonly details?: unknown;
  readonly response?: Response;

  constructor({
    message,
    status,
    code,
    details,
    response
  }: {
    message: string;
    status: number;
    code?: string;
    details?: unknown;
    response?: Response;
  }) {
    super(message);
    this.name = 'BubleAPIError';
    this.status = status;
    this.code = code;
    this.details = details;
    this.response = response;
  }
}

export class BubleTimeoutError extends BubleError {
  readonly timeout: number;

  constructor(message: string, timeout: number) {
    super(message);
    this.name = 'BubleTimeoutError';
    this.timeout = timeout;
  }
}

export class BubleGenerationError<TTask = unknown> extends BubleError {
  readonly task: TTask;

  constructor(message: string, task: TTask) {
    super(message);
    this.name = 'BubleGenerationError';
    this.task = task;
  }
}

export class BubleCanceledError<TTask = unknown> extends BubleError {
  readonly task: TTask;

  constructor(message: string, task: TTask) {
    super(message);
    this.name = 'BubleCanceledError';
    this.task = task;
  }
}
