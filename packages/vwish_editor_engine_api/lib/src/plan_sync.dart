// OWNER: API-02
//
// Placeholder (D-33). API-02 implements `PlanSync` (ARCH §13.1): schedule(project) with ≤ 1
// compile in flight (latest wins), compile in an isolate above 300 items, diff, applyPatch,
// planOutOfSync → setPlan(full) once → else PreviewFailed.

library;
