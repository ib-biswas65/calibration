export class ApiError extends Error {
  status: number;
  detail: unknown;
  constructor(status: number, detail: unknown) {
    super(`ApiError ${status}`);
    this.status = status;
    this.detail = detail;
  }
}

type Init = Omit<RequestInit, "body"> & { json?: unknown; body?: BodyInit | null };

export async function apiFetch<T>(path: string, init: Init = {}): Promise<T> {
  const { json, headers, ...rest } = init;
  const finalHeaders: HeadersInit = {
    ...(json !== undefined ? { "Content-Type": "application/json" } : {}),
    ...headers,
  };
  const resp = await fetch(path, {
    credentials: "include",
    ...rest,
    headers: finalHeaders,
    body: json !== undefined ? JSON.stringify(json) : (rest as RequestInit).body,
  });
  if (!resp.ok) {
    let detail: unknown = null;
    try {
      detail = await resp.json();
    } catch {
      /* ignore */
    }
    throw new ApiError(resp.status, detail);
  }
  if (resp.status === 204) return undefined as T;
  return (await resp.json()) as T;
}
